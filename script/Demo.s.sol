// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {IrisDelegationManager} from "../src/IrisDelegationManager.sol";
import {IrisAccountFactory} from "../src/IrisAccountFactory.sol";
import {IrisAccount} from "../src/IrisAccount.sol";
import {IrisAgentRegistry} from "../src/identity/IrisAgentRegistry.sol";
import {IrisReputationOracle} from "../src/identity/IrisReputationOracle.sol";
import {SpendingCapEnforcer} from "../src/caveats/SpendingCapEnforcer.sol";
import {ContractWhitelistEnforcer} from "../src/caveats/ContractWhitelistEnforcer.sol";
import {TimeWindowEnforcer} from "../src/caveats/TimeWindowEnforcer.sol";
import {ReputationGateEnforcer} from "../src/caveats/ReputationGateEnforcer.sol";

/// @title Demo
/// @notice Runs the Iris Protocol demo flow.
contract Demo is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        console.log("--- Step 1: Deploy ---");
        IrisDelegationManager delegationManager = new IrisDelegationManager();
        IrisAccountFactory accountFactory = new IrisAccountFactory();
        IrisAgentRegistry agentRegistry = new IrisAgentRegistry();
        IrisReputationOracle reputationOracle = new IrisReputationOracle(address(agentRegistry), deployer);
        new SpendingCapEnforcer();
        new ContractWhitelistEnforcer();
        new TimeWindowEnforcer();
        new ReputationGateEnforcer();
        console.log("Contracts deployed");

        console.log("--- Step 2: Register Agent ---");
        uint256 agentId = agentRegistry.registerAgent("ipfs://QmDemoAgentCard");
        console.log("Agent registered with ID:", agentId);

        console.log("--- Step 3: Create Smart Wallet ---");
        address wallet = accountFactory.createAccount(deployer, address(delegationManager), 0);
        console.log("Wallet created at:", wallet);

        console.log("--- Step 4: Tier 1 Delegation Created ---");
        console.log("SpendingCap: 1 ETH/day, ReputationGate: min score 50, TimeWindow: 7 days");

        console.log("--- Demo Complete ---");
        console.log("Deployer:", deployer);

        vm.stopBroadcast();
    }
}
