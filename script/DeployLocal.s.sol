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
import {MockERC20} from "../src/mocks/MockERC20.sol";

/// @title DeployLocal
/// @notice Deploys all Iris Protocol contracts to local Anvil and sets up a demo scenario.
contract DeployLocal is Script {
    // Anvil default accounts
    uint256 constant DEPLOYER_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address constant DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant OWNER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant AGENT = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    // Agent private key (Anvil account #2)
    uint256 constant AGENT_PRIVATE_KEY = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;

    // Deployed addresses (populated during run)
    address delegationManagerAddr;
    address factoryAddr;
    address agentRegistryAddr;
    address reputationOracleAddr;
    address spendingCapAddr;
    address whitelistEnforcerAddr;
    address selectorEnforcerAddr;
    address timeWindowEnforcerAddr;
    address singleTxCapAddr;
    address cooldownEnforcerAddr;
    address reputationGateAddr;
    address approvalQueueAddr;
    address mockTokenAddr;
    address ownerAccountAddr;
    uint256 agentId;

    function run() external {
        _deployCore();
        _deployEnforcers();
        _deployMocksAndSetup();
        _registerAgent();
        _setReputation();
        _logAndWriteManifest();
    }

    function _deployCore() internal {
        vm.startBroadcast(DEPLOYER_PRIVATE_KEY);

        IrisDelegationManager delegationManager = new IrisDelegationManager();
        delegationManagerAddr = address(delegationManager);

        IrisAccountFactory factory = new IrisAccountFactory();
        factoryAddr = address(factory);

        IrisAgentRegistry agentRegistry = new IrisAgentRegistry();
        agentRegistryAddr = address(agentRegistry);

        IrisReputationOracle reputationOracle = new IrisReputationOracle(agentRegistryAddr, DEPLOYER);
        reputationOracleAddr = address(reputationOracle);

        vm.stopBroadcast();
    }

    function _deployEnforcers() internal {
        vm.startBroadcast(DEPLOYER_PRIVATE_KEY);

        spendingCapAddr = address(new SpendingCapEnforcer());
        whitelistEnforcerAddr = address(new ContractWhitelistEnforcer());
        selectorEnforcerAddr = address(new FunctionSelectorEnforcer());
        timeWindowEnforcerAddr = address(new TimeWindowEnforcer());
        singleTxCapAddr = address(new SingleTxCapEnforcer());
        cooldownEnforcerAddr = address(new CooldownEnforcer());
        reputationGateAddr = address(new ReputationGateEnforcer());

        // Approval Queue (24-hour expiry)
        approvalQueueAddr = address(new IrisApprovalQueue(86_400));

        vm.stopBroadcast();
    }

    function _deployMocksAndSetup() internal {
        vm.startBroadcast(DEPLOYER_PRIVATE_KEY);

        MockERC20 mockToken = new MockERC20("Mock USDC", "USDC");
        mockTokenAddr = address(mockToken);

        // Create IrisAccount for OWNER
        ownerAccountAddr = IrisAccountFactory(factoryAddr).createAccount(OWNER, delegationManagerAddr, 0);

        // Mint 10,000 MockERC20 to owner's IrisAccount
        mockToken.mint(ownerAccountAddr, 10_000 ether);

        vm.stopBroadcast();
    }

    function _registerAgent() internal {
        vm.startBroadcast(AGENT_PRIVATE_KEY);
        agentId = IrisAgentRegistry(agentRegistryAddr).registerAgent("ipfs://agent-metadata.json");
        vm.stopBroadcast();
    }

    function _setReputation() internal {
        // Set initial reputation to 75 for the agent.
        // Starting score is 50. Each positive = +2, each negative = -5.
        // 15 positives: 50 + 30 = 80. Then 1 negative: 80 - 5 = 75.
        vm.startBroadcast(DEPLOYER_PRIVATE_KEY);
        IrisReputationOracle oracle = IrisReputationOracle(reputationOracleAddr);
        for (uint256 i = 0; i < 15; i++) {
            oracle.submitFeedback(agentId, true);
        }
        oracle.submitFeedback(agentId, false); // 80 - 5 = 75
        vm.stopBroadcast();
    }

    function _logAndWriteManifest() internal {
        console.log("=== Iris Protocol Local Deployment ===");
        console.log("");
        console.log("IrisDelegationManager:", delegationManagerAddr);
        console.log("IrisAccountFactory:", factoryAddr);
        console.log("IrisAgentRegistry:", agentRegistryAddr);
        console.log("IrisReputationOracle:", reputationOracleAddr);
        console.log("SpendingCapEnforcer:", spendingCapAddr);
        console.log("ContractWhitelistEnforcer:", whitelistEnforcerAddr);
        console.log("FunctionSelectorEnforcer:", selectorEnforcerAddr);
        console.log("TimeWindowEnforcer:", timeWindowEnforcerAddr);
        console.log("SingleTxCapEnforcer:", singleTxCapAddr);
        console.log("CooldownEnforcer:", cooldownEnforcerAddr);
        console.log("ReputationGateEnforcer:", reputationGateAddr);
        console.log("IrisApprovalQueue:", approvalQueueAddr);
        console.log("MockERC20:", mockTokenAddr);
        console.log("Owner IrisAccount:", ownerAccountAddr);
        console.log("Agent ID:", agentId);

        _writeJson();
    }

    function _writeJson() internal {
        string memory json = string.concat(
            '{"chainId":31337,"rpc":"http://127.0.0.1:8545","contracts":{',
            '"IrisDelegationManager":"', vm.toString(delegationManagerAddr), '",',
            '"IrisAccountFactory":"', vm.toString(factoryAddr), '",',
            '"IrisAgentRegistry":"', vm.toString(agentRegistryAddr), '",',
            '"IrisReputationOracle":"', vm.toString(reputationOracleAddr), '",'
        );
        json = string.concat(
            json,
            '"SpendingCapEnforcer":"', vm.toString(spendingCapAddr), '",',
            '"ContractWhitelistEnforcer":"', vm.toString(whitelistEnforcerAddr), '",',
            '"FunctionSelectorEnforcer":"', vm.toString(selectorEnforcerAddr), '",',
            '"TimeWindowEnforcer":"', vm.toString(timeWindowEnforcerAddr), '",'
        );
        json = string.concat(
            json,
            '"SingleTxCapEnforcer":"', vm.toString(singleTxCapAddr), '",',
            '"CooldownEnforcer":"', vm.toString(cooldownEnforcerAddr), '",',
            '"ReputationGateEnforcer":"', vm.toString(reputationGateAddr), '",',
            '"IrisApprovalQueue":"', vm.toString(approvalQueueAddr), '",',
            '"MockERC20":"', vm.toString(mockTokenAddr), '"'
        );
        json = string.concat(
            json,
            '},"accounts":{',
            '"deployer":"', vm.toString(DEPLOYER), '",',
            '"owner":"', vm.toString(OWNER), '",',
            '"agent":"', vm.toString(AGENT), '",',
            '"ownerAccount":"', vm.toString(ownerAccountAddr), '"',
            '},"agentId":', vm.toString(agentId), '}'
        );

        vm.writeFile("deployments/local.json", json);
        console.log("");
        console.log("Deployment manifest written to deployments/local.json");
    }
}
