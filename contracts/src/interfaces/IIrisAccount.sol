// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IIrisAccount
/// @notice Interface for the Iris Protocol smart contract account.
interface IIrisAccount {
    /// @notice Returns the owner of this smart account.
    /// @return The owner address.
    function owner() external view returns (address);

    /// @notice Executes a single call from this account.
    /// @param target The target contract address.
    /// @param value The ETH value to send.
    /// @param data The calldata to execute.
    /// @return The return data from the call.
    function execute(address target, uint256 value, bytes calldata data) external payable returns (bytes memory);

    /// @notice Executes a batch of calls from this account.
    /// @param targets The target contract addresses.
    /// @param values The ETH values to send with each call.
    /// @param datas The calldata for each call.
    /// @return The return data from each call.
    function executeBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas)
        external
        payable
        returns (bytes[] memory);

    /// @notice Returns the authorized delegation manager contract address.
    /// @return The delegation manager address.
    function delegationManager() external view returns (address);

    /// @notice Returns whether a delegation is currently valid (not revoked).
    /// @param delegationHash The hash of the delegation to check.
    /// @return True if the delegation is valid.
    function isDelegationValid(bytes32 delegationHash) external view returns (bool);

    /// @notice Revokes a delegation by its hash.
    /// @param delegationHash The hash of the delegation to revoke.
    function revokeDelegation(bytes32 delegationHash) external;

    event DelegationManagerSet(address indexed oldManager, address indexed newManager);
    event DelegationRevoked(bytes32 indexed delegationHash);
}
