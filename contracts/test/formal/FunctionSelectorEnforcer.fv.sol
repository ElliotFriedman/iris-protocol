// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {FunctionSelectorEnforcer} from "../../src/caveats/FunctionSelectorEnforcer.sol";

/// @title FunctionSelectorEnforcer — Formal Verification (Halmos)
/// @notice Symbolic tests proving function selector whitelist invariants.
contract FunctionSelectorEnforcerFV is Test {
    FunctionSelectorEnforcer enforcer;

    function setUp() public {
        enforcer = new FunctionSelectorEnforcer();
    }

    /// @notice Proves: if calldata selector is NOT in allowed list, beforeHook reverts.
    function check_selector_revertsForDisallowed(
        bytes4 allowed0,
        bytes4 selector
    ) public view {
        vm.assume(selector != allowed0);

        bytes4[] memory allowed = new bytes4[](1);
        allowed[0] = allowed0;
        bytes memory terms = abi.encode(allowed);
        // Build 4-byte calldata with the selector
        bytes memory callData = abi.encodePacked(selector);

        try enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), 0, callData) {
            assert(false); // Must not succeed
        } catch {}
    }

    /// @notice Proves: if calldata selector IS in allowed list, beforeHook succeeds.
    function check_selector_passesForAllowed(bytes4 allowed0) public view {
        bytes4[] memory allowed = new bytes4[](1);
        allowed[0] = allowed0;
        bytes memory terms = abi.encode(allowed);
        bytes memory callData = abi.encodePacked(allowed0);

        // Must not revert
        enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), 0, callData);
    }

    /// @notice Proves: calldata shorter than 4 bytes always reverts.
    function check_selector_shortCalldataReverts() public view {
        bytes4[] memory allowed = new bytes4[](1);
        allowed[0] = bytes4(0x12345678);
        bytes memory terms = abi.encode(allowed);

        // Empty calldata
        try enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), 0, "") {
            assert(false);
        } catch {}

        // 3-byte calldata
        bytes memory shortData = hex"123456";
        try enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), 0, shortData) {
            assert(false);
        } catch {}
    }
}
