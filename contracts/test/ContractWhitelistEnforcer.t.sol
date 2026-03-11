// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {ContractWhitelistEnforcer} from "../src/caveats/ContractWhitelistEnforcer.sol";

contract ContractWhitelistEnforcerTest is Test {
    ContractWhitelistEnforcer enforcer;

    address constant DM = address(0x1);
    bytes32 constant HASH = bytes32(uint256(1));
    address constant DELEGATOR = address(0x2);
    address constant REDEEMER = address(0x3);

    function setUp() public {
        enforcer = new ContractWhitelistEnforcer();
    }

    function _beforeHook(bytes memory terms, address target) internal view {
        enforcer.beforeHook(terms, "", DM, HASH, DELEGATOR, REDEEMER, target, 0, "");
    }

    function test_allowsWhitelistedTarget() public view {
        address target = address(0x10);
        address[] memory allowed = new address[](1);
        allowed[0] = target;
        _beforeHook(abi.encode(allowed), target);
    }

    function test_allowsAnyOfMultipleWhitelistedTargets() public view {
        address[] memory allowed = new address[](3);
        allowed[0] = address(0x10);
        allowed[1] = address(0x20);
        allowed[2] = address(0x30);
        bytes memory terms = abi.encode(allowed);

        _beforeHook(terms, address(0x10));
        _beforeHook(terms, address(0x20));
        _beforeHook(terms, address(0x30));
    }

    function test_revertsForNonWhitelistedTarget() public {
        address[] memory allowed = new address[](1);
        allowed[0] = address(0x10);
        address badTarget = address(0x99);

        vm.expectRevert(
            abi.encodeWithSelector(ContractWhitelistEnforcer.ContractNotWhitelisted.selector, badTarget)
        );
        _beforeHook(abi.encode(allowed), badTarget);
    }

    function test_revertsForEmptyWhitelist() public {
        address[] memory allowed = new address[](0);
        address target = address(0x10);

        vm.expectRevert(
            abi.encodeWithSelector(ContractWhitelistEnforcer.ContractNotWhitelisted.selector, target)
        );
        _beforeHook(abi.encode(allowed), target);
    }
}
