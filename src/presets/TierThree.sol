// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Caveat} from "../interfaces/IERC7710.sol";

/// @title TierThree — Full Delegation Preset
/// @notice Library that constructs a Caveat array for Tier 3 (Full Delegation) delegations.
/// @dev Tier 3 applies six caveats: SpendingCap (weekly), ContractWhitelist, TimeWindow,
///      ReputationGate (higher minimum), SingleTxCap, and Cooldown.
library TierThree {
    /// @notice Builds a Caveat array for a Tier 3 full-delegation preset.
    /// @param spendingCapEnforcer Address of the SpendingCapEnforcer contract.
    /// @param whitelistEnforcer Address of the ContractWhitelistEnforcer contract.
    /// @param timeWindowEnforcer Address of the TimeWindowEnforcer contract.
    /// @param reputationGateEnforcer Address of the ReputationGateEnforcer contract.
    /// @param singleTxCapEnforcer Address of the SingleTxCapEnforcer contract.
    /// @param cooldownEnforcer Address of the CooldownEnforcer contract.
    /// @param reputationOracle Address of the IrisReputationOracle contract.
    /// @param agentId The agent's identity ID for reputation checks.
    /// @param weeklyCap Maximum ETH (in wei) the agent may spend per week.
    /// @param maxTxValue Maximum ETH (in wei) per single transaction.
    /// @param allowedContracts Array of contract addresses the agent is permitted to call.
    /// @param validUntil Timestamp after which the delegation expires.
    /// @param minReputation Minimum reputation score required (should be higher than lower tiers).
    /// @param cooldownPeriod Minimum seconds between consecutive executions.
    /// @param cooldownThreshold ETH value threshold above which the cooldown applies.
    /// @return caveats The constructed array of six caveats.
    function configureTierThree(
        address spendingCapEnforcer,
        address whitelistEnforcer,
        address timeWindowEnforcer,
        address reputationGateEnforcer,
        address singleTxCapEnforcer,
        address cooldownEnforcer,
        address reputationOracle,
        uint256 agentId,
        uint256 weeklyCap,
        uint256 maxTxValue,
        address[] memory allowedContracts,
        uint256 validUntil,
        uint256 minReputation,
        uint256 cooldownPeriod,
        uint256 cooldownThreshold
    ) internal view returns (Caveat[] memory caveats) {
        caveats = new Caveat[](6);

        // Caveat 0: SpendingCap — weekly rolling period (604800 seconds).
        caveats[0] = Caveat({
            enforcer: spendingCapEnforcer,
            terms: abi.encode(weeklyCap, uint256(604_800))
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

        // Caveat 3: ReputationGate — higher minimum reputation score.
        caveats[3] = Caveat({
            enforcer: reputationGateEnforcer,
            terms: abi.encode(reputationOracle, agentId, minReputation)
        });

        // Caveat 4: SingleTxCap — per-transaction value limit.
        caveats[4] = Caveat({
            enforcer: singleTxCapEnforcer,
            terms: abi.encode(maxTxValue)
        });

        // Caveat 5: Cooldown — enforces a minimum delay between high-value executions.
        caveats[5] = Caveat({
            enforcer: cooldownEnforcer,
            terms: abi.encode(cooldownPeriod, cooldownThreshold)
        });
    }
}
