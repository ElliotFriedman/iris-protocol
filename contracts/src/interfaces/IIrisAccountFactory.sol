// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IIrisAccountFactory
/// @notice Interface for the Iris Account factory.
interface IIrisAccountFactory {
    function createAccount(address owner, address delegationManager, uint256 salt) external returns (address account);
    function getAddress(address owner, address delegationManager, uint256 salt) external view returns (address);

    event AccountCreated(address indexed account, address indexed owner);
}
