// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {TimeWindowEnforcer} from "../src/caveats/TimeWindowEnforcer.sol";

contract TimeWindowEnforcerTest is Test {
    TimeWindowEnforcer enforcer;

    address constant DM = address(0x1);
    bytes32 constant HASH = bytes32(uint256(1));
    address constant DELEGATOR = address(0x2);
    address constant REDEEMER = address(0x3);
    address constant TARGET = address(0x4);

    function setUp() public {
        enforcer = new TimeWindowEnforcer();
    }

    function _beforeHook(bytes memory terms) internal view {
        enforcer.beforeHook(terms, "", DM, HASH, DELEGATOR, REDEEMER, TARGET, 0, "");
    }

    function test_allowsWithinWindow() public {
        uint256 notBefore = 1000;
        uint256 notAfter = 2000;
        vm.warp(1500);
        _beforeHook(abi.encode(notBefore, notAfter));
    }

    function test_revertsBefore() public {
        uint256 notBefore = 1000;
        uint256 notAfter = 2000;
        vm.warp(500);
        vm.expectRevert(
            abi.encodeWithSelector(TimeWindowEnforcer.OutsideTimeWindow.selector, 500, notBefore, notAfter)
        );
        _beforeHook(abi.encode(notBefore, notAfter));
    }

    function test_revertsAfter() public {
        uint256 notBefore = 1000;
        uint256 notAfter = 2000;
        vm.warp(3000);
        vm.expectRevert(
            abi.encodeWithSelector(TimeWindowEnforcer.OutsideTimeWindow.selector, 3000, notBefore, notAfter)
        );
        _beforeHook(abi.encode(notBefore, notAfter));
    }

    function test_allowsAtExactBoundaries() public {
        uint256 notBefore = 1000;
        uint256 notAfter = 2000;

        vm.warp(notBefore);
        _beforeHook(abi.encode(notBefore, notAfter));

        vm.warp(notAfter);
        _beforeHook(abi.encode(notBefore, notAfter));
    }
}
