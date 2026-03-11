"use client";

import { useState, useMemo, useCallback } from "react";
import { TRUST_TIERS } from "@/constants/trust-tiers";

export interface DelegationConfig {
  tier: number;
  dailyCap: number;
  singleTxCap: number;
  approvalThreshold: number;
  agentAddress: string;
  whitelistedContracts: string[];
  timeWindow: { start: number; end: number };
}

export function useDelegationConfig() {
  const [tier, setTier] = useState(1);
  const [dailyCap, setDailyCap] = useState(100);
  const [singleTxCap, setSingleTxCap] = useState(50);
  const [approvalThreshold, setApprovalThreshold] = useState(500);
  const [agentAddress, setAgentAddress] = useState("");
  const [whitelistedContracts, setWhitelistedContracts] = useState<string[]>(
    []
  );
  const [timeWindow, setTimeWindow] = useState({ start: 0, end: 0 });

  const tierData = TRUST_TIERS[tier];

  // When tier changes, reset caps to tier defaults
  const handleTierChange = useCallback((newTier: number) => {
    const newTierData = TRUST_TIERS[newTier];
    setTier(newTier);
    setDailyCap(newTierData.spendingCap);
    setSingleTxCap(Math.min(Math.round(newTierData.spendingCap * 0.1), 1000));
    setApprovalThreshold(Math.round(newTierData.spendingCap * 0.8));
    // Set default time window based on tier
    const now = Math.floor(Date.now() / 1000);
    const days = newTier === 0 ? 1 : newTier === 1 ? 7 : newTier === 2 ? 30 : 90;
    setTimeWindow({ start: now, end: now + days * 86400 });
  }, []);

  const isValidAddress = useMemo(() => {
    if (!agentAddress) return false;
    return /^0x[a-fA-F0-9]{40}$/.test(agentAddress);
  }, [agentAddress]);

  const isValid = useMemo(() => {
    return (
      isValidAddress &&
      dailyCap >= 0 &&
      dailyCap <= tierData.spendingCap &&
      singleTxCap >= 0 &&
      singleTxCap <= dailyCap &&
      approvalThreshold >= 0 &&
      timeWindow.end > timeWindow.start
    );
  }, [
    isValidAddress,
    dailyCap,
    singleTxCap,
    approvalThreshold,
    tierData.spendingCap,
    timeWindow,
  ]);

  const whitelistText = useMemo(
    () => whitelistedContracts.join("\n"),
    [whitelistedContracts]
  );

  const setWhitelistFromText = useCallback((text: string) => {
    const addresses = text
      .split("\n")
      .map((line) => line.trim())
      .filter((line) => line.length > 0);
    setWhitelistedContracts(addresses);
  }, []);

  const reset = useCallback(() => {
    setTier(1);
    setDailyCap(100);
    setSingleTxCap(50);
    setApprovalThreshold(500);
    setAgentAddress("");
    setWhitelistedContracts([]);
    setTimeWindow({ start: 0, end: 0 });
  }, []);

  const config: DelegationConfig = useMemo(
    () => ({
      tier,
      dailyCap,
      singleTxCap,
      approvalThreshold,
      agentAddress,
      whitelistedContracts,
      timeWindow,
    }),
    [
      tier,
      dailyCap,
      singleTxCap,
      approvalThreshold,
      agentAddress,
      whitelistedContracts,
      timeWindow,
    ]
  );

  return {
    // State
    tier,
    dailyCap,
    singleTxCap,
    approvalThreshold,
    agentAddress,
    whitelistedContracts,
    whitelistText,
    timeWindow,
    tierData,
    config,

    // Setters
    setTier: handleTierChange,
    setDailyCap,
    setSingleTxCap,
    setApprovalThreshold,
    setAgentAddress,
    setWhitelistedContracts,
    setWhitelistFromText,
    setTimeWindow,

    // Computed
    isValidAddress,
    isValid,

    // Actions
    reset,
  };
}
