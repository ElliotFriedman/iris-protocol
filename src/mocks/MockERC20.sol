// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title MockERC20
/// @notice Simple ERC-20 token with a public mint function for testing.
contract MockERC20 is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    /// @notice Mints tokens to any address. No access control (for testing).
    /// @param to The recipient address.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
