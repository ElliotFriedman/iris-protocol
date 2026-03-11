// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {IrisDelegationManager} from "../src/IrisDelegationManager.sol";
import {IrisAccountFactory} from "../src/IrisAccountFactory.sol";
import {IrisAgentRegistry} from "../src/identity/IrisAgentRegistry.sol";
import {IrisReputationOracle} from "../src/identity/IrisReputationOracle.sol";
import {SpendingCapEnforcer} from "../src/caveats/SpendingCapEnforcer.sol";
import {ContractWhitelistEnforcer} from "../src/caveats/ContractWhitelistEnforcer.sol";
import {FunctionSelectorEnforcer} from "../src/caveats/FunctionSelectorEnforcer.sol";
import {TimeWindowEnforcer} from "../src/caveats/TimeWindowEnforcer.sol";
import {SingleTxCapEnforcer} from "../src/caveats/SingleTxCapEnforcer.sol";
import {CooldownEnforcer} from "../src/caveats/CooldownEnforcer.sol";
import {ReputationGateEnforcer} from "../src/caveats/ReputationGateEnforcer.sol";
import {IrisApprovalQueue} from "../src/IrisApprovalQueue.sol";

/// @title Deploy
/// @notice Deploys all Iris Protocol core contracts to Base Sepolia.
contract Deploy is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        // --- Core ---
        IrisDelegationManager delegationManager = new IrisDelegationManager();
        console.log("IrisDelegationManager:", address(delegationManager));

        IrisAccountFactory factory = new IrisAccountFactory();
        console.log("IrisAccountFactory:", address(factory));

        // --- Identity ---
        IrisAgentRegistry agentRegistry = new IrisAgentRegistry();
        console.log("IrisAgentRegistry:", address(agentRegistry));

        IrisReputationOracle reputationOracle = new IrisReputationOracle(address(agentRegistry), deployer);
        console.log("IrisReputationOracle:", address(reputationOracle));

        // --- Caveat Enforcers ---
        SpendingCapEnforcer spendingCap = new SpendingCapEnforcer();
        console.log("SpendingCapEnforcer:", address(spendingCap));

        ContractWhitelistEnforcer whitelistEnforcer = new ContractWhitelistEnforcer();
        console.log("ContractWhitelistEnforcer:", address(whitelistEnforcer));

        FunctionSelectorEnforcer selectorEnforcer = new FunctionSelectorEnforcer();
        console.log("FunctionSelectorEnforcer:", address(selectorEnforcer));

        TimeWindowEnforcer timeWindowEnforcer = new TimeWindowEnforcer();
        console.log("TimeWindowEnforcer:", address(timeWindowEnforcer));

        SingleTxCapEnforcer singleTxCap = new SingleTxCapEnforcer();
        console.log("SingleTxCapEnforcer:", address(singleTxCap));

        CooldownEnforcer cooldownEnforcer = new CooldownEnforcer();
        console.log("CooldownEnforcer:", address(cooldownEnforcer));

        ReputationGateEnforcer reputationGate = new ReputationGateEnforcer();
        console.log("ReputationGateEnforcer:", address(reputationGate));

        // --- Approval Queue ---
        IrisApprovalQueue approvalQueue = new IrisApprovalQueue(86_400); // 24-hour expiry
        console.log("IrisApprovalQueue:", address(approvalQueue));

        vm.stopBroadcast();

        console.log("");
        console.log("=== Deployment Complete ===");
        console.log("Deployer:", deployer);
    }
}
