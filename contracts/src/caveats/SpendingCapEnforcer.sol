// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICaveatEnforcer} from "../interfaces/ICaveatEnforcer.sol";

/// @title SpendingCapEnforcer
/// @notice Enforces a cumulative spending cap per rolling period on delegated executions.
/// @dev The period resets based on block.timestamp divided by the period length.
contract SpendingCapEnforcer is ICaveatEnforcer {
    /// @notice Emitted when a spend would exceed the allowance for the current period.
    /// @param requested The total spend that was attempted (current + new).
    /// @param remaining The remaining allowance in the current period.
    error SpendingCapExceeded(uint256 requested, uint256 remaining);

    /// @notice Reverted when afterHook is called by an unauthorized address.
    error UnauthorizedCaller();

    /// @notice Reverted when the period is zero (would cause division by zero).
    error InvalidPeriod();

    /// @notice The authorized delegation manager that may update spend tracking.
    address public immutable delegationManager;

    /// @notice Cumulative spend per delegation per period index.
    /// @dev mapping(delegationHash => mapping(periodIndex => amountSpent))
    mapping(bytes32 => mapping(uint256 => uint256)) public periodSpend;

    constructor(address _delegationManager) {
        delegationManager = _delegationManager;
    }

    /// @notice Called before execution to verify the spend would not exceed the cap.
    /// @param terms ABI-encoded (uint256 allowance, uint256 period).
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
        (uint256 allowance, uint256 period) = abi.decode(terms, (uint256, uint256));
        if (period == 0) revert InvalidPeriod();
        uint256 periodIndex = block.timestamp / period;
        uint256 currentSpend = periodSpend[delegationHash][periodIndex];
        if (currentSpend + value > allowance) {
            revert SpendingCapExceeded(currentSpend + value, allowance - currentSpend);
        }
    }

    /// @notice Called after execution to record the spend for the current period.
    /// @param terms ABI-encoded (uint256 allowance, uint256 period).
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
        if (msg.sender != delegationManager) revert UnauthorizedCaller();
        (, uint256 period) = abi.decode(terms, (uint256, uint256));
        if (period == 0) revert InvalidPeriod();
        uint256 periodIndex = block.timestamp / period;
        periodSpend[delegationHash][periodIndex] += value;
    }
}
