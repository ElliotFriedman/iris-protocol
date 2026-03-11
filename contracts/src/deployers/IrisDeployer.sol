// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IrisDelegationManager} from "../IrisDelegationManager.sol";
import {IrisAccountFactory} from "../IrisAccountFactory.sol";
import {IrisAgentRegistry} from "../identity/IrisAgentRegistry.sol";
import {IrisReputationOracle} from "../identity/IrisReputationOracle.sol";
import {SpendingCapEnforcer} from "../caveats/SpendingCapEnforcer.sol";
import {ContractWhitelistEnforcer} from "../caveats/ContractWhitelistEnforcer.sol";
import {FunctionSelectorEnforcer} from "../caveats/FunctionSelectorEnforcer.sol";
import {TimeWindowEnforcer} from "../caveats/TimeWindowEnforcer.sol";
import {SingleTxCapEnforcer} from "../caveats/SingleTxCapEnforcer.sol";
import {CooldownEnforcer} from "../caveats/CooldownEnforcer.sol";
import {ReputationGateEnforcer} from "../caveats/ReputationGateEnforcer.sol";
import {IrisApprovalQueue} from "../IrisApprovalQueue.sol";

/// @title IrisDeployer
/// @notice Shared deployment fixture for Iris Protocol.
/// @dev Used by both deploy scripts (Deploy.s.sol, DeployLocal.s.sol) and integration tests
///      to guarantee that tests exercise the exact same deployment path as mainnet.
library IrisDeployer {
    /// @notice All deployed Iris Protocol contract addresses.
    struct Deployment {
        IrisDelegationManager delegationManager;
        IrisAccountFactory factory;
        IrisAgentRegistry agentRegistry;
        IrisReputationOracle reputationOracle;
        SpendingCapEnforcer spendingCap;
        ContractWhitelistEnforcer contractWhitelist;
        FunctionSelectorEnforcer functionSelector;
        TimeWindowEnforcer timeWindow;
        SingleTxCapEnforcer singleTxCap;
        CooldownEnforcer cooldown;
        ReputationGateEnforcer reputationGate;
        IrisApprovalQueue approvalQueue;
    }

    /// @notice Deploys all Iris Protocol core contracts.
    /// @param oracleOwner The address that will own the IrisReputationOracle (can submit feedback).
    /// @param approvalExpiryDuration Duration in seconds after which approval requests expire.
    /// @return d The complete deployment struct with all contract references.
    function deployAll(address oracleOwner, uint256 approvalExpiryDuration)
        internal
        returns (Deployment memory d)
    {
        // Core
        d.delegationManager = new IrisDelegationManager();
        d.factory = new IrisAccountFactory();

        // Identity
        d.agentRegistry = new IrisAgentRegistry();
        d.reputationOracle = new IrisReputationOracle(address(d.agentRegistry), oracleOwner);

        // Caveat enforcers (stateful enforcers receive delegationManager for caller auth)
        d.spendingCap = new SpendingCapEnforcer(address(d.delegationManager));
        d.contractWhitelist = new ContractWhitelistEnforcer();
        d.functionSelector = new FunctionSelectorEnforcer();
        d.timeWindow = new TimeWindowEnforcer();
        d.singleTxCap = new SingleTxCapEnforcer();
        d.cooldown = new CooldownEnforcer(address(d.delegationManager));
        d.reputationGate = new ReputationGateEnforcer();

        // Approval queue
        d.approvalQueue = new IrisApprovalQueue(approvalExpiryDuration);
    }

    /// @notice Deploys core contracts only (no approval queue).
    /// @param oracleOwner The address that will own the IrisReputationOracle.
    /// @return d The deployment struct (approvalQueue will be address(0)).
    function deployCore(address oracleOwner) internal returns (Deployment memory d) {
        d = deployAll(oracleOwner, 86_400);
    }
}
