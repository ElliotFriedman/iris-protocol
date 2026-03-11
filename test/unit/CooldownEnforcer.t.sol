// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {CooldownEnforcer} from "../../src/caveats/CooldownEnforcer.sol";

contract CooldownEnforcerTest is Test {
    CooldownEnforcer enforcer;
    bytes32 delegationHash;

    function setUp() public {
        enforcer = new CooldownEnforcer();
        delegationHash = keccak256("delegation");
        vm.warp(10_000);
    }

    function _terms(uint256 cooldownPeriod, uint256 valueThreshold) internal pure returns (bytes memory) {
        return abi.encode(cooldownPeriod, valueThreshold);
    }

    function _callBefore(bytes memory terms, uint256 value) internal view {
        enforcer.beforeHook(terms, "", address(0), delegationHash, address(0), address(0), address(0), value, "");
    }

    function _callAfter(bytes memory terms, uint256 value) internal {
        enforcer.afterHook(terms, "", address(0), delegationHash, address(0), address(0), address(0), value, "");
    }

    // -----------------------------------------------------------------------
    // Tests
    // -----------------------------------------------------------------------

    function test_beforeHook_allowsFirstHighValueTx() public view {
        // No prior execution, should pass
        _callBefore(_terms(3600, 1 ether), 2 ether);
    }

    function test_beforeHook_allowsBelowThresholdWithoutCooldown() public {
        bytes memory terms = _terms(3600, 1 ether);

        // Execute a high-value tx
        _callAfter(terms, 2 ether);

        // Low-value tx should pass immediately (below threshold)
        _callBefore(terms, 0.5 ether);
    }

    function test_beforeHook_revertsHighValueDuringCooldown() public {
        bytes memory terms = _terms(3600, 1 ether);

        // Execute a high-value tx at t=10000
        _callAfter(terms, 2 ether);

        // Try another high-value tx at t=10000 (cooldown not elapsed)
        uint256 nextAllowed = block.timestamp + 3600;
        vm.expectRevert(
            abi.encodeWithSelector(CooldownEnforcer.CooldownNotElapsed.selector, nextAllowed, block.timestamp)
        );
        _callBefore(terms, 1 ether);
    }

    function test_beforeHook_allowsAfterCooldownElapsed() public {
        bytes memory terms = _terms(3600, 1 ether);

        _callAfter(terms, 2 ether);

        // Warp past cooldown
        vm.warp(block.timestamp + 3601);

        // Should pass
        _callBefore(terms, 2 ether);
    }

    function test_afterHook_recordsTimestampForHighValue() public {
        bytes memory terms = _terms(3600, 1 ether);

        _callAfter(terms, 1 ether);
        assertEq(enforcer.lastExecution(delegationHash), block.timestamp);
    }

    function test_afterHook_doesNotRecordForLowValue() public {
        bytes memory terms = _terms(3600, 1 ether);

        _callAfter(terms, 0.5 ether);
        assertEq(enforcer.lastExecution(delegationHash), 0);
    }
}
