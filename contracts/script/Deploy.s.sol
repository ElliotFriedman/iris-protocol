// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {IrisDeployer} from "../src/deployers/IrisDeployer.sol";

/// @title Deploy
/// @notice Deploys all Iris Protocol core contracts to Base Sepolia.
/// @dev Uses the shared IrisDeployer fixture to ensure deploy scripts and tests
///      exercise the exact same deployment path.
contract Deploy is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        IrisDeployer.Deployment memory d = IrisDeployer.deployAll(deployer, 86_400);

        vm.stopBroadcast();

        console.log("=== Iris Protocol Deployment ===");
        console.log("Deployer:", deployer);
        console.log("");
        console.log("IrisDelegationManager:", address(d.delegationManager));
        console.log("IrisAccountFactory:", address(d.factory));
        console.log("IrisAgentRegistry:", address(d.agentRegistry));
        console.log("IrisReputationOracle:", address(d.reputationOracle));
        console.log("SpendingCapEnforcer:", address(d.spendingCap));
        console.log("ContractWhitelistEnforcer:", address(d.contractWhitelist));
        console.log("FunctionSelectorEnforcer:", address(d.functionSelector));
        console.log("TimeWindowEnforcer:", address(d.timeWindow));
        console.log("SingleTxCapEnforcer:", address(d.singleTxCap));
        console.log("CooldownEnforcer:", address(d.cooldown));
        console.log("ReputationGateEnforcer:", address(d.reputationGate));
        console.log("IrisApprovalQueue:", address(d.approvalQueue));
        console.log("");
        console.log("=== Deployment Complete ===");
    }
}
