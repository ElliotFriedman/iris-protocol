// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICaveatEnforcer} from "../interfaces/ICaveatEnforcer.sol";

/// @title ProposalFilterEnforcer
/// @notice Restricts which governance proposal IDs an agent may interact with.
/// @dev Terms encode an array of allowed proposal IDs. The enforcer extracts the proposalId
///      from the first parameter of the calldata (assumes standard Governor castVote/execute signature).
contract ProposalFilterEnforcer is ICaveatEnforcer {
    /// @notice Emitted when the agent attempts to act on a proposal not in the allowed list.
    /// @param proposalId The disallowed proposal ID.
    error ProposalNotAllowed(uint256 proposalId);

    /// @notice Called before execution to verify the proposal ID is in the allowed set.
    /// @param terms ABI-encoded uint256[] of allowed proposal IDs.
    /// @param callData The calldata whose first argument (after the selector) is the proposalId.
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
        uint256[] memory allowedProposals = abi.decode(terms, (uint256[]));

        // Extract proposalId from the first parameter after the 4-byte selector.
        uint256 proposalId = abi.decode(callData[4:36], (uint256));

        uint256 length = allowedProposals.length;
        for (uint256 i; i < length;) {
            if (allowedProposals[i] == proposalId) {
                return;
            }
            unchecked { ++i; }
        }
        revert ProposalNotAllowed(proposalId);
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
