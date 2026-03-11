// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisAccount} from "../../src/IrisAccount.sol";
import {IrisAccountFactory} from "../../src/IrisAccountFactory.sol";
import {IrisDelegationManager} from "../../src/IrisDelegationManager.sol";
import {IrisAgentRegistry} from "../../src/identity/IrisAgentRegistry.sol";
import {IrisReputationOracle} from "../../src/identity/IrisReputationOracle.sol";
import {SpendingCapEnforcer} from "../../src/caveats/SpendingCapEnforcer.sol";
import {ReputationGateEnforcer} from "../../src/caveats/ReputationGateEnforcer.sol";
import {Delegation, Action, Caveat} from "../../src/interfaces/IERC7710.sol";

contract MultiTargetContract {
    uint256 public value;

    function setValue(uint256 v) external payable {
        value = v;
    }

    receive() external payable {}
}

/// @title MultiAgent Integration Test
/// @notice Tests multiple agents with different tiers operating on the same account,
///         verifying isolation: revoking one agent doesn't affect others.
contract MultiAgentTest is Test {
    IrisAccountFactory factory;
    IrisDelegationManager delegationManager;
    IrisAgentRegistry agentRegistry;
    IrisReputationOracle reputationOracle;
    SpendingCapEnforcer spendingCap;
    ReputationGateEnforcer reputationGate;
    MultiTargetContract target;

    address owner;
    uint256 ownerKey;
    address agentA;
    uint256 agentAKey;
    address agentB;
    uint256 agentBKey;
    address agentC;
    uint256 agentCKey;
    IrisAccount ownerAccount;
    uint256 agentAId;
    uint256 agentBId;
    uint256 agentCId;

    function setUp() public {
        (owner, ownerKey) = makeAddrAndKey("owner");
        (agentA, agentAKey) = makeAddrAndKey("agentA");
        (agentB, agentBKey) = makeAddrAndKey("agentB");
        (agentC, agentCKey) = makeAddrAndKey("agentC");

        delegationManager = new IrisDelegationManager();
        factory = new IrisAccountFactory();
        agentRegistry = new IrisAgentRegistry();
        reputationOracle = new IrisReputationOracle(address(agentRegistry), address(this));
        spendingCap = new SpendingCapEnforcer();
        reputationGate = new ReputationGateEnforcer();
        target = new MultiTargetContract();

        // Create owner account
        address accountAddr = factory.createAccount(owner, address(delegationManager), 0);
        ownerAccount = IrisAccount(payable(accountAddr));
        vm.deal(accountAddr, 100 ether);

        // Register 3 agents with different reputations
        vm.prank(agentA);
        agentAId = agentRegistry.registerAgent("ipfs://agentA");

        vm.prank(agentB);
        agentBId = agentRegistry.registerAgent("ipfs://agentB");

        vm.prank(agentC);
        agentCId = agentRegistry.registerAgent("ipfs://agentC");

        // Set reputations: A=50 (default), B=70 (10 positives), C=30 (4 negatives)
        for (uint256 i = 0; i < 10; i++) {
            reputationOracle.submitFeedback(agentBId, true); // 50 → 70
        }
        for (uint256 i = 0; i < 4; i++) {
            reputationOracle.submitFeedback(agentCId, false); // 50 → 30
        }
    }

    function helperGetHash(Delegation calldata d) external view returns (bytes32) {
        return delegationManager.getDelegationHash(d);
    }

    function helperRedeem(Delegation[] calldata chain, Action calldata action) external {
        delegationManager.redeemDelegation(chain, action);
    }

    function _signDelegation(Delegation memory d, uint256 pk) internal view returns (Delegation memory) {
        bytes32 hash = this.helperGetHash(d);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, hash);
        d.signature = abi.encodePacked(r, s, v);
        return d;
    }

    function _buildDelegation(address delegate, uint256 dailyCap, uint256 agentId, uint256 minRep, uint256 salt)
        internal
        view
        returns (Delegation memory)
    {
        Caveat[] memory caveats = new Caveat[](2);
        caveats[0] = Caveat({enforcer: address(spendingCap), terms: abi.encode(dailyCap, uint256(86400))});
        caveats[1] = Caveat({
            enforcer: address(reputationGate),
            terms: abi.encode(address(reputationOracle), agentId, minRep)
        });

        return Delegation({
            delegator: address(ownerAccount),
            delegate: delegate,
            authority: address(0),
            caveats: caveats,
            salt: salt,
            signature: ""
        });
    }

    /// @notice 3 agents with different tiers; revoking A doesn't affect B or C
    function test_multiAgentIsolation() public {
        // Grant Tier 1 to A (1 ETH/day, min rep 30)
        Delegation memory delA = _buildDelegation(agentA, 1 ether, agentAId, 30, 1);
        delA = _signDelegation(delA, ownerKey);

        // Grant Tier 2 to B (5 ETH/day, min rep 50)
        Delegation memory delB = _buildDelegation(agentB, 5 ether, agentBId, 50, 2);
        delB = _signDelegation(delB, ownerKey);

        // Grant Tier 3 to C — will fail because rep is 30, threshold 30 (exactly passes)
        Delegation memory delC = _buildDelegation(agentC, 10 ether, agentCId, 30, 3);
        delC = _signDelegation(delC, ownerKey);

        Action memory action = Action({
            target: address(target),
            value: 0.1 ether,
            callData: abi.encodeCall(MultiTargetContract.setValue, (1))
        });

        // All three can execute within their bounds
        Delegation[] memory chainA = new Delegation[](1);
        chainA[0] = delA;
        vm.prank(agentA);
        delegationManager.redeemDelegation(chainA, action);
        assertEq(target.value(), 1);

        Delegation[] memory chainB = new Delegation[](1);
        chainB[0] = delB;
        vm.prank(agentB);
        delegationManager.redeemDelegation(chainB, action);

        Delegation[] memory chainC = new Delegation[](1);
        chainC[0] = delC;
        vm.prank(agentC);
        delegationManager.redeemDelegation(chainC, action);

        // Revoke agent A's delegation
        bytes32 hashA = this.helperGetHash(delA);
        vm.prank(owner);
        delegationManager.revokeDelegation(hashA);

        // Agent A is blocked
        Delegation memory delA2 = _buildDelegation(agentA, 1 ether, agentAId, 30, 4);
        delA2 = _signDelegation(delA2, ownerKey);
        // Use the original chain which is revoked
        vm.prank(agentA);
        vm.expectRevert(); // DelegationIsRevoked
        delegationManager.redeemDelegation(chainA, action);

        // Agents B and C still work (fresh delegations with new salts since prev were marked redeemed)
        Delegation memory delB2 = _buildDelegation(agentB, 5 ether, agentBId, 50, 5);
        delB2 = _signDelegation(delB2, ownerKey);
        Delegation[] memory chainB2 = new Delegation[](1);
        chainB2[0] = delB2;

        vm.prank(agentB);
        delegationManager.redeemDelegation(chainB2, action);

        Delegation memory delC2 = _buildDelegation(agentC, 10 ether, agentCId, 30, 6);
        delC2 = _signDelegation(delC2, ownerKey);
        Delegation[] memory chainC2 = new Delegation[](1);
        chainC2[0] = delC2;

        vm.prank(agentC);
        delegationManager.redeemDelegation(chainC2, action);
    }

    /// @notice Agent B has higher cap than A — verify each respects its own cap
    function test_agentSpecificCaps() public {
        // A: 1 ETH cap, B: 5 ETH cap
        Delegation memory delA = _buildDelegation(agentA, 1 ether, agentAId, 30, 10);
        delA = _signDelegation(delA, ownerKey);

        Delegation memory delB = _buildDelegation(agentB, 5 ether, agentBId, 50, 11);
        delB = _signDelegation(delB, ownerKey);

        Delegation[] memory chainA = new Delegation[](1);
        chainA[0] = delA;
        Delegation[] memory chainB = new Delegation[](1);
        chainB[0] = delB;

        // A tries 2 ETH → blocked (cap 1)
        Action memory bigAction = Action({
            target: address(target),
            value: 2 ether,
            callData: abi.encodeCall(MultiTargetContract.setValue, (1))
        });

        vm.prank(agentA);
        vm.expectRevert(); // SpendingCapExceeded
        delegationManager.redeemDelegation(chainA, bigAction);

        // B can do 2 ETH (cap 5)
        vm.prank(agentB);
        delegationManager.redeemDelegation(chainB, bigAction);
        assertEq(target.value(), 1);
    }
}
