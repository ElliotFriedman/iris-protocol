"use client";

import { useState } from "react";
import IrisAperture from "@/components/ui/IrisAperture";

const TRUST_TIERS = [
  {
    tier: 0,
    name: "View Only",
    label: "Iris Closed",
    description: "Agent reads onchain state only. Human signs every transaction.",
    color: "#9494A6",
  },
  {
    tier: 1,
    name: "Supervised",
    label: "Iris Narrow",
    description: "Agent spends up to $100/day. Excess requires human co-signature.",
    color: "#00F0FF",
  },
  {
    tier: 2,
    name: "Autonomous",
    label: "Iris Wide",
    description: "Broader bounds with reputation-gating. Min score 75 required.",
    color: "#7B2FBE",
  },
  {
    tier: 3,
    name: "Full Delegation",
    label: "Iris Open",
    description: "Maximum autonomy. Emergency revocation always available.",
    color: "#FFB800",
  },
];

export default function ConfigureIrisSection() {
  const [activeTier, setActiveTier] = useState(0);

  return (
    <section id="solution" className="py-32 px-6 bg-void">
      <div className="max-w-6xl mx-auto">
        <h2 className="font-mono text-4xl md:text-5xl font-bold text-bone text-center mb-4">
          Configure the Iris
        </h2>
        <p className="text-ash text-center max-w-2xl mx-auto mb-4 text-lg">
          Dial the aperture to control how much autonomy your agent has.
          Every permission level is enforced by smart contracts.
        </p>
        <p className="text-electric-cyan/70 text-center max-w-2xl mx-auto mb-16 text-base font-mono">
          Trust is earned, not assumed. Agents start restricted and graduate to autonomy
          through onchain reputation.
        </p>

        <div className="flex flex-col items-center mb-16">
          <IrisAperture tier={activeTier} size={280} />

          {/* Tier selector dial */}
          <div className="flex gap-2 mt-10">
            {TRUST_TIERS.map((t) => (
              <button
                key={t.tier}
                onClick={() => setActiveTier(t.tier)}
                className={`px-4 py-2 rounded-lg font-mono text-sm transition-all ${
                  activeTier === t.tier
                    ? "bg-iris-purple text-bone shadow-lg shadow-iris-purple/20"
                    : "bg-onyx text-ash hover:bg-graphite"
                }`}
              >
                Tier {t.tier}
              </button>
            ))}
          </div>
        </div>

        <div className="grid md:grid-cols-4 gap-4">
          {TRUST_TIERS.map((t) => (
            <div
              key={t.tier}
              onClick={() => setActiveTier(t.tier)}
              className={`cursor-pointer rounded-xl p-6 border transition-all ${
                activeTier === t.tier
                  ? "bg-onyx border-iris-purple shadow-lg shadow-iris-purple/10"
                  : "bg-void border-graphite/40 hover:border-graphite"
              }`}
            >
              <div className="flex items-center gap-2 mb-3">
                <span
                  className="font-mono text-xs px-2 py-1 rounded"
                  style={{ backgroundColor: `${t.color}20`, color: t.color }}
                >
                  T{t.tier}
                </span>
                <span className="font-mono text-sm text-bone">{t.name}</span>
              </div>
              <p className="text-xs text-ash mb-2">{t.label}</p>
              <p className="text-sm text-ash">{t.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
