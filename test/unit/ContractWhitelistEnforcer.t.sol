// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {ContractWhitelistEnforcer} from "../../src/caveats/ContractWhitelistEnforcer.sol";

contract ContractWhitelistEnforcerTest is Test {
    ContractWhitelistEnforcer enforcer;

    address allowed1;
    address allowed2;
    address disallowed;

    function setUp() public {
        enforcer = new ContractWhitelistEnforcer();
        allowed1 = makeAddr("allowed1");
        allowed2 = makeAddr("allowed2");
        disallowed = makeAddr("disallowed");
    }

    function _terms(address[] memory addrs) internal pure returns (bytes memory) {
        return abi.encode(addrs);
    }

    function _callBefore(bytes memory terms, address target) internal view {
        enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), target, 0, "");
    }

    // -----------------------------------------------------------------------
    // Tests
    // -----------------------------------------------------------------------

    function test_beforeHook_allowsWhitelistedTarget() public view {
        address[] memory addrs = new address[](2);
        addrs[0] = allowed1;
        addrs[1] = allowed2;

        _callBefore(_terms(addrs), allowed1);
        _callBefore(_terms(addrs), allowed2);
    }

    function test_beforeHook_revertsForNonWhitelistedTarget() public {
        address[] memory addrs = new address[](2);
        addrs[0] = allowed1;
        addrs[1] = allowed2;

        vm.expectRevert(
            abi.encodeWithSelector(ContractWhitelistEnforcer.ContractNotWhitelisted.selector, disallowed)
        );
        _callBefore(_terms(addrs), disallowed);
    }

    function test_beforeHook_revertsWithEmptyWhitelist() public {
        address[] memory addrs = new address[](0);

        vm.expectRevert(
            abi.encodeWithSelector(ContractWhitelistEnforcer.ContractNotWhitelisted.selector, allowed1)
        );
        _callBefore(_terms(addrs), allowed1);
    }

    function test_beforeHook_singleElementWhitelist() public view {
        address[] memory addrs = new address[](1);
        addrs[0] = allowed1;

        _callBefore(_terms(addrs), allowed1);
    }

    function test_afterHook_isNoop() public {
        ContractWhitelistEnforcer e = new ContractWhitelistEnforcer();
        e.afterHook("", "", address(0), bytes32(0), address(0), address(0), address(0), 0, "");
    }
}
