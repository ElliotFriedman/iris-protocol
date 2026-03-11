// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Caveat} from "../interfaces/IERC7710.sol";

/// @title TierThree — Full Delegation Preset
/// @notice Library that constructs a Caveat array for Tier 3 (Full Delegation) delegations.
/// @dev Tier 3 applies six caveats: SpendingCap (weekly), ContractWhitelist, TimeWindow,
///      ReputationGate (higher minimum), SingleTxCap, and Cooldown.
///      Parameters are passed via structs to avoid stack-too-deep errors.
library TierThree {
    /// @notice Enforcer addresses required to build a Tier 3 caveat array.
    struct Enforcers {
        address spendingCapEnforcer;
        address whitelistEnforcer;
        address timeWindowEnforcer;
        address reputationGateEnforcer;
        address singleTxCapEnforcer;
        address cooldownEnforcer;
    }

    /// @notice Configuration parameters for a Tier 3 delegation.
    struct Params {
        address reputationOracle;
        uint256 agentId;
        uint256 weeklyCap;
        uint256 maxTxValue;
        address[] allowedContracts;
        uint256 validUntil;
        uint256 minReputation;
        uint256 cooldownPeriod;
        uint256 cooldownThreshold;
    }

    /// @notice Builds a Caveat array for a Tier 3 full-delegation preset.
    /// @param enforcers The enforcer contract addresses.
    /// @param params The delegation configuration parameters.
    /// @return caveats The constructed array of six caveats.
    function configureTierThree(
        Enforcers memory enforcers,
        Params memory params
    ) internal view returns (Caveat[] memory caveats) {
        caveats = new Caveat[](6);

        // Caveat 0: SpendingCap — weekly rolling period (604800 seconds).
        caveats[0] = Caveat({
            enforcer: enforcers.spendingCapEnforcer,
            terms: abi.encode(params.weeklyCap, uint256(604_800))
        });

        // Caveat 1: ContractWhitelist — restrict callable targets.
        caveats[1] = Caveat({
            enforcer: enforcers.whitelistEnforcer,
            terms: abi.encode(params.allowedContracts)
        });

        // Caveat 2: TimeWindow — valid from now until validUntil.
        caveats[2] = Caveat({
            enforcer: enforcers.timeWindowEnforcer,
            terms: abi.encode(block.timestamp, params.validUntil)
        });

        // Caveat 3: ReputationGate — higher minimum reputation score.
        caveats[3] = Caveat({
            enforcer: enforcers.reputationGateEnforcer,
            terms: abi.encode(params.reputationOracle, params.agentId, params.minReputation)
        });

        // Caveat 4: SingleTxCap — per-transaction value limit.
        caveats[4] = Caveat({
            enforcer: enforcers.singleTxCapEnforcer,
            terms: abi.encode(params.maxTxValue)
        });

        // Caveat 5: Cooldown — enforces a minimum delay between high-value executions.
        caveats[5] = Caveat({
            enforcer: enforcers.cooldownEnforcer,
            terms: abi.encode(params.cooldownPeriod, params.cooldownThreshold)
        });
    }
}
