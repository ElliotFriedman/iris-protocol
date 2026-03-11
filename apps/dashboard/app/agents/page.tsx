"use client";

import { useState } from "react";
import { useDemoMode } from "@/lib/demo-context";
import { MOCK_AGENTS, Agent } from "@/lib/mock-data";

function ReputationBar({ score }: { score: number }) {
  const color = score >= 75 ? "#00F0FF" : score >= 50 ? "#F0C000" : "#FF4444";
  return (
    <div className="flex items-center gap-3">
      <div className="flex-1 h-2 bg-[#1A1A2E] rounded-full overflow-hidden max-w-[100px]">
        <div
          className="h-full rounded-full transition-all"
          style={{ width: `${score}%`, backgroundColor: color }}
        />
      </div>
      <span className="font-mono text-sm font-bold" style={{ color }}>
        {score}
      </span>
    </div>
  );
}

function AgentDetail({ agent, onClose }: { agent: Agent; onClose: () => void }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
      <div className="bg-[#232340] rounded-2xl border border-white/10 max-w-lg w-full p-8">
        <div className="flex items-center justify-between mb-6">
          <h2 className="font-mono text-xl text-white font-bold">{agent.name}</h2>
          <button
            onClick={onClose}
            className="text-gray-500 hover:text-white transition-colors text-xl"
          >
            &times;
          </button>
        </div>

        <div className="space-y-4">
          <div>
            <p className="text-xs text-gray-500 font-mono mb-1">ADDRESS</p>
            <p className="font-mono text-sm text-gray-300 break-all">{agent.address}</p>
          </div>

          <div>
            <p className="text-xs text-gray-500 font-mono mb-1">REPUTATION</p>
            <ReputationBar score={agent.reputation} />
          </div>

          <div>
            <p className="text-xs text-gray-500 font-mono mb-1">CAPABILITIES</p>
            <div className="flex flex-wrap gap-2">
              {agent.capabilities.map((cap) => (
                <span key={cap} className="px-2 py-1 bg-[#7B2FBE]/10 text-[#7B2FBE] rounded text-xs font-mono">
                  {cap}
                </span>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="bg-[#1A1A2E] rounded-lg p-3">
              <p className="text-xs text-gray-500 mb-1">Transactions</p>
              <p className="font-mono text-lg text-white">{agent.totalTransactions.toLocaleString()}</p>
            </div>
            <div className="bg-[#1A1A2E] rounded-lg p-3">
              <p className="text-xs text-gray-500 mb-1">Volume</p>
              <p className="font-mono text-lg text-white">{agent.totalVolume}</p>
            </div>
          </div>

          <div>
            <p className="text-xs text-gray-500 font-mono mb-1">REGISTERED</p>
            <p className="text-sm text-gray-300">
              {new Date(agent.registeredAt).toLocaleDateString("en-US", {
                year: "numeric",
                month: "long",
                day: "numeric",
              })}
            </p>
          </div>
        </div>

        <div className="mt-6 flex gap-3">
          <a
            href={`/delegate?agent=${agent.id}`}
            className="flex-1 px-4 py-2.5 bg-[#7B2FBE] hover:bg-[#6B25A8] text-white text-sm font-medium rounded-lg transition-colors text-center"
          >
            Create Delegation
          </a>
          <button
            onClick={onClose}
            className="px-4 py-2.5 bg-[#1A1A2E] text-gray-400 text-sm font-medium rounded-lg border border-white/5 hover:border-white/10 transition-colors"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
}

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
