"use client";

import { use } from "react";
import Link from "next/link";
import { useDemoMode } from "@/hooks/useDemoMode";
import { MOCK_DELEGATIONS, MOCK_ACTIVITIES } from "@/constants/mock-data";
import { TRUST_TIERS } from "@/constants/trust-tiers";
import IrisAperture from "@/components/ui/IrisAperture";
import { StatusBadge } from "@/components/delegation/StatusBadge";

export default function DelegationDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const { demoMode } = useDemoMode();

  const delegation = demoMode ? MOCK_DELEGATIONS.find((d) => d.id === id) : null;
  const activities = demoMode ? MOCK_ACTIVITIES.filter((a) => a.delegationId === id) : [];
  const tier = delegation ? TRUST_TIERS[delegation.tier] : null;

  if (!delegation) {
    return (
      <div className="max-w-7xl mx-auto px-6 py-8">
        <div className="bg-[#232340] rounded-xl p-12 border border-white/5 text-center">
          <p className="text-gray-500 mb-4">Delegation not found.</p>
          <Link href="/" className="text-[#00F0FF] text-sm hover:underline">
            Back to Dashboard
          </Link>
        </div>
      </div>
    );
  }

  const spendingPct = (delegation.spendingUsed / delegation.spendingCap) * 100;
  const repMet = delegation.reputation >= delegation.reputationRequired;
  const daysLeft = Math.max(0, Math.ceil(
    (new Date(delegation.timeWindowEnd).getTime() - Date.now()) / (1000 * 60 * 60 * 24)
  ));

  return (
    <div className="max-w-7xl mx-auto px-6 py-8">
      {/* Breadcrumb */}
      <div className="flex items-center gap-2 text-sm text-gray-500 mb-6">
        <Link href="/" className="hover:text-white transition-colors">Dashboard</Link>
        <span>/</span>
        <span className="text-gray-300">{delegation.agentName}</span>
      </div>

      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
        <div className="flex items-center gap-4">
          <IrisAperture tier={delegation.tier} size={64} />
          <div>
            <div className="flex items-center gap-3">
              <h1 className="font-mono text-2xl font-bold text-white">{delegation.agentName}</h1>
              <StatusBadge status={delegation.status} variant="pill" />
            </div>
            <p className="font-mono text-sm text-gray-500">{delegation.agentAddress}</p>
          </div>
        </div>

        <button className="px-6 py-2.5 bg-red-500/10 hover:bg-red-500/20 text-red-400 text-sm font-medium rounded-lg transition-colors border border-red-500/20 self-start">
          Revoke Delegation
        </button>
      </div>

      {/* Info Grid */}
      <div className="grid md:grid-cols-3 gap-4 mb-8">
        {/* Tier info */}
        <div className="bg-[#232340] rounded-xl p-6 border border-white/5">
          <p className="text-xs text-gray-500 font-mono uppercase tracking-wider mb-3">Trust Tier</p>
          <div className="flex items-center gap-3">
            <span
              className="font-mono text-sm px-2 py-1 rounded"
              style={{ backgroundColor: `${tier?.color}20`, color: tier?.color }}
            >
              T{delegation.tier}
            </span>
            <span className="font-mono text-white">{delegation.tierName}</span>
          </div>
          <p className="text-xs text-gray-500 mt-2">{tier?.description}</p>
        </div>

        {/* Time window */}
        <div className="bg-[#232340] rounded-xl p-6 border border-white/5">
          <p className="text-xs text-gray-500 font-mono uppercase tracking-wider mb-3">Time Window</p>
          <p className="font-mono text-2xl text-white font-bold">{daysLeft} days</p>
          <p className="text-xs text-gray-500 mt-1">
            {new Date(delegation.timeWindowStart).toLocaleDateString()} &mdash;{" "}
            {new Date(delegation.timeWindowEnd).toLocaleDateString()}
          </p>
        </div>

        {/* Caveats */}
        <div className="bg-[#232340] rounded-xl p-6 border border-white/5">
          <p className="text-xs text-gray-500 font-mono uppercase tracking-wider mb-3">Contract Whitelist</p>
          <div className="space-y-1">
            {delegation.contractWhitelist.map((addr) => (
              <p key={addr} className="font-mono text-xs text-gray-400">{addr}</p>
            ))}
          </div>
        </div>
      </div>

      {/* Spending Tracker */}
      <div className="bg-[#232340] rounded-xl p-6 border border-white/5 mb-8">
        <div className="flex items-center justify-between mb-4">
          <p className="text-xs text-gray-500 font-mono uppercase tracking-wider">Spending Tracker</p>
          <p className="font-mono text-sm text-gray-400">
            ${delegation.spendingUsed.toFixed(2)} / ${delegation.spendingCap.toFixed(2)}
          </p>
        </div>
        <div className="h-4 bg-[#1A1A2E] rounded-full overflow-hidden">
          <div
            className="h-full rounded-full transition-all duration-500"
            style={{
              width: `${spendingPct}%`,
              backgroundColor: spendingPct > 90 ? "#FF4444" : spendingPct > 70 ? "#F0C000" : "#00F0FF",
            }}
          />
        </div>
        <p className="text-xs text-gray-600 mt-2">
          {spendingPct.toFixed(1)}% of daily cap used
        </p>
      </div>

      {/* Reputation Monitor */}
      <div className="bg-[#232340] rounded-xl p-6 border border-white/5 mb-8">
        <div className="flex items-center justify-between mb-4">
          <p className="text-xs text-gray-500 font-mono uppercase tracking-wider">Reputation Monitor</p>
          <span className={`font-mono text-sm font-bold ${repMet ? "text-[#00F0FF]" : "text-red-400"}`}>
            {repMet ? "THRESHOLD MET" : "BELOW THRESHOLD"}
          </span>
        </div>
        <div className="flex items-center gap-6">
          <div>
            <p className="text-xs text-gray-500 mb-1">Current Score</p>
            <p
              className="font-mono text-3xl font-bold"
              style={{
                color: delegation.reputation >= 75 ? "#00F0FF" : delegation.reputation >= 50 ? "#F0C000" : "#FF4444",
              }}
            >
              {delegation.reputation}
            </p>
          </div>
          <div className="text-gray-600 text-2xl">/</div>
          <div>
            <p className="text-xs text-gray-500 mb-1">Required</p>
            <p className="font-mono text-3xl font-bold text-gray-400">
              {delegation.reputationRequired}
            </p>
          </div>
          <div className="flex-1 ml-8">
            <div className="h-3 bg-[#1A1A2E] rounded-full overflow-hidden relative">
              {/* Threshold marker */}
              <div
                className="absolute top-0 bottom-0 w-0.5 bg-white/40 z-10"
                style={{ left: `${delegation.reputationRequired}%` }}
              />
              <div
                className="h-full rounded-full transition-all"
                style={{
                  width: `${delegation.reputation}%`,
                  backgroundColor: delegation.reputation >= 75 ? "#00F0FF" : delegation.reputation >= 50 ? "#F0C000" : "#FF4444",
                }}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Activity Log */}
      <div>
        <h2 className="font-mono text-xl font-bold text-white mb-4">Activity Log</h2>
        {activities.length === 0 ? (
          <div className="bg-[#232340] rounded-xl p-8 border border-white/5 text-center">
            <p className="text-gray-500">No activity recorded for this delegation.</p>
          </div>
        ) : (
          <div className="bg-[#232340] rounded-xl border border-white/5 overflow-hidden">
            <table className="w-full">
              <thead>
                <tr className="border-b border-white/5">
                  <th className="px-4 py-3 text-left text-xs text-gray-500 font-mono uppercase tracking-wider">Type</th>
                  <th className="px-4 py-3 text-left text-xs text-gray-500 font-mono uppercase tracking-wider">Description</th>
                  <th className="px-4 py-3 text-left text-xs text-gray-500 font-mono uppercase tracking-wider">Amount</th>
                  <th className="px-4 py-3 text-left text-xs text-gray-500 font-mono uppercase tracking-wider">Tx Hash</th>
                  <th className="px-4 py-3 text-left text-xs text-gray-500 font-mono uppercase tracking-wider">Status</th>
                </tr>
              </thead>
              <tbody>
                {activities.map((act) => (
                  <tr key={act.id} className="border-b border-white/5 last:border-0">
                    <td className="px-4 py-3">
                      <span className="font-mono text-xs px-2 py-1 rounded bg-[#7B2FBE]/10 text-[#7B2FBE]">
                        {act.type}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-300">{act.description}</td>
                    <td className="px-4 py-3 font-mono text-sm text-white">{act.amount}</td>
                    <td className="px-4 py-3 font-mono text-xs text-gray-500">{act.txHash}</td>
                    <td className="px-4 py-3">
                      <span className={`text-xs font-mono ${
                        act.status === "success" ? "text-green-400" :
                        act.status === "blocked" ? "text-red-400" : "text-yellow-400"
                      }`}>
                        {act.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
