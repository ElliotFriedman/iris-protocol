// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICaveatEnforcer} from "../interfaces/ICaveatEnforcer.sol";

/// @title FunctionSelectorEnforcer
/// @notice Enforces that delegated executions may only invoke whitelisted function selectors.
contract FunctionSelectorEnforcer is ICaveatEnforcer {
    /// @notice Emitted when the calldata's function selector is not in the allowed list.
    /// @param selector The disallowed function selector.
    error SelectorNotAllowed(bytes4 selector);

    /// @notice Called before execution to verify the function selector is allowed.
    /// @param terms ABI-encoded bytes4[] of allowed function selectors.
    /// @param callData The calldata of the execution whose first 4 bytes are the selector.
    function beforeHook(
        bytes calldata terms,
        bytes calldata,
        address,
        bytes32,
        address,
        address,
        address,
        uint256,
        bytes calldata callData
    ) external pure override {
        bytes4 selector = bytes4(callData[:4]);
        bytes4[] memory allowed = abi.decode(terms, (bytes4[]));
        uint256 length = allowed.length;
        for (uint256 i; i < length;) {
            if (allowed[i] == selector) {
                return;
            }
            unchecked { ++i; }
        }
        revert SelectorNotAllowed(selector);
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
