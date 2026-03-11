// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICaveatEnforcer} from "../interfaces/ICaveatEnforcer.sol";

/// @title SingleTxCapEnforcer
/// @notice Enforces a maximum ETH value per individual delegated transaction.
contract SingleTxCapEnforcer is ICaveatEnforcer {
    /// @notice Emitted when the transaction value exceeds the per-transaction cap.
    /// @param value The attempted transaction value.
    /// @param maxValue The maximum allowed value per transaction.
    error SingleTxCapExceeded(uint256 value, uint256 maxValue);

    /// @notice Called before execution to verify the value does not exceed the cap.
    /// @param terms ABI-encoded uint256 maxValue.
    /// @param value The ETH value of the execution.
    function beforeHook(
        bytes calldata terms,
        bytes calldata,
        address,
        bytes32,
        address,
        address,
        address,
        uint256 value,
        bytes calldata
    ) external pure override {
        uint256 maxValue = abi.decode(terms, (uint256));
        if (value > maxValue) {
            revert SingleTxCapExceeded(value, maxValue);
        }
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
