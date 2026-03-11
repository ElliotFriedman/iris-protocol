// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisAccount} from "../../src/IrisAccount.sol";
import {IrisAccountFactory} from "../../src/IrisAccountFactory.sol";
import {IrisDelegationManager} from "../../src/IrisDelegationManager.sol";
import {IrisAgentRegistry} from "../../src/identity/IrisAgentRegistry.sol";
import {IrisReputationOracle} from "../../src/identity/IrisReputationOracle.sol";
import {SpendingCapEnforcer} from "../../src/caveats/SpendingCapEnforcer.sol";
import {ContractWhitelistEnforcer} from "../../src/caveats/ContractWhitelistEnforcer.sol";
import {TimeWindowEnforcer} from "../../src/caveats/TimeWindowEnforcer.sol";
import {ReputationGateEnforcer} from "../../src/caveats/ReputationGateEnforcer.sol";
import {SingleTxCapEnforcer} from "../../src/caveats/SingleTxCapEnforcer.sol";
import {CooldownEnforcer} from "../../src/caveats/CooldownEnforcer.sol";
import {TierOne} from "../../src/presets/TierOne.sol";
import {TierTwo} from "../../src/presets/TierTwo.sol";
import {TierThree} from "../../src/presets/TierThree.sol";
import {Delegation, Action, Caveat} from "../../src/interfaces/IERC7710.sol";

/// @notice Simple target contract for test actions.
contract TierTarget {
    uint256 public lastValue;
    uint256 public callCount;

    function doWork(uint256 v) external payable {
        lastValue = v;
        callCount++;
    }

    receive() external payable {}
}

