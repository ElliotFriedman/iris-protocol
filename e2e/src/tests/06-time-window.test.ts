import { describe, it, expect, beforeAll } from "vitest";
import {
  encodeFunctionData,
  encodeAbiParameters,
  parseEther,
  type Address,
  zeroAddress,
} from "viem";
import {
  getPublicClient,
  getWalletClient,
  loadManifest,
  OWNER_KEY,
  AGENT_KEY,
  type DeploymentManifest,
} from "../setup.js";
import {
  IrisDelegationManagerABI,
  MockERC20ABI,
} from "../abis.js";

const delegationTypes = {
  Caveat: [
    { name: "enforcer", type: "address" },
    { name: "terms", type: "bytes" },
  ],
  Delegation: [
    { name: "delegator", type: "address" },
    { name: "delegate", type: "address" },
    { name: "authority", type: "address" },
    { name: "caveats", type: "Caveat[]" },
    { name: "salt", type: "uint256" },
  ],
} as const;

describe("TimeWindowEnforcer (E2E)", () => {
  let manifest: DeploymentManifest;
  const client = getPublicClient();
  const ownerWallet = getWalletClient(OWNER_KEY);
  const agentWallet = getWalletClient(AGENT_KEY);
  let domain: {
    name: string;
    version: string;
    chainId: number;
    verifyingContract: Address;
  };

  beforeAll(() => {
    manifest = loadManifest();
    domain = {
      name: "IrisDelegationManager",
      version: "1",
      chainId: 31337,
      verifyingContract: manifest.contracts.IrisDelegationManager,
    };
  });

  it("should allow execution within a valid time window", async () => {
    const recipient = "0x14DC79964DA2c08Dba798bb8992A8202570Cf55F" as Address;

    // Window: now - 1 hour to now + 1 hour
    const block = await client.getBlock();
    const now = block.timestamp;
    const notBefore = now - 3600n;
    const notAfter = now + 3600n;

    const timeTerms = encodeAbiParameters(
      [{ type: "uint256" }, { type: "uint256" }],
      [notBefore, notAfter]
    );

    const delegation = {
      delegator: manifest.accounts.ownerAccount,
      delegate: manifest.accounts.agent,
      authority: zeroAddress,
      caveats: [
        {
          enforcer: manifest.contracts.TimeWindowEnforcer,
          terms: timeTerms,
        },
      ],
      salt: 3000n,
    };

    const signature = await ownerWallet.signTypedData({
      domain,
      types: delegationTypes,
      primaryType: "Delegation",
      message: delegation,
    });

    const transferCalldata = encodeFunctionData({
      abi: MockERC20ABI,
      functionName: "transfer",
      args: [recipient, parseEther("1")],
    });

    const hash = await agentWallet.writeContract({
      address: manifest.contracts.IrisDelegationManager,
      abi: IrisDelegationManagerABI,
      functionName: "redeemDelegation",
      args: [
        [{ ...delegation, signature }],
        {
          target: manifest.contracts.MockERC20,
          value: 0n,
          callData: transferCalldata,
        },
      ],
    });

    const receipt = await client.waitForTransactionReceipt({ hash });
    expect(receipt.status).toBe("success");
  });

  it("should block execution with a future-only time window", async () => {
    // Window starts 1 hour from now — current time is before notBefore
    const block = await client.getBlock();
    const now = block.timestamp;
    const notBefore = now + 3600n;
    const notAfter = now + 7200n;

    const timeTerms = encodeAbiParameters(
      [{ type: "uint256" }, { type: "uint256" }],
      [notBefore, notAfter]
    );

    const delegation = {
      delegator: manifest.accounts.ownerAccount,
      delegate: manifest.accounts.agent,
      authority: zeroAddress,
      caveats: [
        {
          enforcer: manifest.contracts.TimeWindowEnforcer,
          terms: timeTerms,
        },
      ],
      salt: 3001n,
    };

    const signature = await ownerWallet.signTypedData({
      domain,
      types: delegationTypes,
      primaryType: "Delegation",
      message: delegation,
    });

    const transferCalldata = encodeFunctionData({
      abi: MockERC20ABI,
      functionName: "transfer",
      args: [
        "0x14DC79964DA2c08Dba798bb8992A8202570Cf55F" as Address,
        parseEther("1"),
      ],
    });

    await expect(
      agentWallet.writeContract({
        address: manifest.contracts.IrisDelegationManager,
        abi: IrisDelegationManagerABI,
        functionName: "redeemDelegation",
        args: [
          [{ ...delegation, signature }],
          {
            target: manifest.contracts.MockERC20,
            value: 0n,
            callData: transferCalldata,
          },
        ],
      })
    ).rejects.toThrow();
  });

  it("should block execution with an expired time window", async () => {
    // Window ended 1 hour ago
    const block = await client.getBlock();
    const now = block.timestamp;
    const notBefore = now - 7200n;
    const notAfter = now - 3600n;

    const timeTerms = encodeAbiParameters(
      [{ type: "uint256" }, { type: "uint256" }],
      [notBefore, notAfter]
    );

    const delegation = {
      delegator: manifest.accounts.ownerAccount,
      delegate: manifest.accounts.agent,
      authority: zeroAddress,
      caveats: [
        {
          enforcer: manifest.contracts.TimeWindowEnforcer,
          terms: timeTerms,
        },
      ],
      salt: 3002n,
    };

    const signature = await ownerWallet.signTypedData({
      domain,
      types: delegationTypes,
      primaryType: "Delegation",
      message: delegation,
    });

    const transferCalldata = encodeFunctionData({
      abi: MockERC20ABI,
      functionName: "transfer",
      args: [
        "0x14DC79964DA2c08Dba798bb8992A8202570Cf55F" as Address,
        parseEther("1"),
      ],
    });

    await expect(
      agentWallet.writeContract({
        address: manifest.contracts.IrisDelegationManager,
        abi: IrisDelegationManagerABI,
        functionName: "redeemDelegation",
        args: [
          [{ ...delegation, signature }],
          {
            target: manifest.contracts.MockERC20,
            value: 0n,
            callData: transferCalldata,
          },
        ],
      })
    ).rejects.toThrow();
  });
});
