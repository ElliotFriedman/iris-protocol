// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {TimeWindowEnforcer} from "../../src/caveats/TimeWindowEnforcer.sol";

/// @title TimeWindowEnforcer — Formal Verification (Halmos)
/// @notice Symbolic tests proving time window invariants hold for ALL timestamps and bounds.
contract TimeWindowEnforcerFV is Test {
    TimeWindowEnforcer enforcer;

    function setUp() public {
        enforcer = new TimeWindowEnforcer();
    }

    /// @notice Proves: beforeHook succeeds iff notBefore <= timestamp <= notAfter.
    function check_timeWindow_exactBoundary(
        uint256 notBefore,
        uint256 notAfter,
        uint256 timestamp
    ) public {
        vm.warp(timestamp);
        bytes memory terms = abi.encode(notBefore, notAfter);
        try enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), 0, "") {
            // Succeeded — timestamp must be within window
            assert(timestamp >= notBefore && timestamp <= notAfter);
        } catch {
            // Reverted — timestamp must be outside window
            assert(timestamp < notBefore || timestamp > notAfter);
        }
    }

    /// @notice Proves: if timestamp is within [notBefore, notAfter], beforeHook succeeds.
    function check_timeWindow_withinWindowSucceeds(
        uint256 notBefore,
        uint256 notAfter,
        uint256 timestamp
    ) public {
        vm.assume(timestamp >= notBefore);
        vm.assume(timestamp <= notAfter);
        vm.warp(timestamp);
        bytes memory terms = abi.encode(notBefore, notAfter);
        // Must not revert
        enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), 0, "");
    }

    /// @notice Proves: if timestamp < notBefore, beforeHook reverts.
    function check_timeWindow_beforeWindowReverts(
        uint256 notBefore,
        uint256 notAfter,
        uint256 timestamp
    ) public {
        vm.assume(timestamp < notBefore);
        vm.warp(timestamp);
        bytes memory terms = abi.encode(notBefore, notAfter);
        try enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), 0, "") {
            assert(false);
        } catch {}
    }

    /// @notice Proves: if timestamp > notAfter, beforeHook reverts.
    function check_timeWindow_afterWindowReverts(
        uint256 notBefore,
        uint256 notAfter,
        uint256 timestamp
    ) public {
        vm.assume(timestamp > notAfter);
        vm.warp(timestamp);
        bytes memory terms = abi.encode(notBefore, notAfter);
        try enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), 0, "") {
            assert(false);
        } catch {}
    }
}
