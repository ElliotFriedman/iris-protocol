// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ICaveatEnforcer} from "../interfaces/ICaveatEnforcer.sol";

/// @title ReputationGateEnforcer
/// @author Iris Protocol
/// @notice Gates delegated executions behind a minimum on-chain reputation score, queried from an
///         ERC-8004 compatible Reputation Registry at execution time.
/// @dev This is the novel contribution of Iris Protocol. Unlike static access-control lists, the
///      ReputationGateEnforcer creates a *dynamic trust boundary*: an agent's ability to act on
///      behalf of a delegator is continuously tethered to its live reputation. If the agent's score
///      drops below the configured threshold -- even after the delegation was granted -- execution
///      is blocked. This makes delegated authority self-healing: misbehaving agents are automatically
///      excluded without requiring the delegator to manually revoke.
///
///      Terms encoding: `abi.encode(address reputationOracle, uint256 agentId, uint256 minScore)`
///        - `reputationOracle`: The address of a contract exposing `getReputationScore(uint256) -> uint256`.
///        - `agentId`: The ERC-8004 identity token ID of the agent.
///        - `minScore`: The minimum reputation score (0-100) required to pass the gate.
///
///      Design rationale:
///        1. The oracle address is encoded in `terms` rather than set in the constructor so that a
///           single enforcer deployment can serve multiple reputation registries (e.g. per-domain oracles).
///        2. The check is performed in `beforeHook` as a view call, consuming no state and producing
///           no side-effects, which keeps gas costs minimal and makes the enforcer composable.
///        3. The enforcer is intentionally stateless -- it holds no mappings and writes no storage --
///           so it can be shared across all delegations in the protocol.
contract ReputationGateEnforcer is ICaveatEnforcer {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Reverted when the agent's current reputation score is below the delegation's minimum.
    /// @param agentId The agent whose reputation was checked.
    /// @param currentScore The agent's score at the time of the check.
    /// @param requiredScore The minimum score configured in the delegation's terms.
    error ReputationTooLow(uint256 agentId, uint256 currentScore, uint256 requiredScore);

    /// @notice Reverted when the terms blob cannot be decoded or contains a zero-address oracle.
    error InvalidTerms();

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted (as a log, not a revert) when a reputation check passes, enabling off-chain
    ///         monitoring of agent activity relative to their reputation.
    /// @param agentId The agent that passed the check.
    /// @param currentScore The agent's reputation score at the moment of execution.
    /// @param requiredScore The minimum score that was required.
    event ReputationCheckPassed(uint256 indexed agentId, uint256 currentScore, uint256 requiredScore);

    // -------------------------------------------------------------------------
    // External — ICaveatEnforcer
    // -------------------------------------------------------------------------

    /// @notice Queries the ERC-8004 Reputation Registry and reverts if the agent's score is below
    ///         the minimum threshold encoded in `terms`.
    /// @dev The reputation oracle is called via a static call to `getReputationScore(uint256)`.
    ///      If the oracle reverts or returns a score below `minScore`, this hook reverts.
    /// @param terms ABI-encoded `(address reputationOracle, uint256 agentId, uint256 minScore)`.
    ///        - `reputationOracle`: must be a non-zero address implementing `getReputationScore`.
    ///        - `agentId`: the ERC-8004 identity token ID of the executing agent.
    ///        - `minScore`: the minimum reputation score (inclusive) required for execution.
    /// @param args Unused runtime arguments (reserved for future extensions).
    /// @param delegationManager The delegation manager invoking this enforcer.
    /// @param delegationHash The hash of the delegation being redeemed.
    /// @param delegator The account that created the delegation.
    /// @param redeemer The agent or account redeeming the delegation.
    /// @param target The target contract of the delegated execution.
    /// @param value The ETH value of the delegated execution.
    /// @param callData The calldata of the delegated execution.
    function beforeHook(
        bytes calldata terms,
        bytes calldata args,
        address delegationManager,
        bytes32 delegationHash,
        address delegator,
        address redeemer,
        address target,
        uint256 value,
        bytes calldata callData
    ) external override {
        (address reputationOracle, uint256 agentId, uint256 minScore) =
            abi.decode(terms, (address, uint256, uint256));

        if (reputationOracle == address(0)) revert InvalidTerms();

        // Query the agent's live reputation score from the ERC-8004 registry.
        uint256 currentScore = _queryReputation(reputationOracle, agentId);

        if (currentScore < minScore) {
            revert ReputationTooLow(agentId, currentScore, minScore);
        }

        emit ReputationCheckPassed(agentId, currentScore, minScore);
    }

    /// @notice Called after the delegated execution. No-op for this enforcer.
    /// @dev The reputation gate is a pre-execution check only; post-execution enforcement is
    ///      intentionally omitted because the reputation score is an input condition, not an output invariant.
    /// @param terms Unused.
    /// @param args Unused.
    /// @param delegationManager Unused.
    /// @param delegationHash Unused.
    /// @param delegator Unused.
    /// @param redeemer Unused.
    /// @param target Unused.
    /// @param value Unused.
    /// @param callData Unused.
    function afterHook(
        bytes calldata terms,
        bytes calldata args,
        address delegationManager,
        bytes32 delegationHash,
        address delegator,
        address redeemer,
        address target,
        uint256 value,
        bytes calldata callData
    ) external pure override {
        // Intentional no-op. Reputation is a pre-condition, not a post-condition.
    }

    // -------------------------------------------------------------------------
    // Internal
    // -------------------------------------------------------------------------

    /// @dev Performs a static call to the reputation oracle to fetch the agent's current score.
    ///      Reverts with `InvalidTerms` if the call fails (e.g. oracle not deployed, wrong interface).
    /// @param oracle The reputation oracle address.
    /// @param agentId The agent's identity token ID.
    /// @return score The agent's current reputation score.
    function _queryReputation(address oracle, uint256 agentId) internal view returns (uint256 score) {
        (bool success, bytes memory data) =
            oracle.staticcall(abi.encodeWithSignature("getReputationScore(uint256)", agentId));
        if (!success || data.length < 32) revert InvalidTerms();
        score = abi.decode(data, (uint256));
    }
}
