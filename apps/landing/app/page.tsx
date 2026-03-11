"use client";

import { useState, useEffect, useRef } from "react";
import IrisAperture from "@/components/IrisAperture";

const TRUST_TIERS = [
  {
    tier: 0,
    name: "View Only",
    label: "Iris Closed",
    description: "Agent reads onchain state only. Human signs every transaction.",
    color: "#7B2FBE",
  },
  {
    tier: 1,
    name: "Supervised",
    label: "Iris Narrow",
    description: "Agent spends up to $100/day. Excess requires human co-signature.",
    color: "#9B4FDE",
  },
  {
    tier: 2,
    name: "Autonomous",
    label: "Iris Wide",
    description: "Broader bounds with reputation-gating. Min score 75 required.",
    color: "#00C0DD",
  },
  {
    tier: 3,
    name: "Full Delegation",
    label: "Iris Open",
    description: "Maximum autonomy. Emergency revocation always available.",
    color: "#00F0FF",
  },
];

const ERC_STACK = [
  { number: "4337", name: "Account Abstraction", role: "Smart contract wallet foundation" },
  { number: "7710", name: "Delegations", role: "Onchain permission delegation framework" },
  { number: "7715", name: "Permission Requests", role: "Standardized permission request flow" },
  { number: "8004", name: "Reputation Registry", role: "Native agent reputation scores" },
  { number: "8128", name: "Multi-Owner", role: "Multi-party account ownership" },
  { number: "7702", name: "Code Delegation", role: "EOA-to-smart-account migration" },
];

const SPONSORS = ["Base", "MetaMask", "EF dAI", "Uniswap", "Self Protocol"];

