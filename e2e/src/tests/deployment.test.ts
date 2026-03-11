import { describe, it, expect, beforeAll } from "vitest";
import { type Address, getAddress } from "viem";
import {
  getPublicClient,
  loadManifest,
  type DeploymentManifest,
} from "../setup.js";
import {
  IrisDelegationManagerABI,
  IrisAccountABI,
  IrisAgentRegistryABI,
  IrisReputationOracleABI,
  MockERC20ABI,
} from "../abis.js";

describe("Deployment verification", () => {
  let manifest: DeploymentManifest;
  const client = getPublicClient();

  beforeAll(() => {
    manifest = loadManifest();
  });

  it("should have correct chain ID", async () => {
    const chainId = await client.getChainId();
    expect(chainId).toBe(31337);
  });

  it("should have deployed all contracts with code", async () => {
    const contracts = manifest.contracts;
    for (const [name, address] of Object.entries(contracts)) {
      const code = await client.getCode({ address: address as Address });
      expect(code, `${name} at ${address} should have code`).toBeDefined();
      expect(code!.length).toBeGreaterThan(2); // "0x" is empty
    }
  });

  it("should have created the owner account with correct owner", async () => {
    const owner = await client.readContract({
      address: manifest.accounts.ownerAccount,
      abi: IrisAccountABI,
      functionName: "owner",
    });
    expect(getAddress(owner)).toBe(getAddress(manifest.accounts.owner));
  });

  it("should have set delegation manager on owner account", async () => {
    const dm = await client.readContract({
      address: manifest.accounts.ownerAccount,
      abi: IrisAccountABI,
      functionName: "delegationManager",
    });
    expect(getAddress(dm)).toBe(
      getAddress(manifest.contracts.IrisDelegationManager)
    );
  });

  it("should have registered the agent", async () => {
    const isRegistered = await client.readContract({
      address: manifest.contracts.IrisAgentRegistry,
      abi: IrisAgentRegistryABI,
      functionName: "isRegistered",
      args: [BigInt(manifest.agentId)],
    });
    expect(isRegistered).toBe(true);
  });

  it("should have agent reputation at ~76", async () => {
    const score = await client.readContract({
      address: manifest.contracts.IrisReputationOracle,
      abi: IrisReputationOracleABI,
      functionName: "getReputationScore",
      args: [BigInt(manifest.agentId)],
    });
    // 50 + (13 * 2) = 76
    expect(Number(score)).toBe(76);
  });

  it("should have minted 10,000 USDC to owner account", async () => {
    const balance = await client.readContract({
      address: manifest.contracts.MockERC20,
      abi: MockERC20ABI,
      functionName: "balanceOf",
      args: [manifest.accounts.ownerAccount],
    });
    expect(balance).toBe(10_000n * 10n ** 18n);
  });

  it("should have domain separator set on delegation manager", async () => {
    const separator = await client.readContract({
      address: manifest.contracts.IrisDelegationManager,
      abi: IrisDelegationManagerABI,
      functionName: "domainSeparator",
    });
    expect(separator).toBeDefined();
    expect(separator).not.toBe(
      "0x0000000000000000000000000000000000000000000000000000000000000000"
    );
  });
});
