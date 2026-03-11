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

describe("Multi-caveat stacking (E2E)", () => {
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

  it("should pass when all stacked caveats are satisfied", async () => {
    const recipient = "0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f" as Address;
    const block = await client.getBlock();
    const now = block.timestamp;

    // Caveat 1: Whitelist only MockERC20
    const whitelistTerms = encodeAbiParameters(
      [{ type: "address[]" }],
      [[manifest.contracts.MockERC20]]
    );

    // Caveat 2: Allow only transfer selector
    const transferSelector = toFunctionSelector("transfer(address,uint256)");
    const selectorTerms = encodeAbiParameters(
      [{ type: "bytes4[]" }],
      [[transferSelector]]
    );

    // Caveat 3: Valid time window (now - 1h to now + 1h)
    const timeTerms = encodeAbiParameters(
      [{ type: "uint256" }, { type: "uint256" }],
      [now - 3600n, now + 3600n]
    );

    // Caveat 4: Spending cap 10 ETH / day (checks ETH value, not ERC-20 — 0 value passes)
    const spendingTerms = encodeAbiParameters(
      [{ type: "uint256" }, { type: "uint256" }],
      [parseEther("10"), 86400n]
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
        {
          enforcer: manifest.contracts.FunctionSelectorEnforcer,
          terms: selectorTerms,
        },
        {
          enforcer: manifest.contracts.TimeWindowEnforcer,
          terms: timeTerms,
        },
        {
          enforcer: manifest.contracts.SpendingCapEnforcer,
          terms: spendingTerms,
        },
      ],
      salt: 5000n,
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
      args: [recipient, parseEther("3")],
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

  it("should fail when one stacked caveat is violated (wrong selector)", async () => {
    const block = await client.getBlock();
    const now = block.timestamp;

    // Whitelist MockERC20
    const whitelistTerms = encodeAbiParameters(
      [{ type: "address[]" }],
      [[manifest.contracts.MockERC20]]
    );

    // Allow only transfer
    const transferSelector = toFunctionSelector("transfer(address,uint256)");
    const selectorTerms = encodeAbiParameters(
      [{ type: "bytes4[]" }],
      [[transferSelector]]
    );

    // Valid time window
    const timeTerms = encodeAbiParameters(
      [{ type: "uint256" }, { type: "uint256" }],
      [now - 3600n, now + 3600n]
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
        {
          enforcer: manifest.contracts.FunctionSelectorEnforcer,
          terms: selectorTerms,
        },
        {
          enforcer: manifest.contracts.TimeWindowEnforcer,
          terms: timeTerms,
        },
      ],
      salt: 5001n,
    };

    const signature = await ownerWallet.signTypedData({
      domain,
      types: delegationTypes,
      primaryType: "Delegation",
      message: delegation,
    });

    // Call approve instead of transfer — selector enforcer should block
    const approveCalldata = encodeFunctionData({
      abi: MockERC20ABI,
      functionName: "approve",
      args: [
        "0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f" as Address,
        parseEther("100"),
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

  it("should fail when one stacked caveat is violated (wrong target)", async () => {
    const block = await client.getBlock();
    const now = block.timestamp;

    // Whitelist only MockERC20
    const whitelistTerms = encodeAbiParameters(
      [{ type: "address[]" }],
      [[manifest.contracts.MockERC20]]
    );

    // Allow transfer
    const transferSelector = toFunctionSelector("transfer(address,uint256)");
    const selectorTerms = encodeAbiParameters(
      [{ type: "bytes4[]" }],
      [[transferSelector]]
    );

    // Valid time window
    const timeTerms = encodeAbiParameters(
      [{ type: "uint256" }, { type: "uint256" }],
      [now - 3600n, now + 3600n]
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
        {
          enforcer: manifest.contracts.FunctionSelectorEnforcer,
          terms: selectorTerms,
        },
        {
          enforcer: manifest.contracts.TimeWindowEnforcer,
          terms: timeTerms,
        },
      ],
      salt: 5002n,
    };

    const signature = await ownerWallet.signTypedData({
      domain,
      types: delegationTypes,
      primaryType: "Delegation",
      message: delegation,
    });

    // Target the ApprovalQueue (not whitelisted)
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
            callData: "0xa9059cbb0000000000000000000000000000000000000000000000000000000000000001" as `0x${string}`,
          },
        ],
      })
    ).rejects.toThrow();
  });
});
