// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {ContractWhitelistEnforcer} from "../../src/caveats/ContractWhitelistEnforcer.sol";

/// @title ContractWhitelistEnforcer — Formal Verification (Halmos)
/// @notice Symbolic tests proving whitelist invariants hold for ALL possible inputs.
contract ContractWhitelistEnforcerFV is Test {
    ContractWhitelistEnforcer enforcer;

    function setUp() public {
        enforcer = new ContractWhitelistEnforcer();
    }

    /// @notice Proves: if target is NOT in the allowed list, beforeHook always reverts.
    /// Uses a concrete 2-element whitelist with symbolic target to keep Halmos tractable.
    function check_whitelist_revertsForNonWhitelisted(
        address allowed0,
        address allowed1,
        address target
    ) public view {
        vm.assume(target != allowed0);
        vm.assume(target != allowed1);

        address[] memory allowed = new address[](2);
        allowed[0] = allowed0;
        allowed[1] = allowed1;
        bytes memory terms = abi.encode(allowed);

        try enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), target, 0, "") {
            assert(false); // Must not succeed for non-whitelisted target
        } catch {
            // Expected: ContractNotWhitelisted
        }
    }

    /// @notice Proves: if target IS in the allowed list, beforeHook succeeds.
    function check_whitelist_passesForWhitelistedFirst(
        address allowed0,
        address allowed1
    ) public view {
        address[] memory allowed = new address[](2);
        allowed[0] = allowed0;
        allowed[1] = allowed1;
        bytes memory terms = abi.encode(allowed);

        // Target = allowed0 => must pass
        enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), allowed0, 0, "");
    }

    function check_whitelist_passesForWhitelistedSecond(
        address allowed0,
        address allowed1
    ) public view {
        address[] memory allowed = new address[](2);
        allowed[0] = allowed0;
        allowed[1] = allowed1;
        bytes memory terms = abi.encode(allowed);

        // Target = allowed1 => must pass
        enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), allowed1, 0, "");
    }

    /// @notice Proves: empty whitelist always reverts for any target.
    function check_whitelist_emptyAlwaysReverts(address target) public view {
        address[] memory allowed = new address[](0);
        bytes memory terms = abi.encode(allowed);

        try enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), target, 0, "") {
            assert(false);
        } catch {}
    }
}
