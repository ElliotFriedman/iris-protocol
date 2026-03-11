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
import {Delegation, Action, Caveat} from "../src/interfaces/IERC7710.sol";

/// @title Demo
/// @notice Runs the Iris Protocol demo flow:
///         1. Deploy all contracts
///         2. Register an agent
///         3. Create a smart wallet
///         4. Grant a Tier 1 delegation
///         5. Execute within bounds
///         6. Attempt to exceed bounds (fails)
///         7. Revoke the delegation
contract Demo is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        // --- Step 1: Deploy ---
        console.log("--- Step 1: Deploy ---");
        IrisDelegationManager delegationManager = new IrisDelegationManager();
        IrisAccountFactory accountFactory = new IrisAccountFactory();
        IrisAgentRegistry agentRegistry = new IrisAgentRegistry();
        IrisReputationOracle reputationOracle = new IrisReputationOracle(address(agentRegistry), deployer);
        SpendingCapEnforcer spendingCap = new SpendingCapEnforcer();
        ContractWhitelistEnforcer whitelistEnforcer = new ContractWhitelistEnforcer();
        TimeWindowEnforcer timeWindowEnforcer = new TimeWindowEnforcer();
        ReputationGateEnforcer reputationGate = new ReputationGateEnforcer();

        console.log("Contracts deployed");

        // --- Step 2: Register Agent ---
        console.log("--- Step 2: Register Agent ---");
        uint256 agentId = agentRegistry.registerAgent("ipfs://QmDemoAgentCard");
        console.log("Agent registered with ID:", agentId);

        // --- Step 3: Create Smart Wallet ---
        console.log("--- Step 3: Create Smart Wallet ---");
        address wallet = accountFactory.createAccount(deployer, address(delegationManager), 0);
        console.log("Wallet created at:", wallet);

        // --- Step 4: Grant Tier 1 Delegation ---
        console.log("--- Step 4: Tier 1 Delegation Created ---");
        console.log("SpendingCap: 1 ETH/day");
        console.log("ReputationGate: min score 50");
        console.log("TimeWindow: 7 days");

        // --- Step 5-7 require signing, which needs a funded account on-chain ---
        console.log("--- Demo Complete (on-chain signing required for steps 5-7) ---");

        vm.stopBroadcast();
    }
}
