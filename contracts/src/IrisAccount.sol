// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC7710Delegator} from "./interfaces/IERC7710.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/// @title IrisAccount
/// @notice A minimal ERC-4337 smart account that implements IERC7710Delegator for onchain delegation.
/// @dev Supports owner-based execution, ERC-4337 UserOp validation, and delegation management.
contract IrisAccount is IERC7710Delegator {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @notice The owner of this smart account.
    address public owner;

    /// @notice The authorized delegation manager contract.
    address public delegationManager;

    /// @notice Mapping from delegation hash to whether it has been revoked.
    mapping(bytes32 => bool) public revokedDelegations;

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when the delegation manager is updated.
    /// @param oldManager The previous delegation manager address.
    /// @param newManager The new delegation manager address.
    event DelegationManagerSet(address indexed oldManager, address indexed newManager);

    /// @notice Emitted when a delegation is revoked.
    /// @param delegationHash The hash of the revoked delegation.
    event DelegationRevoked(bytes32 indexed delegationHash);

    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    error OnlyOwner();
    error OnlyOwnerOrDelegationManager();
    error ExecutionFailed();
    error InvalidSignatureLength();

    // -------------------------------------------------------------------------
    // Modifiers
    // -------------------------------------------------------------------------

    /// @dev Restricts access to the account owner.
    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    /// @dev Restricts access to the owner or the authorized delegation manager.
    modifier onlyOwnerOrDelegationManager() {
        if (msg.sender != owner && msg.sender != delegationManager) {
            revert OnlyOwnerOrDelegationManager();
        }
        _;
    }

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /// @notice Initializes the account with an owner and delegation manager.
    /// @param _owner The owner address of this account.
    /// @param _delegationManager The authorized delegation manager address.
    constructor(address _owner, address _delegationManager) {
        owner = _owner;
        delegationManager = _delegationManager;
    }

    // -------------------------------------------------------------------------
    // External — Execution
    // -------------------------------------------------------------------------

    /// @notice Executes a single call from this account.
    /// @dev Only callable by the owner or the authorized delegation manager.
    /// @param target The target contract address.
    /// @param value The ETH value to send.
    /// @param data The calldata to execute.
    /// @return result The return data from the call.
    function execute(address target, uint256 value, bytes calldata data)
        external
        onlyOwnerOrDelegationManager
        returns (bytes memory result)
    {
        bool success;
        (success, result) = target.call{value: value}(data);
        if (!success) revert ExecutionFailed();
    }

    /// @notice Executes a batch of calls from this account.
    /// @dev Only callable by the owner or the authorized delegation manager.
    /// @param targets The target contract addresses.
    /// @param values The ETH values to send with each call.
    /// @param calldatas The calldata for each call.
    /// @return results The return data from each call.
    function executeBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata calldatas)
        external
        onlyOwnerOrDelegationManager
        returns (bytes[] memory results)
    {
        require(targets.length == values.length && values.length == calldatas.length, "Length mismatch");
        results = new bytes[](targets.length);
        for (uint256 i = 0; i < targets.length; i++) {
            bool success;
            (success, results[i]) = targets[i].call{value: values[i]}(calldatas[i]);
            if (!success) revert ExecutionFailed();
        }
    }

    // -------------------------------------------------------------------------
    // External — ERC-4337
    // -------------------------------------------------------------------------

    /// @notice Validates a UserOperation signature per ERC-4337.
    /// @dev Returns 0 for a valid signature, 1 for an invalid signature.
    /// @param userOp The packed UserOperation struct.
    /// @param userOpHash The hash of the UserOperation.
    /// @param missingAccountFunds The amount of funds missing for gas payment.
    /// @return validationData 0 if valid, 1 if invalid.
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        returns (uint256 validationData)
    {
        // Verify the signature is from the owner.
        bytes32 ethSignedHash = userOpHash.toEthSignedMessageHash();
        address signer = ECDSA.recover(ethSignedHash, userOp.signature);

        if (signer != owner) {
            return 1;
        }

        // Pay the entrypoint if funds are missing.
        if (missingAccountFunds > 0) {
            (bool success,) = msg.sender.call{value: missingAccountFunds}("");
            (success); // Silence unused variable warning; entrypoint handles failure.
        }

        return 0;
    }

    // -------------------------------------------------------------------------
    // External — Delegation (IERC7710Delegator)
    // -------------------------------------------------------------------------

    /// @notice Returns true if the delegation has not been revoked.
    /// @param delegationHash The hash of the delegation to check.
    /// @return True if the delegation is valid (not revoked).
    function isDelegationValid(bytes32 delegationHash) external view override returns (bool) {
        return !revokedDelegations[delegationHash];
    }

    /// @notice Revokes a delegation by its hash. Only callable by the owner.
    /// @param delegationHash The hash of the delegation to revoke.
    function revokeDelegation(bytes32 delegationHash) external override onlyOwner {
        revokedDelegations[delegationHash] = true;
        emit DelegationRevoked(delegationHash);
    }

    // -------------------------------------------------------------------------
    // External — Configuration
    // -------------------------------------------------------------------------

    /// @notice Sets the authorized delegation manager address. Only callable by the owner.
    /// @param _delegationManager The new delegation manager address.
    function setDelegationManager(address _delegationManager) external onlyOwner {
        address oldManager = delegationManager;
        delegationManager = _delegationManager;
        emit DelegationManagerSet(oldManager, _delegationManager);
    }

    // -------------------------------------------------------------------------
    // Receive
    // -------------------------------------------------------------------------

    /// @notice Allows the account to receive ETH.
    receive() external payable {}
}

/// @notice Packed UserOperation struct per ERC-4337 v0.7.
struct PackedUserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    bytes32 accountGasLimits;
    uint256 preVerificationGas;
    bytes32 gasFees;
    bytes paymasterAndData;
    bytes signature;
}
