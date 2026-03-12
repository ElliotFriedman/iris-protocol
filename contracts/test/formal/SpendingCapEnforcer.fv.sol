// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {SpendingCapEnforcer} from "../../src/caveats/SpendingCapEnforcer.sol";

/// @title SpendingCapEnforcer — Formal Verification (Halmos)
/// @notice Symbolic tests proving spending cap invariants hold for ALL possible inputs.
contract SpendingCapEnforcerFV is Test {
    SpendingCapEnforcer enforcer;
    address constant DM = address(0xD1);

    function setUp() public {
        enforcer = new SpendingCapEnforcer(DM);
    }

    // =========================================================================
    // Invariant 1: beforeHook MUST revert if cumulative spend + value > allowance
    // =========================================================================

    /// @notice Proves: if beforeHook succeeds, then currentSpend + value <= allowance.
    /// Halmos explores all symbolic values for allowance, period, value, and delegationHash.
    function check_beforeHook_cannotExceedCap(
        uint256 allowance,
        uint256 period,
        uint256 value,
        bytes32 delegationHash
    ) public view {
        // Precondition: period must be nonzero (enforcer rejects period=0)
        vm.assume(period > 0);
        // Precondition: avoid overflow in currentSpend + value
        uint256 periodIndex = block.timestamp / period;
        uint256 currentSpend = enforcer.periodSpend(delegationHash, periodIndex);
        vm.assume(currentSpend + value >= currentSpend); // no overflow

        bytes memory terms = abi.encode(allowance, period);
        // If beforeHook does not revert, then the invariant must hold:
        try enforcer.beforeHook(terms, "", address(0), delegationHash, address(0), address(0), address(0), value, "") {
            // If we reach here, the call succeeded — assert the invariant
            assert(currentSpend + value <= allowance);
        } catch {
            // Revert is acceptable — enforcer rejected the spend
        }
    }

    /// @notice Proves: beforeHook MUST revert when cumulative spend + value > allowance.
    function check_beforeHook_revertsWhenOverCap(
        uint256 allowance,
        uint256 period,
        uint256 value,
        bytes32 delegationHash
    ) public view {
        vm.assume(period > 0);
        uint256 periodIndex = block.timestamp / period;
        uint256 currentSpend = enforcer.periodSpend(delegationHash, periodIndex);
        vm.assume(currentSpend + value >= currentSpend); // no overflow
        vm.assume(currentSpend + value > allowance); // precondition: over cap

        bytes memory terms = abi.encode(allowance, period);
        try enforcer.beforeHook(terms, "", address(0), delegationHash, address(0), address(0), address(0), value, "") {
            // If we reach here without reverting, the invariant is violated
            assert(false);
        } catch {
            // Expected: must revert when over cap
        }
    }

    // =========================================================================
    // Invariant 1b: beforeHook enforces cap WITH non-zero prior spend
    // =========================================================================

    /// @notice Proves: after accumulating `priorSpend` via afterHook, beforeHook still
    ///         correctly enforces the cap. Addresses the vacuity concern that tests on a
    ///         fresh contract only verify currentSpend=0.
    function check_beforeHook_withPriorSpend(
        uint256 allowance,
        uint256 period,
        uint256 priorSpend,
        uint256 newValue,
        bytes32 delegationHash
    ) public {
        vm.assume(period > 0);
        vm.assume(allowance > 0);
        vm.assume(priorSpend <= allowance); // prior spend was valid
        vm.assume(priorSpend + newValue >= priorSpend); // no overflow

        bytes memory terms = abi.encode(allowance, period);

        // Accumulate prior spend via afterHook (as the delegation manager would)
        vm.prank(DM);
        enforcer.afterHook(terms, "", address(0), delegationHash, address(0), address(0), address(0), priorSpend, "");

        // Now check beforeHook with the accumulated state
        try enforcer.beforeHook(terms, "", address(0), delegationHash, address(0), address(0), address(0), newValue, "") {
            // Succeeded: priorSpend + newValue must be <= allowance
            assert(priorSpend + newValue <= allowance);
        } catch {
            // Reverted: priorSpend + newValue must be > allowance
            assert(priorSpend + newValue > allowance);
        }
    }

    // =========================================================================
    // Invariant 2: afterHook MUST only be callable by delegationManager
    // =========================================================================

    /// @notice Proves: afterHook reverts for any caller != delegationManager.
    function check_afterHook_onlyDelegationManager(
        address caller,
        uint256 allowance,
        uint256 period,
        uint256 value,
        bytes32 delegationHash
    ) public {
        vm.assume(caller != DM);
        vm.assume(period > 0);

        bytes memory terms = abi.encode(allowance, period);
        vm.prank(caller);
        try enforcer.afterHook(terms, "", address(0), delegationHash, address(0), address(0), address(0), value, "") {
            assert(false); // Must not succeed for non-DM callers
        } catch {
            // Expected
        }
    }

    // =========================================================================
    // Invariant 3: afterHook correctly accumulates spend
    // =========================================================================

    /// @notice Proves: after a successful afterHook, periodSpend increases by exactly `value`.
    function check_afterHook_accumulatesCorrectly(
        uint256 allowance,
        uint256 period,
        uint256 value,
        bytes32 delegationHash
    ) public {
        vm.assume(period > 0);
        uint256 periodIndex = block.timestamp / period;
        uint256 spendBefore = enforcer.periodSpend(delegationHash, periodIndex);
        vm.assume(spendBefore + value >= spendBefore); // no overflow

        bytes memory terms = abi.encode(allowance, period);
        vm.prank(DM);
        enforcer.afterHook(terms, "", address(0), delegationHash, address(0), address(0), address(0), value, "");

        uint256 spendAfter = enforcer.periodSpend(delegationHash, periodIndex);
        assert(spendAfter == spendBefore + value);
    }

    // =========================================================================
    // Invariant 4: period=0 always reverts (division by zero guard)
    // =========================================================================

    /// @notice Proves: period=0 in terms always causes beforeHook to revert.
    function check_zeroPeriod_alwaysReverts(
        uint256 allowance,
        uint256 value,
        bytes32 delegationHash
    ) public view {
        bytes memory terms = abi.encode(allowance, uint256(0));
        try enforcer.beforeHook(terms, "", address(0), delegationHash, address(0), address(0), address(0), value, "") {
            assert(false); // Must not succeed with period=0
        } catch {
            // Expected: InvalidPeriod
        }
    }

    // =========================================================================
    // Invariant 5: Period boundary reset — spending does not carry over
    // =========================================================================

    /// @notice Proves: spending in one period does not carry over to the next period.
    /// After spending the full allowance in period N, a new period N+1 starts fresh.
    function check_periodReset_newPeriodStartsFresh(
        bytes32 delegationHash
    ) public {
        // Use concrete values; the property is architectural (mapping keyed by periodIndex)
        uint256 allowance = 1000;
        uint256 period = 3600; // 1 hour

        // Warp to a clean period boundary (period * 10 = 36000)
        uint256 t1 = period * 10;
        vm.warp(t1);

        bytes memory terms = abi.encode(allowance, period);
        uint256 currentPeriodIndex = t1 / period; // = 10

        // Spend the full allowance in current period via afterHook
        vm.prank(DM);
        enforcer.afterHook(terms, "", address(0), delegationHash, address(0), address(0), address(0), allowance, "");

        // Verify current period is maxed out
        assert(enforcer.periodSpend(delegationHash, currentPeriodIndex) == allowance);

        // Warp to next period (period * 11 = 39600)
        uint256 t2 = t1 + period;
        vm.warp(t2);
        uint256 newPeriodIndex = t2 / period; // = 11

        // New period should have zero spend
        assert(enforcer.periodSpend(delegationHash, newPeriodIndex) == 0);

        // beforeHook should succeed in the new period (spend is fresh)
        enforcer.beforeHook(terms, "", address(0), delegationHash, address(0), address(0), address(0), 1, "");
    }

    // =========================================================================
    // Invariant 6: Per-delegationHash independence
    // =========================================================================

    /// @notice Proves: spending under one delegation hash does not affect another.
    function check_hashIndependence(
        uint256 allowance,
        uint256 period,
        bytes32 hashA,
        bytes32 hashB,
        uint256 spendAmount
    ) public {
        vm.assume(period > 0);
        vm.assume(allowance > 0);
        vm.assume(hashA != hashB);
        vm.assume(spendAmount <= allowance);

        bytes memory terms = abi.encode(allowance, period);

        // Spend under hashA
        vm.prank(DM);
        enforcer.afterHook(terms, "", address(0), hashA, address(0), address(0), address(0), spendAmount, "");

        // hashB should be unaffected
        uint256 periodIndex = block.timestamp / period;
        assert(enforcer.periodSpend(hashB, periodIndex) == 0);

        // hashB can still spend up to the full allowance
        enforcer.beforeHook(terms, "", address(0), hashB, address(0), address(0), address(0), allowance, "");
    }

    // =========================================================================
    // Invariant 7: Overflow protection
    // =========================================================================

    /// @notice Proves: if currentSpend + value would overflow, beforeHook correctly reverts
    /// rather than wrapping around and allowing the spend.
    function check_overflowProtection(
        uint256 allowance,
        uint256 period,
        bytes32 delegationHash
    ) public {
        vm.assume(period > 0);
        vm.assume(allowance > 0);

        bytes memory terms = abi.encode(allowance, period);

        // Record a large prior spend (close to max uint256)
        uint256 bigSpend = type(uint256).max - 100;
        vm.prank(DM);
        enforcer.afterHook(terms, "", address(0), delegationHash, address(0), address(0), address(0), bigSpend, "");

        // Trying to spend 200 more should revert (overflow or exceeds cap)
        try enforcer.beforeHook(terms, "", address(0), delegationHash, address(0), address(0), address(0), 200, "") {
            assert(false); // Must revert — either overflow or exceeds cap
        } catch {}
    }
}
