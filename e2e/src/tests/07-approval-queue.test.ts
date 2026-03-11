import { describe, it, expect, beforeAll } from "vitest";
import {
  encodeFunctionData,
  parseEther,
  type Address,
  zeroAddress,
  getAddress,
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
  IrisApprovalQueueABI,
  MockERC20ABI,
} from "../abis.js";

describe("IrisApprovalQueue (E2E)", () => {
  let manifest: DeploymentManifest;
  const client = getPublicClient();
  const ownerWallet = getWalletClient(OWNER_KEY);
  const agentWallet = getWalletClient(AGENT_KEY);

  beforeAll(() => {
    manifest = loadManifest();
  });

  it("should submit an approval request and query it", async () => {
    const recipient = "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720" as Address;
    const transferCalldata = encodeFunctionData({
      abi: MockERC20ABI,
      functionName: "transfer",
      args: [recipient, parseEther("500")],
    });

    const fakeDelegationHash =
      "0x1111111111111111111111111111111111111111111111111111111111111111" as `0x${string}`;

    // Agent submits an approval request
    const hash = await agentWallet.writeContract({
      address: manifest.contracts.IrisApprovalQueue,
      abi: IrisApprovalQueueABI,
      functionName: "submitRequest",
      args: [
        manifest.contracts.MockERC20,
        transferCalldata,
        0n,
        fakeDelegationHash,
        manifest.accounts.ownerAccount,
      ],
    });

    const receipt = await client.waitForTransactionReceipt({ hash });
    expect(receipt.status).toBe("success");

    // Get pending requests for the owner account
    const pending = await client.readContract({
      address: manifest.contracts.IrisApprovalQueue,
      abi: IrisApprovalQueueABI,
      functionName: "getPendingRequests",
      args: [manifest.accounts.ownerAccount],
    });

    expect(pending.length).toBeGreaterThan(0);

    // Query the request details
    const requestId = pending[pending.length - 1];
    const request = await client.readContract({
      address: manifest.contracts.IrisApprovalQueue,
      abi: IrisApprovalQueueABI,
      functionName: "getRequest",
      args: [requestId],
    });

    expect(getAddress(request.agent)).toBe(
      getAddress(manifest.accounts.agent)
    );
    expect(getAddress(request.target)).toBe(
      getAddress(manifest.contracts.MockERC20)
    );
    expect(request.approved).toBe(false);
    expect(request.rejected).toBe(false);
  });

  it("should allow the delegator to approve a request", async () => {
    const transferCalldata = encodeFunctionData({
      abi: MockERC20ABI,
      functionName: "transfer",
      args: [
        "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720" as Address,
        parseEther("100"),
      ],
    });

    const fakeDelegationHash =
      "0x2222222222222222222222222222222222222222222222222222222222222222" as `0x${string}`;

    // Submit
    const submitHash = await agentWallet.writeContract({
      address: manifest.contracts.IrisApprovalQueue,
      abi: IrisApprovalQueueABI,
      functionName: "submitRequest",
      args: [
        manifest.contracts.MockERC20,
        transferCalldata,
        0n,
        fakeDelegationHash,
        manifest.accounts.owner, // delegator is the owner EOA
      ],
    });
    await client.waitForTransactionReceipt({ hash: submitHash });

    // Get the request ID
    const pending = await client.readContract({
      address: manifest.contracts.IrisApprovalQueue,
      abi: IrisApprovalQueueABI,
      functionName: "getPendingRequests",
      args: [manifest.accounts.owner],
    });
    const requestId = pending[pending.length - 1];

    // Owner approves
    const approveHash = await ownerWallet.writeContract({
      address: manifest.contracts.IrisApprovalQueue,
      abi: IrisApprovalQueueABI,
      functionName: "approveRequest",
      args: [requestId],
    });
    const receipt = await client.waitForTransactionReceipt({
      hash: approveHash,
    });
    expect(receipt.status).toBe("success");

    // Verify approved
    const request = await client.readContract({
      address: manifest.contracts.IrisApprovalQueue,
      abi: IrisApprovalQueueABI,
      functionName: "getRequest",
      args: [requestId],
    });
    expect(request.approved).toBe(true);
    expect(request.rejected).toBe(false);
  });

  it("should allow the delegator to reject a request", async () => {
    const transferCalldata = encodeFunctionData({
      abi: MockERC20ABI,
      functionName: "transfer",
      args: [
        "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720" as Address,
        parseEther("100"),
      ],
    });

    const fakeDelegationHash =
      "0x3333333333333333333333333333333333333333333333333333333333333333" as `0x${string}`;

    // Submit
    const submitHash = await agentWallet.writeContract({
      address: manifest.contracts.IrisApprovalQueue,
      abi: IrisApprovalQueueABI,
      functionName: "submitRequest",
      args: [
        manifest.contracts.MockERC20,
        transferCalldata,
        0n,
        fakeDelegationHash,
        manifest.accounts.owner,
      ],
    });
    await client.waitForTransactionReceipt({ hash: submitHash });

    const pending = await client.readContract({
      address: manifest.contracts.IrisApprovalQueue,
      abi: IrisApprovalQueueABI,
      functionName: "getPendingRequests",
      args: [manifest.accounts.owner],
    });
    const requestId = pending[pending.length - 1];

    // Owner rejects
    const rejectHash = await ownerWallet.writeContract({
      address: manifest.contracts.IrisApprovalQueue,
      abi: IrisApprovalQueueABI,
      functionName: "rejectRequest",
      args: [requestId],
    });
    const receipt = await client.waitForTransactionReceipt({
      hash: rejectHash,
    });
    expect(receipt.status).toBe("success");

    const request = await client.readContract({
      address: manifest.contracts.IrisApprovalQueue,
      abi: IrisApprovalQueueABI,
      functionName: "getRequest",
      args: [requestId],
    });
    expect(request.approved).toBe(false);
    expect(request.rejected).toBe(true);
  });

  it("should reject approval from non-delegator", async () => {
    const transferCalldata = encodeFunctionData({
      abi: MockERC20ABI,
      functionName: "transfer",
      args: [
        "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720" as Address,
        parseEther("50"),
      ],
    });

    const fakeDelegationHash =
      "0x4444444444444444444444444444444444444444444444444444444444444444" as `0x${string}`;

    // Submit (agent submits, owner is delegator)
    const submitHash = await agentWallet.writeContract({
      address: manifest.contracts.IrisApprovalQueue,
      abi: IrisApprovalQueueABI,
      functionName: "submitRequest",
      args: [
        manifest.contracts.MockERC20,
        transferCalldata,
        0n,
        fakeDelegationHash,
        manifest.accounts.owner,
      ],
    });
    await client.waitForTransactionReceipt({ hash: submitHash });

    const pending = await client.readContract({
      address: manifest.contracts.IrisApprovalQueue,
      abi: IrisApprovalQueueABI,
      functionName: "getPendingRequests",
      args: [manifest.accounts.owner],
    });
    const requestId = pending[pending.length - 1];

    // Agent tries to approve (not the delegator) — should fail
    await expect(
      agentWallet.writeContract({
        address: manifest.contracts.IrisApprovalQueue,
        abi: IrisApprovalQueueABI,
        functionName: "approveRequest",
        args: [requestId],
      })
    ).rejects.toThrow();
  });
});
