// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisAccount} from "../../src/IrisAccount.sol";
import {IrisAccountFactory} from "../../src/IrisAccountFactory.sol";
import {IrisDelegationManager} from "../../src/IrisDelegationManager.sol";
import {IrisAgentRegistry} from "../../src/identity/IrisAgentRegistry.sol";
import {IrisReputationOracle} from "../../src/identity/IrisReputationOracle.sol";
import {ReputationGateEnforcer} from "../../src/caveats/ReputationGateEnforcer.sol";
import {Delegation, Action, Caveat} from "../../src/interfaces/IERC7710.sol";

/// @notice Simple target contract for tests.
contract SimpleTarget {
    uint256 public value;

    function setValue(uint256 v) external payable {
        value = v;
    }

    receive() external payable {}
}

/// @title ReputationDegradation Integration Test
/// @notice Demonstrates the novel narrative: reputation drops automatically block delegated execution,
///         and reputation recovery restores access — all without manual revocation.
contract ReputationDegradationTest is Test {
    IrisAccountFactory factory;
    IrisDelegationManager delegationManager;
    IrisAgentRegistry agentRegistry;
    IrisReputationOracle reputationOracle;
    ReputationGateEnforcer reputationGate;
    SimpleTarget target;

    address owner;
    uint256 ownerKey;
    address agent;
    uint256 agentKey;
    IrisAccount ownerAccount;
    uint256 agentId;

    function setUp() public {
        (owner, ownerKey) = makeAddrAndKey("owner");
        (agent, agentKey) = makeAddrAndKey("agent");

        delegationManager = new IrisDelegationManager();
        factory = new IrisAccountFactory();
        agentRegistry = new IrisAgentRegistry();
        reputationOracle = new IrisReputationOracle(address(agentRegistry), address(this));
        reputationGate = new ReputationGateEnforcer();
        target = new SimpleTarget();

        // Register agent
        vm.prank(agent);
        agentId = agentRegistry.registerAgent("ipfs://agent");

        // Create and fund owner account
        address accountAddr = factory.createAccount(owner, address(delegationManager), 0);
        ownerAccount = IrisAccount(payable(accountAddr));
        vm.deal(accountAddr, 100 ether);
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

    function _redeemAsAgent(Delegation[] memory chain, Action memory action) internal {
        vm.prank(agent);
        delegationManager.redeemDelegation(chain, action);
    }

    /// @notice THE KEY TEST: reputation drop blocks delegation, recovery restores it
    function test_reputationDegradationAndRecovery() public {
        // Step 1: Agent starts with reputation 50 (default)
        assertEq(reputationOracle.getReputationScore(agentId), 50);

        // Step 2: Owner grants delegation with reputation threshold 50
        Caveat[] memory caveats = new Caveat[](1);
        caveats[0] = Caveat({
            enforcer: address(reputationGate),
            terms: abi.encode(address(reputationOracle), agentId, uint256(50))
        });

        Delegation memory delegation = Delegation({
            delegator: address(ownerAccount),
            delegate: agent,
            authority: address(0),
            caveats: caveats,
            salt: 1,
            signature: ""
        });
        delegation = _signDelegation(delegation, ownerKey);
        Delegation[] memory chain = new Delegation[](1);
        chain[0] = delegation;

        Action memory action = Action({
            target: address(target),
            value: 0,
            callData: abi.encodeCall(SimpleTarget.setValue, (42))
        });

        // Step 3: Agent executes successfully (rep 50 >= threshold 50)
        _redeemAsAgent(chain, action);
        assertEq(target.value(), 42);

        // Step 4: Multiple bad feedback drops reputation below threshold
        // 50 → 45 → 40 (3 negatives: each -5)
        reputationOracle.submitFeedback(agentId, false); // 50 → 45
        reputationOracle.submitFeedback(agentId, false); // 45 → 40
        assertEq(reputationOracle.getReputationScore(agentId), 40);
        assertTrue(reputationOracle.getReputationScore(agentId) < 50, "Rep should be below threshold");

        // Step 5: Agent's next execution REVERTS (reputation below threshold)
        // Need fresh delegation since previous was marked redeemed
        Delegation memory delegation2 = Delegation({
            delegator: address(ownerAccount),
            delegate: agent,
            authority: address(0),
            caveats: caveats,
            salt: 2,
            signature: ""
        });
        delegation2 = _signDelegation(delegation2, ownerKey);
        Delegation[] memory chain2 = new Delegation[](1);
        chain2[0] = delegation2;

        Action memory action2 = Action({
            target: address(target),
            value: 0,
            callData: abi.encodeCall(SimpleTarget.setValue, (99))
        });

        vm.prank(agent);
        vm.expectRevert(); // ReputationTooLow(agentId, 40, 50)
        delegationManager.redeemDelegation(chain2, action2);

        // Step 6: Good feedback restores reputation above threshold
        // 40 → 42 → 44 → 46 → 48 → 50 (5 positives: each +2)
        reputationOracle.submitFeedback(agentId, true); // 42
        reputationOracle.submitFeedback(agentId, true); // 44
        reputationOracle.submitFeedback(agentId, true); // 46
        reputationOracle.submitFeedback(agentId, true); // 48
        reputationOracle.submitFeedback(agentId, true); // 50
        assertEq(reputationOracle.getReputationScore(agentId), 50);

        // Step 7: Agent's next execution SUCCEEDS again
        Delegation memory delegation3 = Delegation({
            delegator: address(ownerAccount),
            delegate: agent,
            authority: address(0),
            caveats: caveats,
            salt: 3,
            signature: ""
        });
        delegation3 = _signDelegation(delegation3, ownerKey);
        Delegation[] memory chain3 = new Delegation[](1);
        chain3[0] = delegation3;

        vm.prank(agent);
        delegationManager.redeemDelegation(chain3, action2);
        assertEq(target.value(), 99);
    }

    /// @notice Multiple rapid reputation drops cascade into full lockout
    function test_cascadingReputationDrop() public {
        // Start at 50, drop to 0
        for (uint256 i = 0; i < 10; i++) {
            reputationOracle.submitFeedback(agentId, false);
        }
        assertEq(reputationOracle.getReputationScore(agentId), 0);

        // Even threshold of 1 blocks agent
        Caveat[] memory caveats = new Caveat[](1);
        caveats[0] = Caveat({
            enforcer: address(reputationGate),
            terms: abi.encode(address(reputationOracle), agentId, uint256(1))
        });

        Delegation memory delegation = Delegation({
            delegator: address(ownerAccount),
            delegate: agent,
            authority: address(0),
            caveats: caveats,
            salt: 10,
            signature: ""
        });
        delegation = _signDelegation(delegation, ownerKey);
        Delegation[] memory chain = new Delegation[](1);
        chain[0] = delegation;

        Action memory action = Action({
            target: address(target),
            value: 0,
            callData: abi.encodeCall(SimpleTarget.setValue, (1))
        });

        vm.prank(agent);
        vm.expectRevert(); // ReputationTooLow
        delegationManager.redeemDelegation(chain, action);
    }
}
