"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useDemoMode } from "@/lib/demo-context";
import { MOCK_AGENTS, TRUST_TIERS } from "@/lib/mock-data";
import IrisAperture from "@/components/IrisAperture";

export default function DelegatePage() {
  const { demoMode } = useDemoMode();
  const router = useRouter();
  const [step, setStep] = useState(1);
  const [selectedAgentId, setSelectedAgentId] = useState<string | null>(null);
  const [selectedTier, setSelectedTier] = useState(1);
  const [customCap, setCustomCap] = useState("");
  const [customWhitelist, setCustomWhitelist] = useState("");
  const [customDays, setCustomDays] = useState("");
  const [signing, setSigning] = useState(false);

  const agents = demoMode ? MOCK_AGENTS : [];
  const selectedAgent = agents.find((a) => a.id === selectedAgentId);
  const tier = TRUST_TIERS[selectedTier];

  const effectiveCap = customCap ? Number(customCap) : tier.spendingCap;
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
        <h1 className="font-mono text-3xl font-bold text-white mb-2">Create Delegation</h1>
        <p className="text-gray-400">
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
              className={`w-8 h-8 rounded-full font-mono text-sm flex items-center justify-center transition-all ${
                s === step
                  ? "bg-[#7B2FBE] text-white"
                  : s < step
                  ? "bg-[#00F0FF]/20 text-[#00F0FF] cursor-pointer"
                  : "bg-[#232340] text-gray-600"
              }`}
            >
              {s}
            </button>
            {s < 4 && (
              <div
                className={`w-12 h-0.5 ${
                  s < step ? "bg-[#00F0FF]/30" : "bg-[#232340]"
                }`}
              />
            )}
          </div>
        ))}
        <span className="ml-4 text-sm text-gray-500 font-mono">
          {step === 1 && "Select Agent"}
          {step === 2 && "Choose Trust Tier"}
          {step === 3 && "Customize Caveats"}
          {step === 4 && "Review & Sign"}
        </span>
      </div>

      {/* Step 1: Select Agent */}
      {step === 1 && (
        <div>
          <h2 className="font-mono text-xl text-white mb-6">Select an Agent</h2>
          {agents.length === 0 ? (
            <p className="text-gray-500">Enable Demo Mode to select from sample agents.</p>
          ) : (
            <div className="grid md:grid-cols-2 gap-4">
              {agents.map((agent) => {
                const repColor = agent.reputation >= 75 ? "#00F0FF" : agent.reputation >= 50 ? "#F0C000" : "#FF4444";
                return (
                  <button
                    key={agent.id}
                    onClick={() => {
                      setSelectedAgentId(agent.id);
                      setStep(2);
                    }}
                    className={`text-left p-5 rounded-xl border transition-all ${
                      selectedAgentId === agent.id
                        ? "bg-[#232340] border-[#7B2FBE]"
                        : "bg-[#232340] border-white/5 hover:border-white/10"
                    }`}
                  >
                    <div className="flex items-center justify-between mb-2">
                      <span className="font-mono text-white font-medium">{agent.name}</span>
                      <span className="font-mono text-sm font-bold" style={{ color: repColor }}>
                        {agent.reputation}
                      </span>
                    </div>
                    <p className="font-mono text-xs text-gray-500 truncate mb-3">{agent.address}</p>
                    <div className="flex flex-wrap gap-1">
                      {agent.capabilities.map((c) => (
                        <span key={c} className="px-2 py-0.5 bg-[#1A1A2E] text-gray-400 rounded text-xs font-mono">{c}</span>
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
          <h2 className="font-mono text-xl text-white mb-6">Choose Trust Tier</h2>
          <div className="flex flex-col items-center mb-10">
            <IrisAperture tier={selectedTier} size={220} />
            <p className="mt-4 font-mono text-sm text-gray-400">
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
                  className={`text-left p-4 rounded-xl border transition-all ${
                    !meetsRep
                      ? "opacity-40 cursor-not-allowed bg-[#1A1A2E] border-white/5"
                      : selectedTier === t.tier
                      ? "bg-[#232340] border-[#7B2FBE] shadow-lg shadow-purple-500/10"
                      : "bg-[#1A1A2E] border-white/5 hover:border-white/10"
                  }`}
                >
                  <div className="flex items-center gap-2 mb-2">
                    <span
                      className="font-mono text-xs px-2 py-0.5 rounded"
                      style={{ backgroundColor: `${t.color}20`, color: t.color }}
                    >
                      T{t.tier}
                    </span>
                    <span className="font-mono text-sm text-white">{t.name}</span>
                  </div>
                  <p className="text-xs text-gray-500 mb-2">{t.description}</p>
                  <ul className="space-y-1">
                    {t.permissions.map((p) => (
                      <li key={p} className="text-xs text-gray-600 flex items-start gap-1">
                        <span className="text-[#00F0FF]">&middot;</span> {p}
                      </li>
                    ))}
                  </ul>
                  {!meetsRep && (
                    <p className="text-xs text-red-400 mt-2 font-mono">
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
              className="px-5 py-2.5 bg-[#232340] text-gray-400 text-sm rounded-lg border border-white/5"
            >
              Back
            </button>
            <button
              onClick={() => setStep(3)}
              className="px-5 py-2.5 bg-[#7B2FBE] hover:bg-[#6B25A8] text-white text-sm font-medium rounded-lg transition-colors"
            >
              Continue
            </button>
          </div>
        </div>
      )}

      {/* Step 3: Customize Caveats */}
      {step === 3 && (
        <div>
          <h2 className="font-mono text-xl text-white mb-6">Customize Caveats</h2>
          <p className="text-gray-400 text-sm mb-6">
            Adjust within Tier {selectedTier} bounds, or leave defaults.
          </p>

          <div className="space-y-6 max-w-md">
            <div>
              <label className="block text-xs text-gray-500 font-mono mb-2 uppercase tracking-wider">
                Spending Cap (USD/day)
              </label>
              <input
                type="number"
                placeholder={`Default: $${tier.spendingCap}`}
                value={customCap}
                onChange={(e) => setCustomCap(e.target.value)}
                max={tier.spendingCap}
                className="w-full px-4 py-3 bg-[#1A1A2E] border border-white/10 rounded-lg text-white font-mono text-sm focus:outline-none focus:border-[#7B2FBE] transition-colors placeholder-gray-600"
              />
              <p className="text-xs text-gray-600 mt-1">Max: ${tier.spendingCap}/day for Tier {selectedTier}</p>
            </div>

            <div>
              <label className="block text-xs text-gray-500 font-mono mb-2 uppercase tracking-wider">
                Contract Whitelist
              </label>
              <textarea
                placeholder="0x1234...abcd (one per line)"
                value={customWhitelist}
                onChange={(e) => setCustomWhitelist(e.target.value)}
                rows={3}
                className="w-full px-4 py-3 bg-[#1A1A2E] border border-white/10 rounded-lg text-white font-mono text-sm focus:outline-none focus:border-[#7B2FBE] transition-colors placeholder-gray-600 resize-none"
              />
            </div>

            <div>
              <label className="block text-xs text-gray-500 font-mono mb-2 uppercase tracking-wider">
                Time Window (days)
              </label>
              <input
                type="number"
                placeholder={`Default: ${selectedTier === 1 ? 7 : selectedTier === 2 ? 30 : 90} days`}
                value={customDays}
                onChange={(e) => setCustomDays(e.target.value)}
                className="w-full px-4 py-3 bg-[#1A1A2E] border border-white/10 rounded-lg text-white font-mono text-sm focus:outline-none focus:border-[#7B2FBE] transition-colors placeholder-gray-600"
              />
            </div>
          </div>

          <div className="flex gap-3 mt-8">
            <button
              onClick={() => setStep(2)}
              className="px-5 py-2.5 bg-[#232340] text-gray-400 text-sm rounded-lg border border-white/5"
            >
              Back
            </button>
            <button
              onClick={() => setStep(4)}
              className="px-5 py-2.5 bg-[#7B2FBE] hover:bg-[#6B25A8] text-white text-sm font-medium rounded-lg transition-colors"
            >
              Review
            </button>
          </div>
        </div>
      )}

      {/* Step 4: Review & Sign */}
      {step === 4 && (
        <div>
          <h2 className="font-mono text-xl text-white mb-6">Review &amp; Sign</h2>

          <div className="flex justify-center mb-8">
            <IrisAperture tier={selectedTier} size={160} />
          </div>

          <div className="bg-[#232340] rounded-xl p-6 border border-white/5 max-w-lg mx-auto mb-8">
            <h3 className="font-mono text-sm text-gray-500 uppercase tracking-wider mb-4">Delegation Parameters</h3>

            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-sm text-gray-500">Agent</span>
                <span className="text-sm text-white font-mono">{selectedAgent?.name || "None"}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-500">Address</span>
                <span className="text-sm text-gray-300 font-mono text-xs">
                  {selectedAgent?.address.slice(0, 14)}...{selectedAgent?.address.slice(-8)}
                </span>
              </div>
              <div className="border-t border-white/5" />
              <div className="flex justify-between">
                <span className="text-sm text-gray-500">Trust Tier</span>
                <span className="text-sm text-white font-mono">T{selectedTier} — {tier.name}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-500">Spending Cap</span>
                <span className="text-sm text-white font-mono">${effectiveCap}/day</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-500">Time Window</span>
                <span className="text-sm text-white font-mono">{effectiveDays} days</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-500">Min Reputation</span>
                <span className="text-sm text-white font-mono">{tier.reputationRequired}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-500">Agent Reputation</span>
                <span
                  className="text-sm font-mono font-bold"
                  style={{
                    color: (selectedAgent?.reputation || 0) >= 75 ? "#00F0FF" : (selectedAgent?.reputation || 0) >= 50 ? "#F0C000" : "#FF4444",
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
              className="px-5 py-2.5 bg-[#232340] text-gray-400 text-sm rounded-lg border border-white/5"
            >
              Back
            </button>
            <button
              onClick={handleSign}
              disabled={signing}
              className="px-8 py-2.5 bg-[#7B2FBE] hover:bg-[#6B25A8] text-white text-sm font-medium rounded-lg transition-colors disabled:opacity-50"
            >
              {signing ? "Signing..." : "Sign Delegation"}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
