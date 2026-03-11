// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {CooldownEnforcer} from "../../src/caveats/CooldownEnforcer.sol";

/// @title CooldownEnforcer — Formal Verification (Halmos)
/// @notice Symbolic tests proving cooldown period invariants.
contract CooldownEnforcerFV is Test {
    CooldownEnforcer enforcer;
    address constant DM = address(0xD1);

    function setUp() public {
        enforcer = new CooldownEnforcer(DM);
    }

    /// @notice Proves: if value >= threshold AND we are within cooldown, beforeHook reverts.
    function check_cooldown_revertsWithinPeriod(
        uint256 cooldownPeriod,
        uint256 valueThreshold,
        uint256 value,
        bytes32 delegationHash,
        uint256 firstTimestamp,
        uint256 secondTimestamp
    ) public {
        vm.assume(cooldownPeriod > 0);
        vm.assume(value >= valueThreshold);
        vm.assume(firstTimestamp > 0);
        // Ensure second call is within cooldown window
        vm.assume(secondTimestamp >= firstTimestamp);
        vm.assume(secondTimestamp < firstTimestamp + cooldownPeriod);
        // Avoid overflow
        vm.assume(firstTimestamp + cooldownPeriod >= firstTimestamp);

        bytes memory terms = abi.encode(cooldownPeriod, valueThreshold);

        // First execution: record via afterHook
        vm.warp(firstTimestamp);
        vm.prank(DM);
        enforcer.afterHook(terms, "", address(0), delegationHash, address(0), address(0), address(0), value, "");

        // Second execution: should revert (within cooldown)
        vm.warp(secondTimestamp);
        try enforcer.beforeHook(terms, "", address(0), delegationHash, address(0), address(0), address(0), value, "") {
            assert(false); // Must revert within cooldown
        } catch {}
    }

    /// @notice Proves: if value >= threshold AND we are past cooldown, beforeHook succeeds.
    function check_cooldown_passesAfterPeriod(
        uint256 cooldownPeriod,
        uint256 valueThreshold,
        uint256 value,
        bytes32 delegationHash,
        uint256 firstTimestamp,
        uint256 secondTimestamp
    ) public {
        vm.assume(cooldownPeriod > 0);
        vm.assume(value >= valueThreshold);
        vm.assume(firstTimestamp > 0);
        vm.assume(firstTimestamp + cooldownPeriod >= firstTimestamp); // no overflow
        vm.assume(secondTimestamp >= firstTimestamp + cooldownPeriod);

        bytes memory terms = abi.encode(cooldownPeriod, valueThreshold);

        // First execution
        vm.warp(firstTimestamp);
        vm.prank(DM);
        enforcer.afterHook(terms, "", address(0), delegationHash, address(0), address(0), address(0), value, "");

        // Second execution: past cooldown
        vm.warp(secondTimestamp);
        // Must not revert
        enforcer.beforeHook(terms, "", address(0), delegationHash, address(0), address(0), address(0), value, "");
    }

    /// @notice Proves: if value < threshold, cooldown does not apply (always passes).
    function check_cooldown_belowThresholdAlwaysPasses(
        uint256 cooldownPeriod,
        uint256 valueThreshold,
        uint256 value,
        bytes32 delegationHash,
        uint256 timestamp
    ) public {
        vm.assume(cooldownPeriod > 0);
        vm.assume(valueThreshold > 0);
        vm.assume(value < valueThreshold);
        vm.assume(timestamp > 0);

        bytes memory terms = abi.encode(cooldownPeriod, valueThreshold);

        // Even with a recent lastExecution, below-threshold should pass
        vm.warp(timestamp);
        vm.prank(DM);
        enforcer.afterHook(terms, "", address(0), delegationHash, address(0), address(0), address(0), valueThreshold, "");

        // Same timestamp, below threshold
        enforcer.beforeHook(terms, "", address(0), delegationHash, address(0), address(0), address(0), value, "");
    }

    /// @notice Proves: afterHook only callable by delegation manager.
    function check_cooldown_afterHookAccessControl(
        address caller,
        bytes32 delegationHash
    ) public {
        vm.assume(caller != DM);
        bytes memory terms = abi.encode(uint256(3600), uint256(1 ether));

        vm.prank(caller);
        try enforcer.afterHook(terms, "", address(0), delegationHash, address(0), address(0), address(0), 1 ether, "") {
            assert(false);
        } catch {}
    }
}
