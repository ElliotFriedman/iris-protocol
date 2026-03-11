// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IrisAccount} from "./IrisAccount.sol";

/// @title IrisAccountFactory
/// @notice Deploys IrisAccount instances via CREATE2 for deterministic addresses.
contract IrisAccountFactory {
    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when a new account is created.
    /// @param account The address of the newly created account.
    /// @param owner The owner of the newly created account.
    event AccountCreated(address indexed account, address indexed owner);

    // -------------------------------------------------------------------------
    // External
    // -------------------------------------------------------------------------

    /// @notice Deploys a new IrisAccount via CREATE2.
    /// @dev If the account already exists at the deterministic address, returns the existing address.
    /// @param owner The owner address for the new account.
    /// @param delegationManager The delegation manager address for the new account.
    /// @param salt The salt value for CREATE2 address derivation.
    /// @return account The address of the deployed (or existing) account.
    function createAccount(address owner, address delegationManager, uint256 salt)
        external
        returns (address account)
    {
        bytes32 combinedSalt = _combinedSalt(owner, delegationManager, salt);
        bytes memory bytecode = _creationCode(owner, delegationManager);

        // Check if the account already exists.
        account = getAddress(owner, delegationManager, salt);
        if (account.code.length > 0) {
            return account;
        }

        assembly {
            account := create2(0, add(bytecode, 0x20), mload(bytecode), combinedSalt)
        }
        require(account != address(0), "CREATE2 failed");

        emit AccountCreated(account, owner);
    }

    /// @notice Predicts the deterministic address for an IrisAccount deployment.
    /// @param owner The owner address for the account.
    /// @param delegationManager The delegation manager address for the account.
    /// @param salt The salt value for CREATE2 address derivation.
    /// @return predicted The predicted address of the account.
    function getAddress(address owner, address delegationManager, uint256 salt)
        public
        view
        returns (address predicted)
    {
        bytes32 combinedSalt = _combinedSalt(owner, delegationManager, salt);
        bytes memory bytecode = _creationCode(owner, delegationManager);
        bytes32 bytecodeHash = keccak256(bytecode);

        predicted = address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), combinedSalt, bytecodeHash))))
        );
    }

    // -------------------------------------------------------------------------
    // Internal
    // -------------------------------------------------------------------------

    /// @dev Computes a combined salt from the owner, delegation manager, and user-provided salt.
    function _combinedSalt(address owner, address delegationManager, uint256 salt)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(owner, delegationManager, salt));
    }

    /// @dev Returns the creation bytecode for an IrisAccount with the given constructor arguments.
    function _creationCode(address owner, address delegationManager) internal pure returns (bytes memory) {
        return abi.encodePacked(type(IrisAccount).creationCode, abi.encode(owner, delegationManager));
    }
}
