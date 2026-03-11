import { describe, it, expect, beforeAll } from "vitest";
import {
  encodeFunctionData,
  encodeAbiParameters,
  parseEther,
  getAddress,
  type Address,
  zeroAddress,
} from "viem";
import {
  getPublicClient,
  getWalletClient,
  loadManifest,
  ownerAccount,
  agentAccount,
  OWNER_KEY,
  AGENT_KEY,
  DEPLOYER_KEY,
  type DeploymentManifest,
} from "../setup.js";
import {
  IrisDelegationManagerABI,
  IrisAccountABI,
  MockERC20ABI,
  IrisReputationOracleABI,
} from "../abis.js";

// EIP-712 types for Iris delegation signing
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

describe("Delegation flow (EIP-712)", () => {
  let manifest: DeploymentManifest;
  const client = getPublicClient();
  const ownerWallet = getWalletClient(OWNER_KEY);
  const agentWallet = getWalletClient(AGENT_KEY);
  const deployerWallet = getWalletClient(DEPLOYER_KEY);

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

  it("should sign and redeem a delegation for an ERC-20 transfer", async () => {
    const recipient = "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65" as Address; // Anvil #5

    // Build delegation: ownerAccount delegates to agent, with SpendingCap enforcer
    // SpendingCapEnforcer terms: abi.encode(uint256 cap, uint256 period)
    const spendingTerms = encodeAbiParameters(
      [{ type: "uint256" }, { type: "uint256" }],
      [parseEther("1000"), 86400n]
    );

    const delegation = {
      delegator: manifest.accounts.ownerAccount,
      delegate: manifest.accounts.agent,
      authority: zeroAddress,
      caveats: [
        {
          enforcer: manifest.contracts.SpendingCapEnforcer,
          terms: spendingTerms,
        },
      ],
      salt: 42n,
    };

    // Owner signs the delegation (smart contract account — signer is the owner EOA)
    const signature = await ownerWallet.signTypedData({
      domain,
      types: delegationTypes,
      primaryType: "Delegation",
      message: delegation,
    });

    // Build the action: transfer 100 USDC from ownerAccount to recipient
    const transferCalldata = encodeFunctionData({
      abi: MockERC20ABI,
      functionName: "transfer",
      args: [recipient, parseEther("100")],
    });

    const action = {
      target: manifest.contracts.MockERC20,
      value: 0n,
      callData: transferCalldata,
    };

    const signedDelegation = { ...delegation, signature };

    // Agent redeems the delegation
    const hash = await agentWallet.writeContract({
      address: manifest.contracts.IrisDelegationManager,
      abi: IrisDelegationManagerABI,
      functionName: "redeemDelegation",
      args: [[signedDelegation], action],
    });

    const receipt = await client.waitForTransactionReceipt({ hash });
    expect(receipt.status).toBe("success");

    // Verify the transfer happened
    const recipientBalance = await client.readContract({
      address: manifest.contracts.MockERC20,
      abi: MockERC20ABI,
      functionName: "balanceOf",
      args: [recipient],
    });
    expect(recipientBalance).toBe(parseEther("100"));
  });

  it("should block redemption when spending cap is exceeded", async () => {
    // Try to transfer more than the cap allows in a single tx
    const spendingTerms = encodeAbiParameters(
      [{ type: "uint256" }, { type: "uint256" }],
      [parseEther("50"), 86400n] // only 50 allowed
    );

    const delegation = {
      delegator: manifest.accounts.ownerAccount,
      delegate: manifest.accounts.agent,
      authority: zeroAddress,
      caveats: [
        {
          enforcer: manifest.contracts.SpendingCapEnforcer,
          terms: spendingTerms,
        },
      ],
      salt: 100n, // different salt for fresh delegation
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
        "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65" as Address,
        parseEther("200"), // exceeds 50 cap
      ],
    });

    const signedDelegation = { ...delegation, signature };

    await expect(
      agentWallet.writeContract({
        address: manifest.contracts.IrisDelegationManager,
        abi: IrisDelegationManagerABI,
        functionName: "redeemDelegation",
        args: [
          [signedDelegation],
          {
            target: manifest.contracts.MockERC20,
            value: 0n,
            callData: transferCalldata,
          },
        ],
      })
    ).rejects.toThrow();
  });

  it("should revoke a delegation and block subsequent redemption", async () => {
    const spendingTerms = encodeAbiParameters(
      [{ type: "uint256" }, { type: "uint256" }],
      [parseEther("500"), 86400n]
    );

    const delegation = {
      delegator: manifest.accounts.ownerAccount,
      delegate: manifest.accounts.agent,
      authority: zeroAddress,
      caveats: [
        {
          enforcer: manifest.contracts.SpendingCapEnforcer,
          terms: spendingTerms,
        },
      ],
      salt: 200n,
    };

    const signature = await ownerWallet.signTypedData({
      domain,
      types: delegationTypes,
      primaryType: "Delegation",
      message: delegation,
    });

    const signedDelegation = { ...delegation, signature };

    // Get delegation hash
    const delegationHash = await client.readContract({
      address: manifest.contracts.IrisDelegationManager,
      abi: IrisDelegationManagerABI,
      functionName: "getDelegationHash",
      args: [signedDelegation],
    });

    // Revoke (anyone can call revokeDelegation on the manager — it just sets the flag)
    const revokeHash = await ownerWallet.writeContract({
      address: manifest.contracts.IrisDelegationManager,
      abi: IrisDelegationManagerABI,
      functionName: "revokeDelegation",
      args: [delegationHash],
    });
    await client.waitForTransactionReceipt({ hash: revokeHash });

    // Verify revoked
    const isRevoked = await client.readContract({
      address: manifest.contracts.IrisDelegationManager,
      abi: IrisDelegationManagerABI,
      functionName: "revokedDelegations",
      args: [delegationHash],
    });
    expect(isRevoked).toBe(true);

    // Attempt to redeem the revoked delegation — should fail
    const transferCalldata = encodeFunctionData({
      abi: MockERC20ABI,
      functionName: "transfer",
      args: [
        "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65" as Address,
        parseEther("10"),
      ],
    });

    await expect(
      agentWallet.writeContract({
        address: manifest.contracts.IrisDelegationManager,
        abi: IrisDelegationManagerABI,
        functionName: "redeemDelegation",
        args: [
          [signedDelegation],
          {
            target: manifest.contracts.MockERC20,
            value: 0n,
            callData: transferCalldata,
          },
        ],
      })
    ).rejects.toThrow();
  });

  it("should block delegation from unauthorized signer", async () => {
    const delegation = {
      delegator: manifest.accounts.ownerAccount,
      delegate: manifest.accounts.agent,
      authority: zeroAddress,
      caveats: [],
      salt: 300n,
    };

    // Sign with deployer (NOT the owner) — should be rejected
    const badSignature = await deployerWallet.signTypedData({
      domain,
      types: delegationTypes,
      primaryType: "Delegation",
      message: delegation,
    });

    const signedDelegation = { ...delegation, signature: badSignature };

    const transferCalldata = encodeFunctionData({
      abi: MockERC20ABI,
      functionName: "transfer",
      args: [
        "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65" as Address,
        parseEther("1"),
      ],
    });

    await expect(
      agentWallet.writeContract({
        address: manifest.contracts.IrisDelegationManager,
        abi: IrisDelegationManagerABI,
        functionName: "redeemDelegation",
        args: [
          [signedDelegation],
          {
            target: manifest.contracts.MockERC20,
            value: 0n,
            callData: transferCalldata,
          },
        ],
      })
    ).rejects.toThrow();
  });

  it("should block reputation-gated delegation when reputation drops", async () => {
    // ReputationGateEnforcer terms: abi.encode(address oracle, uint256 agentId, uint256 minScore)
    const repTerms = encodeAbiParameters(
      [{ type: "address" }, { type: "uint256" }, { type: "uint256" }],
      [
        manifest.contracts.IrisReputationOracle,
        BigInt(manifest.agentId),
        80n, // require score >= 80
      ]
    );

    const delegation = {
      delegator: manifest.accounts.ownerAccount,
      delegate: manifest.accounts.agent,
      authority: zeroAddress,
      caveats: [
        {
          enforcer: manifest.contracts.ReputationGateEnforcer,
          terms: repTerms,
        },
      ],
      salt: 400n,
    };

    const signature = await ownerWallet.signTypedData({
      domain,
      types: delegationTypes,
      primaryType: "Delegation",
      message: delegation,
    });

    const signedDelegation = { ...delegation, signature };

    const transferCalldata = encodeFunctionData({
      abi: MockERC20ABI,
      functionName: "transfer",
      args: [
        "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65" as Address,
        parseEther("1"),
      ],
    });

    // Agent's reputation is 73 (from earlier test). Threshold is 80. Should fail.
    await expect(
      agentWallet.writeContract({
        address: manifest.contracts.IrisDelegationManager,
        abi: IrisDelegationManagerABI,
        functionName: "redeemDelegation",
        args: [
          [signedDelegation],
          {
            target: manifest.contracts.MockERC20,
            value: 0n,
            callData: transferCalldata,
          },
        ],
      })
    ).rejects.toThrow();

    // Now boost reputation above 80
    for (let i = 0; i < 5; i++) {
      const h = await deployerWallet.writeContract({
        address: manifest.contracts.IrisReputationOracle,
        abi: IrisReputationOracleABI,
        functionName: "submitFeedback",
        args: [BigInt(manifest.agentId), true],
      });
      await client.waitForTransactionReceipt({ hash: h });
    }
    // 73 + 10 = 83, now above 80

    // Retry — should succeed
    const hash = await agentWallet.writeContract({
      address: manifest.contracts.IrisDelegationManager,
      abi: IrisDelegationManagerABI,
      functionName: "redeemDelegation",
      args: [
        [signedDelegation],
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
});
