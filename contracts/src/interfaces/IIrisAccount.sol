// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IIrisAccount
/// @notice Interface for the Iris Protocol smart contract account.
interface IIrisAccount {
    function owner() external view returns (address);
    function execute(address target, uint256 value, bytes calldata data) external payable returns (bytes memory);
    function executeBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas)
        external
        payable
        returns (bytes[] memory);
    function delegationManager() external view returns (address);
    function isDelegationValid(bytes32 delegationHash) external view returns (bool);
    function revokeDelegation(bytes32 delegationHash) external;

    event DelegationManagerSet(address indexed oldManager, address indexed newManager);
    event DelegationRevoked(bytes32 indexed delegationHash);
}
