// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title IrisAgentRegistry
/// @notice Registry for AI agent identities, wrapping ERC-8004 Identity Registry concepts.
/// @dev Each registered agent receives an incrementing agentId and a lightweight NFT-like ownership record.
contract IrisAgentRegistry {
    // -------------------------------------------------------------------------
    // Types
    // -------------------------------------------------------------------------

    /// @notice On-chain metadata for a registered agent.
    struct AgentInfo {
        address operator;
        string metadataURI;
        bool active;
        uint256 registeredAt;
    }

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @notice The next agent ID to be assigned (starts at 1).
    uint256 private _nextAgentId = 1;

    /// @notice Agent ID to agent info.
    mapping(uint256 => AgentInfo) private _agents;

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when a new agent is registered.
    /// @param agentId The unique identifier assigned to the agent.
    /// @param operator The address that controls the agent.
    /// @param metadataURI URI pointing to the agent's metadata / capability card.
    event AgentRegistered(uint256 indexed agentId, address indexed operator, string metadataURI);

    /// @notice Emitted when an agent is deactivated by its operator.
    /// @param agentId The agent that was deactivated.
    /// @param operator The operator who deactivated the agent.
    event AgentDeactivated(uint256 indexed agentId, address indexed operator);

    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    error AgentNotFound(uint256 agentId);
    error NotOperator(uint256 agentId, address caller);
    error AgentAlreadyInactive(uint256 agentId);

    // -------------------------------------------------------------------------
    // External — Registration
    // -------------------------------------------------------------------------

    /// @notice Registers msg.sender as the operator of a new agent and mints an identity NFT.
    /// @param metadataURI URI pointing to the agent's off-chain metadata (capabilities, description).
    /// @return agentId The unique identifier assigned to the newly registered agent.
    function registerAgent(string calldata metadataURI) external returns (uint256 agentId) {
        agentId = _nextAgentId++;

        _agents[agentId] = AgentInfo({
            operator: msg.sender,
            metadataURI: metadataURI,
            active: true,
            registeredAt: block.timestamp
        });

        emit AgentRegistered(agentId, msg.sender, metadataURI);
    }

    // -------------------------------------------------------------------------
    // External — Management
    // -------------------------------------------------------------------------

    /// @notice Deactivates an agent. Only the agent's operator may call this.
    /// @param agentId The ID of the agent to deactivate.
    function deactivateAgent(uint256 agentId) external {
        AgentInfo storage info = _agents[agentId];
        if (info.operator == address(0)) revert AgentNotFound(agentId);
        if (info.operator != msg.sender) revert NotOperator(agentId, msg.sender);
        if (!info.active) revert AgentAlreadyInactive(agentId);

        info.active = false;
        emit AgentDeactivated(agentId, msg.sender);
    }

    // -------------------------------------------------------------------------
    // External — Views
    // -------------------------------------------------------------------------

    /// @notice Returns the full AgentInfo struct for a given agent ID.
    /// @param agentId The agent to look up.
    /// @return info The agent's on-chain information.
    function getAgent(uint256 agentId) external view returns (AgentInfo memory info) {
        info = _agents[agentId];
        if (info.operator == address(0)) revert AgentNotFound(agentId);
    }

    /// @notice Returns whether an agent ID is registered and active.
    /// @param agentId The agent to check.
    /// @return True if the agent exists and is active.
    function isRegistered(uint256 agentId) external view returns (bool) {
        AgentInfo storage info = _agents[agentId];
        return info.operator != address(0) && info.active;
    }

    /// @notice Returns the operator of the agent identity.
    /// @param agentId The agent ID.
    /// @return The address that operates this agent.
    function ownerOf(uint256 agentId) external view returns (address) {
        address operator = _agents[agentId].operator;
        if (operator == address(0)) revert AgentNotFound(agentId);
        return operator;
    }
}
