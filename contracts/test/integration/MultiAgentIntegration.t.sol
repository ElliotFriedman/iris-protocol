// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IrisTestBase} from "../helpers/IrisTestBase.sol";
import {IrisAccount} from "../../src/IrisAccount.sol";
import {Delegation, Action, Caveat} from "../../src/interfaces/IERC7710.sol";

contract Receiver {
    mapping(address => uint256) public received;
    uint256 public totalCalls;

    receive() external payable {
        received[msg.sender] += msg.value;
        totalCalls++;
    }
}

/// @title MultiAgentIntegrationTest
/// @notice Tests multiple agents with different trust levels on the same account.
/// @dev Uses IrisDeployer fixture via IrisTestBase for deployment parity with mainnet scripts.
contract MultiAgentIntegrationTest is IrisTestBase {
    address owner;
    uint256 ownerKey;
    address agentA;
    uint256 agentAId;
    address agentB;
    uint256 agentBId;
    address agentC;
    uint256 agentCId;

    IrisAccount account;
    Receiver receiver;

    function setUp() public {
        vm.warp(1_000_000);
        _deployIris();
        (owner, ownerKey) = makeAddrAndKey("owner");

        agentA = makeAddr("agentA");
        agentAId = _registerAgent(agentA, "ipfs://agentA");
        agentB = makeAddr("agentB");
        agentBId = _registerAgent(agentB, "ipfs://agentB");
        agentC = makeAddr("agentC");
        agentCId = _registerAgent(agentC, "ipfs://agentC");

        // Boost Agent A to 70
        for (uint256 i = 0; i < 10; i++) d.reputationOracle.submitFeedback(agentAId, true);

        account = _createFundedAccount(owner, 1000 ether);
        receiver = new Receiver();
    }

    function _buildDel(address agent, uint256 agentId_, Caveat[] memory caveats, uint256 salt)
        internal view returns (Delegation memory del)
    {
        del.delegator = address(account);
        del.delegate = agent;
        del.authority = address(0);
        del.caveats = caveats;
        del.salt = salt;

        bytes32 dHash = this._helperGetHash(del);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, dHash);
        del.signature = abi.encodePacked(r, s, v);
    }

    function test_multiAgent_differentSpendingCaps() public {
        Caveat[] memory cavA = new Caveat[](1);
        cavA[0] = Caveat({enforcer: address(d.spendingCap), terms: abi.encode(uint256(50 ether), uint256(1 days))});
        Delegation memory dA = _buildDel(agentA, agentAId, cavA, 1);

        Caveat[] memory cavB = new Caveat[](1);
        cavB[0] = Caveat({enforcer: address(d.spendingCap), terms: abi.encode(uint256(5 ether), uint256(1 days))});
        Delegation memory dB = _buildDel(agentB, agentBId, cavB, 2);

        _redeemAs(agentA, dA, Action({target: address(receiver), value: 20 ether, callData: ""}));
        _redeemAs(agentB, dB, Action({target: address(receiver), value: 3 ether, callData: ""}));

        bool ok = _tryRedeemAs(agentB, dB, Action({target: address(receiver), value: 3 ether, callData: ""}));
        assertFalse(ok);

        Delegation memory dA2 = _buildDel(agentA, agentAId, cavA, 4);
        _redeemAs(agentA, dA2, Action({target: address(receiver), value: 25 ether, callData: ""}));
        assertEq(address(receiver).balance, 48 ether);
    }

    function test_multiAgent_independentReputationGates() public {
        Caveat[] memory cavA = new Caveat[](1);
        cavA[0] = Caveat({enforcer: address(d.reputationGate), terms: abi.encode(address(d.reputationOracle), agentAId, uint256(60))});

        Caveat[] memory cavB = new Caveat[](1);
        cavB[0] = Caveat({enforcer: address(d.reputationGate), terms: abi.encode(address(d.reputationOracle), agentBId, uint256(40))});

        _redeemAs(agentA, _buildDel(agentA, agentAId, cavA, 10), Action({target: address(receiver), value: 1 ether, callData: ""}));
        _redeemAs(agentB, _buildDel(agentB, agentBId, cavB, 11), Action({target: address(receiver), value: 1 ether, callData: ""}));

        // Drop Agent A: 70 → 55
        d.reputationOracle.submitFeedback(agentAId, false);
        d.reputationOracle.submitFeedback(agentAId, false);
        d.reputationOracle.submitFeedback(agentAId, false);

        bool ok = _tryRedeemAs(agentA, _buildDel(agentA, agentAId, cavA, 12), Action({target: address(receiver), value: 1 ether, callData: ""}));
        assertFalse(ok);

        _redeemAs(agentB, _buildDel(agentB, agentBId, cavB, 13), Action({target: address(receiver), value: 1 ether, callData: ""}));
        assertEq(receiver.totalCalls(), 3);
    }

    function test_multiAgent_selectiveRevocation() public {
        Caveat[] memory emptyCaveats = new Caveat[](0);

        Delegation memory dA = _buildDel(agentA, agentAId, emptyCaveats, 20);
        Delegation memory dB = _buildDel(agentB, agentBId, emptyCaveats, 21);
        Delegation memory dC = _buildDel(agentC, agentCId, emptyCaveats, 22);

        _redeemAs(agentA, dA, Action({target: address(receiver), value: 1 ether, callData: ""}));
        _redeemAs(agentB, dB, Action({target: address(receiver), value: 1 ether, callData: ""}));
        _redeemAs(agentC, dC, Action({target: address(receiver), value: 1 ether, callData: ""}));
        assertEq(receiver.totalCalls(), 3);

        vm.prank(owner);
        d.delegationManager.revokeDelegation(dC);

        // C with new salt still works
        _redeemAs(agentC, _buildDel(agentC, agentCId, emptyCaveats, 23), Action({target: address(receiver), value: 1 ether, callData: ""}));
        _redeemAs(agentA, _buildDel(agentA, agentAId, emptyCaveats, 24), Action({target: address(receiver), value: 1 ether, callData: ""}));
        _redeemAs(agentB, _buildDel(agentB, agentBId, emptyCaveats, 25), Action({target: address(receiver), value: 1 ether, callData: ""}));
        assertEq(receiver.totalCalls(), 6);
    }

    function test_multiAgent_reputationDegradation_blocksAllDelegations() public {
        IrisAccount account2 = _createFundedAccount(owner, 100 ether, 1);
        uint256 minRep = 45;

        Caveat[] memory caveats = new Caveat[](1);
        caveats[0] = Caveat({enforcer: address(d.reputationGate), terms: abi.encode(address(d.reputationOracle), agentCId, minRep)});

        // Delegation from account1
        Delegation memory d1;
        d1.delegator = address(account);
        d1.delegate = agentC;
        d1.authority = address(0);
        d1.caveats = caveats;
        d1.salt = 30;
        bytes32 d1Hash = this._helperGetHash(d1);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, d1Hash);
        d1.signature = abi.encodePacked(r, s, v);

        // Delegation from account2
        Delegation memory d2;
        d2.delegator = address(account2);
        d2.delegate = agentC;
        d2.authority = address(0);
        d2.caveats = caveats;
        d2.salt = 31;
        bytes32 d2Hash = this._helperGetHash(d2);
        (v, r, s) = vm.sign(ownerKey, d2Hash);
        d2.signature = abi.encodePacked(r, s, v);

        // Both work (rep 50 >= 45)
        _redeemAs(agentC, d1, Action({target: address(receiver), value: 1 ether, callData: ""}));
        _redeemAs(agentC, d2, Action({target: address(receiver), value: 1 ether, callData: ""}));
        assertEq(receiver.totalCalls(), 2);

        // Drop rep: 50 → 40
        d.reputationOracle.submitFeedback(agentCId, false);
        d.reputationOracle.submitFeedback(agentCId, false);

        // Both blocked
        Delegation memory d1b;
        d1b.delegator = address(account);
        d1b.delegate = agentC;
        d1b.authority = address(0);
        d1b.caveats = caveats;
        d1b.salt = 32;
        bytes32 d1bHash = this._helperGetHash(d1b);
        (v, r, s) = vm.sign(ownerKey, d1bHash);
        d1b.signature = abi.encodePacked(r, s, v);

        bool ok1 = _tryRedeemAs(agentC, d1b, Action({target: address(receiver), value: 1 ether, callData: ""}));
        assertFalse(ok1);

        Delegation memory d2b;
        d2b.delegator = address(account2);
        d2b.delegate = agentC;
        d2b.authority = address(0);
        d2b.caveats = caveats;
        d2b.salt = 33;
        bytes32 d2bHash = this._helperGetHash(d2b);
        (v, r, s) = vm.sign(ownerKey, d2bHash);
        d2b.signature = abi.encodePacked(r, s, v);

        bool ok2 = _tryRedeemAs(agentC, d2b, Action({target: address(receiver), value: 1 ether, callData: ""}));
        assertFalse(ok2);
    }

    function test_multiAgent_cannotCrossRedeem() public {
        Caveat[] memory emptyCaveats = new Caveat[](0);
        Delegation memory dA = _buildDel(agentA, agentAId, emptyCaveats, 40);

        bool ok = _tryRedeemAs(agentB, dA, Action({target: address(receiver), value: 1 ether, callData: ""}));
        assertFalse(ok);
    }
}
