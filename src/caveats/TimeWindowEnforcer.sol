// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICaveatEnforcer} from "../interfaces/ICaveatEnforcer.sol";

/// @title TimeWindowEnforcer
/// @notice Enforces that delegated executions may only occur within a specified time window.
contract TimeWindowEnforcer is ICaveatEnforcer {
    /// @notice Emitted when execution is attempted outside the allowed time window.
    /// @param current The current block timestamp.
    /// @param notBefore The earliest allowed timestamp.
    /// @param notAfter The latest allowed timestamp.
    error OutsideTimeWindow(uint256 current, uint256 notBefore, uint256 notAfter);

    /// @notice Called before execution to verify the current time is within bounds.
    /// @param terms ABI-encoded (uint256 notBefore, uint256 notAfter).
    function beforeHook(
        bytes calldata terms,
        bytes calldata,
        address,
        bytes32,
        address,
        address,
        address,
        uint256,
        bytes calldata
    ) external view override {
        (uint256 notBefore, uint256 notAfter) = abi.decode(terms, (uint256, uint256));
        if (block.timestamp < notBefore || block.timestamp > notAfter) {
            revert OutsideTimeWindow(block.timestamp, notBefore, notAfter);
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
