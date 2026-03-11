"use client";

import { useState, useEffect } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { useDemoMode } from "@/hooks/useDemoMode";
import { MOCK_AGENTS } from "@/constants/mock-data";
import { TRUST_TIERS } from "@/constants/trust-tiers";
import IrisAperture from "@/components/ui/IrisAperture";
import DelegationConfigurator from "@/components/delegation/DelegationConfigurator";
import type { DelegationConfig } from "@/hooks/useDelegationConfig";

export default function DelegatePage() {
  const { demoMode } = useDemoMode();
  const router = useRouter();
  const searchParams = useSearchParams();
  const [step, setStep] = useState(1);
  const [selectedAgentId, setSelectedAgentId] = useState<string | null>(null);
  const [signing, setSigning] = useState(false);

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

  const agents = demoMode ? MOCK_AGENTS : [];
  const selectedAgent = agents.find((a) => a.id === selectedAgentId);

  const handleCreateDelegation = (config: DelegationConfig) => {
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
        {[1, 2].map((s) => (
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
            {s < 2 && (
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
          {step === 2 && "Configure Delegation"}
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

      {/* Step 2: Configure Delegation */}
      {step === 2 && (
        <div>
          {selectedAgent && (
            <div className="bg-onyx rounded-xl p-4 border border-graphite mb-8 flex items-center gap-4">
              <IrisAperture tier={1} size={48} />
              <div>
                <p className="font-mono text-bone font-medium">{selectedAgent.name}</p>
                <p className="font-mono text-xs text-ash">{selectedAgent.address}</p>
              </div>
              <button
                onClick={() => setStep(1)}
                className="ml-auto text-xs text-ash hover:text-bone font-mono transition-colors"
              >
                Change
              </button>
            </div>
          )}

          <DelegationConfigurator
            onSubmit={handleCreateDelegation}
            walletConnected={demoMode}
          />
        </div>
      )}

      {signing && (
        <div className="fixed inset-0 bg-void/80 flex items-center justify-center z-50">
          <div className="bg-onyx rounded-xl p-8 border border-graphite text-center">
            <IrisAperture tier={2} size={80} animated />
            <p className="font-mono text-bone mt-4">Signing delegation...</p>
            <p className="text-xs text-ash mt-2">Confirm in your wallet</p>
          </div>
        </div>
      )}
    </div>
  );
}
