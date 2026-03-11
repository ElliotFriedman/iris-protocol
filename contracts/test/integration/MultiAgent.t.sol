// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IrisTestBase} from "../helpers/IrisTestBase.sol";
import {IrisAccount} from "../../src/IrisAccount.sol";
import {Delegation, Action, Caveat} from "../../src/interfaces/IERC7710.sol";

contract MultiTargetContract {
    uint256 public value;
    function setValue(uint256 v) external payable { value = v; }
    receive() external payable {}
}

/// @title MultiAgent Integration Test
/// @notice Tests multiple agents with different tiers operating on the same account.
/// @dev Uses IrisDeployer fixture via IrisTestBase for deployment parity with mainnet scripts.
contract MultiAgentTest is IrisTestBase {
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

        _deployIris();
        target = new MultiTargetContract();
        ownerAccount = _createFundedAccount(owner, 100 ether);

        agentAId = _registerAgent(agentA, "ipfs://agentA");
        agentBId = _registerAgent(agentB, "ipfs://agentB");
        agentCId = _registerAgent(agentC, "ipfs://agentC");

        // Set reputations: A=50 (default), B=70 (10 positives), C=30 (4 negatives)
        for (uint256 i = 0; i < 10; i++) d.reputationOracle.submitFeedback(agentBId, true);
        for (uint256 i = 0; i < 4; i++) d.reputationOracle.submitFeedback(agentCId, false);
    }

    function _buildDelegation(address delegate, uint256 dailyCap, uint256 agentId, uint256 minRep, uint256 salt)
        internal view returns (Delegation memory)
    {
        Caveat[] memory caveats = new Caveat[](2);
        caveats[0] = Caveat({enforcer: address(d.spendingCap), terms: abi.encode(dailyCap, uint256(86400))});
        caveats[1] = Caveat({enforcer: address(d.reputationGate), terms: abi.encode(address(d.reputationOracle), agentId, minRep)});

        Delegation memory del = Delegation({
            delegator: address(ownerAccount), delegate: delegate, authority: address(0),
            caveats: caveats, salt: salt, signature: ""
        });
        return del;
    }

    function test_multiAgentIsolation() public {
        Delegation memory delA = _signDelegation(_buildDelegation(agentA, 1 ether, agentAId, 30, 1), ownerKey);
        Delegation memory delB = _signDelegation(_buildDelegation(agentB, 5 ether, agentBId, 50, 2), ownerKey);
        Delegation memory delC = _signDelegation(_buildDelegation(agentC, 10 ether, agentCId, 30, 3), ownerKey);

        Action memory action = Action({target: address(target), value: 0.1 ether, callData: abi.encodeCall(MultiTargetContract.setValue, (1))});

        _redeemAs(agentA, delA, action);
        _redeemAs(agentB, delB, action);
        _redeemAs(agentC, delC, action);

        // Revoke agent A
        bytes32 hashA = this._helperGetHash(delA);
        vm.prank(owner);
        d.delegationManager.revokeDelegation(hashA);

        // Agent A blocked (original chain revoked)
        Delegation[] memory chainA = new Delegation[](1);
        chainA[0] = delA;
        vm.prank(agentA);
        vm.expectRevert();
        d.delegationManager.redeemDelegation(chainA, action);

        // B and C still work with new delegations
        Delegation memory delB2 = _signDelegation(_buildDelegation(agentB, 5 ether, agentBId, 50, 5), ownerKey);
        _redeemAs(agentB, delB2, action);

        Delegation memory delC2 = _signDelegation(_buildDelegation(agentC, 10 ether, agentCId, 30, 6), ownerKey);
        _redeemAs(agentC, delC2, action);
    }

    function test_agentSpecificCaps() public {
        Delegation memory delA = _signDelegation(_buildDelegation(agentA, 1 ether, agentAId, 30, 10), ownerKey);
        Delegation memory delB = _signDelegation(_buildDelegation(agentB, 5 ether, agentBId, 50, 11), ownerKey);

        Action memory bigAction = Action({target: address(target), value: 2 ether, callData: abi.encodeCall(MultiTargetContract.setValue, (1))});

        // A tries 2 ETH → blocked
        Delegation[] memory chainA = new Delegation[](1);
        chainA[0] = delA;
        vm.prank(agentA);
        vm.expectRevert();
        d.delegationManager.redeemDelegation(chainA, bigAction);

        // B can do 2 ETH
        _redeemAs(agentB, delB, bigAction);
        assertEq(target.value(), 1);
    }
}
