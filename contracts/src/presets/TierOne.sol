// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Caveat} from "../interfaces/IERC7710.sol";

/// @title TierOne — Supervised Preset
/// @notice Library that constructs a Caveat array for Tier 1 (Supervised) delegations.
/// @dev Tier 1 applies four caveats: SpendingCap, ContractWhitelist, TimeWindow, and ReputationGate.
library TierOne {
    /// @notice Builds a Caveat array for a Tier 1 supervised delegation.
    /// @param spendingCapEnforcer Address of the SpendingCapEnforcer contract.
    /// @param whitelistEnforcer Address of the ContractWhitelistEnforcer contract.
    /// @param timeWindowEnforcer Address of the TimeWindowEnforcer contract.
    /// @param reputationGateEnforcer Address of the ReputationGateEnforcer contract.
    /// @param reputationOracle Address of the IrisReputationOracle contract.
    /// @param agentId The agent's identity ID for reputation checks.
    /// @param dailyCap Maximum ETH (in wei) the agent may spend per day.
    /// @param allowedContracts Array of contract addresses the agent is permitted to call.
    /// @param validUntil Timestamp after which the delegation expires.
    /// @param minReputation Minimum reputation score required to execute.
    /// @return caveats The constructed array of four caveats.
    function configureTierOne(
        address spendingCapEnforcer,
        address whitelistEnforcer,
        address timeWindowEnforcer,
        address reputationGateEnforcer,
        address reputationOracle,
        uint256 agentId,
        uint256 dailyCap,
        address[] memory allowedContracts,
        uint256 validUntil,
        uint256 minReputation
    ) internal view returns (Caveat[] memory caveats) {
        caveats = new Caveat[](4);

        // Caveat 0: SpendingCap — daily rolling period (86400 seconds).
        caveats[0] = Caveat({
            enforcer: spendingCapEnforcer,
            terms: abi.encode(dailyCap, uint256(86_400))
        });

        // Caveat 1: ContractWhitelist — restrict callable targets.
        caveats[1] = Caveat({
            enforcer: whitelistEnforcer,
            terms: abi.encode(allowedContracts)
        });

        // Caveat 2: TimeWindow — valid from now until validUntil.
        caveats[2] = Caveat({
            enforcer: timeWindowEnforcer,
            terms: abi.encode(block.timestamp, validUntil)
        });

        // Caveat 3: ReputationGate — minimum reputation score.
        caveats[3] = Caveat({
            enforcer: reputationGateEnforcer,
            terms: abi.encode(reputationOracle, agentId, minReputation)
        });
    }
}
