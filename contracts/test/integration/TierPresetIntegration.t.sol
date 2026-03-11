// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IrisTestBase} from "../helpers/IrisTestBase.sol";
import {IrisAccount} from "../../src/IrisAccount.sol";
import {TierOne} from "../../src/presets/TierOne.sol";
import {TierTwo} from "../../src/presets/TierTwo.sol";
import {TierThree} from "../../src/presets/TierThree.sol";
import {Delegation, Action, Caveat} from "../../src/interfaces/IERC7710.sol";

contract TierTarget {
    uint256 public lastValue;
    uint256 public callCount;
    function doWork(uint256 v) external payable { lastValue = v; callCount++; }
    receive() external payable {}
}

/// @title TierPresetIntegrationTest
/// @notice Tests Tier 1/2/3 preset libraries in full delegation flows.
/// @dev Uses IrisDeployer fixture via IrisTestBase for deployment parity with mainnet scripts.
contract TierPresetIntegrationTest is IrisTestBase {
    address owner;
    uint256 ownerKey;
    address agentOperator;
    uint256 agentId;

    IrisAccount account;
    TierTarget target;

    function setUp() public {
        vm.warp(1_000_000);
        _deployIris();

        (owner, ownerKey) = makeAddrAndKey("owner");
        agentOperator = makeAddr("agent");

        agentId = _registerAgent(agentOperator, "ipfs://agent-card");
        account = _createFundedAccount(owner, 1000 ether);
        target = new TierTarget();
    }

    // =========================================================================
    // Tier One — Supervised
    // =========================================================================

    function test_tierOne_happyPath() public {
        address[] memory allowed = new address[](1);
        allowed[0] = address(target);

        Caveat[] memory caveats = TierOne.configureTierOne(
            address(d.spendingCap), address(d.contractWhitelist), address(d.timeWindow), address(d.reputationGate),
            address(d.reputationOracle), agentId, 10 ether, allowed, block.timestamp + 7 days, 40
        );

        Delegation memory del;
        del.delegator = address(account);
        del.delegate = agentOperator;
        del.authority = address(0);
        del.caveats = caveats;
        del.salt = 1;
        del = _signDelegation(del, ownerKey);

        _redeemAs(agentOperator, del, Action({target: address(target), value: 1 ether, callData: abi.encodeCall(TierTarget.doWork, (42))}));
        assertEq(target.lastValue(), 42);
        assertEq(target.callCount(), 1);
    }

    function test_tierOne_blockedBySpendingCap() public {
        address[] memory allowed = new address[](1);
        allowed[0] = address(target);

        Caveat[] memory caveats = TierOne.configureTierOne(
            address(d.spendingCap), address(d.contractWhitelist), address(d.timeWindow), address(d.reputationGate),
            address(d.reputationOracle), agentId, 5 ether, allowed, block.timestamp + 7 days, 40
        );

        Delegation memory del;
        del.delegator = address(account);
        del.delegate = agentOperator;
        del.authority = address(0);
        del.caveats = caveats;
        del.salt = 2;
        del = _signDelegation(del, ownerKey);

        bool ok = _tryRedeemAs(agentOperator, del, Action({target: address(target), value: 6 ether, callData: abi.encodeCall(TierTarget.doWork, (1))}));
        assertFalse(ok);
    }

    function test_tierOne_blockedByWhitelist() public {
        address[] memory allowed = new address[](1);
        allowed[0] = address(target);

        Caveat[] memory caveats = TierOne.configureTierOne(
            address(d.spendingCap), address(d.contractWhitelist), address(d.timeWindow), address(d.reputationGate),
            address(d.reputationOracle), agentId, 10 ether, allowed, block.timestamp + 7 days, 40
        );

        Delegation memory del;
        del.delegator = address(account);
        del.delegate = agentOperator;
        del.authority = address(0);
        del.caveats = caveats;
        del.salt = 3;
        del = _signDelegation(del, ownerKey);

        bool ok = _tryRedeemAs(agentOperator, del, Action({target: makeAddr("rogue"), value: 1 ether, callData: ""}));
        assertFalse(ok);
    }

    function test_tierOne_blockedByTimeWindowExpiry() public {
        address[] memory allowed = new address[](1);
        allowed[0] = address(target);

        Caveat[] memory caveats = TierOne.configureTierOne(
            address(d.spendingCap), address(d.contractWhitelist), address(d.timeWindow), address(d.reputationGate),
            address(d.reputationOracle), agentId, 10 ether, allowed, block.timestamp + 1 days, 40
        );

        Delegation memory del;
        del.delegator = address(account);
        del.delegate = agentOperator;
        del.authority = address(0);
        del.caveats = caveats;
        del.salt = 4;
        del = _signDelegation(del, ownerKey);

        _redeemAs(agentOperator, del, Action({target: address(target), value: 0, callData: abi.encodeCall(TierTarget.doWork, (1))}));
        assertEq(target.callCount(), 1);

        vm.warp(block.timestamp + 2 days);

        Delegation memory del2;
        del2.delegator = address(account);
        del2.delegate = agentOperator;
        del2.authority = address(0);
        del2.caveats = caveats;
        del2.salt = 5;
        del2 = _signDelegation(del2, ownerKey);

        bool ok = _tryRedeemAs(agentOperator, del2, Action({target: address(target), value: 0, callData: abi.encodeCall(TierTarget.doWork, (2))}));
        assertFalse(ok);
    }

    function test_tierOne_blockedByReputation() public {
        address[] memory allowed = new address[](1);
        allowed[0] = address(target);

        d.reputationOracle.submitFeedback(agentId, false); // 50 -> 45
        d.reputationOracle.submitFeedback(agentId, false); // 45 -> 40
        d.reputationOracle.submitFeedback(agentId, false); // 40 -> 35

        Caveat[] memory caveats = TierOne.configureTierOne(
            address(d.spendingCap), address(d.contractWhitelist), address(d.timeWindow), address(d.reputationGate),
            address(d.reputationOracle), agentId, 10 ether, allowed, block.timestamp + 7 days, 40
        );

        Delegation memory del;
        del.delegator = address(account);
        del.delegate = agentOperator;
        del.authority = address(0);
        del.caveats = caveats;
        del.salt = 6;
        del = _signDelegation(del, ownerKey);

        bool ok = _tryRedeemAs(agentOperator, del, Action({target: address(target), value: 0, callData: abi.encodeCall(TierTarget.doWork, (1))}));
        assertFalse(ok);
    }

    // =========================================================================
    // Tier Two — Autonomous
    // =========================================================================

    function test_tierTwo_happyPath() public {
        address[] memory allowed = new address[](1);
        allowed[0] = address(target);

        Caveat[] memory caveats = TierTwo.configureTierTwo(
            address(d.spendingCap), address(d.contractWhitelist), address(d.timeWindow), address(d.reputationGate),
            address(d.singleTxCap), address(d.reputationOracle), agentId,
            50 ether, 10 ether, allowed, block.timestamp + 30 days, 40
        );

        Delegation memory del;
        del.delegator = address(account);
        del.delegate = agentOperator;
        del.authority = address(0);
        del.caveats = caveats;
        del.salt = 10;
        del = _signDelegation(del, ownerKey);

        _redeemAs(agentOperator, del, Action({target: address(target), value: 5 ether, callData: abi.encodeCall(TierTarget.doWork, (100))}));
        assertEq(target.lastValue(), 100);
    }

    function test_tierTwo_blockedBySingleTxCap() public {
        address[] memory allowed = new address[](1);
        allowed[0] = address(target);

        Caveat[] memory caveats = TierTwo.configureTierTwo(
            address(d.spendingCap), address(d.contractWhitelist), address(d.timeWindow), address(d.reputationGate),
            address(d.singleTxCap), address(d.reputationOracle), agentId,
            50 ether, 5 ether, allowed, block.timestamp + 30 days, 40
        );

        Delegation memory del;
        del.delegator = address(account);
        del.delegate = agentOperator;
        del.authority = address(0);
        del.caveats = caveats;
        del.salt = 11;
        del = _signDelegation(del, ownerKey);

        bool ok = _tryRedeemAs(agentOperator, del, Action({target: address(target), value: 6 ether, callData: abi.encodeCall(TierTarget.doWork, (1))}));
        assertFalse(ok);
    }

    // =========================================================================
    // Tier Three — Full Delegation
    // =========================================================================

    function test_tierThree_happyPath() public {
        address[] memory allowed = new address[](1);
        allowed[0] = address(target);

        TierThree.Enforcers memory enforcers = TierThree.Enforcers({
            spendingCapEnforcer: address(d.spendingCap), whitelistEnforcer: address(d.contractWhitelist),
            timeWindowEnforcer: address(d.timeWindow), reputationGateEnforcer: address(d.reputationGate),
            singleTxCapEnforcer: address(d.singleTxCap), cooldownEnforcer: address(d.cooldown)
        });

        TierThree.Params memory params = TierThree.Params({
            reputationOracle: address(d.reputationOracle), agentId: agentId,
            weeklyCap: 100 ether, maxTxValue: 20 ether, allowedContracts: allowed,
            validUntil: block.timestamp + 90 days, minReputation: 40, cooldownPeriod: 1 hours, cooldownThreshold: 10 ether
        });

        Delegation memory del;
        del.delegator = address(account);
        del.delegate = agentOperator;
        del.authority = address(0);
        del.caveats = TierThree.configureTierThree(enforcers, params);
        del.salt = 20;
        del = _signDelegation(del, ownerKey);

        _redeemAs(agentOperator, del, Action({target: address(target), value: 15 ether, callData: abi.encodeCall(TierTarget.doWork, (999))}));
        assertEq(target.lastValue(), 999);
    }

    function test_tierThree_blockedByCooldown() public {
        address[] memory allowed = new address[](1);
        allowed[0] = address(target);

        TierThree.Enforcers memory enforcers = TierThree.Enforcers({
            spendingCapEnforcer: address(d.spendingCap), whitelistEnforcer: address(d.contractWhitelist),
            timeWindowEnforcer: address(d.timeWindow), reputationGateEnforcer: address(d.reputationGate),
            singleTxCapEnforcer: address(d.singleTxCap), cooldownEnforcer: address(d.cooldown)
        });

        TierThree.Params memory params = TierThree.Params({
            reputationOracle: address(d.reputationOracle), agentId: agentId,
            weeklyCap: 100 ether, maxTxValue: 20 ether, allowedContracts: allowed,
            validUntil: block.timestamp + 90 days, minReputation: 40, cooldownPeriod: 1 hours, cooldownThreshold: 10 ether
        });

        Delegation memory del;
        del.delegator = address(account);
        del.delegate = agentOperator;
        del.authority = address(0);
        del.caveats = TierThree.configureTierThree(enforcers, params);
        del.salt = 21;
        del = _signDelegation(del, ownerKey);

        _redeemAs(agentOperator, del, Action({target: address(target), value: 12 ether, callData: abi.encodeCall(TierTarget.doWork, (1))}));
        assertEq(target.callCount(), 1);

        bool ok = _tryRedeemAs(agentOperator, del, Action({target: address(target), value: 11 ether, callData: abi.encodeCall(TierTarget.doWork, (2))}));
        assertFalse(ok);

        vm.warp(block.timestamp + 1 hours + 1);

        _redeemAs(agentOperator, del, Action({target: address(target), value: 11 ether, callData: abi.encodeCall(TierTarget.doWork, (3))}));
        assertEq(target.callCount(), 2);
        assertEq(target.lastValue(), 3);
    }

    function test_tierThree_lowValueBypassesCooldown() public {
        address[] memory allowed = new address[](1);
        allowed[0] = address(target);

        TierThree.Enforcers memory enforcers = TierThree.Enforcers({
            spendingCapEnforcer: address(d.spendingCap), whitelistEnforcer: address(d.contractWhitelist),
            timeWindowEnforcer: address(d.timeWindow), reputationGateEnforcer: address(d.reputationGate),
            singleTxCapEnforcer: address(d.singleTxCap), cooldownEnforcer: address(d.cooldown)
        });

        TierThree.Params memory params = TierThree.Params({
            reputationOracle: address(d.reputationOracle), agentId: agentId,
            weeklyCap: 100 ether, maxTxValue: 20 ether, allowedContracts: allowed,
            validUntil: block.timestamp + 90 days, minReputation: 40, cooldownPeriod: 1 hours, cooldownThreshold: 10 ether
        });

        Delegation memory del;
        del.delegator = address(account);
        del.delegate = agentOperator;
        del.authority = address(0);
        del.caveats = TierThree.configureTierThree(enforcers, params);
        del.salt = 30;
        del = _signDelegation(del, ownerKey);

        _redeemAs(agentOperator, del, Action({target: address(target), value: 15 ether, callData: abi.encodeCall(TierTarget.doWork, (1))}));

        // Low value bypasses cooldown
        _redeemAs(agentOperator, del, Action({target: address(target), value: 5 ether, callData: abi.encodeCall(TierTarget.doWork, (2))}));
        assertEq(target.callCount(), 2);
    }
}
