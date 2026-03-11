"use client";

import { useState, useEffect } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { useDemoMode } from "@/hooks/useDemoMode";
import { MOCK_AGENTS } from "@/constants/mock-data";
import { TRUST_TIERS } from "@/constants/trust-tiers";
import IrisAperture from "@/components/ui/IrisAperture";

export default function DelegatePage() {
  const { demoMode } = useDemoMode();
  const router = useRouter();
  const searchParams = useSearchParams();
  const [step, setStep] = useState(1);
  const [selectedAgentId, setSelectedAgentId] = useState<string | null>(null);

  useEffect(() => {
    const agentParam = searchParams.get("agent");
    if (agentParam && demoMode) {
      const found = MOCK_AGENTS.find((a) => a.id === agentParam);
      if (found) {
        setSelectedAgentId(agentParam);
        setStep(2);
      }
    }
  }, [searchParams, demoMode]);
  const [selectedTier, setSelectedTier] = useState(1);
  const [spendingCap, setSpendingCap] = useState<number | null>(null);
  const [approvalThreshold, setApprovalThreshold] = useState<number | null>(null);
  const [customWhitelist, setCustomWhitelist] = useState("");
  const [customDays, setCustomDays] = useState("");
  const [signing, setSigning] = useState(false);

  const agents = demoMode ? MOCK_AGENTS : [];
  const selectedAgent = agents.find((a) => a.id === selectedAgentId);
  const tier = TRUST_TIERS[selectedTier];

  const effectiveCap = spendingCap !== null ? spendingCap : tier.spendingCap;
  const effectiveThreshold = approvalThreshold !== null ? approvalThreshold : Math.round(tier.spendingCap * 0.8);
  const effectiveDays = customDays ? Number(customDays) : selectedTier === 1 ? 7 : selectedTier === 2 ? 30 : 90;

  const handleSign = () => {
    setSigning(true);
    setTimeout(() => {
      setSigning(false);
      router.push("/");
    }, 2000);
  };

  return (
    <div className="max-w-4xl mx-auto px-6 py-8">
      <div className="mb-8">
        <h1 className="font-mono text-3xl font-bold text-bone mb-2">Create Delegation</h1>
        <p className="text-ash">
          Grant an AI agent onchain permissions to act on your behalf.
        </p>
      </div>

      {/* Step indicator */}
      <div className="flex items-center gap-2 mb-10">
        {[1, 2, 3, 4].map((s) => (
          <div key={s} className="flex items-center gap-2">
            <button
              onClick={() => {
                if (s < step) setStep(s);
              }}
              className={`w-8 h-8 rounded-full font-mono text-sm flex items-center justify-center transition-all duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2 ${
                s === step
                  ? "bg-iris-purple text-bone"
                  : s < step
                  ? "bg-electric-cyan/20 text-electric-cyan cursor-pointer hover:bg-electric-cyan/30"
                  : "bg-onyx text-ash"
              }`}
            >
              {s}
            </button>
            {s < 4 && (
              <div
                className={`w-12 h-0.5 ${
                  s < step ? "bg-electric-cyan/30" : "bg-onyx"
                }`}
              />
            )}
          </div>
        ))}
        <span className="ml-4 text-sm text-ash font-mono hidden sm:inline">
          {step === 1 && "Select Agent"}
          {step === 2 && "Choose Trust Tier"}
          {step === 3 && "Configure Limits"}
          {step === 4 && "Review & Sign"}
        </span>
      </div>

      {/* Step 1: Select Agent */}
      {step === 1 && (
        <div>
          <h2 className="font-mono text-xl text-bone mb-6">Select an Agent</h2>
          {agents.length === 0 ? (
            <p className="text-ash">Enable Demo Mode to select from sample agents.</p>
          ) : (
            <div className="grid md:grid-cols-2 gap-4">
              {agents.map((agent) => {
                const repColor = agent.reputation >= 75 ? "var(--mint)" : agent.reputation >= 50 ? "var(--amber)" : "var(--signal-red)";
                return (
                  <button
                    key={agent.id}
                    onClick={() => {
                      setSelectedAgentId(agent.id);
                      setStep(2);
                    }}
                    className={`text-left p-5 rounded-xl border transition-all duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2 ${
                      selectedAgentId === agent.id
                        ? "bg-onyx border-iris-purple"
                        : "bg-onyx border-graphite hover:border-ash/30"
                    }`}
                  >
                    <div className="flex items-center justify-between mb-2">
                      <span className="font-mono text-bone font-medium">{agent.name}</span>
                      <span className="font-mono text-sm font-bold" style={{ color: repColor }}>
                        {agent.reputation}
                      </span>
                    </div>
                    <p className="font-mono text-xs text-ash truncate mb-3">{agent.address}</p>
                    <div className="flex flex-wrap gap-1">
                      {agent.capabilities.map((c) => (
                        <span key={c} className="px-2 py-0.5 bg-obsidian text-ash rounded text-xs font-mono">{c}</span>
                      ))}
                    </div>
                  </button>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* Step 2: Choose Trust Tier */}
      {step === 2 && (
        <div>
          <h2 className="font-mono text-xl text-bone mb-6">Choose Trust Tier</h2>
          <div className="flex flex-col items-center mb-10">
            <IrisAperture tier={selectedTier} size={220} />
            <p className="mt-4 font-mono text-sm text-ash">
              {TRUST_TIERS[selectedTier].label}
            </p>
          </div>

          <div className="grid md:grid-cols-4 gap-3 mb-8">
            {TRUST_TIERS.map((t) => {
              const meetsRep = selectedAgent ? selectedAgent.reputation >= t.reputationRequired : true;
              return (
                <button
                  key={t.tier}
                  onClick={() => meetsRep && setSelectedTier(t.tier)}
                  disabled={!meetsRep}
                  className={`text-left p-4 rounded-xl border transition-all duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2 ${
                    !meetsRep
                      ? "opacity-40 cursor-not-allowed bg-obsidian border-graphite"
                      : selectedTier === t.tier
                      ? "bg-onyx border-iris-purple shadow-lg shadow-iris-purple/10"
                      : "bg-obsidian border-graphite hover:border-ash/30"
                  }`}
                >
                  <div className="flex items-center gap-2 mb-2">
                    <span
                      className="font-mono text-xs px-2 py-0.5 rounded"
                      style={{ backgroundColor: `${t.color}20`, color: t.color }}
                    >
                      T{t.tier}
                    </span>
                    <span className="font-mono text-sm text-bone">{t.name}</span>
                  </div>
                  <p className="text-xs text-ash mb-2">{t.description}</p>
                  <ul className="space-y-1">
                    {t.permissions.map((p) => (
                      <li key={p} className="text-xs text-ash/60 flex items-start gap-1">
                        <span className="text-electric-cyan">&middot;</span> {p}
                      </li>
                    ))}
                  </ul>
                  {!meetsRep && (
                    <p className="text-xs text-signal-red mt-2 font-mono">
                      Requires reputation {t.reputationRequired}+
                    </p>
                  )}
                </button>
              );
            })}
          </div>

          <div className="flex gap-3">
            <button
              onClick={() => setStep(1)}
              className="px-5 py-2.5 bg-onyx text-ash text-sm rounded-lg border border-graphite hover:bg-white/10 hover:border-ash/30 transition-colors duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2"
            >
              Back
            </button>
            <button
              onClick={() => setStep(3)}
              className="px-5 py-2.5 bg-iris-purple hover:bg-iris-purple/80 text-bone text-sm font-medium rounded-lg transition-colors duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2"
            >
              Continue
            </button>
          </div>
        </div>
      )}

      {/* Step 3: Configure Limits */}
      {step === 3 && (
        <div>
          <h2 className="font-mono text-xl text-bone mb-6">Configure Limits</h2>
          <p className="text-ash text-sm mb-8">
            Set spending limits and approval thresholds within Tier {selectedTier} bounds.
          </p>

          <div className="space-y-8 max-w-lg">
            {/* Spending Cap Slider */}
            <div>
              <div className="flex items-center justify-between mb-3">
                <label className="text-xs text-ash font-mono uppercase tracking-wider">
                  Daily Spending Cap
                </label>
                <span className="font-mono text-lg text-bone font-bold">
                  ${effectiveCap}
                </span>
              </div>
              <div className="relative">
                <input
                  type="range"
                  min={0}
                  max={tier.spendingCap}
                  step={tier.spendingCap <= 100 ? 5 : tier.spendingCap <= 1000 ? 10 : 100}
                  value={effectiveCap}
                  onChange={(e) => setSpendingCap(Number(e.target.value))}
                  className="w-full h-2 rounded-full appearance-none cursor-pointer bg-obsidian
                    [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-5 [&::-webkit-slider-thumb]:h-5 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-electric-cyan [&::-webkit-slider-thumb]:shadow-[0_0_12px_var(--electric-cyan)]
                    [&::-moz-range-thumb]:w-5 [&::-moz-range-thumb]:h-5 [&::-moz-range-thumb]:rounded-full [&::-moz-range-thumb]:bg-electric-cyan [&::-moz-range-thumb]:border-0 [&::-moz-range-thumb]:shadow-[0_0_12px_var(--electric-cyan)]"
                />
                {/* Track fill */}
                <div
                  className="absolute top-0 left-0 h-2 rounded-full pointer-events-none bg-electric-cyan/40"
                  style={{ width: `${(effectiveCap / tier.spendingCap) * 100}%` }}
                />
              </div>
              <div className="flex justify-between mt-2">
                <span className="text-xs text-ash font-mono">$0</span>
                <span className="text-xs text-ash font-mono">Max: ${tier.spendingCap}/day</span>
              </div>
            </div>

            {/* Approval Threshold Slider */}
            <div>
              <div className="flex items-center justify-between mb-3">
                <label className="text-xs text-ash font-mono uppercase tracking-wider">
                  Approval Threshold
                </label>
                <span className="font-mono text-lg text-bone font-bold">
                  ${effectiveThreshold}
                </span>
              </div>
              <p className="text-xs text-ash/60 mb-3">
                Transactions above this amount require human approval.
              </p>
              <div className="relative">
                <input
                  type="range"
                  min={0}
                  max={effectiveCap}
                  step={effectiveCap <= 100 ? 5 : effectiveCap <= 1000 ? 10 : 100}
                  value={effectiveThreshold}
                  onChange={(e) => setApprovalThreshold(Number(e.target.value))}
                  className="w-full h-2 rounded-full appearance-none cursor-pointer bg-obsidian
                    [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-5 [&::-webkit-slider-thumb]:h-5 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-amber [&::-webkit-slider-thumb]:shadow-[0_0_12px_var(--amber)]
                    [&::-moz-range-thumb]:w-5 [&::-moz-range-thumb]:h-5 [&::-moz-range-thumb]:rounded-full [&::-moz-range-thumb]:bg-amber [&::-moz-range-thumb]:border-0 [&::-moz-range-thumb]:shadow-[0_0_12px_var(--amber)]"
                />
                <div
                  className="absolute top-0 left-0 h-2 rounded-full pointer-events-none bg-amber/40"
                  style={{ width: `${effectiveCap > 0 ? (effectiveThreshold / effectiveCap) * 100 : 0}%` }}
                />
              </div>
              <div className="flex justify-between mt-2">
                <span className="text-xs text-ash font-mono">$0 (approve all)</span>
                <span className="text-xs text-ash font-mono">${effectiveCap} (no approval)</span>
              </div>

              {/* Visual zone breakdown */}
              <div className="mt-4 bg-obsidian rounded-lg p-4 border border-graphite">
                <p className="text-xs text-ash font-mono uppercase tracking-wider mb-3">How it works</p>
                <div className="space-y-2">
                  <div className="flex items-center gap-3">
                    <div className="w-3 h-3 rounded-full bg-mint" />
                    <span className="text-xs text-bone">
                      Up to ${effectiveThreshold} — agent acts autonomously
                    </span>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="w-3 h-3 rounded-full bg-amber" />
                    <span className="text-xs text-bone">
                      ${effectiveThreshold} to ${effectiveCap} — requires your approval
                    </span>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="w-3 h-3 rounded-full bg-signal-red" />
                    <span className="text-xs text-bone">
                      Above ${effectiveCap} — blocked by spending cap
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* Contract Whitelist */}
            <div>
              <label className="block text-xs text-ash font-mono mb-2 uppercase tracking-wider">
                Contract Whitelist
              </label>
              <textarea
                placeholder="0x1234...abcd (one per line)"
                value={customWhitelist}
                onChange={(e) => setCustomWhitelist(e.target.value)}
                rows={3}
                className="w-full px-4 py-3 bg-obsidian border border-graphite rounded-lg text-bone font-mono text-sm focus:outline-none focus:border-iris-purple transition-colors duration-200 placeholder-ash/40 resize-none"
              />
            </div>

            {/* Time Window */}
            <div>
              <label className="block text-xs text-ash font-mono mb-2 uppercase tracking-wider">
                Time Window (days)
              </label>
              <input
                type="number"
                placeholder={`Default: ${selectedTier === 1 ? 7 : selectedTier === 2 ? 30 : 90} days`}
                value={customDays}
                onChange={(e) => setCustomDays(e.target.value)}
                className="w-full px-4 py-3 bg-obsidian border border-graphite rounded-lg text-bone font-mono text-sm focus:outline-none focus:border-iris-purple transition-colors duration-200 placeholder-ash/40"
              />
            </div>
          </div>

          <div className="flex gap-3 mt-8">
            <button
              onClick={() => setStep(2)}
              className="px-5 py-2.5 bg-onyx text-ash text-sm rounded-lg border border-graphite hover:bg-white/10 hover:border-ash/30 transition-colors duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2"
            >
              Back
            </button>
            <button
              onClick={() => setStep(4)}
              className="px-5 py-2.5 bg-iris-purple hover:bg-iris-purple/80 text-bone text-sm font-medium rounded-lg transition-colors duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2"
            >
              Review
            </button>
          </div>
        </div>
      )}

      {/* Step 4: Review & Sign */}
      {step === 4 && (
        <div>
          <h2 className="font-mono text-xl text-bone mb-6">Review &amp; Sign</h2>

          <div className="flex justify-center mb-8">
            <IrisAperture tier={selectedTier} size={160} />
          </div>

          <div className="bg-onyx rounded-xl p-6 border border-graphite max-w-lg mx-auto mb-8">
            <h3 className="font-mono text-sm text-ash uppercase tracking-wider mb-4">Delegation Parameters</h3>

            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-sm text-ash">Agent</span>
                <span className="text-sm text-bone font-mono">{selectedAgent?.name || "None"}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-ash">Address</span>
                <span className="text-sm text-bone/80 font-mono text-xs">
                  {selectedAgent?.address.slice(0, 14)}...{selectedAgent?.address.slice(-8)}
                </span>
              </div>
              <div className="border-t border-graphite" />
              <div className="flex justify-between">
                <span className="text-sm text-ash">Trust Tier</span>
                <span className="text-sm text-bone font-mono">T{selectedTier} — {tier.name}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-ash">Spending Cap</span>
                <span className="text-sm text-bone font-mono">${effectiveCap}/day</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-ash">Approval Threshold</span>
                <span className="text-sm text-amber font-mono">${effectiveThreshold}/tx</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-ash">Time Window</span>
                <span className="text-sm text-bone font-mono">{effectiveDays} days</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-ash">Min Reputation</span>
                <span className="text-sm text-bone font-mono">{tier.reputationRequired}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-ash">Agent Reputation</span>
                <span
                  className="text-sm font-mono font-bold"
                  style={{
                    color: (selectedAgent?.reputation || 0) >= 75
                      ? "var(--mint)"
                      : (selectedAgent?.reputation || 0) >= 50
                      ? "var(--amber)"
                      : "var(--signal-red)",
                  }}
                >
                  {selectedAgent?.reputation || "—"}
                </span>
              </div>
            </div>
          </div>

          <div className="flex gap-3 justify-center">
            <button
              onClick={() => setStep(3)}
              className="px-5 py-2.5 bg-onyx text-ash text-sm rounded-lg border border-graphite hover:bg-white/10 hover:border-ash/30 transition-colors duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2"
            >
              Back
            </button>
            <button
              onClick={handleSign}
              disabled={signing}
              className="px-8 py-2.5 bg-iris-purple hover:bg-iris-purple/80 text-bone text-sm font-medium rounded-lg transition-colors duration-200 disabled:opacity-50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2"
            >
              {signing ? "Signing..." : "Sign Delegation"}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
