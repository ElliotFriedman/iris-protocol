// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {SpendingCapEnforcer} from "../../src/caveats/SpendingCapEnforcer.sol";

contract SpendingCapEnforcerTest is Test {
    SpendingCapEnforcer enforcer;
    bytes32 delegationHash;
    address dm;
    address delegator;
    address redeemer;
    address target;

    function setUp() public {
        enforcer = new SpendingCapEnforcer();
        delegationHash = keccak256("delegation");
        dm = makeAddr("dm");
        delegator = makeAddr("delegator");
        redeemer = makeAddr("redeemer");
        target = makeAddr("target");
    }

    function _terms(uint256 allowance, uint256 period) internal pure returns (bytes memory) {
        return abi.encode(allowance, period);
    }

    function _callBefore(bytes memory terms, uint256 value) internal view {
        enforcer.beforeHook(terms, "", dm, delegationHash, delegator, redeemer, target, value, "");
    }

    function _callAfter(bytes memory terms, uint256 value) internal {
        enforcer.afterHook(terms, "", dm, delegationHash, delegator, redeemer, target, value, "");
    }

    // -----------------------------------------------------------------------
    // Tests
    // -----------------------------------------------------------------------

    function test_beforeHook_allowsWithinCap() public view {
        _callBefore(_terms(1 ether, 3600), 0.5 ether);
    }

    function test_beforeHook_revertsWhenExceedsCap() public {
        bytes memory terms = _terms(1 ether, 3600);

        // Record spend in afterHook
        _callAfter(terms, 0.8 ether);

        // Now beforeHook should revert for 0.3 ether (0.8+0.3 = 1.1 > 1.0)
        vm.expectRevert(
            abi.encodeWithSelector(SpendingCapEnforcer.SpendingCapExceeded.selector, 1.1 ether, 0.2 ether)
        );
        _callBefore(terms, 0.3 ether);
    }

    function test_afterHook_tracksCumulativeSpend() public {
        bytes memory terms = _terms(1 ether, 3600);

        _callAfter(terms, 0.3 ether);
        _callAfter(terms, 0.2 ether);

        uint256 periodIndex = block.timestamp / 3600;
        assertEq(enforcer.periodSpend(delegationHash, periodIndex), 0.5 ether);
    }

    function test_periodReset_allowsSpendInNewPeriod() public {
        bytes memory terms = _terms(1 ether, 3600);

        // Spend full cap
        _callAfter(terms, 1 ether);

        // beforeHook should revert
        vm.expectRevert();
        _callBefore(terms, 0.1 ether);

        // Warp to next period
        vm.warp(block.timestamp + 3601);

        // Should succeed in the new period
        _callBefore(terms, 0.5 ether);
    }

    function test_beforeHook_allowsExactCap() public {
        bytes memory terms = _terms(1 ether, 3600);
        _callBefore(terms, 1 ether);
    }

    function test_separateDelegationHashes_trackIndependently() public {
        bytes memory terms = _terms(1 ether, 3600);
        bytes32 hash2 = keccak256("other");

        _callAfter(terms, 0.9 ether);

        // Different delegation hash should not be affected
        enforcer.afterHook(terms, "", dm, hash2, delegator, redeemer, target, 0.5 ether, "");

        // Original should still be near cap
        vm.expectRevert();
        _callBefore(terms, 0.2 ether);

        // Other hash should have independent tracking
        enforcer.beforeHook(terms, "", dm, hash2, delegator, redeemer, target, 0.4 ether, "");
    }
}
