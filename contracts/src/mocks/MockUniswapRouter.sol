// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {MockERC20} from "./MockERC20.sol";

/// @title MockUniswapRouter
/// @notice Simplified swap mock that mints output tokens 1:1 for testing.
contract MockUniswapRouter {
    event Swapped(
        address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut
    );

    /// @notice Swaps tokenIn for tokenOut at a 1:1 ratio.
    /// @dev Burns tokenIn from caller and mints tokenOut to caller.
    /// @param tokenIn The input token address.
    /// @param tokenOut The output token address.
    /// @param amountIn The amount of input tokens to swap.
    /// @return amountOut The amount of output tokens received (always == amountIn).
    function swap(address tokenIn, address tokenOut, uint256 amountIn) external payable returns (uint256 amountOut) {
        amountOut = amountIn;
        MockERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        MockERC20(tokenOut).mint(msg.sender, amountOut);
        emit Swapped(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }
}
