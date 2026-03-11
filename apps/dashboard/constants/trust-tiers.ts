import type { TrustTier } from "@/types";

export const TRUST_TIERS: TrustTier[] = [
  {
    tier: 0,
    name: "View Only",
    label: "Iris Closed",
    description: "Agent reads onchain state only. Human signs every transaction.",
    spendingCap: 0,
    reputationRequired: 0,
    permissions: ["Read balances", "Read positions", "Read prices"],
    color: "#9494A6",
  },
  {
    tier: 1,
    name: "Supervised",
    label: "Iris Narrow",
    description: "Agent spends up to $100/day. Excess requires human co-signature.",
    spendingCap: 100,
    reputationRequired: 50,
    permissions: ["Spend up to $100/day", "Whitelisted contracts only", "7-day time window", "Co-sign for excess"],
    color: "#00F0FF",
  },
  {
    tier: 2,
    name: "Autonomous",
    label: "Iris Wide",
    description: "Broader bounds with reputation-gating. Minimum score 75 required.",
    spendingCap: 1000,
    reputationRequired: 75,
    permissions: ["Spend up to $1,000/day", "Expanded contract list", "30-day time window", "Reputation-gated"],
    color: "#7B2FBE",
  },
  {
    tier: 3,
    name: "Full Delegation",
    label: "Iris Open",
    description: "Maximum autonomy. Emergency revocation always available.",
    spendingCap: 10000,
    reputationRequired: 90,
    permissions: ["Unrestricted spending", "Any contract interaction", "90-day time window", "Emergency revoke available"],
    color: "#FFB800",
  },
];
