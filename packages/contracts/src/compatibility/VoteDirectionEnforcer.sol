// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICaveatEnforcer} from "../interfaces/ICaveatEnforcer.sol";

/// @title VoteDirectionEnforcer
/// @notice Restricts the vote direction an agent may cast in governance proposals.
/// @dev Terms encode an array of allowed vote values (0 = Against, 1 = For, 2 = Abstain per Governor convention).
///      The enforcer extracts the support value from the second parameter of castVote(proposalId, support).
contract VoteDirectionEnforcer is ICaveatEnforcer {
    /// @notice Emitted when the agent attempts to vote with a disallowed direction.
    /// @param support The disallowed vote direction.
    error VoteDirectionNotAllowed(uint8 support);

    /// @notice Called before execution to verify the vote direction is allowed.
    /// @param terms ABI-encoded uint8[] of allowed vote directions.
    /// @param callData The calldata for castVote(uint256 proposalId, uint8 support).
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
        uint8[] memory allowedDirections = abi.decode(terms, (uint8[]));

        // Extract support from the second parameter: bytes 4..36 = proposalId, 36..68 = support.
        uint8 support = uint8(uint256(bytes32(callData[36:68])));

        uint256 length = allowedDirections.length;
        for (uint256 i; i < length;) {
            if (allowedDirections[i] == support) {
                return;
            }
            unchecked { ++i; }
        }
        revert VoteDirectionNotAllowed(support);
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
