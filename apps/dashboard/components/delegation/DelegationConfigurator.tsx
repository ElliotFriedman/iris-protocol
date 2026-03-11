"use client";

import { useMemo } from "react";
import { TRUST_TIERS } from "@/constants/trust-tiers";
import IrisAperture from "@/components/ui/IrisAperture";
import { useDelegationConfig } from "@/hooks/useDelegationConfig";

interface DelegationConfiguratorProps {
  onSubmit?: (config: ReturnType<typeof useDelegationConfig>["config"]) => void;
  walletConnected?: boolean;
}

const TIER_COLORS: Record<number, string> = {
  0: "#8A8A9A",
  1: "#00F0FF",
  2: "#7B2FBE",
  3: "#FFB800",
};

function formatDate(timestamp: number): string {
  if (!timestamp) return "";
  const d = new Date(timestamp * 1000);
  return d.toISOString().slice(0, 16);
}

function parseDate(value: string): number {
  if (!value) return 0;
  return Math.floor(new Date(value).getTime() / 1000);
}

export default function DelegationConfigurator({
  onSubmit,
  walletConnected = false,
}: DelegationConfiguratorProps) {
  const {
    tier,
    dailyCap,
    singleTxCap,
    approvalThreshold,
    agentAddress,
    whitelistText,
    timeWindow,
    tierData,
    config,
    setTier,
    setDailyCap,
    setSingleTxCap,
    setApprovalThreshold,
    setAgentAddress,
    setWhitelistFromText,
    setTimeWindow,
    isValidAddress,
    isValid,
  } = useDelegationConfig();

  const maxDailyCap = tierData.spendingCap;
  const maxSingleTx = Math.min(dailyCap, 1000);

  const tierDays = useMemo(() => {
    if (timeWindow.end > timeWindow.start) {
      return Math.round((timeWindow.end - timeWindow.start) / 86400);
    }
    return tier === 0 ? 1 : tier === 1 ? 7 : tier === 2 ? 30 : 90;
  }, [timeWindow, tier]);

  return (
    <div className="max-w-4xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <h1 className="font-mono text-3xl font-bold text-bone mb-2">
          Configure Delegation
        </h1>
        <p className="text-ash text-sm">
          Set trust parameters for an AI agent to act onchain on your behalf.
        </p>
      </div>

      <div className="grid lg:grid-cols-[1fr_340px] gap-8">
        {/* Left column: Configuration */}
        <div className="space-y-8">
          {/* Trust Tier Selector */}
          <section>
            <label className="block text-xs text-ash font-mono mb-4 uppercase tracking-wider">
              Trust Tier
            </label>
            <div className="flex flex-col items-center mb-6">
              <IrisAperture tier={tier} size={180} />
              <p className="mt-3 font-mono text-sm text-ash">
                {TRUST_TIERS[tier].label}
              </p>
            </div>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
              {TRUST_TIERS.map((t) => {
                const isSelected = tier === t.tier;
                const color = TIER_COLORS[t.tier];
                return (
                  <button
                    key={t.tier}
                    onClick={() => setTier(t.tier)}
                    className={`relative text-left p-4 rounded-xl border-2 transition-all duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2 ${
                      isSelected
                        ? "bg-onyx shadow-lg"
                        : "bg-obsidian border-graphite hover:border-ash/30"
                    }`}
                    style={{
                      borderColor: isSelected ? color : undefined,
                      boxShadow: isSelected
                        ? `0 0 20px ${color}15`
                        : undefined,
                    }}
                  >
                    <div className="flex items-center gap-2 mb-1.5">
                      <span
                        className="font-mono text-xs px-2 py-0.5 rounded font-bold"
                        style={{
                          backgroundColor: `${color}20`,
                          color: color,
                        }}
                      >
                        T{t.tier}
                      </span>
                    </div>
                    <span className="font-mono text-sm text-bone block mb-1">
                      {t.name}
                    </span>
                    <p className="text-xs text-ash leading-relaxed">
                      {t.description}
                    </p>
                  </button>
                );
              })}
            </div>
          </section>

          {/* Agent Address */}
          <section>
            <label className="block text-xs text-ash font-mono mb-2 uppercase tracking-wider">
              Agent Address
            </label>
            <input
              type="text"
              placeholder="0x742d35Cc6634C0532925a3b844Bc9e7595f2bD18"
              value={agentAddress}
              onChange={(e) => setAgentAddress(e.target.value)}
              className={`w-full px-4 py-3 bg-obsidian border rounded-lg text-bone font-mono text-sm focus:outline-none transition-colors duration-200 placeholder-ash/40 ${
                agentAddress && !isValidAddress
                  ? "border-signal-red focus:border-signal-red"
                  : "border-graphite focus:border-iris-purple"
              }`}
            />
            {agentAddress && !isValidAddress && (
              <p className="text-xs text-signal-red font-mono mt-1.5">
                Enter a valid Ethereum address (0x followed by 40 hex
                characters)
              </p>
            )}
          </section>

          {/* Daily Spending Cap */}
          <section>
            <div className="flex items-center justify-between mb-3">
              <label className="text-xs text-ash font-mono uppercase tracking-wider">
                Daily Spending Cap
              </label>
              <span className="font-mono text-lg text-bone font-bold">
                ${dailyCap.toLocaleString()}
              </span>
            </div>
            <div className="relative">
              <input
                type="range"
                min={0}
                max={maxDailyCap}
                step={maxDailyCap <= 100 ? 5 : maxDailyCap <= 1000 ? 10 : 100}
                value={dailyCap}
                onChange={(e) => setDailyCap(Number(e.target.value))}
                className="w-full h-2 rounded-full appearance-none cursor-pointer bg-obsidian
                  [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-5 [&::-webkit-slider-thumb]:h-5 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-electric-cyan [&::-webkit-slider-thumb]:shadow-[0_0_12px_var(--electric-cyan)]
                  [&::-moz-range-thumb]:w-5 [&::-moz-range-thumb]:h-5 [&::-moz-range-thumb]:rounded-full [&::-moz-range-thumb]:bg-electric-cyan [&::-moz-range-thumb]:border-0 [&::-moz-range-thumb]:shadow-[0_0_12px_var(--electric-cyan)]"
              />
              <div
                className="absolute top-0 left-0 h-2 rounded-full pointer-events-none bg-electric-cyan/40"
                style={{
                  width: `${maxDailyCap > 0 ? (dailyCap / maxDailyCap) * 100 : 0}%`,
                }}
              />
            </div>
            <div className="flex justify-between mt-2">
              <span className="text-xs text-ash font-mono">$0</span>
              <span className="text-xs text-ash font-mono">
                Max: ${maxDailyCap.toLocaleString()}/day
              </span>
            </div>
          </section>

          {/* Single Transaction Cap */}
          <section>
            <div className="flex items-center justify-between mb-3">
              <label className="text-xs text-ash font-mono uppercase tracking-wider">
                Single Tx Cap
              </label>
              <span className="font-mono text-lg text-bone font-bold">
                ${singleTxCap.toLocaleString()}
              </span>
            </div>
            <div className="relative">
              <input
                type="range"
                min={0}
                max={maxSingleTx}
                step={maxSingleTx <= 100 ? 1 : maxSingleTx <= 500 ? 5 : 10}
                value={singleTxCap}
                onChange={(e) => setSingleTxCap(Number(e.target.value))}
                className="w-full h-2 rounded-full appearance-none cursor-pointer bg-obsidian
                  [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-5 [&::-webkit-slider-thumb]:h-5 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-iris-purple [&::-webkit-slider-thumb]:shadow-[0_0_12px_var(--iris-purple)]
                  [&::-moz-range-thumb]:w-5 [&::-moz-range-thumb]:h-5 [&::-moz-range-thumb]:rounded-full [&::-moz-range-thumb]:bg-iris-purple [&::-moz-range-thumb]:border-0 [&::-moz-range-thumb]:shadow-[0_0_12px_var(--iris-purple)]"
              />
              <div
                className="absolute top-0 left-0 h-2 rounded-full pointer-events-none bg-iris-purple/40"
                style={{
                  width: `${maxSingleTx > 0 ? (singleTxCap / maxSingleTx) * 100 : 0}%`,
                }}
              />
            </div>
            <div className="flex justify-between mt-2">
              <span className="text-xs text-ash font-mono">$0</span>
              <span className="text-xs text-ash font-mono">
                Max: ${maxSingleTx.toLocaleString()}/tx
              </span>
            </div>
          </section>

          {/* Approval Threshold */}
          <section>
            <div className="flex items-center justify-between mb-2">
              <label className="text-xs text-ash font-mono uppercase tracking-wider">
                Approval Threshold
              </label>
              <span className="font-mono text-lg text-bone font-bold">
                ${approvalThreshold.toLocaleString()}
              </span>
            </div>
            <p className="text-xs text-ash/60 mb-3">
              Transactions above this amount require human approval.
            </p>
            <input
              type="number"
              min={0}
              max={dailyCap}
              value={approvalThreshold}
              onChange={(e) => setApprovalThreshold(Number(e.target.value))}
              className="w-full px-4 py-3 bg-obsidian border border-graphite rounded-lg text-bone font-mono text-sm focus:outline-none focus:border-iris-purple transition-colors duration-200 placeholder-ash/40"
              placeholder="Amount in USD"
            />
            {/* Visual zone breakdown */}
            <div className="mt-4 bg-obsidian rounded-lg p-4 border border-graphite">
              <p className="text-xs text-ash font-mono uppercase tracking-wider mb-3">
                How it works
              </p>
              <div className="space-y-2">
                <div className="flex items-center gap-3">
                  <div className="w-3 h-3 rounded-full bg-mint shrink-0" />
                  <span className="text-xs text-bone">
                    Up to ${approvalThreshold.toLocaleString()} — agent acts
                    autonomously
                  </span>
                </div>
                <div className="flex items-center gap-3">
                  <div className="w-3 h-3 rounded-full bg-amber shrink-0" />
                  <span className="text-xs text-bone">
                    ${approvalThreshold.toLocaleString()} to $
                    {dailyCap.toLocaleString()} — requires your approval
                  </span>
                </div>
                <div className="flex items-center gap-3">
                  <div className="w-3 h-3 rounded-full bg-signal-red shrink-0" />
                  <span className="text-xs text-bone">
                    Above ${dailyCap.toLocaleString()} — blocked by spending cap
                  </span>
                </div>
              </div>
            </div>
          </section>

          {/* Contract Whitelist */}
          <section>
            <label className="block text-xs text-ash font-mono mb-2 uppercase tracking-wider">
              Contract Whitelist{" "}
              <span className="text-ash/40 normal-case">(optional)</span>
            </label>
            <textarea
              placeholder={"0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984\n0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"}
              value={whitelistText}
              onChange={(e) => setWhitelistFromText(e.target.value)}
              rows={4}
              className="w-full px-4 py-3 bg-obsidian border border-graphite rounded-lg text-bone font-mono text-sm focus:outline-none focus:border-iris-purple transition-colors duration-200 placeholder-ash/40 resize-none"
            />
            <p className="text-xs text-ash/50 mt-1.5">
              One contract address per line. Leave empty to allow any contract.
            </p>
          </section>

          {/* Time Window */}
          <section>
            <label className="block text-xs text-ash font-mono mb-3 uppercase tracking-wider">
              Time Window
            </label>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs text-ash/60 mb-1.5">
                  Start
                </label>
                <input
                  type="datetime-local"
                  value={formatDate(timeWindow.start)}
                  onChange={(e) =>
                    setTimeWindow({
                      ...timeWindow,
                      start: parseDate(e.target.value),
                    })
                  }
                  className="w-full px-4 py-3 bg-obsidian border border-graphite rounded-lg text-bone font-mono text-sm focus:outline-none focus:border-iris-purple transition-colors duration-200 [color-scheme:dark]"
                />
              </div>
              <div>
                <label className="block text-xs text-ash/60 mb-1.5">End</label>
                <input
                  type="datetime-local"
                  value={formatDate(timeWindow.end)}
                  onChange={(e) =>
                    setTimeWindow({
                      ...timeWindow,
                      end: parseDate(e.target.value),
                    })
                  }
                  className="w-full px-4 py-3 bg-obsidian border border-graphite rounded-lg text-bone font-mono text-sm focus:outline-none focus:border-iris-purple transition-colors duration-200 [color-scheme:dark]"
                />
              </div>
            </div>
            {timeWindow.start > 0 && timeWindow.end > 0 && (
              <p className="text-xs text-ash/50 mt-2 font-mono">
                Duration: {tierDays} day{tierDays !== 1 ? "s" : ""}
              </p>
            )}
          </section>
        </div>

        {/* Right column: Summary Card */}
        <div className="lg:sticky lg:top-8 lg:self-start">
          <div className="bg-onyx rounded-xl p-6 border border-graphite">
            <h3 className="font-mono text-sm text-ash uppercase tracking-wider mb-5">
              Delegation Summary
            </h3>

            <div className="flex justify-center mb-5">
              <IrisAperture tier={tier} size={100} />
            </div>

            <div className="space-y-3">
              <SummaryRow
                label="Trust Tier"
                value={`T${tier} — ${tierData.name}`}
                valueColor={TIER_COLORS[tier]}
              />
              <SummaryRow
                label="Agent"
                value={
                  agentAddress
                    ? `${agentAddress.slice(0, 8)}...${agentAddress.slice(-6)}`
                    : "Not set"
                }
                valueColor={agentAddress ? undefined : "#8A8A9A"}
              />
              <div className="border-t border-graphite" />
              <SummaryRow
                label="Daily Cap"
                value={`$${dailyCap.toLocaleString()}/day`}
              />
              <SummaryRow
                label="Single Tx Cap"
                value={`$${singleTxCap.toLocaleString()}/tx`}
              />
              <SummaryRow
                label="Approval Above"
                value={`$${approvalThreshold.toLocaleString()}`}
                valueColor="#FFB800"
              />
              <div className="border-t border-graphite" />
              <SummaryRow
                label="Contracts"
                value={
                  whitelistText
                    ? `${whitelistText.split("\n").filter((l) => l.trim()).length} whitelisted`
                    : "Any contract"
                }
              />
              <SummaryRow
                label="Duration"
                value={
                  timeWindow.end > timeWindow.start
                    ? `${tierDays} day${tierDays !== 1 ? "s" : ""}`
                    : "Not set"
                }
              />
              <SummaryRow
                label="Min Reputation"
                value={`${tierData.reputationRequired}`}
              />
            </div>

            <button
              onClick={() => onSubmit?.(config)}
              disabled={!isValid || !walletConnected}
              className="mt-6 w-full px-6 py-3 bg-iris-purple hover:bg-iris-purple/80 text-bone text-sm font-mono font-medium rounded-lg transition-colors duration-200 disabled:opacity-40 disabled:cursor-not-allowed focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2"
            >
              {!walletConnected
                ? "Connect Wallet"
                : !isValid
                  ? "Complete Configuration"
                  : "Create Delegation"}
            </button>

            {!walletConnected && (
              <p className="text-xs text-ash/50 text-center mt-2 font-mono">
                Wallet connection required to sign delegation
              </p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function SummaryRow({
  label,
  value,
  valueColor,
}: {
  label: string;
  value: string;
  valueColor?: string;
}) {
  return (
    <div className="flex justify-between items-center">
      <span className="text-sm text-ash">{label}</span>
      <span
        className="text-sm font-mono font-medium"
        style={{ color: valueColor || "#E8E6E1" }}
      >
        {value}
      </span>
    </div>
  );
}
