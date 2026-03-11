// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {SpendingCapEnforcer} from "../src/caveats/SpendingCapEnforcer.sol";

/// @title SpendingCapEnforcerTest
/// @notice Tests for the SpendingCapEnforcer caveat.
contract SpendingCapEnforcerTest is Test {
    SpendingCapEnforcer public enforcer;

    bytes32 constant DH = bytes32(uint256(1));
    address constant DM = address(0xDEAD);
    address constant D = address(0x1);
    address constant R = address(0x2);
    address constant T = address(0x3);

    uint256 constant DAILY_CAP = 1 ether;
    uint256 constant PERIOD = 86_400;

    function setUp() public {
        enforcer = new SpendingCapEnforcer();
        vm.warp(86_400);
    }

    function test_withinCapPasses() public view {
        bytes memory terms = abi.encode(DAILY_CAP, PERIOD);
        enforcer.beforeHook(terms, "", DM, DH, D, R, T, 0.5 ether, "");
    }

    function test_exactlyAtCapPasses() public view {
        bytes memory terms = abi.encode(DAILY_CAP, PERIOD);
        enforcer.beforeHook(terms, "", DM, DH, D, R, T, DAILY_CAP, "");
    }

    function test_exceedingCapReverts() public {
        bytes memory terms = abi.encode(DAILY_CAP, PERIOD);
        vm.expectRevert(
            abi.encodeWithSelector(SpendingCapEnforcer.SpendingCapExceeded.selector, 1.5 ether, DAILY_CAP)
        );
        enforcer.beforeHook(terms, "", DM, DH, D, R, T, 1.5 ether, "");
    }

    function test_cumulativeSpendExceedsCap() public {
        bytes memory terms = abi.encode(DAILY_CAP, PERIOD);
        enforcer.afterHook(terms, "", DM, DH, D, R, T, 0.6 ether, "");
        vm.expectRevert(
            abi.encodeWithSelector(SpendingCapEnforcer.SpendingCapExceeded.selector, 1.1 ether, 0.4 ether)
        );
        enforcer.beforeHook(terms, "", DM, DH, D, R, T, 0.5 ether, "");
    }

    function test_capResetsAfterPeriod() public {
        bytes memory terms = abi.encode(DAILY_CAP, PERIOD);
        enforcer.afterHook(terms, "", DM, DH, D, R, T, DAILY_CAP, "");
        vm.expectRevert();
        enforcer.beforeHook(terms, "", DM, DH, D, R, T, 0.1 ether, "");
        vm.warp(86_400 * 2);
        enforcer.beforeHook(terms, "", DM, DH, D, R, T, 0.5 ether, "");
    }

    function test_zeroValueAlwaysPasses() public view {
        bytes memory terms = abi.encode(DAILY_CAP, PERIOD);
        enforcer.beforeHook(terms, "", DM, DH, D, R, T, 0, "");
    }
}
