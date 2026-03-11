export interface Agent {
  id: string;
  name: string;
  address: string;
  reputation: number;
  capabilities: string[];
  registeredAt: string;
  totalTransactions: number;
  totalVolume: string;
}

export interface Delegation {
  id: string;
  agentId: string;
  agentName: string;
  agentAddress: string;
  tier: number;
  tierName: string;
  spendingCap: number;
  spendingUsed: number;
  contractWhitelist: string[];
  timeWindowStart: string;
  timeWindowEnd: string;
  reputation: number;
  reputationRequired: number;
  createdAt: string;
  status: "active" | "expired" | "revoked" | "degraded";
}

export interface Activity {
  id: string;
  delegationId: string;
  type: "transfer" | "swap" | "approve" | "call";
  description: string;
  amount: string;
  timestamp: string;
  txHash: string;
  status: "success" | "reverted" | "blocked";
}

export interface TrustTier {
  tier: number;
  name: string;
  label: string;
  description: string;
  spendingCap: number;
  reputationRequired: number;
  permissions: string[];
  color: string;
}
