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
        <div className="bg-onyx rounded-xl p-12 border border-graphite text-center">
          <p className="text-ash mb-4">Delegation not found.</p>
          <Link href="/" className="text-electric-cyan text-sm hover:underline focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2 rounded">
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
      <div className="flex items-center gap-2 text-sm text-ash mb-6">
        <Link href="/" className="hover:text-bone transition-colors duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2 rounded">Dashboard</Link>
        <span>/</span>
        <span className="text-bone/80">{delegation.agentName}</span>
      </div>

      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
        <div className="flex items-center gap-4">
          <IrisAperture tier={delegation.tier} size={64} />
          <div>
            <div className="flex items-center gap-3">
              <h1 className="font-mono text-2xl font-bold text-bone">{delegation.agentName}</h1>
              <StatusBadge status={delegation.status} variant="pill" />
            </div>
            <p className="font-mono text-sm text-ash">{delegation.agentAddress}</p>
          </div>
        </div>

        <button className="px-6 py-2.5 bg-signal-red/10 hover:bg-signal-red/20 text-signal-red text-sm font-medium rounded-lg transition-colors duration-200 border border-signal-red/20 self-start focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2">
          Revoke Delegation
        </button>
      </div>

      {/* Approval Notification Banner (if degraded) */}
      {delegation.status === "degraded" && (
        <div className="relative mb-8 bg-obsidian rounded-xl overflow-hidden border border-graphite">
          {/* Severity stripe */}
          <div className="absolute left-0 top-0 bottom-0 w-1 bg-signal-red" />
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 px-6 py-4 pl-8">
            <div className="flex items-start sm:items-center gap-3 min-w-0">
              <IrisAperture tier={delegation.tier} size={16} />
              <span className="text-sm text-bone">
                <span className="font-mono text-signal-red">Agent #{delegation.agentId}</span>
                {" "}reputation has dropped below required threshold. Delegation is degraded.
              </span>
            </div>
            <div className="flex items-center gap-2 shrink-0 pl-7 sm:pl-0">
              <button className="px-3 py-1.5 rounded-lg text-xs font-mono border border-mint text-mint hover:bg-mint/10 transition-colors duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2">
                Approve
              </button>
              <button className="px-3 py-1.5 rounded-lg text-xs font-mono border border-ash text-ash hover:bg-ash/10 transition-colors duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2">
                View Details
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Info Grid */}
      <div className="grid md:grid-cols-3 gap-4 mb-8">
        {/* Tier info */}
        <div className="bg-onyx rounded-xl p-6 border border-graphite">
          <p className="text-xs text-ash font-mono uppercase tracking-wider mb-3">Trust Tier</p>
          <div className="flex items-center gap-3">
            <span
              className="font-mono text-sm px-2 py-1 rounded"
              style={{ backgroundColor: `${tier?.color}20`, color: tier?.color }}
            >
              T{delegation.tier}
            </span>
            <span className="font-mono text-bone">{delegation.tierName}</span>
          </div>
          <p className="text-xs text-ash mt-2">{tier?.description}</p>
        </div>

        {/* Time window */}
        <div className="bg-onyx rounded-xl p-6 border border-graphite">
          <p className="text-xs text-ash font-mono uppercase tracking-wider mb-3">Time Window</p>
          <p className="font-mono text-2xl text-bone font-bold">{daysLeft} {daysLeft === 1 ? "day" : "days"}</p>
          <p className="text-xs text-ash mt-1">
            {new Date(delegation.timeWindowStart).toLocaleDateString()} &mdash;{" "}
            {new Date(delegation.timeWindowEnd).toLocaleDateString()}
          </p>
        </div>

        {/* Caveats */}
        <div className="bg-onyx rounded-xl p-6 border border-graphite">
          <p className="text-xs text-ash font-mono uppercase tracking-wider mb-3">Contract Whitelist</p>
          <div className="space-y-1">
            {delegation.contractWhitelist.map((addr) => (
              <p key={addr} className="font-mono text-xs text-ash">{addr}</p>
            ))}
          </div>
        </div>
      </div>

      {/* Spending Tracker */}
      <div className="bg-onyx rounded-xl p-6 border border-graphite mb-8">
        <div className="flex items-center justify-between mb-4">
          <p className="text-xs text-ash font-mono uppercase tracking-wider">Spending Tracker</p>
          <p className="font-mono text-sm text-ash">
            ${delegation.spendingUsed.toFixed(2)} / ${delegation.spendingCap.toFixed(2)}
          </p>
        </div>
        <div className="h-4 bg-obsidian rounded-full overflow-hidden">
          <div
            className="h-full rounded-full transition-all duration-500"
            style={{
              width: `${spendingPct}%`,
              backgroundColor: spendingPct > 90 ? "var(--signal-red)" : spendingPct > 70 ? "var(--amber)" : "var(--electric-cyan)",
            }}
          />
        </div>
        <p className="text-xs text-ash mt-2">
          {spendingPct.toFixed(1)}% of daily cap used
        </p>
      </div>

      {/* Reputation Monitor */}
      <div className="bg-onyx rounded-xl p-6 border border-graphite mb-8">
        <div className="flex items-center justify-between mb-4">
          <p className="text-xs text-ash font-mono uppercase tracking-wider">Reputation Monitor</p>
          <span className={`font-mono text-sm font-bold ${repMet ? "text-mint" : "text-signal-red"}`}>
            {repMet ? "THRESHOLD MET" : "BELOW THRESHOLD"}
          </span>
        </div>
        <div className="flex flex-col sm:flex-row sm:items-center gap-4 sm:gap-6">
          <div className="flex items-center gap-6">
            <div>
              <p className="text-xs text-ash mb-1">Current Score</p>
              <p
                className="font-mono text-3xl font-bold"
                style={{
                  color: delegation.reputation >= 75 ? "var(--mint)" : delegation.reputation >= 50 ? "var(--amber)" : "var(--signal-red)",
                }}
              >
                {delegation.reputation}
              </p>
            </div>
            <div className="text-ash text-2xl">/</div>
            <div>
              <p className="text-xs text-ash mb-1">Required</p>
              <p className="font-mono text-3xl font-bold text-ash">
                {delegation.reputationRequired}
              </p>
            </div>
          </div>
          <div className="flex-1">
            <div className="h-3 bg-obsidian rounded-full overflow-hidden relative">
              {/* Threshold marker */}
              <div
                className="absolute top-0 bottom-0 w-0.5 bg-bone/40 z-10"
                style={{ left: `${delegation.reputationRequired}%` }}
              />
              <div
                className="h-full rounded-full transition-all duration-200"
                style={{
                  width: `${delegation.reputation}%`,
                  backgroundColor: delegation.reputation >= 75 ? "var(--mint)" : delegation.reputation >= 50 ? "var(--amber)" : "var(--signal-red)",
                }}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Activity Log */}
      <div>
        <h2 className="font-mono text-xl font-bold text-bone mb-4">Activity Log</h2>
        {activities.length === 0 ? (
          <div className="bg-onyx rounded-xl p-8 border border-graphite text-center">
            <p className="text-ash">No activity recorded for this delegation.</p>
          </div>
        ) : (
          <div className="bg-onyx rounded-xl border border-graphite overflow-x-auto">
            <table className="w-full min-w-[640px]">
              <thead>
                <tr className="border-b border-graphite">
                  <th className="px-4 py-3 text-left text-xs text-ash font-mono uppercase tracking-wider">Type</th>
                  <th className="px-4 py-3 text-left text-xs text-ash font-mono uppercase tracking-wider">Description</th>
                  <th className="px-4 py-3 text-left text-xs text-ash font-mono uppercase tracking-wider">Amount</th>
                  <th className="px-4 py-3 text-left text-xs text-ash font-mono uppercase tracking-wider">Tx Hash</th>
                  <th className="px-4 py-3 text-left text-xs text-ash font-mono uppercase tracking-wider">Status</th>
                </tr>
              </thead>
              <tbody>
                {activities.map((act) => (
                  <tr key={act.id} className="border-b border-graphite last:border-0">
                    <td className="px-4 py-3">
                      <span className="font-mono text-xs px-2 py-1 rounded bg-iris-purple/10 text-electric-cyan">
                        {act.type}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-sm text-bone/80">{act.description}</td>
                    <td className="px-4 py-3 font-mono text-sm text-bone">{act.amount}</td>
                    <td className="px-4 py-3 font-mono text-xs text-ash">{act.txHash}</td>
                    <td className="px-4 py-3">
                      <span className={`text-xs font-mono ${
                        act.status === "success" ? "text-mint" :
                        act.status === "blocked" ? "text-signal-red" : "text-amber"
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
