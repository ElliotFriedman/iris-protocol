// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title ISafe — Minimal Gnosis Safe interface for module integration.
interface ISafe {
    /// @notice Execute a transaction from an enabled module.
    /// @param to Target address.
    /// @param value ETH value.
    /// @param data Calldata.
    /// @param operation 0 = Call, 1 = DelegateCall.
    /// @return success True if the transaction succeeded.
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, uint8 operation)
        external
        returns (bool success);

    /// @notice Returns true if the given module is enabled.
    function isModuleEnabled(address module) external view returns (bool);
}
