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
import {FunctionSelectorEnforcer} from "../src/caveats/FunctionSelectorEnforcer.sol";
import {TimeWindowEnforcer} from "../src/caveats/TimeWindowEnforcer.sol";
import {SingleTxCapEnforcer} from "../src/caveats/SingleTxCapEnforcer.sol";
import {CooldownEnforcer} from "../src/caveats/CooldownEnforcer.sol";
import {ReputationGateEnforcer} from "../src/caveats/ReputationGateEnforcer.sol";
import {IrisApprovalQueue} from "../src/IrisApprovalQueue.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockUniswapRouter} from "../src/mocks/MockUniswapRouter.sol";

/// @title DeployLocal
/// @notice Deploys all Iris Protocol contracts to local Anvil and sets up a demo scenario.
contract DeployLocal is Script {
    // Anvil default accounts
    address constant DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant OWNER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant AGENT = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    function run() external {
        uint256 deployerKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

        vm.startBroadcast(deployerKey);

        // --- Core ---
        IrisDelegationManager delegationManager = new IrisDelegationManager();
        IrisAccountFactory factory = new IrisAccountFactory();

        // --- Identity ---
        IrisAgentRegistry agentRegistry = new IrisAgentRegistry();
        IrisReputationOracle reputationOracle = new IrisReputationOracle(address(agentRegistry), DEPLOYER);

        // --- Caveat Enforcers ---
        SpendingCapEnforcer spendingCap = new SpendingCapEnforcer();
        ContractWhitelistEnforcer whitelistEnforcer = new ContractWhitelistEnforcer();
        FunctionSelectorEnforcer selectorEnforcer = new FunctionSelectorEnforcer();
        TimeWindowEnforcer timeWindowEnforcer = new TimeWindowEnforcer();
        SingleTxCapEnforcer singleTxCap = new SingleTxCapEnforcer();
        CooldownEnforcer cooldownEnforcer = new CooldownEnforcer();
        ReputationGateEnforcer reputationGate = new ReputationGateEnforcer();

        // --- Approval Queue ---
        IrisApprovalQueue approvalQueue = new IrisApprovalQueue(86_400);

        // --- Mocks ---
        MockERC20 mockUSDC = new MockERC20("Mock USDC", "USDC");
        MockUniswapRouter mockRouter = new MockUniswapRouter();

        // --- Setup: Create account for OWNER ---
        address ownerAccount = factory.createAccount(OWNER, address(delegationManager), 0);

        // --- Setup: Register agent ---
        // Switch to AGENT for registration
        vm.stopBroadcast();

        uint256 agentKey = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
        vm.startBroadcast(agentKey);
        uint256 agentId = agentRegistry.registerAgent("ipfs://agent-metadata.json");
        vm.stopBroadcast();

        // --- Setup: Set initial reputation to 75 ---
        vm.startBroadcast(deployerKey);
        // Owner (of oracle) submits positive feedback to raise rep from 50 to 75
        // Each positive = +2, need 13 positives: 50 + 26 = 76 (close enough)
        for (uint256 i = 0; i < 13; i++) {
            reputationOracle.submitFeedback(agentId, true);
        }

        // --- Setup: Mint MockERC20 to owner's account ---
        mockUSDC.mint(ownerAccount, 10_000 ether);

        vm.stopBroadcast();

        // --- Log ---
        console.log("=== Iris Protocol Local Deployment ===");
        console.log("");
        console.log("IrisDelegationManager:", address(delegationManager));
        console.log("IrisAccountFactory:", address(factory));
        console.log("IrisAgentRegistry:", address(agentRegistry));
        console.log("IrisReputationOracle:", address(reputationOracle));
        console.log("SpendingCapEnforcer:", address(spendingCap));
        console.log("ContractWhitelistEnforcer:", address(whitelistEnforcer));
        console.log("FunctionSelectorEnforcer:", address(selectorEnforcer));
        console.log("TimeWindowEnforcer:", address(timeWindowEnforcer));
        console.log("SingleTxCapEnforcer:", address(singleTxCap));
        console.log("CooldownEnforcer:", address(cooldownEnforcer));
        console.log("ReputationGateEnforcer:", address(reputationGate));
        console.log("IrisApprovalQueue:", address(approvalQueue));
        console.log("MockERC20 (USDC):", address(mockUSDC));
        console.log("MockUniswapRouter:", address(mockRouter));
        console.log("Owner IrisAccount:", ownerAccount);
        console.log("Agent ID:", agentId);

        // Write deployment manifest
        string memory json = string.concat(
            '{"chainId":31337,"rpc":"http://127.0.0.1:8545","contracts":{',
            '"IrisDelegationManager":"', vm.toString(address(delegationManager)), '",',
            '"IrisAccountFactory":"', vm.toString(address(factory)), '",',
            '"IrisAgentRegistry":"', vm.toString(address(agentRegistry)), '",',
            '"IrisReputationOracle":"', vm.toString(address(reputationOracle)), '",',
            '"SpendingCapEnforcer":"', vm.toString(address(spendingCap)), '",',
            '"ContractWhitelistEnforcer":"', vm.toString(address(whitelistEnforcer)), '",',
            '"FunctionSelectorEnforcer":"', vm.toString(address(selectorEnforcer)), '",',
            '"TimeWindowEnforcer":"', vm.toString(address(timeWindowEnforcer)), '",',
            '"SingleTxCapEnforcer":"', vm.toString(address(singleTxCap)), '",',
            '"CooldownEnforcer":"', vm.toString(address(cooldownEnforcer)), '",',
            '"ReputationGateEnforcer":"', vm.toString(address(reputationGate)), '",',
            '"IrisApprovalQueue":"', vm.toString(address(approvalQueue)), '",',
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
