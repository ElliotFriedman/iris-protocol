// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {IrisDeployer} from "../src/deployers/IrisDeployer.sol";
import {IrisAccount} from "../src/IrisAccount.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockUniswapRouter} from "../src/mocks/MockUniswapRouter.sol";

/// @title DeployLocal
/// @notice Deploys all Iris Protocol contracts to local Anvil and sets up a demo scenario.
/// @dev Uses the shared IrisDeployer fixture to ensure deploy scripts and tests
///      exercise the exact same deployment path.
contract DeployLocal is Script {
    // Anvil default accounts
    address constant DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant OWNER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant AGENT = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    function run() external {
        uint256 deployerKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

        vm.startBroadcast(deployerKey);

        // Deploy all Iris infrastructure via shared fixture
        IrisDeployer.Deployment memory d = IrisDeployer.deployAll(DEPLOYER, 86_400);

        // Deploy mocks
        MockERC20 mockUSDC = new MockERC20("Mock USDC", "USDC");
        MockUniswapRouter mockRouter = new MockUniswapRouter();

        // Create account for OWNER
        address ownerAccount = d.factory.createAccount(OWNER, address(d.delegationManager), 0);

        vm.stopBroadcast();

        // Register agent (switch to AGENT key)
        uint256 agentKey = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
        vm.startBroadcast(agentKey);
        uint256 agentId = d.agentRegistry.registerAgent("ipfs://agent-metadata.json");
        vm.stopBroadcast();

        // Setup reputation and mint tokens
        vm.startBroadcast(deployerKey);
        // Owner (of oracle) submits positive feedback to raise rep from 50 to 76
        for (uint256 i = 0; i < 13; i++) {
            d.reputationOracle.submitFeedback(agentId, true);
        }
        mockUSDC.mint(ownerAccount, 10_000 ether);
        vm.stopBroadcast();

        // Log
        console.log("=== Iris Protocol Local Deployment ===");
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
        console.log("MockERC20 (USDC):", address(mockUSDC));
        console.log("MockUniswapRouter:", address(mockRouter));
        console.log("Owner IrisAccount:", ownerAccount);
        console.log("Agent ID:", agentId);

        // Write deployment manifest
        string memory json = string.concat(
            '{"chainId":31337,"rpc":"http://127.0.0.1:8545","contracts":{',
            '"IrisDelegationManager":"', vm.toString(address(d.delegationManager)), '",',
            '"IrisAccountFactory":"', vm.toString(address(d.factory)), '",',
            '"IrisAgentRegistry":"', vm.toString(address(d.agentRegistry)), '",',
            '"IrisReputationOracle":"', vm.toString(address(d.reputationOracle)), '",',
            '"SpendingCapEnforcer":"', vm.toString(address(d.spendingCap)), '",',
            '"ContractWhitelistEnforcer":"', vm.toString(address(d.contractWhitelist)), '",',
            '"FunctionSelectorEnforcer":"', vm.toString(address(d.functionSelector)), '",',
            '"TimeWindowEnforcer":"', vm.toString(address(d.timeWindow)), '",',
            '"SingleTxCapEnforcer":"', vm.toString(address(d.singleTxCap)), '",',
            '"CooldownEnforcer":"', vm.toString(address(d.cooldown)), '",',
            '"ReputationGateEnforcer":"', vm.toString(address(d.reputationGate)), '",',
            '"IrisApprovalQueue":"', vm.toString(address(d.approvalQueue)), '",',
            '"MockERC20":"', vm.toString(address(mockUSDC)), '",',
            '"MockUniswapRouter":"', vm.toString(address(mockRouter)), '"',
            '},"accounts":{',
            '"deployer":"', vm.toString(DEPLOYER), '",',
            '"owner":"', vm.toString(OWNER), '",',
            '"agent":"', vm.toString(AGENT), '",',
            '"ownerAccount":"', vm.toString(ownerAccount), '"',
            '},"agentId":', vm.toString(agentId), '}'
        );

        vm.writeFile("deployments/local.json", json);
        console.log("");
        console.log("Deployment manifest written to deployments/local.json");
    }
}
