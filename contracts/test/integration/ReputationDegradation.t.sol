// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IrisTestBase} from "../helpers/IrisTestBase.sol";
import {IrisAccount} from "../../src/IrisAccount.sol";
import {Delegation, Action, Caveat} from "../../src/interfaces/IERC7710.sol";

contract SimpleTarget {
    uint256 public value;
    function setValue(uint256 v) external payable { value = v; }
    receive() external payable {}
}

/// @title ReputationDegradation Integration Test
/// @notice Demonstrates reputation drops automatically blocking delegated execution.
/// @dev Uses IrisDeployer fixture via IrisTestBase for deployment parity with mainnet scripts.
contract ReputationDegradationTest is IrisTestBase {
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

        _deployIris();
        target = new SimpleTarget();
        agentId = _registerAgent(agent, "ipfs://agent");
        ownerAccount = _createFundedAccount(owner, 100 ether);
    }

    function test_reputationDegradationAndRecovery() public {
        assertEq(d.reputationOracle.getReputationScore(agentId), 50);

        Caveat[] memory caveats = new Caveat[](1);
        caveats[0] = Caveat({enforcer: address(d.reputationGate), terms: abi.encode(address(d.reputationOracle), agentId, uint256(50))});

        Delegation memory delegation = Delegation({
            delegator: address(ownerAccount), delegate: agent, authority: address(0),
            caveats: caveats, salt: 1, signature: ""
        });
        delegation = _signDelegation(delegation, ownerKey);

        Action memory action = Action({target: address(target), value: 0, callData: abi.encodeCall(SimpleTarget.setValue, (42))});

        // Succeeds at rep 50
        _redeemAs(agent, delegation, action);
        assertEq(target.value(), 42);

        // Drop rep: 50 → 45 → 40
        d.reputationOracle.submitFeedback(agentId, false);
        d.reputationOracle.submitFeedback(agentId, false);
        assertEq(d.reputationOracle.getReputationScore(agentId), 40);

        // Blocked
        Delegation memory delegation2 = Delegation({
            delegator: address(ownerAccount), delegate: agent, authority: address(0),
            caveats: caveats, salt: 2, signature: ""
        });
        delegation2 = _signDelegation(delegation2, ownerKey);

        Delegation[] memory chain2 = new Delegation[](1);
        chain2[0] = delegation2;
        vm.prank(agent);
        vm.expectRevert();
        d.delegationManager.redeemDelegation(chain2, Action({target: address(target), value: 0, callData: abi.encodeCall(SimpleTarget.setValue, (99))}));

        // Recover: 40 → 50
        for (uint256 i = 0; i < 5; i++) d.reputationOracle.submitFeedback(agentId, true);
        assertEq(d.reputationOracle.getReputationScore(agentId), 50);

        // Works again
        Delegation memory delegation3 = Delegation({
            delegator: address(ownerAccount), delegate: agent, authority: address(0),
            caveats: caveats, salt: 3, signature: ""
        });
        delegation3 = _signDelegation(delegation3, ownerKey);

        _redeemAs(agent, delegation3, Action({target: address(target), value: 0, callData: abi.encodeCall(SimpleTarget.setValue, (99))}));
        assertEq(target.value(), 99);
    }

    function test_cascadingReputationDrop() public {
        for (uint256 i = 0; i < 10; i++) d.reputationOracle.submitFeedback(agentId, false);
        assertEq(d.reputationOracle.getReputationScore(agentId), 0);

        Caveat[] memory caveats = new Caveat[](1);
        caveats[0] = Caveat({enforcer: address(d.reputationGate), terms: abi.encode(address(d.reputationOracle), agentId, uint256(1))});

        Delegation memory delegation = Delegation({
            delegator: address(ownerAccount), delegate: agent, authority: address(0),
            caveats: caveats, salt: 10, signature: ""
        });
        delegation = _signDelegation(delegation, ownerKey);

        Delegation[] memory chain = new Delegation[](1);
        chain[0] = delegation;
        vm.prank(agent);
        vm.expectRevert();
        d.delegationManager.redeemDelegation(chain, Action({target: address(target), value: 0, callData: abi.encodeCall(SimpleTarget.setValue, (1))}));
    }
}
