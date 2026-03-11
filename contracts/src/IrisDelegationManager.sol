// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Delegation, Action, Caveat, IERC7710Delegate} from "./interfaces/IERC7710.sol";
import {ICaveatEnforcer} from "./interfaces/ICaveatEnforcer.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title IrisDelegationManager
/// @notice Core delegation lifecycle manager for the Iris Protocol.
/// @dev Manages delegation creation, redemption, and revocation using EIP-712 typed data.
contract IrisDelegationManager is IERC7710Delegate, EIP712, ReentrancyGuard {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // -------------------------------------------------------------------------
    // Type hashes
    // -------------------------------------------------------------------------

    bytes32 public constant CAVEAT_TYPEHASH = keccak256("Caveat(address enforcer,bytes terms)");

    bytes32 public constant DELEGATION_TYPEHASH = keccak256(
        "Delegation(address delegator,address delegate,address authority,Caveat[] caveats,uint256 salt)"
        "Caveat(address enforcer,bytes terms)"
    );

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @notice Mapping from delegation hash to whether it has been revoked.
    mapping(bytes32 => bool) public revokedDelegations;

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when a delegation is successfully redeemed.
    /// @param delegationHash The hash of the redeemed delegation.
    /// @param delegator The delegator whose account was acted upon.
    /// @param delegate The delegate who redeemed the delegation.
    event DelegationRedeemed(bytes32 indexed delegationHash, address indexed delegator, address indexed delegate);

    /// @notice Emitted when a delegation is revoked by its delegator.
    /// @param delegationHash The hash of the revoked delegation.
    /// @param delegator The delegator who revoked the delegation.
    event DelegationRevoked(bytes32 indexed delegationHash, address indexed delegator);

    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    error EmptyDelegationChain();
    error DelegationIsRevoked(bytes32 delegationHash);
    error InvalidSignature();
    error InvalidDelegationChain();
    error NotDelegatorOrOwner();
    error ExecutionFailed();
    error ManagerNotAuthorized();

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    constructor() EIP712("IrisDelegationManager", "1") {}

    // -------------------------------------------------------------------------
    // External — Redemption
    // -------------------------------------------------------------------------

    /// @notice Redeems a delegation chain to execute an action on the delegator's account.
    /// @dev Iterates through all caveats calling beforeHook, executes the action, then calls afterHook on all caveats.
    /// @param delegations The delegation chain to redeem (leaf first, root last).
    /// @param action The action to execute on the delegator's account.
    function redeemDelegation(Delegation[] calldata delegations, Action calldata action)
        external
        override
        nonReentrant
    {
        if (delegations.length == 0) revert EmptyDelegationChain();

        // The root delegation is the last in the array.
        address delegator = delegations[delegations.length - 1].delegator;

        // Verify the delegation manager is authorized on the delegator's account.
        _verifyManagerAuthorized(delegator);

        // Validate the full chain and get all hashes.
        bytes32[] memory chainHashes = _validateChain(delegations);

        // The leaf delegation's delegate must be msg.sender.
        if (delegations[0].delegate != msg.sender) revert InvalidDelegationChain();

        // Call beforeHook on every caveat of EVERY delegation in the chain.
        for (uint256 i = 0; i < delegations.length; i++) {
            _executeCaveatHooks(delegations[i].caveats, chainHashes[i], delegator, action, true);
        }

        // Execute the action on the delegator's account.
        (bool success,) = delegator.call(
            abi.encodeWithSignature("execute(address,uint256,bytes)", action.target, action.value, action.callData)
        );
        if (!success) revert ExecutionFailed();

        // Call afterHook on every caveat of EVERY delegation in the chain (reverse order).
        for (uint256 i = delegations.length; i > 0;) {
            unchecked { --i; }
            _executeCaveatHooks(delegations[i].caveats, chainHashes[i], delegator, action, false);
        }

        emit DelegationRedeemed(chainHashes[0], delegator, msg.sender);
    }

    // -------------------------------------------------------------------------
    // External — Revocation
    // -------------------------------------------------------------------------

    /// @notice Revokes a delegation. Only callable by the delegator or the delegator's owner.
    /// @dev Accepts the full delegation struct to verify the caller is the delegator or its owner.
    /// @param delegation The delegation to revoke.
    function revokeDelegation(Delegation calldata delegation) external {
        bytes32 delegationHash = getDelegationHash(delegation);
        _verifyCallerIsDelegatorOrOwner(delegation.delegator);
        revokedDelegations[delegationHash] = true;
        emit DelegationRevoked(delegationHash, delegation.delegator);
    }

    // -------------------------------------------------------------------------
    // Public — Hashing
    // -------------------------------------------------------------------------

    /// @notice Computes the EIP-712 hash of a delegation struct.
    /// @param delegation The delegation to hash.
    /// @return The EIP-712 typed data hash.
    function getDelegationHash(Delegation calldata delegation) public view returns (bytes32) {
        bytes32[] memory caveatHashes = new bytes32[](delegation.caveats.length);
        for (uint256 i = 0; i < delegation.caveats.length; i++) {
            caveatHashes[i] = keccak256(
                abi.encode(CAVEAT_TYPEHASH, delegation.caveats[i].enforcer, keccak256(delegation.caveats[i].terms))
            );
        }

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegation.delegator,
                delegation.delegate,
                delegation.authority,
                keccak256(abi.encodePacked(caveatHashes)),
                delegation.salt
            )
        );

        return _hashTypedDataV4(structHash);
    }

    /// @notice Returns the EIP-712 domain separator used by this contract.
    /// @return The domain separator bytes32 value.
    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    // -------------------------------------------------------------------------
    // Internal
    // -------------------------------------------------------------------------

    /// @dev Validates the full delegation chain and returns all hashes (indexed same as delegations array).
    function _validateChain(Delegation[] calldata delegations) internal view returns (bytes32[] memory hashes) {
        hashes = new bytes32[](delegations.length);
        bytes32 lastHash = bytes32(0);
        for (uint256 i = delegations.length; i > 0;) {
            unchecked {
                --i;
            }
            Delegation calldata d = delegations[i];

            if (i == delegations.length - 1) {
                if (d.authority != address(0)) revert InvalidDelegationChain();
            } else {
                if (d.authority != address(uint160(uint256(lastHash)))) revert InvalidDelegationChain();
            }

            bytes32 dHash = getDelegationHash(d);
            if (revokedDelegations[dHash]) revert DelegationIsRevoked(dHash);

            _verifySignature(d, dHash);
            hashes[i] = dHash;
            lastHash = dHash;
        }
    }

    /// @dev Executes beforeHook or afterHook on all caveats.
    /// @param caveats The array of caveats to invoke.
    /// @param delegationHash The hash of the delegation being redeemed.
    /// @param delegator The delegator address.
    /// @param action The action being executed.
    /// @param isBefore True to call beforeHook, false for afterHook.
    function _executeCaveatHooks(
        Caveat[] calldata caveats,
        bytes32 delegationHash,
        address delegator,
        Action calldata action,
        bool isBefore
    ) internal {
        for (uint256 i = 0; i < caveats.length; i++) {
            if (isBefore) {
                ICaveatEnforcer(caveats[i].enforcer).beforeHook(
                    caveats[i].terms,
                    "",
                    address(this),
                    delegationHash,
                    delegator,
                    msg.sender,
                    action.target,
                    action.value,
                    action.callData
                );
            } else {
                ICaveatEnforcer(caveats[i].enforcer).afterHook(
                    caveats[i].terms,
                    "",
                    address(this),
                    delegationHash,
                    delegator,
                    msg.sender,
                    action.target,
                    action.value,
                    action.callData
                );
            }
        }
    }

    /// @dev Verifies that the delegation manager is authorized on the delegator account.
    function _verifyManagerAuthorized(address delegator) internal view {
        (bool success, bytes memory data) =
            delegator.staticcall(abi.encodeWithSignature("delegationManager()"));
        if (!success || data.length < 32) revert ManagerNotAuthorized();
        address manager = abi.decode(data, (address));
        if (manager != address(this)) revert ManagerNotAuthorized();
    }

    /// @dev Verifies that msg.sender is the delegator or the delegator's owner (for smart accounts).
    function _verifyCallerIsDelegatorOrOwner(address delegator) internal view {
        if (msg.sender == delegator) return;
        if (delegator.code.length > 0) {
            (bool success, bytes memory data) =
                delegator.staticcall(abi.encodeWithSignature("owner()"));
            if (success && data.length >= 32) {
                address accountOwner = abi.decode(data, (address));
                if (msg.sender == accountOwner) return;
            }
        }
        revert NotDelegatorOrOwner();
    }

    /// @dev Verifies the EIP-712 signature on a delegation.
    ///      For smart contract delegators, checks if the signer is the account owner.
    function _verifySignature(Delegation calldata delegation, bytes32 delegationHash) internal view {
        address signer = ECDSA.recover(delegationHash, delegation.signature);
        if (signer == delegation.delegator) return;

        // For smart contract accounts, check if signer is the owner
        if (delegation.delegator.code.length > 0) {
            (bool success, bytes memory data) =
                delegation.delegator.staticcall(abi.encodeWithSignature("owner()"));
            if (success && data.length >= 32) {
                address accountOwner = abi.decode(data, (address));
                if (signer == accountOwner) return;
            }
        }

        revert InvalidSignature();
    }
}
