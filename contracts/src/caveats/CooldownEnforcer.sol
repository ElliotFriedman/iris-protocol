// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICaveatEnforcer} from "../interfaces/ICaveatEnforcer.sol";

/// @title CooldownEnforcer
/// @notice Enforces a cooldown period between high-value delegated executions.
/// @dev The cooldown only applies to transactions whose value meets or exceeds the threshold.
contract CooldownEnforcer is ICaveatEnforcer {
    /// @notice Emitted when execution is attempted before the cooldown has elapsed.
    /// @param nextAllowed The earliest timestamp at which execution is permitted.
    /// @param current The current block timestamp.
    error CooldownNotElapsed(uint256 nextAllowed, uint256 current);

    /// @notice Last execution timestamp per delegation hash.
    mapping(bytes32 => uint256) public lastExecution;

    /// @notice Called before execution to verify the cooldown period has elapsed.
    /// @param terms ABI-encoded (uint256 cooldownPeriod, uint256 valueThreshold).
    /// @param delegationHash The hash identifying the delegation.
    /// @param value The ETH value of the execution.
    function beforeHook(
        bytes calldata terms,
        bytes calldata,
        address,
        bytes32 delegationHash,
        address,
        address,
        address,
        uint256 value,
        bytes calldata
    ) external view override {
        (uint256 cooldownPeriod, uint256 valueThreshold) = abi.decode(terms, (uint256, uint256));
        if (value >= valueThreshold) {
            uint256 nextAllowed = lastExecution[delegationHash] + cooldownPeriod;
            if (block.timestamp < nextAllowed) {
                revert CooldownNotElapsed(nextAllowed, block.timestamp);
            }
        }
    }

    /// @notice Called after execution to record the timestamp if the value met the threshold.
    /// @param terms ABI-encoded (uint256 cooldownPeriod, uint256 valueThreshold).
    /// @param delegationHash The hash identifying the delegation.
    /// @param value The ETH value of the execution.
    function afterHook(
        bytes calldata terms,
        bytes calldata,
        address,
        bytes32 delegationHash,
        address,
        address,
        address,
        uint256 value,
        bytes calldata
    ) external override {
        (, uint256 valueThreshold) = abi.decode(terms, (uint256, uint256));
        if (value >= valueThreshold) {
            lastExecution[delegationHash] = block.timestamp;
        }
    }
}
