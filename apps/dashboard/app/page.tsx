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
        <h1 className="font-mono text-3xl font-bold text-white mb-2">Dashboard</h1>
        <p className="text-gray-400">
          {demoMode ? (
            <span>
              Viewing demo data.{" "}
              <span className="text-[#00F0FF]">Connected as 0x1234...5678</span>
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
          <div key={stat.label} className="bg-[#232340] rounded-xl p-5 border border-white/5">
            <p className="text-xs text-gray-500 mb-1 font-mono uppercase tracking-wider">{stat.label}</p>
            <p className={`font-mono text-2xl font-bold ${stat.alert && Number(stat.value) > 0 ? "text-yellow-400" : "text-white"}`}>
              {stat.value}
            </p>
          </div>
        ))}
      </div>

      {/* Quick actions */}
      <div className="flex flex-wrap gap-3 mb-8">
        <Link
          href="/delegate"
          className="px-5 py-2.5 bg-[#7B2FBE] hover:bg-[#6B25A8] text-white text-sm font-medium rounded-lg transition-colors"
        >
          Create Delegation
        </Link>
        <Link
          href="/agents"
          className="px-5 py-2.5 bg-[#232340] hover:bg-[#2D2D50] text-gray-300 text-sm font-medium rounded-lg transition-colors border border-white/5"
        >
          View Agents
        </Link>
        <button className="px-5 py-2.5 bg-red-500/10 hover:bg-red-500/20 text-red-400 text-sm font-medium rounded-lg transition-colors border border-red-500/20">
          Revoke All
        </button>
      </div>

      {/* Delegations list */}
      <div className="mb-8">
        <h2 className="font-mono text-xl font-bold text-white mb-4">Active Delegations</h2>
        {delegations.length === 0 ? (
          <div className="bg-[#232340] rounded-xl p-12 border border-white/5 text-center">
            <IrisAperture tier={0} size={80} className="mx-auto mb-4" />
            <p className="text-gray-500">No active delegations.</p>
            <Link href="/delegate" className="text-[#00F0FF] text-sm hover:underline mt-2 inline-block">
              Create your first delegation
            </Link>
          </div>
        ) : (
          <div className="space-y-4">
            {delegations.map((del) => (
              <Link
                key={del.id}
                href={`/delegations/${del.id}`}
                className="block bg-[#232340] rounded-xl p-6 border border-white/5 hover:border-[#7B2FBE]/30 transition-all"
              >
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                  <div className="flex items-center gap-4">
                    <IrisAperture tier={del.tier} size={48} />
                    <div>
                      <div className="flex items-center gap-3">
                        <span className="font-mono text-white font-medium">{del.agentName}</span>
                        <StatusBadge status={del.status} />
                      </div>
                      <p className="text-sm text-gray-500 font-mono">{del.agentAddress.slice(0, 10)}...{del.agentAddress.slice(-8)}</p>
                    </div>
                  </div>

                  <div className="flex items-center gap-6">
                    {/* Tier */}
                    <div className="text-center">
                      <p className="text-xs text-gray-500 mb-1">Tier</p>
                      <p className="font-mono text-sm text-white">T{del.tier} {del.tierName}</p>
                    </div>

                    {/* Spending */}
                    <div className="text-center min-w-[120px]">
                      <p className="text-xs text-gray-500 mb-1">Spending</p>
                      <div className="flex items-center gap-2">
                        <div className="flex-1 h-2 bg-[#1A1A2E] rounded-full overflow-hidden">
                          <div
                            className="h-full rounded-full transition-all"
                            style={{
                              width: `${(del.spendingUsed / del.spendingCap) * 100}%`,
                              backgroundColor: del.spendingUsed / del.spendingCap > 0.9 ? "#FF4444" : "#00F0FF",
                            }}
                          />
                        </div>
                        <span className="font-mono text-xs text-gray-400">
                          ${del.spendingUsed}/{del.spendingCap}
                        </span>
                      </div>
                    </div>

                    {/* Reputation */}
                    <div className="text-center">
                      <p className="text-xs text-gray-500 mb-1">Reputation</p>
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
        <h2 className="font-mono text-xl font-bold text-white mb-4">Recent Activity</h2>
        {activities.length === 0 ? (
          <p className="text-gray-500">No recent activity.</p>
        ) : (
          <div className="bg-[#232340] rounded-xl border border-white/5 overflow-hidden">
            <table className="w-full">
              <thead>
                <tr className="border-b border-white/5">
                  <th className="px-4 py-3 text-left text-xs text-gray-500 font-mono uppercase tracking-wider">Type</th>
                  <th className="px-4 py-3 text-left text-xs text-gray-500 font-mono uppercase tracking-wider">Description</th>
                  <th className="px-4 py-3 text-left text-xs text-gray-500 font-mono uppercase tracking-wider">Amount</th>
                  <th className="px-4 py-3 text-left text-xs text-gray-500 font-mono uppercase tracking-wider">Status</th>
                </tr>
              </thead>
              <tbody>
                {activities.slice(0, 5).map((act) => (
                  <tr key={act.id} className="border-b border-white/5 last:border-0">
                    <td className="px-4 py-3">
                      <span className="font-mono text-xs px-2 py-1 rounded bg-[#7B2FBE]/10 text-[#7B2FBE]">
                        {act.type}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-300">{act.description}</td>
                    <td className="px-4 py-3 font-mono text-sm text-white">{act.amount}</td>
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
