"use client";

import Link from "next/link";
import { useDemoMode } from "@/hooks/useDemoMode";
import { MOCK_DELEGATIONS, MOCK_ACTIVITIES } from "@/constants/mock-data";
import IrisAperture from "@/components/ui/IrisAperture";
import { ReputationBadge } from "@/components/delegation/ReputationBadge";
import { StatusBadge } from "@/components/delegation/StatusBadge";

export default function Dashboard() {
  const { demoMode } = useDemoMode();

  const delegations = demoMode ? MOCK_DELEGATIONS : [];
  const activities = demoMode ? MOCK_ACTIVITIES : [];

  return (
    <div className="max-w-7xl mx-auto px-6 py-8">
      {/* Welcome header */}
      <div className="mb-8">
        <h1 className="font-mono text-3xl font-bold text-bone mb-2">Dashboard</h1>
        <p className="text-ash">
          {demoMode ? (
            <span>
              Viewing demo data.{" "}
              <span className="text-electric-cyan">Connected as 0x1234...5678</span>
            </span>
          ) : (
            "Connect your wallet to view delegations."
          )}
        </p>
      </div>

      {/* Stats grid */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        {[
          { label: "Active Delegations", value: delegations.filter((d) => d.status === "active").length.toString() },
          { label: "Total Agents", value: delegations.length.toString() },
          { label: "Total Spent", value: `$${delegations.reduce((s, d) => s + d.spendingUsed, 0).toFixed(0)}` },
          { label: "Alerts", value: delegations.filter((d) => d.status === "degraded").length.toString(), alert: true },
        ].map((stat) => (
          <div key={stat.label} className="bg-onyx rounded-xl p-5 border border-graphite">
            <p className="text-xs text-ash mb-1 font-mono uppercase tracking-wider">{stat.label}</p>
            <p className={`font-mono text-2xl font-bold ${stat.alert && Number(stat.value) > 0 ? "text-amber" : "text-bone"}`}>
              {stat.value}
            </p>
          </div>
        ))}
      </div>

      {/* Quick actions */}
      <div className="flex flex-wrap gap-3 mb-8">
        <Link
          href="/delegate"
          className="px-5 py-2.5 bg-iris-purple hover:bg-iris-purple/80 text-bone text-sm font-medium rounded-lg transition-colors duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2"
        >
          Create Delegation
        </Link>
        <Link
          href="/agents"
          className="px-5 py-2.5 bg-onyx hover:bg-graphite text-ash text-sm font-medium rounded-lg transition-colors duration-200 border border-graphite focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2"
        >
          View Agents
        </Link>
        <button className="px-5 py-2.5 bg-signal-red/10 hover:bg-signal-red/20 text-signal-red text-sm font-medium rounded-lg transition-colors duration-200 border border-signal-red/20 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2">
          Revoke All
        </button>
      </div>

      {/* Delegations list */}
      <div className="mb-8">
        <h2 className="font-mono text-xl font-bold text-bone mb-4">Active Delegations</h2>
        {delegations.length === 0 ? (
          <div className="bg-onyx rounded-xl p-12 border border-graphite text-center">
            <IrisAperture tier={0} size={80} className="mx-auto mb-4" />
            <p className="text-ash">No active delegations.</p>
            <Link href="/delegate" className="text-electric-cyan text-sm hover:underline mt-2 inline-block focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2 rounded">
              Create your first delegation
            </Link>
          </div>
        ) : (
          <div className="space-y-4">
            {delegations.map((del) => (
              <Link
                key={del.id}
                href={`/delegations/${del.id}`}
                className="block bg-onyx rounded-xl p-6 border border-graphite hover:border-iris-purple/30 transition-all duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2"
              >
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                  <div className="flex items-center gap-4">
                    <IrisAperture tier={del.tier} size={48} />
                    <div>
                      <div className="flex items-center gap-3">
                        <span className="font-mono text-bone font-medium">{del.agentName}</span>
                        <StatusBadge status={del.status} />
                      </div>
                      <p className="text-sm text-ash font-mono">{del.agentAddress.slice(0, 10)}...{del.agentAddress.slice(-8)}</p>
                    </div>
                  </div>

                  <div className="flex items-center gap-6">
                    {/* Tier */}
                    <div className="text-center">
                      <p className="text-xs text-ash mb-1">Tier</p>
                      <p className="font-mono text-sm text-bone">T{del.tier} {del.tierName}</p>
                    </div>

                    {/* Spending */}
                    <div className="text-center min-w-[120px]">
                      <p className="text-xs text-ash mb-1">Spending</p>
                      <div className="flex items-center gap-2">
                        <div className="flex-1 h-2 bg-obsidian rounded-full overflow-hidden">
                          <div
                            className="h-full rounded-full transition-all duration-200"
                            style={{
                              width: `${(del.spendingUsed / del.spendingCap) * 100}%`,
                              backgroundColor: del.spendingUsed / del.spendingCap > 0.9
                                ? "var(--signal-red)"
                                : del.spendingUsed / del.spendingCap > 0.7
                                ? "var(--amber)"
                                : "var(--electric-cyan)",
                            }}
                          />
                        </div>
                        <span className="font-mono text-xs text-ash">
                          ${del.spendingUsed}/{del.spendingCap}
                        </span>
                      </div>
                    </div>

                    {/* Reputation */}
                    <div className="text-center">
                      <p className="text-xs text-ash mb-1">Reputation</p>
                      <ReputationBadge score={del.reputation} />
                    </div>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>

      {/* Recent Activity */}
      <div>
        <h2 className="font-mono text-xl font-bold text-bone mb-4">Recent Activity</h2>
        {activities.length === 0 ? (
          <p className="text-ash">No recent activity.</p>
        ) : (
          <div className="bg-onyx rounded-xl border border-graphite overflow-x-auto">
            <table className="w-full min-w-[540px]">
              <thead>
                <tr className="border-b border-graphite">
                  <th className="px-4 py-3 text-left text-xs text-ash font-mono uppercase tracking-wider">Type</th>
                  <th className="px-4 py-3 text-left text-xs text-ash font-mono uppercase tracking-wider">Description</th>
                  <th className="px-4 py-3 text-left text-xs text-ash font-mono uppercase tracking-wider">Amount</th>
                  <th className="px-4 py-3 text-left text-xs text-ash font-mono uppercase tracking-wider">Status</th>
                </tr>
              </thead>
              <tbody>
                {activities.slice(0, 5).map((act) => (
                  <tr key={act.id} className="border-b border-graphite last:border-0">
                    <td className="px-4 py-3">
                      <span className="font-mono text-xs px-2 py-1 rounded bg-iris-purple/10 text-electric-cyan">
                        {act.type}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-sm text-bone/80">{act.description}</td>
                    <td className="px-4 py-3 font-mono text-sm text-bone">{act.amount}</td>
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
