import { describe, it, expect, beforeAll } from "vitest";
import { getAddress } from "viem";
import {
  getPublicClient,
  getWalletClient,
  loadManifest,
  type DeploymentManifest,
} from "../setup.js";
import { IrisAgentRegistryABI, IrisReputationOracleABI } from "../abis.js";

// Use Anvil account #4 as a fresh agent
const FRESH_AGENT_KEY =
  "0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a" as `0x${string}`;

describe("Agent registry and reputation", () => {
  let manifest: DeploymentManifest;
  const client = getPublicClient();

  beforeAll(() => {
    manifest = loadManifest();
  });

  it("should register a new agent and return an incrementing ID", async () => {
    const wallet = getWalletClient(FRESH_AGENT_KEY);

    const hash = await wallet.writeContract({
      address: manifest.contracts.IrisAgentRegistry,
      abi: IrisAgentRegistryABI,
      functionName: "registerAgent",
      args: ["ipfs://e2e-test-agent"],
    });

    const receipt = await client.waitForTransactionReceipt({ hash });
    expect(receipt.status).toBe("success");

    // New agent ID should be > 1 (agent 1 was created in deploy)
    const agentInfo = await client.readContract({
      address: manifest.contracts.IrisAgentRegistry,
      abi: IrisAgentRegistryABI,
      functionName: "getAgent",
      args: [2n],
    });
    expect(agentInfo.active).toBe(true);
    expect(agentInfo.metadataURI).toBe("ipfs://e2e-test-agent");
  });

  it("should have default reputation of 50 for new agent", async () => {
    const score = await client.readContract({
      address: manifest.contracts.IrisReputationOracle,
      abi: IrisReputationOracleABI,
      functionName: "getReputationScore",
      args: [2n],
    });
    expect(Number(score)).toBe(50);
  });

  it("should increase reputation with positive feedback", async () => {
    // Deployer is the oracle owner and can submit feedback
    const deployerWallet = getWalletClient(
      "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
    );

    const hash = await deployerWallet.writeContract({
      address: manifest.contracts.IrisReputationOracle,
      abi: IrisReputationOracleABI,
      functionName: "submitFeedback",
      args: [BigInt(manifest.agentId), true],
    });
    await client.waitForTransactionReceipt({ hash });

    const score = await client.readContract({
      address: manifest.contracts.IrisReputationOracle,
      abi: IrisReputationOracleABI,
      functionName: "getReputationScore",
      args: [BigInt(manifest.agentId)],
    });
    // Was 76, now 78
    expect(Number(score)).toBe(78);
  });

  it("should decrease reputation with negative feedback", async () => {
    const deployerWallet = getWalletClient(
      "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
    );

    const hash = await deployerWallet.writeContract({
      address: manifest.contracts.IrisReputationOracle,
      abi: IrisReputationOracleABI,
      functionName: "submitFeedback",
      args: [BigInt(manifest.agentId), false],
    });
    await client.waitForTransactionReceipt({ hash });

    const score = await client.readContract({
      address: manifest.contracts.IrisReputationOracle,
      abi: IrisReputationOracleABI,
      functionName: "getReputationScore",
      args: [BigInt(manifest.agentId)],
    });
    // Was 78, now 73 (-5)
    expect(Number(score)).toBe(73);
  });

  it("should deactivate an agent", async () => {
    const wallet = getWalletClient(FRESH_AGENT_KEY);

    const hash = await wallet.writeContract({
      address: manifest.contracts.IrisAgentRegistry,
      abi: IrisAgentRegistryABI,
      functionName: "deactivateAgent",
      args: [2n],
    });
    const receipt = await client.waitForTransactionReceipt({ hash });
    expect(receipt.status).toBe("success");

    const isRegistered = await client.readContract({
      address: manifest.contracts.IrisAgentRegistry,
      abi: IrisAgentRegistryABI,
      functionName: "isRegistered",
      args: [2n],
    });
    expect(isRegistered).toBe(false);
  });
});
