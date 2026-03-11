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
        <h1 className="font-mono text-3xl font-bold text-bone mb-2">Agent Registry</h1>
        <p className="text-ash">
          Registered agents from the ERC-8004 reputation registry.
        </p>
      </div>

      {agents.length === 0 ? (
        <div className="bg-onyx rounded-xl p-12 border border-graphite text-center">
          <p className="text-ash">No agents registered. Enable Demo Mode to view sample agents.</p>
        </div>
      ) : (
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
          {agents.map((agent) => (
            <button
              key={agent.id}
              onClick={() => setSelectedAgent(agent)}
              className="text-left bg-onyx rounded-xl p-6 border border-graphite hover:border-iris-purple/30 transition-all duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2"
            >
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-mono text-bone font-medium">{agent.name}</h3>
                <span className="font-mono text-xs text-ash">{agent.id}</span>
              </div>

              <p className="font-mono text-xs text-ash mb-4 truncate">
                {agent.address}
              </p>

              <div className="mb-4">
                <p className="text-xs text-ash mb-1">Reputation</p>
                <ReputationBar score={agent.reputation} />
              </div>

              <div className="flex flex-wrap gap-1.5 mb-4">
                {agent.capabilities.map((cap) => (
                  <span key={cap} className="px-2 py-0.5 bg-obsidian text-ash rounded text-xs font-mono">
                    {cap}
                  </span>
                ))}
              </div>

              <div className="flex items-center justify-between text-xs text-ash">
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
