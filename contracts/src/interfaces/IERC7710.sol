// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IERC7710 — Delegation Interface
/// @notice Minimal interface for ERC-7710 smart contract delegation.
/// @dev Delegators sign offchain delegations; delegates redeem them onchain via the DelegationManager.

/// @notice A single caveat attached to a delegation.
struct Caveat {
    address enforcer; // The caveat enforcer contract
    bytes terms; // Encoded terms set by the delegator
}

/// @notice A delegation from a delegator to a delegate with optional caveats.
struct Delegation {
    address delegator; // The account granting authority
    address delegate; // The account receiving authority
    address authority; // Parent delegation hash (address(0) for root)
    Caveat[] caveats; // Array of caveats that must pass
    uint256 salt; // Unique salt for replay protection
    bytes signature; // EIP-712 signature from the delegator
}

/// @notice The action to execute via a delegation.
struct Action {
    address target; // Target contract
    uint256 value; // ETH value
    bytes callData; // Calldata to execute
}

interface IERC7710Delegator {
    /// @notice Returns true if the delegation is currently valid.
    function isDelegationValid(bytes32 delegationHash) external view returns (bool);

    /// @notice Revokes a delegation by its hash.
    function revokeDelegation(bytes32 delegationHash) external;
}

interface IERC7710Delegate {
    /// @notice Redeems a delegation chain to execute an action.
    function redeemDelegation(Delegation[] calldata delegations, Action calldata action) external;
}
