// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ISafe} from "../interfaces/ISafe.sol";
import {Delegation, Action, Caveat} from "../interfaces/IERC7710.sol";
import {ICaveatEnforcer} from "../interfaces/ICaveatEnforcer.sol";

/// @title IrisSafeModule
/// @notice A Gnosis Safe module that validates delegation caveats and executes actions through a Safe.
/// @dev The module performs its own caveat enforcement (beforeHook / afterHook) and then routes
///      execution through Safe.execTransactionFromModule. The Safe must enable this module via enableModule().
contract IrisSafeModule {
    // -------------------------------------------------------------------------
    // Types
    // -------------------------------------------------------------------------

    /// @dev Internal struct to bundle hook-call parameters and avoid stack-too-deep.
    struct HookContext {
        bytes32 delegationHash;
        address delegator;
        address redeemer;
        address manager;
        address target;
        uint256 value;
    }

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @notice The address authorised to act as the delegation manager.
    address public immutable delegationManager;

    /// @notice The owner of this module (typically the Safe itself).
    address public owner;

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when a delegated action is executed through a Safe.
    /// @param safe The Safe that executed the transaction.
    /// @param agent The agent (msg.sender) that triggered execution.
    /// @param target The target contract of the executed action.
    /// @param value The ETH value forwarded in the execution.
    event ExecutedViaSafe(address indexed safe, address indexed agent, address target, uint256 value);

    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    error NotOwner();
    error SafeExecutionFailed();
    error ModuleNotEnabled(address safe);
    error EmptyDelegationChain();
    error HookFailed(address enforcer);

    // -------------------------------------------------------------------------
    // Modifiers
    // -------------------------------------------------------------------------

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /// @param _delegationManager The authorised delegation manager address.
    /// @param _owner The owner of this module (typically the Safe address).
    constructor(address _delegationManager, address _owner) {
        delegationManager = _delegationManager;
        owner = _owner;
    }

    // -------------------------------------------------------------------------
    // External — Execution
    // -------------------------------------------------------------------------

    /// @notice Validates all caveats in the leaf delegation and executes the action through the Safe.
    /// @dev Calls beforeHook on every caveat, executes via Safe.execTransactionFromModule,
    ///      then calls afterHook on every caveat.
    /// @param safe The Gnosis Safe to execute through (must have this module enabled).
    /// @param delegations The delegation chain (leaf first). Only the leaf delegation's caveats are enforced.
    /// @param action The action to execute (target, value, callData).
    function redeemDelegationViaSafe(
        address safe,
        Delegation[] calldata delegations,
        Action calldata action
    ) external {
        if (delegations.length == 0) revert EmptyDelegationChain();

        if (!ISafe(safe).isModuleEnabled(address(this))) {
            revert ModuleNotEnabled(safe);
        }

        Delegation calldata leafDelegation = delegations[0];

        HookContext memory ctx = HookContext({
            delegationHash: keccak256(abi.encode(leafDelegation)),
            delegator: delegations[delegations.length - 1].delegator,
            redeemer: msg.sender,
            manager: delegationManager,
            target: action.target,
            value: action.value
        });

        bytes calldata actionCallData = action.callData;

        // --- beforeHook on all caveats ---
        _runHooks(leafDelegation.caveats, ctx, actionCallData, true);

        // --- Execute through Safe ---
        {
            bool success = ISafe(safe).execTransactionFromModule(ctx.target, ctx.value, actionCallData, 0);
            if (!success) revert SafeExecutionFailed();
        }

        // --- afterHook on all caveats ---
        _runHooks(leafDelegation.caveats, ctx, actionCallData, false);

        emit ExecutedViaSafe(safe, msg.sender, ctx.target, ctx.value);
    }

    // -------------------------------------------------------------------------
    // External — Administration
    // -------------------------------------------------------------------------

    /// @notice Transfers ownership of this module to a new address.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    // -------------------------------------------------------------------------
    // Internal
    // -------------------------------------------------------------------------

    /// @dev Calls beforeHook or afterHook on every caveat enforcer using a bundled context struct.
    function _runHooks(
        Caveat[] calldata caveats,
        HookContext memory ctx,
        bytes calldata callData_,
        bool isBefore
    ) internal {
        bytes4 sel = isBefore
            ? ICaveatEnforcer.beforeHook.selector
            : ICaveatEnforcer.afterHook.selector;

        for (uint256 i = 0; i < caveats.length; i++) {
            bytes memory payload = abi.encodeWithSelector(
                sel,
                caveats[i].terms,
                "",
                ctx.manager,
                ctx.delegationHash,
                ctx.delegator,
                ctx.redeemer,
                ctx.target,
                ctx.value,
                callData_
            );
            (bool ok,) = caveats[i].enforcer.call(payload);
            if (!ok) revert HookFailed(caveats[i].enforcer);
        }
    }
}
