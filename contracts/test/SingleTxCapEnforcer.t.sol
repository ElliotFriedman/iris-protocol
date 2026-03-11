// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {SingleTxCapEnforcer} from "../src/caveats/SingleTxCapEnforcer.sol";

contract SingleTxCapEnforcerTest is Test {
    SingleTxCapEnforcer enforcer;

    address constant DM = address(0x1);
    bytes32 constant HASH = bytes32(uint256(1));
    address constant DELEGATOR = address(0x2);
    address constant REDEEMER = address(0x3);
    address constant TARGET = address(0x4);

    function setUp() public {
        enforcer = new SingleTxCapEnforcer();
    }

    function _beforeHook(bytes memory terms, uint256 value) internal view {
        enforcer.beforeHook(terms, "", DM, HASH, DELEGATOR, REDEEMER, TARGET, value, "");
    }

    function test_allowsBelowCap() public view {
        _beforeHook(abi.encode(uint256(100)), 50);
    }

    function test_allowsExactCap() public view {
        _beforeHook(abi.encode(uint256(100)), 100);
    }

    function test_revertsAboveCap() public {
        vm.expectRevert(
            abi.encodeWithSelector(SingleTxCapEnforcer.SingleTxCapExceeded.selector, 150, 100)
        );
        _beforeHook(abi.encode(uint256(100)), 150);
    }

    function test_afterHookIsNoop() public view {
        enforcer.afterHook(abi.encode(uint256(100)), "", DM, HASH, DELEGATOR, REDEEMER, TARGET, 50, "");
    }
}