export default function LandingPage() {
  const [activeTier, setActiveTier] = useState(0);
  const solutionRef = useRef<HTMLDivElement>(null);

  return (
    <main className="min-h-screen">
      {/* Navigation */}
      <nav className="fixed top-0 left-0 right-0 z-50 border-b border-white/5 backdrop-blur-md bg-[#0D0D14]/80">
        <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <IrisAperture tier={2} size={32} />
            <span className="font-mono font-bold text-white text-lg tracking-tight">
              iris<span className="text-[#00F0FF]">.</span>protocol
            </span>
          </div>
          <div className="hidden md:flex items-center gap-8">
            <a href="#problem" className="text-sm text-gray-400 hover:text-white transition-colors">
              Problem
            </a>
            <a href="#solution" className="text-sm text-gray-400 hover:text-white transition-colors">
              Solution
            </a>
            <a href="#stack" className="text-sm text-gray-400 hover:text-white transition-colors">
              ERC Stack
            </a>
            <a href="#reputation" className="text-sm text-gray-400 hover:text-white transition-colors">
              Reputation
            </a>
            <a
              href="../app"
              className="px-4 py-2 bg-[#7B2FBE] hover:bg-[#6B25A8] text-white text-sm font-medium rounded-lg transition-colors"
            >
              Launch App
            </a>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="relative min-h-screen flex items-center justify-center overflow-hidden pt-16">
        {/* Background grid */}
        <div className="absolute inset-0 opacity-5">
          <div
            className="w-full h-full"
            style={{
              backgroundImage:
                "linear-gradient(rgba(123,47,190,0.3) 1px, transparent 1px), linear-gradient(90deg, rgba(123,47,190,0.3) 1px, transparent 1px)",
              backgroundSize: "60px 60px",
            }}
          />
        </div>

        <div className="relative z-10 text-center px-6 max-w-5xl mx-auto">
          <div className="flex justify-center mb-10 float-animation">
            <IrisAperture tier={2} size={240} animated />
          </div>

          <h1 className="font-mono text-5xl md:text-7xl font-bold text-white mb-6 tracking-tight">
            Iris Protocol
          </h1>

          <p className="text-2xl md:text-3xl font-mono text-[#00F0FF] mb-4">
            Privy, but trustless.
          </p>

          <p className="text-lg md:text-xl text-gray-400 max-w-2xl mx-auto mb-12">
            Embedded agent wallets where every permission lives onchain.
          </p>

          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <a
              href="../app"
              className="px-8 py-4 bg-[#7B2FBE] hover:bg-[#6B25A8] text-white font-semibold rounded-lg transition-all hover:shadow-lg hover:shadow-purple-500/20 text-lg"
            >
              View Demo
            </a>
            <a
              href="../docs"
              className="px-8 py-4 border border-[#00F0FF]/30 hover:border-[#00F0FF] text-[#00F0FF] font-semibold rounded-lg transition-all hover:bg-[#00F0FF]/5 text-lg"
            >
              Read Docs
            </a>
          </div>
        </div>

        {/* Bottom gradient fade */}
        <div className="absolute bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-[#0D0D14] to-transparent" />
      </section>

      {/* Problem Section */}
      <section id="problem" className="py-32 px-6">
        <div className="max-w-6xl mx-auto">
          <h2 className="font-mono text-4xl md:text-5xl font-bold text-white text-center mb-6">
            The Trust Problem
          </h2>
          <p className="text-gray-400 text-center max-w-3xl mx-auto mb-16 text-lg">
            Embedded wallet providers require trusting a company with key shards and TEEs.
            For AI agents operating with real economic value, these trust assumptions are
            unacceptable.
          </p>

          <div className="grid md:grid-cols-2 gap-8">
            {/* Privy / Custodial Side */}
            <div className="bg-[#232340] rounded-2xl p-8 border border-red-500/20">
              <div className="flex items-center gap-3 mb-6">
                <div className="w-3 h-3 rounded-full bg-red-500" />
                <h3 className="font-mono text-xl text-red-400">Custodial Embedded Wallets</h3>
              </div>
              <ul className="space-y-4">
                {[
                  { label: "TEE Key Sharding", desc: "Keys split across trusted execution environments" },
                  { label: "Offchain Policy Engine", desc: "Permissions enforced by company servers" },
                  { label: "Company Trust Required", desc: "Provider can freeze or access funds" },
                  { label: "Opaque Key Management", desc: "Key lifecycle controlled by third party" },
                  { label: "Single Point of Failure", desc: "Provider outage = wallet inaccessible" },
                ].map((item) => (
                  <li key={item.label} className="flex items-start gap-3">
                    <span className="text-red-500 mt-1 text-lg">&#x2717;</span>
                    <div>
                      <span className="text-white font-medium">{item.label}</span>
                      <p className="text-gray-500 text-sm">{item.desc}</p>
                    </div>
                  </li>
                ))}
              </ul>
            </div>

            {/* Iris / Trustless Side */}
            <div className="bg-[#232340] rounded-2xl p-8 border border-[#00F0FF]/20">
              <div className="flex items-center gap-3 mb-6">
                <div className="w-3 h-3 rounded-full bg-[#00F0FF]" />
                <h3 className="font-mono text-xl text-[#00F0FF]">Iris Protocol</h3>
              </div>
              <ul className="space-y-4">
                {[
                  { label: "Smart Contract Wallets", desc: "ERC-4337 accounts with onchain logic" },
                  { label: "Onchain Caveat Enforcers", desc: "Permissions verified by smart contracts" },
                  { label: "Zero Trust Assumptions", desc: "No company can access or freeze funds" },
                  { label: "ERC-7710 Delegations", desc: "Transparent, auditable permission chains" },
                  { label: "Decentralized & Resilient", desc: "Works as long as the chain is live" },
                ].map((item) => (
                  <li key={item.label} className="flex items-start gap-3">
                    <span className="text-[#00F0FF] mt-1 text-lg">&#x2713;</span>
                    <div>
                      <span className="text-white font-medium">{item.label}</span>
                      <p className="text-gray-500 text-sm">{item.desc}</p>
                    </div>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* Solution Section */}
      <section id="solution" ref={solutionRef} className="py-32 px-6 bg-[#0D0D14]">
        <div className="max-w-6xl mx-auto">
          <h2 className="font-mono text-4xl md:text-5xl font-bold text-white text-center mb-4">
            Configure the Iris
          </h2>
          <p className="text-gray-400 text-center max-w-2xl mx-auto mb-16 text-lg">
            Dial the aperture to control how much autonomy your agent has.
            Every permission level is enforced by smart contracts.
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
                      ? "bg-[#7B2FBE] text-white shadow-lg shadow-purple-500/20"
                      : "bg-[#232340] text-gray-400 hover:bg-[#2D2D50]"
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
                    ? "bg-[#232340] border-[#7B2FBE] shadow-lg shadow-purple-500/10"
                    : "bg-[#0D0D14] border-white/5 hover:border-white/10"
                }`}
              >
                <div className="flex items-center gap-2 mb-3">
                  <span
                    className="font-mono text-xs px-2 py-1 rounded"
                    style={{ backgroundColor: `${t.color}20`, color: t.color }}
                  >
                    T{t.tier}
                  </span>
                  <span className="font-mono text-sm text-white">{t.name}</span>
                </div>
                <p className="text-xs text-gray-500 mb-2">{t.label}</p>
                <p className="text-sm text-gray-400">{t.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ERC Stack Section */}
      <section id="stack" className="py-32 px-6">
        <div className="max-w-6xl mx-auto">
          <h2 className="font-mono text-4xl md:text-5xl font-bold text-white text-center mb-4">
            Built on Standards
          </h2>
          <p className="text-gray-400 text-center max-w-2xl mx-auto mb-16 text-lg">
            Six ERCs compose to create a trustless agent permission layer.
          </p>

          <div className="grid md:grid-cols-3 gap-4">
            {ERC_STACK.map((erc) => (
              <div
                key={erc.number}
                className="bg-[#232340] rounded-xl p-6 border border-white/5 hover:border-[#7B2FBE]/30 transition-all group"
              >
                <div className="flex items-baseline gap-2 mb-3">
                  <span className="font-mono text-2xl font-bold text-[#00F0FF] group-hover:text-white transition-colors">
                    ERC-{erc.number}
                  </span>
                </div>
                <p className="font-mono text-sm text-white mb-1">{erc.name}</p>
                <p className="text-sm text-gray-500">{erc.role}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Novel Contribution: ReputationGateEnforcer */}
      <section id="reputation" className="py-32 px-6 bg-[#0D0D14]">
        <div className="max-w-6xl mx-auto">
          <h2 className="font-mono text-4xl md:text-5xl font-bold text-white text-center mb-4">
            ReputationGateEnforcer
          </h2>
          <p className="text-gray-400 text-center max-w-2xl mx-auto mb-12 text-lg">
            A novel caveat enforcer that queries ERC-8004 reputation in real-time.
            Agent permissions degrade automatically if reputation drops &mdash; a network-level immune system.
          </p>

          {/* Flowchart */}
          <div className="max-w-4xl mx-auto">
            <div className="flex flex-col md:flex-row items-center justify-between gap-4">
              {[
                { step: "01", title: "Agent Requests Action", desc: "Delegation redemption initiated" },
                { step: "02", title: "Enforcer Queries ERC-8004", desc: "Real-time reputation check" },
                { step: "03", title: "Score Evaluated", desc: "Compare against tier threshold" },
                { step: "04", title: "Permission Resolved", desc: "Grant, restrict, or deny" },
              ].map((item, i) => (
                <div key={item.step} className="flex items-center gap-4">
                  <div className="bg-[#232340] border border-[#7B2FBE]/30 rounded-xl p-5 text-center min-w-[180px]">
                    <div className="font-mono text-xs text-[#7B2FBE] mb-2">STEP {item.step}</div>
                    <div className="font-mono text-sm text-white mb-1">{item.title}</div>
                    <div className="text-xs text-gray-500">{item.desc}</div>
                  </div>
                  {i < 3 && (
                    <span className="hidden md:block text-[#00F0FF] font-mono text-xl">&rarr;</span>
                  )}
                </div>
              ))}
            </div>

            <div className="mt-12 bg-[#232340] rounded-xl p-6 border border-white/5">
              <div className="font-mono text-sm text-gray-400 mb-4">{"// ReputationGateEnforcer.sol"}</div>
              <pre className="font-mono text-sm text-[#00F0FF]/80 overflow-x-auto">
{`function beforeHook(
    bytes calldata _terms,
    bytes calldata,
    ModeCode,
    bytes calldata,
    bytes32,
    address delegator,
    address redeemer
) external view {
    uint256 minScore = abi.decode(_terms, (uint256));
    uint256 reputation = IReputationRegistry(registry)
        .getReputation(redeemer);

    require(reputation >= minScore, "Reputation below threshold");
}`}
              </pre>
            </div>
          </div>
        </div>
      </section>

      {/* Team Section */}
      <section className="py-32 px-6">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="font-mono text-4xl md:text-5xl font-bold text-white mb-12">
            Built by
          </h2>

          <div className="bg-[#232340] rounded-2xl p-8 border border-white/5 inline-block text-left max-w-lg w-full">
            <div className="flex items-center gap-4 mb-6">
              <div className="w-16 h-16 rounded-full bg-gradient-to-br from-[#7B2FBE] to-[#00F0FF] flex items-center justify-center">
                <span className="font-mono text-xl font-bold text-white">E</span>
              </div>
              <div>
                <h3 className="font-mono text-xl text-white">Elliot</h3>
                <p className="text-sm text-gray-500">Smart Contract Security &amp; Infrastructure</p>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4 mb-6">
              {[
                { value: "67+", label: "Contracts Deployed" },
                { value: "$2B+", label: "TVL Secured" },
                { value: "0", label: "Security Incidents" },
                { value: "Kleidi", label: "Founder" },
              ].map((stat) => (
                <div key={stat.label} className="bg-[#0D0D14] rounded-lg p-3">
                  <div className="font-mono text-lg text-[#00F0FF]">{stat.value}</div>
                  <div className="text-xs text-gray-500">{stat.label}</div>
                </div>
              ))}
            </div>

            <p className="text-sm text-gray-400">
              Stanford Blockchain Review &middot; Protocol infrastructure engineer
            </p>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-white/5 py-16 px-6 bg-[#0D0D14]">
        <div className="max-w-6xl mx-auto">
          <div className="flex flex-col md:flex-row items-center justify-between gap-8 mb-12">
            <div className="flex items-center gap-3">
              <IrisAperture tier={2} size={28} />
              <span className="font-mono font-bold text-white">
                iris<span className="text-[#00F0FF]">.</span>protocol
              </span>
            </div>

            <div className="flex gap-6">
              <a href="#" className="text-sm text-gray-500 hover:text-white transition-colors">
                GitHub
              </a>
              <a href="../docs" className="text-sm text-gray-500 hover:text-white transition-colors">
                Documentation
              </a>
              <a href="../app" className="text-sm text-gray-500 hover:text-white transition-colors">
                Demo App
              </a>
            </div>
          </div>

          {/* Synthesis badge */}
          <div className="text-center mb-10">
            <span className="inline-block px-4 py-2 bg-[#232340] rounded-full text-sm font-mono text-gray-400 border border-white/5">
              Built at The Synthesis 2026
            </span>
          </div>

          {/* Sponsor logos placeholder */}
          <div className="border-t border-white/5 pt-8">
            <p className="text-xs text-gray-600 text-center mb-4 font-mono uppercase tracking-widest">
              Sponsors
            </p>
            <div className="flex flex-wrap items-center justify-center gap-8">
              {SPONSORS.map((name) => (
                <span
                  key={name}
                  className="font-mono text-sm text-gray-600 hover:text-gray-400 transition-colors"
                >
                  {name}
                </span>
              ))}
            </div>
          </div>

          <p className="text-center text-xs text-gray-700 mt-8">
            &copy; 2026 Iris Protocol. All rights reserved.
          </p>
        </div>
      </footer>
    </main>
  );
}
