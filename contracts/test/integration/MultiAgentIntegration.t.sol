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
import {ContractWhitelistEnforcer} from "../../src/caveats/ContractWhitelistEnforcer.sol";
import {Delegation, Action, Caveat} from "../../src/interfaces/IERC7710.sol";

/// @notice Simple target contract.
contract Receiver {
    mapping(address => uint256) public received;
    uint256 public totalCalls;

    receive() external payable {
        received[msg.sender] += msg.value;
        totalCalls++;
    }
}

/// @title MultiAgentIntegrationTest
/// @notice Tests multiple agents with different trust levels operating on the same account.
///         Validates that delegations are scoped per-agent and caveats enforce independently.
contract MultiAgentIntegrationTest is Test {
    IrisAccountFactory factory;
    IrisDelegationManager dm;
    IrisAgentRegistry registry;
    IrisReputationOracle oracle;
    SpendingCapEnforcer spendingCap;
    ReputationGateEnforcer reputationGate;
    ContractWhitelistEnforcer whitelist;

    address owner;
    uint256 ownerKey;

    // Agent A: trusted, high reputation
    address agentA;
    uint256 agentAId;

    // Agent B: new, low reputation
    address agentB;
    uint256 agentBId;

    // Agent C: malicious, will lose reputation
    address agentC;
    uint256 agentCId;

    IrisAccount account;
    Receiver receiver;

    function setUp() public {
        vm.warp(1_000_000);

        dm = new IrisDelegationManager();
        factory = new IrisAccountFactory();
        registry = new IrisAgentRegistry();
        oracle = new IrisReputationOracle(address(registry), address(this));
        spendingCap = new SpendingCapEnforcer();
        reputationGate = new ReputationGateEnforcer();
        whitelist = new ContractWhitelistEnforcer();

        (owner, ownerKey) = makeAddrAndKey("owner");

        // Register three agents
        agentA = makeAddr("agentA");
        vm.prank(agentA);
        agentAId = registry.registerAgent("ipfs://agentA");

        agentB = makeAddr("agentB");
        vm.prank(agentB);
        agentBId = registry.registerAgent("ipfs://agentB");

        agentC = makeAddr("agentC");
        vm.prank(agentC);
        agentCId = registry.registerAgent("ipfs://agentC");

        // Boost Agent A reputation to 70
        for (uint256 i = 0; i < 10; i++) {
            oracle.submitFeedback(agentAId, true); // 50 -> 70
        }
        assertEq(oracle.getReputationScore(agentAId), 70);

        // Agent B stays at default (50)
        assertEq(oracle.getReputationScore(agentBId), 50);

        // Agent C stays at default (50) — will degrade later
        assertEq(oracle.getReputationScore(agentCId), 50);

        // Deploy and fund account
        address acctAddr = factory.createAccount(owner, address(dm), 0);
        account = IrisAccount(payable(acctAddr));
        vm.deal(address(account), 1000 ether);

        receiver = new Receiver();
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    function _helperGetHash(Delegation calldata d) external view returns (bytes32) {
        return dm.getDelegationHash(d);
    }

    function _buildDelegation(address agent, uint256 agentId_, Caveat[] memory caveats, uint256 salt)
        internal view returns (Delegation memory d)
    {
        d.delegator = address(account);
        d.delegate = agent;
        d.authority = address(0);
        d.caveats = caveats;
        d.salt = salt;

        bytes32 dHash = this._helperGetHash(d);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, dHash);
        d.signature = abi.encodePacked(r, s, v);
    }

    function _redeemAs(address agent, Delegation memory d, Action memory action) internal {
        Delegation[] memory chain = new Delegation[](1);
        chain[0] = d;
        vm.prank(agent);
        dm.redeemDelegation(chain, action);
    }

    function _tryRedeemAs(address agent, Delegation memory d, Action memory action) internal returns (bool) {
        Delegation[] memory chain = new Delegation[](1);
        chain[0] = d;
        vm.prank(agent);
        (bool ok,) = address(dm).call(
            abi.encodeCall(dm.redeemDelegation, (chain, action))
        );
        return ok;
    }

    // =========================================================================
    // Tests
    // =========================================================================

    /// @notice Agent A (high rep) gets higher spending cap than Agent B (low rep).
    function test_multiAgent_differentSpendingCaps() public {
        // Agent A: 50 ETH/day cap
        Caveat[] memory cavA = new Caveat[](1);
        cavA[0] = Caveat({
            enforcer: address(spendingCap),
            terms: abi.encode(uint256(50 ether), uint256(1 days))
        });
        Delegation memory dA = _buildDelegation(agentA, agentAId, cavA, 1);

        // Agent B: 5 ETH/day cap
        Caveat[] memory cavB = new Caveat[](1);
        cavB[0] = Caveat({
            enforcer: address(spendingCap),
            terms: abi.encode(uint256(5 ether), uint256(1 days))
        });
        Delegation memory dB = _buildDelegation(agentB, agentBId, cavB, 2);

        // Agent A sends 20 ETH — OK
        _redeemAs(agentA, dA, Action({target: address(receiver), value: 20 ether, callData: ""}));
        assertEq(address(receiver).balance, 20 ether);

        // Agent B sends 3 ETH — OK
        _redeemAs(agentB, dB, Action({target: address(receiver), value: 3 ether, callData: ""}));
        assertEq(address(receiver).balance, 23 ether);

        // Agent B tries 3 ETH again — cumulative 6, exceeds 5 cap
        Delegation memory dB2 = _buildDelegation(agentB, agentBId, cavB, 3);
        bool ok = _tryRedeemAs(agentB, dB2, Action({target: address(receiver), value: 3 ether, callData: ""}));
        assertFalse(ok, "Agent B should be capped at 5 ETH/day");

        // Agent A can still send — independent spending tracker
        Delegation memory dA2 = _buildDelegation(agentA, agentAId, cavA, 4);
        _redeemAs(agentA, dA2, Action({target: address(receiver), value: 25 ether, callData: ""}));
        assertEq(address(receiver).balance, 48 ether);
    }

    /// @notice Agent A and Agent B have different reputation thresholds.
    ///         Agent B is gated at a lower threshold. When Agent A's reputation drops,
    ///         Agent A is blocked but Agent B continues to operate.
    function test_multiAgent_independentReputationGates() public {
        // Agent A: min rep 60
        Caveat[] memory cavA = new Caveat[](1);
        cavA[0] = Caveat({
            enforcer: address(reputationGate),
            terms: abi.encode(address(oracle), agentAId, uint256(60))
        });

        // Agent B: min rep 40
        Caveat[] memory cavB = new Caveat[](1);
        cavB[0] = Caveat({
            enforcer: address(reputationGate),
            terms: abi.encode(address(oracle), agentBId, uint256(40))
        });

        // Both can execute initially
        Delegation memory dA = _buildDelegation(agentA, agentAId, cavA, 10);
        _redeemAs(agentA, dA, Action({target: address(receiver), value: 1 ether, callData: ""}));

        Delegation memory dB = _buildDelegation(agentB, agentBId, cavB, 11);
        _redeemAs(agentB, dB, Action({target: address(receiver), value: 1 ether, callData: ""}));

        // Drop Agent A's reputation from 70 to 55 (3 negative = -15)
        oracle.submitFeedback(agentAId, false); // 70 -> 65
        oracle.submitFeedback(agentAId, false); // 65 -> 60
        oracle.submitFeedback(agentAId, false); // 60 -> 55
        assertEq(oracle.getReputationScore(agentAId), 55);

        // Agent A is now below threshold (55 < 60) — blocked
        Delegation memory dA2 = _buildDelegation(agentA, agentAId, cavA, 12);
        bool ok = _tryRedeemAs(agentA, dA2, Action({target: address(receiver), value: 1 ether, callData: ""}));
        assertFalse(ok, "Agent A reputation too low");

        // Agent B is unaffected — still at 50, above threshold 40
        Delegation memory dB2 = _buildDelegation(agentB, agentBId, cavB, 13);
        _redeemAs(agentB, dB2, Action({target: address(receiver), value: 1 ether, callData: ""}));
        assertEq(receiver.totalCalls(), 3);
    }

    /// @notice Agent C's delegation is revoked, but Agent A and B keep working.
    function test_multiAgent_selectiveRevocation() public {
        Caveat[] memory emptyCaveats = new Caveat[](0);

        Delegation memory dA = _buildDelegation(agentA, agentAId, emptyCaveats, 20);
        Delegation memory dB = _buildDelegation(agentB, agentBId, emptyCaveats, 21);
        Delegation memory dC = _buildDelegation(agentC, agentCId, emptyCaveats, 22);

        // All three agents execute
        _redeemAs(agentA, dA, Action({target: address(receiver), value: 1 ether, callData: ""}));
        _redeemAs(agentB, dB, Action({target: address(receiver), value: 1 ether, callData: ""}));
        _redeemAs(agentC, dC, Action({target: address(receiver), value: 1 ether, callData: ""}));
        assertEq(receiver.totalCalls(), 3);

        // Owner revokes Agent C's delegation on the DM
        bytes32 dCHash = this._helperGetHash(dC);
        vm.prank(owner);
        dm.revokeDelegation(dCHash);

        // Agent C can't use a new delegation with the same hash (already revoked on DM)
        // Agent C tries with fresh delegation
        Delegation memory dC2 = _buildDelegation(agentC, agentCId, emptyCaveats, 23);
        _redeemAs(agentC, dC2, Action({target: address(receiver), value: 1 ether, callData: ""}));

        // But Agent A and B continue fine with new delegations
        Delegation memory dA2 = _buildDelegation(agentA, agentAId, emptyCaveats, 24);
        _redeemAs(agentA, dA2, Action({target: address(receiver), value: 1 ether, callData: ""}));

        Delegation memory dB2 = _buildDelegation(agentB, agentBId, emptyCaveats, 25);
        _redeemAs(agentB, dB2, Action({target: address(receiver), value: 1 ether, callData: ""}));

        assertEq(receiver.totalCalls(), 6);
    }

    /// @notice Agent C's reputation degrades, blocking execution across ALL delegations
    ///         from any account — the network-level immune system.
    function test_multiAgent_reputationDegradation_blocksAllDelegations() public {
        // Create a SECOND account for Agent C
        address acct2Addr = factory.createAccount(owner, address(dm), 1);
        IrisAccount account2 = IrisAccount(payable(acct2Addr));
        vm.deal(address(account2), 100 ether);

        uint256 minRep = 45;

        // Delegation from account1 to Agent C
        Caveat[] memory caveats = new Caveat[](1);
        caveats[0] = Caveat({
            enforcer: address(reputationGate),
            terms: abi.encode(address(oracle), agentCId, minRep)
        });

        Delegation memory d1;
        d1.delegator = address(account);
        d1.delegate = agentC;
        d1.authority = address(0);
        d1.caveats = caveats;
        d1.salt = 30;
        bytes32 d1Hash = this._helperGetHash(d1);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, d1Hash);
        d1.signature = abi.encodePacked(r, s, v);

        // Delegation from account2 to Agent C
        Delegation memory d2;
        d2.delegator = address(account2);
        d2.delegate = agentC;
        d2.authority = address(0);
        d2.caveats = caveats;
        d2.salt = 31;
        bytes32 d2Hash = this._helperGetHash(d2);
        (v, r, s) = vm.sign(ownerKey, d2Hash);
        d2.signature = abi.encodePacked(r, s, v);

        // Both work initially (reputation 50 >= 45)
        _redeemAs(agentC, d1, Action({target: address(receiver), value: 1 ether, callData: ""}));
        _redeemAs(agentC, d2, Action({target: address(receiver), value: 1 ether, callData: ""}));
        assertEq(receiver.totalCalls(), 2);

        // Drop Agent C's reputation below threshold: 50 -> 45 -> 40
        oracle.submitFeedback(agentCId, false); // 50 -> 45
        oracle.submitFeedback(agentCId, false); // 45 -> 40

        // Both delegations are now blocked by reputation
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
        assertFalse(ok1, "account1 delegation blocked by reputation");

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
        assertFalse(ok2, "account2 delegation also blocked -- network-level immune system");
    }

    /// @notice Cannot redeem someone else's delegation.
    function test_multiAgent_cannotCrossRedeem() public {
        // Delegation for Agent A
        Caveat[] memory emptyCaveats = new Caveat[](0);
        Delegation memory dA = _buildDelegation(agentA, agentAId, emptyCaveats, 40);

        // Agent B tries to redeem Agent A's delegation
        bool ok = _tryRedeemAs(agentB, dA, Action({target: address(receiver), value: 1 ether, callData: ""}));
        assertFalse(ok, "Agent B should not be able to redeem Agent A's delegation");
    }
}
