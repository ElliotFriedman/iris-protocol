// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IERC8004 — Trustless Agent Identity & Reputation
/// @notice Interface for the ERC-8004 agent identity, reputation, and validation registries.

interface IERC8004Identity {
    /// @notice Registers a new agent and mints an identity NFT.
    /// @param operator The operator address controlling the agent.
    /// @param metadataURI URI pointing to the agent card (capabilities, description).
    /// @return agentId The unique agent identifier (NFT token ID).
    function registerAgent(address operator, string calldata metadataURI) external returns (uint256 agentId);

    /// @notice Returns the operator of a registered agent.
    /// @param agentId The agent's identity token ID.
    /// @return The operator address controlling the agent.
    function getOperator(uint256 agentId) external view returns (address);

    /// @notice Returns true if the agent ID is registered and active.
    /// @param agentId The agent's identity token ID.
    /// @return True if the agent is registered and active.
    function isRegistered(uint256 agentId) external view returns (bool);

    /// @notice Returns the metadata URI for a given agent.
    /// @param agentId The agent's identity token ID.
    /// @return The metadata URI string.
    function getMetadataURI(uint256 agentId) external view returns (string memory);
}

interface IERC8004Reputation {
    /// @notice Returns the reputation score for an agent (0–100).
    /// @param agentId The agent's identity token ID.
    /// @return score The current reputation score.
    function getReputation(uint256 agentId) external view returns (uint256 score);

    /// @notice Submits feedback for an agent interaction.
    /// @param agentId The agent receiving feedback.
    /// @param positive True for positive feedback, false for negative.
    /// @param context Optional bytes context about the interaction.
    function submitFeedback(uint256 agentId, bool positive, bytes calldata context) external;
}

interface IERC8004Validation {
    /// @notice Validates that an agent meets requirements for a given action.
    /// @param agentId The agent to validate.
    /// @param requirements Encoded requirements to check against.
    /// @return valid True if the agent meets all requirements.
    function validateAgent(uint256 agentId, bytes calldata requirements) external view returns (bool valid);
}