/// @title TierPresetIntegrationTest
/// @notice Tests the TierOne, TierTwo, and TierThree preset libraries in full delegation flows.
contract TierPresetIntegrationTest is Test {
    // Infrastructure
    IrisAccountFactory factory;
    IrisDelegationManager dm;
    IrisAgentRegistry registry;
    IrisReputationOracle oracle;

    // Enforcers
    SpendingCapEnforcer spendingCap;
    ContractWhitelistEnforcer whitelist;
    TimeWindowEnforcer timeWindow;
    ReputationGateEnforcer reputationGate;
    SingleTxCapEnforcer singleTxCap;
    CooldownEnforcer cooldown;

    // Actors
    address owner;
    uint256 ownerKey;
    address agentOperator;
    uint256 agentId;

    // Contracts
    IrisAccount account;
    TierTarget target;

    function setUp() public {
        vm.warp(1_000_000);

        // Deploy infrastructure
        dm = new IrisDelegationManager();
        factory = new IrisAccountFactory();
        registry = new IrisAgentRegistry();
        oracle = new IrisReputationOracle(address(registry), address(this));

        // Deploy enforcers
        spendingCap = new SpendingCapEnforcer();
        whitelist = new ContractWhitelistEnforcer();
        timeWindow = new TimeWindowEnforcer();
        reputationGate = new ReputationGateEnforcer();
        singleTxCap = new SingleTxCapEnforcer();
        cooldown = new CooldownEnforcer();

        // Create actors
        (owner, ownerKey) = makeAddrAndKey("owner");
        agentOperator = makeAddr("agent");

        // Register agent (default reputation: 50)
        vm.prank(agentOperator);
        agentId = registry.registerAgent("ipfs://agent-card");

        // Deploy account and fund it
        address acctAddr = factory.createAccount(owner, address(dm), 0);
        account = IrisAccount(payable(acctAddr));
        vm.deal(address(account), 1000 ether);

        // Deploy target
        target = new TierTarget();
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    function _helperGetHash(Delegation calldata d) external view returns (bytes32) {
        return dm.getDelegationHash(d);
    }

    function _sign(Delegation memory d) internal view returns (Delegation memory) {
        bytes32 dHash = this._helperGetHash(d);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, dHash);
        d.signature = abi.encodePacked(r, s, v);
        return d;
    }

    function _redeemAsAgent(Delegation memory d, Action memory action) internal {
        Delegation[] memory chain = new Delegation[](1);
        chain[0] = d;
        vm.prank(agentOperator);
        dm.redeemDelegation(chain, action);
    }

    function _tryRedeemAsAgent(Delegation memory d, Action memory action) internal returns (bool) {
        Delegation[] memory chain = new Delegation[](1);
        chain[0] = d;
        vm.prank(agentOperator);
        (bool ok,) = address(dm).call(
            abi.encodeCall(dm.redeemDelegation, (chain, action))
        );
        return ok;
    }

    // =========================================================================
    // Tier One — Supervised
    // =========================================================================

    function test_tierOne_happyPath() public {
        address[] memory allowed = new address[](1);
        allowed[0] = address(target);

        Caveat[] memory caveats = TierOne.configureTierOne(
            address(spendingCap),
            address(whitelist),
            address(timeWindow),
            address(reputationGate),
            address(oracle),
            agentId,
            10 ether,       // daily cap
            allowed,
            block.timestamp + 7 days,
            40              // min reputation
        );

        Delegation memory d;
        d.delegator = address(account);
        d.delegate = agentOperator;
        d.authority = address(0);
        d.caveats = caveats;
        d.salt = 1;
        d = _sign(d);

        Action memory action = Action({
            target: address(target),
            value: 1 ether,
            callData: abi.encodeCall(TierTarget.doWork, (42))
        });

        _redeemAsAgent(d, action);

        assertEq(target.lastValue(), 42);
        assertEq(target.callCount(), 1);
        assertEq(address(target).balance, 1 ether);
    }

    function test_tierOne_blockedBySpendingCap() public {
        address[] memory allowed = new address[](1);
        allowed[0] = address(target);

        Caveat[] memory caveats = TierOne.configureTierOne(
            address(spendingCap),
            address(whitelist),
            address(timeWindow),
            address(reputationGate),
            address(oracle),
            agentId,
            5 ether,
            allowed,
            block.timestamp + 7 days,
            40
        );

        Delegation memory d;
        d.delegator = address(account);
        d.delegate = agentOperator;
        d.authority = address(0);
        d.caveats = caveats;
        d.salt = 2;
        d = _sign(d);

        // Attempt to spend 6 ether — exceeds 5 ether daily cap
        bool ok = _tryRedeemAsAgent(d, Action({
            target: address(target),
            value: 6 ether,
            callData: abi.encodeCall(TierTarget.doWork, (1))
        }));
        assertFalse(ok, "Should be blocked by spending cap");
        assertEq(target.callCount(), 0);
    }

    function test_tierOne_blockedByWhitelist() public {
        address[] memory allowed = new address[](1);
        allowed[0] = address(target);

        Caveat[] memory caveats = TierOne.configureTierOne(
            address(spendingCap),
            address(whitelist),
            address(timeWindow),
            address(reputationGate),
            address(oracle),
            agentId,
            10 ether,
            allowed,
            block.timestamp + 7 days,
            40
        );

        Delegation memory d;
        d.delegator = address(account);
        d.delegate = agentOperator;
        d.authority = address(0);
        d.caveats = caveats;
        d.salt = 3;
        d = _sign(d);

        // Attempt to call a non-whitelisted address
        bool ok = _tryRedeemAsAgent(d, Action({
            target: makeAddr("rogue"),
            value: 1 ether,
            callData: ""
        }));
        assertFalse(ok, "Should be blocked by contract whitelist");
    }

    function test_tierOne_blockedByTimeWindowExpiry() public {
        address[] memory allowed = new address[](1);
        allowed[0] = address(target);

        Caveat[] memory caveats = TierOne.configureTierOne(
            address(spendingCap),
            address(whitelist),
            address(timeWindow),
            address(reputationGate),
            address(oracle),
            agentId,
            10 ether,
            allowed,
            block.timestamp + 1 days, // expires in 1 day
            40
        );

        Delegation memory d;
        d.delegator = address(account);
        d.delegate = agentOperator;
        d.authority = address(0);
        d.caveats = caveats;
        d.salt = 4;
        d = _sign(d);

        // Works now
        _redeemAsAgent(d, Action({
            target: address(target),
            value: 0,
            callData: abi.encodeCall(TierTarget.doWork, (1))
        }));
        assertEq(target.callCount(), 1);

        // Fast-forward past expiry, new delegation with same caveats
        vm.warp(block.timestamp + 2 days);

        Delegation memory d2;
        d2.delegator = address(account);
        d2.delegate = agentOperator;
        d2.authority = address(0);
        d2.caveats = caveats;
        d2.salt = 5;
        d2 = _sign(d2);

        bool ok = _tryRedeemAsAgent(d2, Action({
            target: address(target),
            value: 0,
            callData: abi.encodeCall(TierTarget.doWork, (2))
        }));
        assertFalse(ok, "Should be blocked after time window expires");
    }

    function test_tierOne_blockedByReputation() public {
        address[] memory allowed = new address[](1);
        allowed[0] = address(target);

        // Drop reputation below threshold
        oracle.submitFeedback(agentId, false); // 50 -> 45
        oracle.submitFeedback(agentId, false); // 45 -> 40
        oracle.submitFeedback(agentId, false); // 40 -> 35

        Caveat[] memory caveats = TierOne.configureTierOne(
            address(spendingCap),
            address(whitelist),
            address(timeWindow),
            address(reputationGate),
            address(oracle),
            agentId,
            10 ether,
            allowed,
            block.timestamp + 7 days,
            40 // min reputation 40, agent has 35
        );

        Delegation memory d;
        d.delegator = address(account);
        d.delegate = agentOperator;
        d.authority = address(0);
        d.caveats = caveats;
        d.salt = 6;
        d = _sign(d);

        bool ok = _tryRedeemAsAgent(d, Action({
            target: address(target),
            value: 0,
            callData: abi.encodeCall(TierTarget.doWork, (1))
        }));
        assertFalse(ok, "Should be blocked by low reputation");
    }

    // =========================================================================
    // Tier Two — Autonomous
    // =========================================================================

    function test_tierTwo_happyPath() public {
        address[] memory allowed = new address[](1);
        allowed[0] = address(target);

        Caveat[] memory caveats = TierTwo.configureTierTwo(
            address(spendingCap),
            address(whitelist),
            address(timeWindow),
            address(reputationGate),
            address(singleTxCap),
            address(oracle),
            agentId,
            50 ether,       // daily cap
            10 ether,       // max per tx
            allowed,
            block.timestamp + 30 days,
            40
        );

        Delegation memory d;
        d.delegator = address(account);
        d.delegate = agentOperator;
        d.authority = address(0);
        d.caveats = caveats;
        d.salt = 10;
        d = _sign(d);

        _redeemAsAgent(d, Action({
            target: address(target),
            value: 5 ether,
            callData: abi.encodeCall(TierTarget.doWork, (100))
        }));
        assertEq(target.lastValue(), 100);
        assertEq(address(target).balance, 5 ether);
    }

    function test_tierTwo_blockedBySingleTxCap() public {
        address[] memory allowed = new address[](1);
        allowed[0] = address(target);

        Caveat[] memory caveats = TierTwo.configureTierTwo(
            address(spendingCap),
            address(whitelist),
            address(timeWindow),
            address(reputationGate),
            address(singleTxCap),
            address(oracle),
            agentId,
            50 ether,
            5 ether,        // max per tx = 5 ETH
            allowed,
            block.timestamp + 30 days,
            40
        );

        Delegation memory d;
        d.delegator = address(account);
        d.delegate = agentOperator;
        d.authority = address(0);
        d.caveats = caveats;
        d.salt = 11;
        d = _sign(d);

        // 6 ETH exceeds 5 ETH single tx cap
        bool ok = _tryRedeemAsAgent(d, Action({
            target: address(target),
            value: 6 ether,
            callData: abi.encodeCall(TierTarget.doWork, (1))
        }));
        assertFalse(ok, "Should be blocked by single tx cap");
    }

    // =========================================================================
    // Tier Three — Full Delegation
    // =========================================================================

    function test_tierThree_happyPath() public {
        address[] memory allowed = new address[](1);
        allowed[0] = address(target);

        TierThree.Enforcers memory enforcers = TierThree.Enforcers({
            spendingCapEnforcer: address(spendingCap),
            whitelistEnforcer: address(whitelist),
            timeWindowEnforcer: address(timeWindow),
            reputationGateEnforcer: address(reputationGate),
            singleTxCapEnforcer: address(singleTxCap),
            cooldownEnforcer: address(cooldown)
        });

        TierThree.Params memory params = TierThree.Params({
            reputationOracle: address(oracle),
            agentId: agentId,
            weeklyCap: 100 ether,
            maxTxValue: 20 ether,
            allowedContracts: allowed,
            validUntil: block.timestamp + 90 days,
            minReputation: 40,
            cooldownPeriod: 1 hours,
            cooldownThreshold: 10 ether
        });

        Caveat[] memory caveats = TierThree.configureTierThree(enforcers, params);

        Delegation memory d;
        d.delegator = address(account);
        d.delegate = agentOperator;
        d.authority = address(0);
        d.caveats = caveats;
        d.salt = 20;
        d = _sign(d);

        _redeemAsAgent(d, Action({
            target: address(target),
            value: 15 ether,
            callData: abi.encodeCall(TierTarget.doWork, (999))
        }));
        assertEq(target.lastValue(), 999);
        assertEq(address(target).balance, 15 ether);
    }

    function test_tierThree_blockedByCooldown() public {
        address[] memory allowed = new address[](1);
        allowed[0] = address(target);

        TierThree.Enforcers memory enforcers = TierThree.Enforcers({
            spendingCapEnforcer: address(spendingCap),
            whitelistEnforcer: address(whitelist),
            timeWindowEnforcer: address(timeWindow),
            reputationGateEnforcer: address(reputationGate),
            singleTxCapEnforcer: address(singleTxCap),
            cooldownEnforcer: address(cooldown)
        });

        TierThree.Params memory params = TierThree.Params({
            reputationOracle: address(oracle),
            agentId: agentId,
            weeklyCap: 100 ether,
            maxTxValue: 20 ether,
            allowedContracts: allowed,
            validUntil: block.timestamp + 90 days,
            minReputation: 40,
            cooldownPeriod: 1 hours,
            cooldownThreshold: 10 ether
        });

        Caveat[] memory caveats = TierThree.configureTierThree(enforcers, params);

        Delegation memory d;
        d.delegator = address(account);
        d.delegate = agentOperator;
        d.authority = address(0);
        d.caveats = caveats;
        d.salt = 21;
        d = _sign(d);

        // First tx: 12 ETH (above cooldown threshold) — succeeds
        _redeemAsAgent(d, Action({
            target: address(target),
            value: 12 ether,
            callData: abi.encodeCall(TierTarget.doWork, (1))
        }));
        assertEq(target.callCount(), 1);

        // Second tx: 11 ETH immediately — blocked by cooldown
        // Reuse same delegation (same hash) so the cooldown tracking applies
        bool ok = _tryRedeemAsAgent(d, Action({
            target: address(target),
            value: 11 ether,
            callData: abi.encodeCall(TierTarget.doWork, (2))
        }));
        assertFalse(ok, "Should be blocked by cooldown");

        // Wait for cooldown to expire
        vm.warp(block.timestamp + 1 hours + 1);

        // Reuse same delegation again — cooldown has now elapsed
        _redeemAsAgent(d, Action({
            target: address(target),
            value: 11 ether,
            callData: abi.encodeCall(TierTarget.doWork, (3))
        }));
        assertEq(target.callCount(), 2);
        assertEq(target.lastValue(), 3);
    }

    function test_tierThree_lowValueBypassesCooldown() public {
        address[] memory allowed = new address[](1);
        allowed[0] = address(target);

        TierThree.Enforcers memory enforcers = TierThree.Enforcers({
            spendingCapEnforcer: address(spendingCap),
            whitelistEnforcer: address(whitelist),
            timeWindowEnforcer: address(timeWindow),
            reputationGateEnforcer: address(reputationGate),
            singleTxCapEnforcer: address(singleTxCap),
            cooldownEnforcer: address(cooldown)
        });

        TierThree.Params memory params = TierThree.Params({
            reputationOracle: address(oracle),
            agentId: agentId,
            weeklyCap: 100 ether,
            maxTxValue: 20 ether,
            allowedContracts: allowed,
            validUntil: block.timestamp + 90 days,
            minReputation: 40,
            cooldownPeriod: 1 hours,
            cooldownThreshold: 10 ether
        });

        Caveat[] memory caveats = TierThree.configureTierThree(enforcers, params);

        Delegation memory d;
        d.delegator = address(account);
        d.delegate = agentOperator;
        d.authority = address(0);
        d.caveats = caveats;
        d.salt = 30;
        d = _sign(d);

        // High value tx, triggers cooldown recording
        _redeemAsAgent(d, Action({
            target: address(target),
            value: 15 ether,
            callData: abi.encodeCall(TierTarget.doWork, (1))
        }));

        // Low value tx immediately — bypasses cooldown (reuse same delegation hash)
        _redeemAsAgent(d, Action({
            target: address(target),
            value: 5 ether,
            callData: abi.encodeCall(TierTarget.doWork, (2))
        }));
        assertEq(target.callCount(), 2);
        assertEq(target.lastValue(), 2);
    }
}
