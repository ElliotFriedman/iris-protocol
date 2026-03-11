"use client";

import { useState } from "react";
import { useDemoMode } from "@/hooks/useDemoMode";
import { MOCK_AGENTS } from "@/constants/mock-data";
import type { Agent } from "@/types";
import { ReputationBar } from "@/components/delegation/ReputationBadge";
import { AgentDetail } from "@/components/agents/AgentDetail";

export default function AgentsPage() {
  const { demoMode } = useDemoMode();
  const [selectedAgent, setSelectedAgent] = useState<Agent | null>(null);

  const agents = demoMode ? MOCK_AGENTS : [];

  return (
    <div className="max-w-7xl mx-auto px-6 py-8">
      <div className="mb-8">
        <h1 className="font-mono text-3xl font-bold text-white mb-2">Agent Registry</h1>
        <p className="text-gray-400">
          Registered agents from the ERC-8004 reputation registry.
        </p>
      </div>

      {agents.length === 0 ? (
        <div className="bg-[#232340] rounded-xl p-12 border border-white/5 text-center">
          <p className="text-gray-500">No agents registered. Enable Demo Mode to view sample agents.</p>
        </div>
      ) : (
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
          {agents.map((agent) => (
            <button
              key={agent.id}
              onClick={() => setSelectedAgent(agent)}
              className="text-left bg-[#232340] rounded-xl p-6 border border-white/5 hover:border-[#7B2FBE]/30 transition-all"
            >
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-mono text-white font-medium">{agent.name}</h3>
                <span className="font-mono text-xs text-gray-600">{agent.id}</span>
              </div>

              <p className="font-mono text-xs text-gray-500 mb-4 truncate">
                {agent.address}
              </p>

              <div className="mb-4">
                <p className="text-xs text-gray-500 mb-1">Reputation</p>
                <ReputationBar score={agent.reputation} />
              </div>

              <div className="flex flex-wrap gap-1.5 mb-4">
                {agent.capabilities.map((cap) => (
                  <span key={cap} className="px-2 py-0.5 bg-[#1A1A2E] text-gray-400 rounded text-xs font-mono">
                    {cap}
                  </span>
                ))}
              </div>

              <div className="flex items-center justify-between text-xs text-gray-500">
                <span>{agent.totalTransactions.toLocaleString()} txns</span>
                <span>{agent.totalVolume}</span>
              </div>
            </button>
          ))}
        </div>
      )}

      {selectedAgent && (
        <AgentDetail agent={selectedAgent} onClose={() => setSelectedAgent(null)} />
      )}
    </div>
  );
}
