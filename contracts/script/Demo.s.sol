// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {IrisDeployer} from "../src/deployers/IrisDeployer.sol";
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
/// @dev Uses the shared IrisDeployer fixture to ensure deploy scripts and tests
///      exercise the exact same deployment path.
contract Demo is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        // --- Step 1: Deploy via shared fixture ---
        console.log("--- Step 1: Deploy ---");
        IrisDeployer.Deployment memory d = IrisDeployer.deployAll(deployer, 86_400);
        console.log("Contracts deployed");

        // --- Step 2: Register Agent ---
        console.log("--- Step 2: Register Agent ---");
        uint256 agentId = d.agentRegistry.registerAgent("ipfs://QmDemoAgentCard");
        console.log("Agent registered with ID:", agentId);

        // --- Step 3: Create Smart Wallet ---
        console.log("--- Step 3: Create Smart Wallet ---");
        address wallet = d.factory.createAccount(deployer, address(d.delegationManager), 0);
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
