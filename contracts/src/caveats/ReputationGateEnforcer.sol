// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

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
    // External — ICaveatEnforcer
    // -------------------------------------------------------------------------

    /// @notice Queries the ERC-8004 Reputation Registry and reverts if the agent's score is below
    ///         the minimum threshold encoded in `terms`.
    /// @dev The reputation oracle is called via a static call to `getReputationScore(uint256)`.
    ///      If the oracle reverts or returns a score below `minScore`, this hook reverts.
    /// @param terms ABI-encoded `(address reputationOracle, uint256 agentId, uint256 minScore)`.
    function beforeHook(
        bytes calldata terms,
        bytes calldata,
        address,
        bytes32,
        address,
        address,
        address,
        uint256,
        bytes calldata
    ) external view override {
        (address reputationOracle, uint256 agentId, uint256 minScore) =
            abi.decode(terms, (address, uint256, uint256));

        if (reputationOracle == address(0)) revert InvalidTerms();

        uint256 currentScore = _queryReputation(reputationOracle, agentId);

        if (currentScore < minScore) {
            revert ReputationTooLow(agentId, currentScore, minScore);
        }
    }

    /// @notice Called after the delegated execution. No-op for this enforcer.
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
