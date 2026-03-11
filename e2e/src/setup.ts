import {
  createPublicClient,
  createWalletClient,
  http,
  type Address,
  type PublicClient,
  type WalletClient,
} from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { foundry } from "viem/chains";
import { readFileSync } from "fs";
import { resolve } from "path";

// Anvil default private keys
export const DEPLOYER_KEY =
  "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" as const;
export const OWNER_KEY =
  "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d" as const;
export const AGENT_KEY =
  "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a" as const;

export const deployerAccount = privateKeyToAccount(DEPLOYER_KEY);
export const ownerAccount = privateKeyToAccount(OWNER_KEY);
export const agentAccount = privateKeyToAccount(AGENT_KEY);

const RPC_URL = "http://127.0.0.1:8545";

export function getPublicClient(): PublicClient {
  return createPublicClient({
    chain: foundry,
    transport: http(RPC_URL),
  });
}

export function getWalletClient(
  privateKey: `0x${string}`
): WalletClient {
  return createWalletClient({
    account: privateKeyToAccount(privateKey),
    chain: foundry,
    transport: http(RPC_URL),
  });
}

export interface DeploymentManifest {
  chainId: number;
  rpc: string;
  contracts: {
    IrisDelegationManager: Address;
    IrisAccountFactory: Address;
    IrisAgentRegistry: Address;
    IrisReputationOracle: Address;
    SpendingCapEnforcer: Address;
    ContractWhitelistEnforcer: Address;
    FunctionSelectorEnforcer: Address;
    TimeWindowEnforcer: Address;
    SingleTxCapEnforcer: Address;
    CooldownEnforcer: Address;
    ReputationGateEnforcer: Address;
    IrisApprovalQueue: Address;
    MockERC20: Address;
  };
  accounts: {
    deployer: Address;
    owner: Address;
    agent: Address;
    ownerAccount: Address;
  };
  agentId: number;
}

export function loadManifest(): DeploymentManifest {
  const manifestPath = resolve(
    import.meta.dirname,
    "../../deployments/local.json"
  );
  const raw = readFileSync(manifestPath, "utf-8");
  return JSON.parse(raw) as DeploymentManifest;
}
