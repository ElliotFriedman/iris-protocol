// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisAccount} from "../../src/IrisAccount.sol";

/// @title IrisAccount — Formal Verification (Halmos)
/// @notice Symbolic tests proving account access control and delegation revocation invariants.
contract IrisAccountFV is Test {
    IrisAccount account;
    address constant OWNER = address(0xA1);
    address constant DM = address(0xD1);

    function setUp() public {
        account = new IrisAccount(OWNER, DM);
        vm.deal(address(account), 100 ether);
    }

    // =========================================================================
    // Invariant: execute() only callable by owner or delegationManager
    // =========================================================================

    /// @notice Proves: execute reverts for any caller that is not owner or delegationManager.
    function check_execute_accessControl(address caller) public {
        vm.assume(caller != OWNER);
        vm.assume(caller != DM);

        vm.prank(caller);
        try account.execute(address(0x1234), 0, "") {
            assert(false); // Must not succeed for unauthorized callers
        } catch {}
    }

    /// @notice Proves: execute succeeds for the owner (non-vacuous — owner CAN call).
    function check_execute_ownerSucceeds() public {
        vm.prank(OWNER);
        account.execute(address(this), 0, "");
    }

    /// @notice Proves: execute succeeds for the delegation manager.
    function check_execute_dmSucceeds() public {
        vm.prank(DM);
        account.execute(address(this), 0, "");
    }

    // =========================================================================
    // Invariant: delegation revocation is permanent and owner-only
    // =========================================================================

    /// @notice Proves: after revokeDelegation(hash), isDelegationValid returns false.
    function check_revocation_makesInvalid(bytes32 delegationHash) public {
        // Before revocation: valid
        assert(account.isDelegationValid(delegationHash) == true);

        vm.prank(OWNER);
        account.revokeDelegation(delegationHash);

        // After revocation: must be invalid
        assert(account.isDelegationValid(delegationHash) == false);
    }

    /// @notice Proves: non-owner cannot revoke delegations.
    function check_revocation_onlyOwner(address caller, bytes32 delegationHash) public {
        vm.assume(caller != OWNER);

        vm.prank(caller);
        try account.revokeDelegation(delegationHash) {
            assert(false); // Must not succeed
        } catch {}
    }

    /// @notice Proves: revocation is idempotent — revoking twice does not revert.
    function check_revocation_idempotent(bytes32 delegationHash) public {
        vm.prank(OWNER);
        account.revokeDelegation(delegationHash);
        assert(account.isDelegationValid(delegationHash) == false);

        vm.prank(OWNER);
        account.revokeDelegation(delegationHash);
        assert(account.isDelegationValid(delegationHash) == false);
    }

    // =========================================================================
    // Invariant: setDelegationManager only callable by owner
    // =========================================================================

    /// @notice Proves: non-owner cannot change delegation manager.
    function check_setDM_onlyOwner(address caller, address newDM) public {
        vm.assume(caller != OWNER);

        vm.prank(caller);
        try account.setDelegationManager(newDM) {
            assert(false);
        } catch {}
    }

    // =========================================================================
    // Invariant: revocation is isolated across hashes (cross-hash monotonicity)
    // =========================================================================

    /// @notice Proves: revoking one hash does not affect the validity of another hash.
    function check_revocation_crossHashIsolation(bytes32 hash1, bytes32 hash2) public {
        vm.assume(hash1 != hash2);

        // Revoke hash1
        vm.prank(OWNER);
        account.revokeDelegation(hash1);
        assert(account.isDelegationValid(hash1) == false);
        assert(account.isDelegationValid(hash2) == true); // hash2 unaffected

        // Revoke hash2
        vm.prank(OWNER);
        account.revokeDelegation(hash2);
        assert(account.isDelegationValid(hash1) == false); // hash1 still revoked
        assert(account.isDelegationValid(hash2) == false);
    }

    // =========================================================================
    // Non-vacuity: prove the contract actually works (not trivially reverting)
    // =========================================================================

    /// @notice Proves: a fresh delegation hash is valid (not revoked).
    function check_nonVacuous_freshDelegationIsValid(bytes32 delegationHash) public view {
        assert(account.isDelegationValid(delegationHash) == true);
    }

    // Helper to receive ETH for execute() calls targeting this contract
    receive() external payable {}
}
