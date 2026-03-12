// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IIrisAccountFactory
/// @notice Interface for the Iris Account factory.
interface IIrisAccountFactory {
    /// @notice Deploys a new IrisAccount via CREATE2.
    /// @param owner The owner address for the new account.
    /// @param delegationManager The delegation manager address for the new account.
    /// @param salt The salt value for CREATE2 address derivation.
    /// @return account The address of the deployed (or existing) account.
    function createAccount(address owner, address delegationManager, uint256 salt) external returns (address account);

    /// @notice Predicts the deterministic address for an IrisAccount deployment.
    /// @param owner The owner address for the account.
    /// @param delegationManager The delegation manager address for the account.
    /// @param salt The salt value for CREATE2 address derivation.
    /// @return The predicted address of the account.
    function getAddress(address owner, address delegationManager, uint256 salt) external view returns (address);

    event AccountCreated(address indexed account, address indexed owner);
}
