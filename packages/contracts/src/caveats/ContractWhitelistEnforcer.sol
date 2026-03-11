// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICaveatEnforcer} from "../interfaces/ICaveatEnforcer.sol";

/// @title ContractWhitelistEnforcer
/// @notice Enforces that delegated executions may only target whitelisted contracts.
contract ContractWhitelistEnforcer is ICaveatEnforcer {
    /// @notice Emitted when the target contract is not in the whitelist.
    /// @param target The disallowed target address.
    error ContractNotWhitelisted(address target);

    /// @notice Called before execution to verify the target is whitelisted.
    /// @param terms ABI-encoded address[] of allowed target contracts.
    /// @param target The target contract of the execution.
    function beforeHook(
        bytes calldata terms,
        bytes calldata,
        address,
        bytes32,
        address,
        address,
        address target,
        uint256,
        bytes calldata
    ) external pure override {
        address[] memory allowed = abi.decode(terms, (address[]));
        uint256 length = allowed.length;
        for (uint256 i; i < length;) {
            if (allowed[i] == target) {
                return;
            }
            unchecked { ++i; }
        }
        revert ContractNotWhitelisted(target);
    }

    /// @notice Called after execution. No-op for this enforcer.
    function afterHook(
        bytes calldata,
        bytes calldata,
        address,
        bytes32,
        address,
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override {}
}
