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

describe("ContractWhitelistEnforcer (E2E)", () => {
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

  it("should allow execution against a whitelisted contract", async () => {
    const recipient = "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc" as Address;

    // Whitelist only the MockERC20 contract
    const whitelistTerms = encodeAbiParameters(
      [{ type: "address[]" }],
      [[manifest.contracts.MockERC20]]
    );

    const delegation = {
      delegator: manifest.accounts.ownerAccount,
      delegate: manifest.accounts.agent,
      authority: zeroAddress,
      caveats: [
        {
          enforcer: manifest.contracts.ContractWhitelistEnforcer,
          terms: whitelistTerms,
        },
      ],
      salt: 1000n,
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
      args: [recipient, parseEther("5")],
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

  it("should block execution against a non-whitelisted contract", async () => {
    // Whitelist only MockERC20, but try to call a different address
    const whitelistTerms = encodeAbiParameters(
      [{ type: "address[]" }],
      [[manifest.contracts.MockERC20]]
    );

    const delegation = {
      delegator: manifest.accounts.ownerAccount,
      delegate: manifest.accounts.agent,
      authority: zeroAddress,
      caveats: [
        {
          enforcer: manifest.contracts.ContractWhitelistEnforcer,
          terms: whitelistTerms,
        },
      ],
      salt: 1001n,
    };

    const signature = await ownerWallet.signTypedData({
      domain,
      types: delegationTypes,
      primaryType: "Delegation",
      message: delegation,
    });

    // Target the ApprovalQueue instead (not whitelisted)
    await expect(
      agentWallet.writeContract({
        address: manifest.contracts.IrisDelegationManager,
        abi: IrisDelegationManagerABI,
        functionName: "redeemDelegation",
        args: [
          [{ ...delegation, signature }],
          {
            target: manifest.contracts.IrisApprovalQueue,
            value: 0n,
            callData: "0x12345678" as `0x${string}`,
          },
        ],
      })
    ).rejects.toThrow();
  });
});
