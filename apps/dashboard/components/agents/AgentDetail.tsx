"use client";

import { useEffect } from "react";
import Link from "next/link";
import type { Agent } from "@/types";
import { ReputationBar } from "@/components/delegation/ReputationBadge";

export function AgentDetail({ agent, onClose }: { agent: Agent; onClose: () => void }) {
  useEffect(() => {
    const handleEsc = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    document.addEventListener("keydown", handleEsc);
    return () => document.removeEventListener("keydown", handleEsc);
  }, [onClose]);

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-void/60 backdrop-blur-sm"
      onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}
    >
      <div className="bg-onyx rounded-2xl border border-graphite max-w-lg w-full p-8">
        <div className="flex items-center justify-between mb-6">
          <h2 className="font-mono text-xl text-bone font-bold">{agent.name}</h2>
          <button
            onClick={onClose}
            className="text-ash hover:text-bone hover:bg-white/10 rounded-lg px-2 py-1 transition-colors duration-200 text-xl focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2"
          >
            &times;
          </button>
        </div>

        <div className="space-y-4">
          <div>
            <p className="text-xs text-ash font-mono mb-1">ADDRESS</p>
            <p className="font-mono text-sm text-bone/80 break-all">{agent.address}</p>
          </div>

          <div>
            <p className="text-xs text-ash font-mono mb-1">REPUTATION</p>
            <ReputationBar score={agent.reputation} />
          </div>

          <div>
            <p className="text-xs text-ash font-mono mb-1">CAPABILITIES</p>
            <div className="flex flex-wrap gap-2">
              {agent.capabilities.map((cap) => (
                <span key={cap} className="px-2 py-1 bg-iris-purple/10 text-electric-cyan rounded text-xs font-mono">
                  {cap}
                </span>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="bg-obsidian rounded-lg p-3">
              <p className="text-xs text-ash mb-1">Transactions</p>
              <p className="font-mono text-lg text-bone">{agent.totalTransactions.toLocaleString()}</p>
            </div>
            <div className="bg-obsidian rounded-lg p-3">
              <p className="text-xs text-ash mb-1">Volume</p>
              <p className="font-mono text-lg text-bone">{agent.totalVolume}</p>
            </div>
          </div>

          <div>
            <p className="text-xs text-ash font-mono mb-1">REGISTERED</p>
            <p className="text-sm text-bone/80">
              {new Date(agent.registeredAt).toLocaleDateString("en-US", {
                year: "numeric",
                month: "long",
                day: "numeric",
              })}
            </p>
          </div>
        </div>

        <div className="mt-6 flex gap-3">
          <Link
            href={`/delegate?agent=${agent.id}`}
            className="flex-1 px-4 py-2.5 bg-iris-purple hover:bg-iris-purple/80 text-bone text-sm font-medium rounded-lg transition-colors duration-200 text-center focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2"
          >
            Create Delegation
          </Link>
          <button
            onClick={onClose}
            className="px-4 py-2.5 bg-obsidian text-ash text-sm font-medium rounded-lg border border-graphite hover:border-ash/30 hover:bg-white/10 transition-colors duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
}
