import { describe, it, expect, beforeAll } from "vitest";
import {
  encodeFunctionData,
  encodeAbiParameters,
  parseEther,
  type Address,
  zeroAddress,
  toFunctionSelector,
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

describe("FunctionSelectorEnforcer (E2E)", () => {
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

  it("should allow an allowed function selector (transfer)", async () => {
    const recipient = "0x976EA74026E726554dB657fA54763abd0C3a0aa9" as Address;

    // Allow only transfer(address,uint256) selector
    const transferSelector = toFunctionSelector("transfer(address,uint256)");
    const selectorTerms = encodeAbiParameters(
      [{ type: "bytes4[]" }],
      [[transferSelector]]
    );

    const delegation = {
      delegator: manifest.accounts.ownerAccount,
      delegate: manifest.accounts.agent,
      authority: zeroAddress,
      caveats: [
        {
          enforcer: manifest.contracts.FunctionSelectorEnforcer,
          terms: selectorTerms,
        },
      ],
      salt: 2000n,
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
      args: [recipient, parseEther("2")],
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

  it("should block a disallowed function selector (approve)", async () => {
    // Allow only transfer, try approve
    const transferSelector = toFunctionSelector("transfer(address,uint256)");
    const selectorTerms = encodeAbiParameters(
      [{ type: "bytes4[]" }],
      [[transferSelector]]
    );

    const delegation = {
      delegator: manifest.accounts.ownerAccount,
      delegate: manifest.accounts.agent,
      authority: zeroAddress,
      caveats: [
        {
          enforcer: manifest.contracts.FunctionSelectorEnforcer,
          terms: selectorTerms,
        },
      ],
      salt: 2001n,
    };

    const signature = await ownerWallet.signTypedData({
      domain,
      types: delegationTypes,
      primaryType: "Delegation",
      message: delegation,
    });

    const approveCalldata = encodeFunctionData({
      abi: MockERC20ABI,
      functionName: "approve",
      args: [
        "0x976EA74026E726554dB657fA54763abd0C3a0aa9" as Address,
        parseEther("1000"),
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
            callData: approveCalldata,
          },
        ],
      })
    ).rejects.toThrow();
  });
});
