// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {TimeWindowEnforcer} from "../../src/caveats/TimeWindowEnforcer.sol";

contract TimeWindowEnforcerTest is Test {
    TimeWindowEnforcer enforcer;

    function setUp() public {
        enforcer = new TimeWindowEnforcer();
    }

    function _terms(uint256 notBefore, uint256 notAfter) internal pure returns (bytes memory) {
        return abi.encode(notBefore, notAfter);
    }

    function _callBefore(bytes memory terms) internal view {
        enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), 0, "");
    }

    // -----------------------------------------------------------------------
    // Tests
    // -----------------------------------------------------------------------

    function test_beforeHook_allowsWithinWindow() public {
        vm.warp(1000);
        _callBefore(_terms(500, 1500));
    }

    function test_beforeHook_allowsAtExactNotBefore() public {
        vm.warp(500);
        _callBefore(_terms(500, 1500));
    }

    function test_beforeHook_allowsAtExactNotAfter() public {
        vm.warp(1500);
        _callBefore(_terms(500, 1500));
    }

    function test_beforeHook_revertsBeforeWindow() public {
        vm.warp(499);
        vm.expectRevert(
            abi.encodeWithSelector(TimeWindowEnforcer.OutsideTimeWindow.selector, 499, 500, 1500)
        );
        _callBefore(_terms(500, 1500));
    }

    function test_beforeHook_revertsAfterWindow() public {
        vm.warp(1501);
        vm.expectRevert(
            abi.encodeWithSelector(TimeWindowEnforcer.OutsideTimeWindow.selector, 1501, 500, 1500)
        );
        _callBefore(_terms(500, 1500));
    }

    function test_afterHook_isNoop() public {
        TimeWindowEnforcer e = new TimeWindowEnforcer();
        e.afterHook("", "", address(0), bytes32(0), address(0), address(0), address(0), 0, "");
    }
}
