// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {CooldownEnforcer} from "../src/caveats/CooldownEnforcer.sol";

/// @title CooldownEnforcerTest
/// @notice Tests for the CooldownEnforcer caveat.
contract CooldownEnforcerTest is Test {
    CooldownEnforcer public enforcer;

    bytes32 constant DELEGATION_HASH = bytes32(uint256(42));
    address constant DELEGATION_MANAGER = address(0xDEAD);
    address constant DELEGATOR = address(0x1);
    address constant REDEEMER = address(0x2);
    address constant TARGET = address(0x3);

    uint256 constant COOLDOWN = 300; // 5 minutes
    uint256 constant THRESHOLD = 0.5 ether;

    function setUp() public {
        enforcer = new CooldownEnforcer(DELEGATION_MANAGER);
        vm.warp(1000);
    }

    function test_firstExecutionPasses() public view {
        bytes memory terms = abi.encode(COOLDOWN, THRESHOLD);
        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 1 ether, "");
    }

    function test_firstExecutionBelowThresholdPasses() public view {
        bytes memory terms = abi.encode(COOLDOWN, THRESHOLD);
        enforcer.beforeHook(
            terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0.1 ether, ""
        );
    }

    function test_revertsWithinCooldown() public {
        bytes memory terms = abi.encode(COOLDOWN, THRESHOLD);

        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 1 ether, "");
        vm.prank(DELEGATION_MANAGER);
        enforcer.afterHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 1 ether, "");

        vm.warp(1100);

        vm.expectRevert(
            abi.encodeWithSelector(CooldownEnforcer.CooldownNotElapsed.selector, 1300, 1100)
        );
        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 1 ether, "");
    }

    function test_passesAfterCooldownElapsed() public {
        bytes memory terms = abi.encode(COOLDOWN, THRESHOLD);

        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 1 ether, "");
        vm.prank(DELEGATION_MANAGER);
        enforcer.afterHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 1 ether, "");

        vm.warp(1301);

        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 1 ether, "");
    }

    function test_belowThresholdBypassesCooldown() public {
        bytes memory terms = abi.encode(COOLDOWN, THRESHOLD);

        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 1 ether, "");
        vm.prank(DELEGATION_MANAGER);
        enforcer.afterHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 1 ether, "");

        vm.warp(1001);
        enforcer.beforeHook(
            terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0.1 ether, ""
        );
    }

    function test_afterHookDoesNotRecordBelowThreshold() public {
        bytes memory terms = abi.encode(COOLDOWN, THRESHOLD);

        vm.prank(DELEGATION_MANAGER);
        enforcer.afterHook(
            terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0.1 ether, ""
        );

        assertEq(enforcer.lastExecution(DELEGATION_HASH), 0);
    }

    function test_afterHookRecordsAboveThreshold() public {
        bytes memory terms = abi.encode(COOLDOWN, THRESHOLD);

        vm.prank(DELEGATION_MANAGER);
        enforcer.afterHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 1 ether, "");

        assertEq(enforcer.lastExecution(DELEGATION_HASH), 1000);
    }

    function test_exactThresholdTriggersCooldown() public {
        bytes memory terms = abi.encode(COOLDOWN, THRESHOLD);

        enforcer.beforeHook(
            terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, THRESHOLD, ""
        );
        vm.prank(DELEGATION_MANAGER);
        enforcer.afterHook(
            terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, THRESHOLD, ""
        );

        vm.warp(1100);

        vm.expectRevert();
        enforcer.beforeHook(
            terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, THRESHOLD, ""
        );
    }

    function test_afterHookRevertsForUnauthorizedCaller() public {
        bytes memory terms = abi.encode(COOLDOWN, THRESHOLD);
        vm.prank(address(0xBEEF));
        vm.expectRevert(CooldownEnforcer.UnauthorizedCaller.selector);
        enforcer.afterHook(
            terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 1 ether, ""
        );
    }

    function test_afterHookValueBelowThresholdDoesNotRecord() public {
        bytes memory terms = abi.encode(COOLDOWN, THRESHOLD);
        // Value is exactly 1 wei below threshold
        uint256 justBelow = THRESHOLD - 1;
        vm.prank(DELEGATION_MANAGER);
        enforcer.afterHook(
            terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, justBelow, ""
        );
        assertEq(enforcer.lastExecution(DELEGATION_HASH), 0);
    }

    function test_afterHookValueAtExactThresholdRecords() public {
        bytes memory terms = abi.encode(COOLDOWN, THRESHOLD);
        vm.prank(DELEGATION_MANAGER);
        enforcer.afterHook(
            terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, THRESHOLD, ""
        );
        assertEq(enforcer.lastExecution(DELEGATION_HASH), 1000);
    }

    function test_passesAtExactCooldownBoundary() public {
        bytes memory terms = abi.encode(COOLDOWN, THRESHOLD);

        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 1 ether, "");
        vm.prank(DELEGATION_MANAGER);
        enforcer.afterHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 1 ether, "");

        // Warp to exactly lastExecution + cooldown = 1000 + 300 = 1300
        vm.warp(1300);

        // Should pass: block.timestamp == nextAllowed, so block.timestamp < nextAllowed is false
        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 1 ether, "");
    }
}
