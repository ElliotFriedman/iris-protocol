// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {SingleTxCapEnforcer} from "../../src/caveats/SingleTxCapEnforcer.sol";

contract SingleTxCapEnforcerTest is Test {
    SingleTxCapEnforcer enforcer;

    function setUp() public {
        enforcer = new SingleTxCapEnforcer();
    }

    function _terms(uint256 maxValue) internal pure returns (bytes memory) {
        return abi.encode(maxValue);
    }

    function _callBefore(bytes memory terms, uint256 value) internal view {
        enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), value, "");
    }

    // -----------------------------------------------------------------------
    // Tests
    // -----------------------------------------------------------------------

    function test_beforeHook_allowsBelowCap() public view {
        _callBefore(_terms(1 ether), 0.5 ether);
    }

    function test_beforeHook_allowsExactCap() public view {
        _callBefore(_terms(1 ether), 1 ether);
    }

    function test_beforeHook_revertsAboveCap() public {
        vm.expectRevert(
            abi.encodeWithSelector(SingleTxCapEnforcer.SingleTxCapExceeded.selector, 1.5 ether, 1 ether)
        );
        _callBefore(_terms(1 ether), 1.5 ether);
    }

    function test_beforeHook_allowsZeroValue() public view {
        _callBefore(_terms(1 ether), 0);
    }

    function test_beforeHook_zeroCapRevertsForAnyPositiveValue() public {
        vm.expectRevert(
            abi.encodeWithSelector(SingleTxCapEnforcer.SingleTxCapExceeded.selector, 1, 0)
        );
        _callBefore(_terms(0), 1);
    }

    function test_afterHook_isNoop() public {
        SingleTxCapEnforcer e = new SingleTxCapEnforcer();
        e.afterHook("", "", address(0), bytes32(0), address(0), address(0), address(0), 0, "");
    }
}
