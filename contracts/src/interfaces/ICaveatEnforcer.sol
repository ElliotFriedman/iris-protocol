// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title ICaveatEnforcer
/// @notice Interface for caveat enforcers that validate delegated executions.
/// @dev Enforcers are called before and after delegated execution to enforce constraints.
interface ICaveatEnforcer {
    /// @notice Called before the delegated execution.
    /// @param terms The encoded caveat terms set by the delegator.
    /// @param args Runtime arguments provided by the redeemer.
    /// @param delegationManager The delegation manager calling this enforcer.
    /// @param delegationHash The hash of the delegation being redeemed.
    /// @param delegator The address that created the delegation.
    /// @param redeemer The address redeeming the delegation.
    /// @param target The target contract of the execution.
    /// @param value The ETH value of the execution.
    /// @param callData The calldata of the execution.
    function beforeHook(
        bytes calldata terms,
        bytes calldata args,
        address delegationManager,
        bytes32 delegationHash,
        address delegator,
        address redeemer,
        address target,
        uint256 value,
        bytes calldata callData
    ) external;

    /// @notice Called after the delegated execution.
    /// @param terms The encoded caveat terms set by the delegator.
    /// @param args Runtime arguments provided by the redeemer.
    /// @param delegationManager The delegation manager calling this enforcer.
    /// @param delegationHash The hash of the delegation being redeemed.
    /// @param delegator The address that created the delegation.
    /// @param redeemer The address redeeming the delegation.
    /// @param target The target contract of the execution.
    /// @param value The ETH value of the execution.
    /// @param callData The calldata of the execution.
    function afterHook(
        bytes calldata terms,
        bytes calldata args,
        address delegationManager,
        bytes32 delegationHash,
        address delegator,
        address redeemer,
        address target,
        uint256 value,
        bytes calldata callData
    ) external;
}
