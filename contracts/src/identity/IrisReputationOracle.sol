// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IrisAgentRegistry} from "./IrisAgentRegistry.sol";

/// @title IrisReputationOracle
/// @notice Standalone reputation registry that tracks reputation scores (0-100) for registered agents.
/// @dev Positive feedback adds 2 points (capped at 100); negative feedback subtracts 5 (floored at 0).
contract IrisReputationOracle is Ownable {
    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @notice The agent registry used to resolve agent operators.
    IrisAgentRegistry public immutable agentRegistry;

    /// @notice Reputation score per agentId. Initialised to 50 on first feedback.
    mapping(uint256 => uint256) private _scores;

    /// @notice Whether a score has been explicitly initialised for an agentId.
    mapping(uint256 => bool) private _initialised;

    /// @notice Set of addresses authorised to submit feedback for a given agent.
    /// @dev agentId => reviewer => authorised.
    mapping(uint256 => mapping(address => bool)) private _allowedReviewers;

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when feedback is submitted for an agent.
    /// @param agentId The agent that received feedback.
    /// @param reviewer The address that submitted the feedback.
    /// @param positive True for positive feedback, false for negative.
    /// @param newScore The agent's reputation score after applying the feedback.
    event FeedbackSubmitted(uint256 indexed agentId, address indexed reviewer, bool positive, uint256 newScore);

    /// @notice Emitted when a reviewer is authorised for an agent.
    /// @param agentId The agent the reviewer is authorised for.
    /// @param reviewer The newly authorised reviewer address.
    event ReviewerAdded(uint256 indexed agentId, address indexed reviewer);

    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    error NotAuthorisedReviewer(uint256 agentId, address caller);
    error NotOperatorOrOwner(uint256 agentId, address caller);
    error AgentNotRegistered(uint256 agentId);

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /// @param _agentRegistry The IrisAgentRegistry contract address.
    /// @param _owner The initial owner of this oracle contract.
    constructor(address _agentRegistry, address _owner) Ownable(_owner) {
        agentRegistry = IrisAgentRegistry(_agentRegistry);
    }

    // -------------------------------------------------------------------------
    // External — Feedback
    // -------------------------------------------------------------------------

    /// @notice Submits positive or negative feedback for an agent.
    /// @dev Caller must be an allowed reviewer for the agent or the contract owner.
    ///      Positive feedback adds 2 (capped at 100). Negative feedback subtracts 5 (floored at 0).
    /// @param agentId The agent to submit feedback for.
    /// @param positive True for positive, false for negative feedback.
    function submitFeedback(uint256 agentId, bool positive) external {
        if (!agentRegistry.isRegistered(agentId)) {
            revert AgentNotRegistered(agentId);
        }
        if (!_allowedReviewers[agentId][msg.sender] && msg.sender != owner()) {
            revert NotAuthorisedReviewer(agentId, msg.sender);
        }

        _ensureInitialised(agentId);

        uint256 score = _scores[agentId];
        if (positive) {
            score = score + 2 > 100 ? 100 : score + 2;
        } else {
            score = score < 5 ? 0 : score - 5;
        }
        _scores[agentId] = score;

        emit FeedbackSubmitted(agentId, msg.sender, positive, score);
    }

    // -------------------------------------------------------------------------
    // External — Reviewer Management
    // -------------------------------------------------------------------------

    /// @notice Authorises an address to submit feedback for a given agent.
    /// @dev Only the agent's operator (from the registry) or the contract owner may call this.
    /// @param agentId The agent to authorise the reviewer for.
    /// @param reviewer The address to authorise.
    function addReviewer(uint256 agentId, address reviewer) external {
        IrisAgentRegistry.AgentInfo memory info = agentRegistry.getAgent(agentId);
        if (msg.sender != info.operator && msg.sender != owner()) {
            revert NotOperatorOrOwner(agentId, msg.sender);
        }
        _allowedReviewers[agentId][reviewer] = true;
        emit ReviewerAdded(agentId, reviewer);
    }

    // -------------------------------------------------------------------------
    // External — Views
    // -------------------------------------------------------------------------

    /// @notice Returns the current reputation score for an agent (0-100).
    /// @dev Returns 50 (the default) if no feedback has been submitted yet.
    /// @param agentId The agent to query.
    /// @return The agent's current reputation score.
    function getReputationScore(uint256 agentId) external view returns (uint256) {
        if (!_initialised[agentId]) {
            return 50;
        }
        return _scores[agentId];
    }

    /// @notice Returns whether the given address is an allowed reviewer for the agent.
    /// @param agentId The agent to check.
    /// @param reviewer The address to check.
    /// @return True if the address is allowed to review the agent.
    function isAllowedReviewer(uint256 agentId, address reviewer) external view returns (bool) {
        return _allowedReviewers[agentId][reviewer];
    }

    // -------------------------------------------------------------------------
    // Internal
    // -------------------------------------------------------------------------

    /// @dev Initialises the score to 50 if it has not been set yet.
    function _ensureInitialised(uint256 agentId) internal {
        if (!_initialised[agentId]) {
            _scores[agentId] = 50;
            _initialised[agentId] = true;
        }
    }
}
