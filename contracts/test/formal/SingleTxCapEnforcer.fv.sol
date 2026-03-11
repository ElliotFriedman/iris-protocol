// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {SingleTxCapEnforcer} from "../../src/caveats/SingleTxCapEnforcer.sol";

/// @title SingleTxCapEnforcer — Formal Verification (Halmos)
/// @notice Symbolic tests proving per-transaction value cap invariants.
contract SingleTxCapEnforcerFV is Test {
    SingleTxCapEnforcer enforcer;

    function setUp() public {
        enforcer = new SingleTxCapEnforcer();
    }

    /// @notice Proves: beforeHook succeeds iff value <= maxValue.
    function check_singleTxCap_exactBoundary(uint256 maxValue, uint256 value) public view {
        bytes memory terms = abi.encode(maxValue);
        try enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), value, "") {
            // Succeeded — must mean value <= maxValue
            assert(value <= maxValue);
        } catch {
            // Reverted — must mean value > maxValue
            assert(value > maxValue);
        }
    }

    /// @notice Proves: if value <= maxValue, beforeHook always succeeds.
    function check_singleTxCap_passesUnderCap(uint256 maxValue, uint256 value) public view {
        vm.assume(value <= maxValue);
        bytes memory terms = abi.encode(maxValue);
        // Must not revert
        enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), value, "");
    }

    /// @notice Proves: if value > maxValue, beforeHook always reverts.
    function check_singleTxCap_revertsOverCap(uint256 maxValue, uint256 value) public view {
        vm.assume(value > maxValue);
        bytes memory terms = abi.encode(maxValue);
        try enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), value, "") {
            assert(false); // Must not succeed
        } catch {
            // Expected
        }
    }
}
