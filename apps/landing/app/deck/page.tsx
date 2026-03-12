"use client";

import { useState, useEffect, useCallback } from "react";

/* ------------------------------------------------------------------ */
/*  Slide data                                                         */
/* ------------------------------------------------------------------ */

function SlideHook() {
  const [showSubtext, setShowSubtext] = useState(false);

  useEffect(() => {
    const t = setTimeout(() => setShowSubtext(true), 800);
    return () => clearTimeout(t);
  }, []);

  return (
    <div className="flex flex-col items-center justify-center h-full gap-8 text-center px-8">
      <h1 className="font-mono text-5xl md:text-7xl font-bold text-bone leading-tight">
        Every AI agent needs a wallet.
      </h1>
      <p
        className={`text-3xl md:text-5xl text-ash transition-all duration-1000 ${
          showSubtext ? "opacity-100 translate-y-0" : "opacity-0 translate-y-4"
        }`}
      >
        No wallet trusts them back.
      </p>
      <p className="text-xl md:text-2xl mt-8">
        <span className="text-iris-purple font-mono font-bold">Iris Protocol</span>
      </p>
      <p className="text-ash text-sm md:text-base absolute bottom-12">
        The Synthesis 2026
      </p>
    </div>
  );
}

function SlideProblem() {
  return (
    <div className="flex flex-col items-center justify-center h-full gap-10 px-8 max-w-6xl mx-auto">
      <h2 className="font-mono text-3xl md:text-5xl font-bold text-bone text-center">
        Agents that Pay
      </h2>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8 w-full mt-4">
        <div className="border border-signal-red/30 rounded-2xl p-8 bg-signal-red/5">
          <p className="text-signal-red text-xl md:text-2xl font-mono font-semibold">
            Give agent full access
          </p>
          <p className="text-ash mt-2 text-lg">Catastrophic risk</p>
        </div>
        <div className="border border-signal-red/30 rounded-2xl p-8 bg-signal-red/5">
          <p className="text-signal-red text-xl md:text-2xl font-mono font-semibold">
            Keep agent locked out
          </p>
          <p className="text-ash mt-2 text-lg">No utility</p>
        </div>
      </div>
      <p className="text-electric-cyan text-2xl md:text-3xl font-mono font-bold mt-4">
        Where&rsquo;s the middle ground?
      </p>
      <p className="text-ash text-base md:text-lg mt-4 text-center max-w-2xl">
        <span className="text-signal-red font-bold">$47K</span> lost to one recursive agent
        loop &mdash; <span className="text-signal-red font-bold">11 days</span> undetected
      </p>
    </div>
  );
}

function SlideTrustGap() {
  const stats = [
    { value: "42%", label: "of consumers fear losing control over AI purchases" },
    { value: "97%", sub: "vs 11%", label: "of CFOs understand agent autonomy — only 11% testing it" },
    { value: "$233", label: "maximum consumers trust AI to spend" },
    { value: "$139B", label: "agentic economy market by 2034" },
  ];

  return (
    <div className="flex flex-col items-center justify-center h-full gap-8 px-8 max-w-6xl mx-auto">
      <h2 className="font-mono text-3xl md:text-5xl font-bold text-bone text-center">
        The Trust Gap
      </h2>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 w-full mt-4">
        {stats.map((s, i) => (
          <div
            key={i}
            className="border border-onyx rounded-2xl p-6 bg-onyx/30 text-center"
          >
            <p className="text-electric-cyan text-4xl md:text-5xl font-mono font-bold">
              {s.value}
            </p>
            <p className="text-bone/80 text-sm md:text-base mt-3 leading-relaxed">
              {s.label}
            </p>
          </div>
        ))}
      </div>
      <p className="text-ash text-base md:text-lg mt-4 text-center max-w-3xl">
        Trust is the bottleneck.
      </p>
    </div>
  );
}

function SlideIrisProtocol() {
  const pillars = [
    { title: "Onchain Delegation", color: "text-electric-cyan" },
    { title: "Configurable Trust", color: "text-iris-purple" },
    { title: "Earned Reputation", color: "text-amber" },
  ];

  return (
    <div className="flex flex-col items-center justify-center h-full gap-10 px-8">
      <p className="text-ash text-lg md:text-xl font-mono">Introducing</p>
      <h2 className="font-mono text-4xl md:text-6xl font-bold text-iris-purple">
        Iris Protocol
      </h2>
      <p className="text-bone text-2xl md:text-3xl font-mono mt-2">
        Privy, but trustless.
      </p>
      <div className="flex flex-col md:flex-row gap-6 mt-8">
        {pillars.map((p) => (
          <div
            key={p.title}
            className="border border-onyx rounded-2xl px-8 py-6 bg-onyx/20 text-center min-w-[220px]"
          >
            <p className={`text-xl md:text-2xl font-mono font-bold ${p.color}`}>
              {p.title}
            </p>
          </div>
        ))}
      </div>
      <p className="text-ash text-lg md:text-xl mt-8">
        Agents get guardrails, not blank checks.
      </p>
    </div>
  );
}

function SlideTrustTiers() {
  const tiers = [
    {
      tier: "Tier 0",
      name: "Iris Closed",
      color: "#9494A6",
      desc: "View only, human signs everything",
    },
    {
      tier: "Tier 1",
      name: "Iris Narrow",
      color: "#00F0FF",
      desc: "$100/day, supervised",
    },
    {
      tier: "Tier 2",
      name: "Iris Wide",
      color: "#7B2FBE",
      desc: "Broader bounds, reputation-gated",
    },
    {
      tier: "Tier 3",
      name: "Iris Open",
      color: "#FFB800",
      desc: "Full delegation, max autonomy",
    },
  ];

  return (
    <div className="flex flex-col items-center justify-center h-full gap-8 px-8 max-w-5xl mx-auto">
      <h2 className="font-mono text-3xl md:text-5xl font-bold text-bone text-center">
        Trust Tiers
      </h2>
      <div className="flex flex-col gap-4 w-full mt-4">
        {tiers.map((t) => (
          <div
            key={t.tier}
            className="flex items-center gap-6 border rounded-xl px-6 py-5 bg-onyx/20"
            style={{ borderColor: t.color + "40" }}
          >
            <div
              className="w-3 h-3 rounded-full shrink-0"
              style={{ backgroundColor: t.color, boxShadow: `0 0 12px ${t.color}60` }}
            />
            <div className="flex flex-col md:flex-row md:items-center md:gap-4 flex-1">
              <span className="font-mono font-bold text-lg md:text-xl" style={{ color: t.color }}>
                {t.tier}
              </span>
              <span className="font-mono text-bone text-lg md:text-xl">{t.name}</span>
              <span className="text-ash text-sm md:text-base md:ml-auto">{t.desc}</span>
            </div>
          </div>
        ))}
      </div>
      <p className="text-ash text-lg mt-4">Trust is earned, not assumed.</p>
    </div>
  );
}

function SlideDefenseInDepth() {
  const layers = [
    { name: "SpendingCap", desc: "Cumulative budget" },
    { name: "SingleTxCap", desc: "Per-tx limit" },
    { name: "ContractWhitelist", desc: "Approved protocols" },
    { name: "FunctionSelector", desc: "Approved actions" },
    { name: "TimeWindow", desc: "Operating hours" },
    { name: "Cooldown", desc: "Rate limiting" },
    { name: "ReputationGate", desc: "Live reputation check" },
  ];

  return (
    <div className="flex flex-col items-center justify-center h-full gap-8 px-8 max-w-5xl mx-auto">
      <h2 className="font-mono text-3xl md:text-5xl font-bold text-bone text-center">
        Defense in Depth
      </h2>
      <div className="flex flex-col gap-2 w-full mt-4">
        {layers.map((l, i) => (
          <div
            key={l.name}
            className="flex items-center gap-4 rounded-lg px-6 py-3 bg-onyx/30 border border-onyx/60"
            style={{
              marginLeft: `${i * 16}px`,
              borderLeftColor: i === 6 ? "#00F0FF" : undefined,
              borderLeftWidth: i === 6 ? "3px" : undefined,
            }}
          >
            <span className="text-electric-cyan font-mono font-bold text-sm w-6">
              {i + 1}
            </span>
            <span className="font-mono text-bone text-base md:text-lg font-semibold">
              {l.name}
            </span>
            <span className="text-ash text-sm md:text-base ml-auto">{l.desc}</span>
          </div>
        ))}
      </div>
      <p className="text-ash text-base md:text-lg mt-4 text-center">
        Not one lock &mdash; <span className="text-electric-cyan font-bold">seven</span>.
        Each independently enforceable.
      </p>
    </div>
  );
}

function SlideStandards() {
  const standards = [
    { name: "ERC-7710", desc: "MetaMask delegation framework" },
    { name: "ERC-8004", desc: "EF dAI agent identity", note: "Created by Davide Crapis" },
    { name: "ERC-4337", desc: "Account abstraction" },
  ];

  return (
    <div className="flex flex-col items-center justify-center h-full gap-10 px-8 max-w-5xl mx-auto">
      <h2 className="font-mono text-3xl md:text-5xl font-bold text-bone text-center">
        Built on Open Standards
      </h2>
      <div className="flex flex-col gap-6 w-full mt-4">
        {standards.map((s) => (
          <div
            key={s.name}
            className="flex flex-col md:flex-row md:items-center gap-2 md:gap-6 border border-onyx rounded-xl px-6 py-5 bg-onyx/20"
          >
            <span className="font-mono text-electric-cyan text-2xl md:text-3xl font-bold">
              {s.name}
            </span>
            <span className="text-bone text-lg md:text-xl">{s.desc}</span>
            {s.note && (
              <span className="text-iris-purple text-sm md:text-base md:ml-auto font-mono">
                {s.note}
              </span>
            )}
          </div>
        ))}
      </div>
      <p className="text-ash text-base md:text-lg mt-4 text-center max-w-3xl">
        We didn&rsquo;t invent new standards. We composed the ones Ethereum already has.
      </p>
    </div>
  );
}

function SlideNovelContribution() {
  return (
    <div className="flex flex-col items-center justify-center h-full gap-8 px-8 max-w-5xl mx-auto">
      <h2 className="font-mono text-3xl md:text-5xl font-bold text-electric-cyan text-center">
        ReputationGateEnforcer
      </h2>
      <p className="text-bone text-xl md:text-2xl text-center">
        A network-level immune system
      </p>
      <div className="flex flex-col md:flex-row items-center gap-4 mt-6">
        {[
          "Agent misbehaves",
          "Reputation drops",
          "ALL delegations auto-blocked",
          "No manual revocation",
        ].map((step, i) => (
          <div key={i} className="flex items-center gap-4">
            <div className="border border-onyx rounded-xl px-5 py-4 bg-onyx/30 text-center min-w-[180px]">
              <p className="text-bone text-sm md:text-base font-mono">{step}</p>
            </div>
            {i < 3 && (
              <span className="text-electric-cyan text-2xl font-bold hidden md:block">
                &rarr;
              </span>
            )}
          </div>
        ))}
      </div>
      <p className="text-iris-purple text-xl md:text-2xl font-mono font-bold mt-8">
        Self-healing trust at protocol level
      </p>
    </div>
  );
}

function SlideSecurity() {
  const points = [
    { value: "233", label: "tests passing", color: "text-mint" },
    { value: "74", label: "Halmos symbolic proofs across 10 suites", color: "text-electric-cyan" },
    { value: "TOCTOU", label: "vulnerability found and fixed", color: "text-signal-red" },
  ];

  return (
    <div className="flex flex-col items-center justify-center h-full gap-8 px-8 max-w-5xl mx-auto">
      <h2 className="font-mono text-3xl md:text-5xl font-bold text-bone text-center">
        Security
      </h2>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 w-full mt-4">
        {points.map((p) => (
          <div
            key={p.value}
            className="border border-onyx rounded-2xl p-6 bg-onyx/20 text-center"
          >
            <p className={`text-4xl md:text-5xl font-mono font-bold ${p.color}`}>
              {p.value}
            </p>
            <p className="text-ash text-sm md:text-base mt-3">{p.label}</p>
          </div>
        ))}
      </div>
      <p className="text-bone text-lg md:text-xl text-center mt-4">
        Not a hackathon prototype.{" "}
        <span className="text-electric-cyan font-bold">Production-grade infrastructure.</span>
      </p>
      <p className="text-ash text-sm md:text-base text-center max-w-2xl mt-2">
        Hyperstructure: no pause, no fees, no admin keys, no proxies
      </p>
    </div>
  );
}

function SlideUseCases() {
  const cases = [
    { title: "Shopping agents", desc: "Browse & buy within budget" },
    { title: "DeFi agents", desc: "Rebalance within approved protocols" },
    { title: "Subscription agents", desc: "Manage recurring payments" },
    { title: "Enterprise agents", desc: "Department-level autonomy" },
  ];

  return (
    <div className="flex flex-col items-center justify-center h-full gap-8 px-8 max-w-5xl mx-auto">
      <h2 className="font-mono text-3xl md:text-5xl font-bold text-bone text-center">
        Users Today
      </h2>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 w-full mt-4">
        {cases.map((c) => (
          <div
            key={c.title}
            className="border border-onyx rounded-2xl p-6 bg-onyx/20"
          >
            <p className="text-electric-cyan text-xl md:text-2xl font-mono font-bold">
              {c.title}
            </p>
            <p className="text-ash text-sm md:text-base mt-2">{c.desc}</p>
          </div>
        ))}
      </div>
      <p className="text-ash text-base md:text-lg mt-6 text-center">
        Any app putting an AI agent near money needs this.
      </p>
    </div>
  );
}

function SlideCompetitive() {
  const rows = [
    { name: "Privy (Stripe)", traits: ["Custodial", "No tiers", "No reputation"] },
    { name: "Coinbase AgentKit", traits: ["Vendor lock-in", "No standards"] },
    { name: "Safe", traits: ["Heavy multi-sig", "No progressive autonomy"] },
    {
      name: "Iris Protocol",
      traits: ["Trustless", "Tiered", "Reputation-gated", "Open standards"],
      highlight: true,
    },
  ];

  return (
    <div className="flex flex-col items-center justify-center h-full gap-8 px-8 max-w-5xl mx-auto">
      <h2 className="font-mono text-3xl md:text-5xl font-bold text-bone text-center">
        Competitive Edge
      </h2>
      <div className="flex flex-col gap-3 w-full mt-4">
        {rows.map((r) => (
          <div
            key={r.name}
            className={`flex flex-col md:flex-row md:items-center gap-2 md:gap-6 rounded-xl px-6 py-4 ${
              r.highlight
                ? "border-2 border-iris-purple bg-iris-purple/10"
                : "border border-onyx bg-onyx/20"
            }`}
          >
            <span
              className={`font-mono font-bold text-lg md:text-xl min-w-[200px] ${
                r.highlight ? "text-iris-purple" : "text-bone"
              }`}
            >
              {r.name}
            </span>
            <div className="flex flex-wrap gap-2">
              {r.traits.map((t) => (
                <span
                  key={t}
                  className={`text-xs md:text-sm px-3 py-1 rounded-full ${
                    r.highlight
                      ? "bg-electric-cyan/10 text-electric-cyan border border-electric-cyan/30"
                      : "bg-onyx/60 text-ash border border-onyx"
                  }`}
                >
                  {t}
                </span>
              ))}
            </div>
          </div>
        ))}
      </div>
      <p className="text-ash text-sm md:text-base mt-6 text-center max-w-3xl leading-relaxed">
        Every competitor gives agents a wallet.{" "}
        <span className="text-iris-purple font-bold">Iris Protocol</span> gives them a
        leash &mdash; one that loosens as they prove themselves.
      </p>
    </div>
  );
}

function SlideCTA() {
  return (
    <div className="flex flex-col items-center justify-center h-full gap-8 px-8 text-center">
      <h2 className="font-mono text-3xl md:text-5xl font-bold text-bone leading-tight">
        Try it. Deploy an agent.
        <br />
        Set its limits.
      </h2>
      <p className="text-electric-cyan text-xl md:text-2xl mt-2">
        Watch it earn your trust.
      </p>
      <div className="flex gap-6 mt-8">
        {[
          { label: "Demo", href: "#" },
          { label: "Docs", href: "#" },
          { label: "GitHub", href: "#" },
        ].map((link) => (
          <a
            key={link.label}
            href={link.href}
            className="font-mono text-lg md:text-xl px-6 py-3 rounded-xl border border-iris-purple text-iris-purple hover:bg-iris-purple/10 transition-colors"
          >
            {link.label}
          </a>
        ))}
      </div>
      <p className="text-ash text-sm md:text-base mt-12">
        Built for The Synthesis by{" "}
        <span className="text-bone font-bold">Elliot</span>
      </p>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/*  Slide registry                                                     */
/* ------------------------------------------------------------------ */

const SLIDES = [
  SlideHook,
  SlideProblem,
  SlideTrustGap,
  SlideIrisProtocol,
  SlideTrustTiers,
  SlideDefenseInDepth,
  SlideStandards,
  SlideNovelContribution,
  SlideSecurity,
  SlideUseCases,
  SlideCompetitive,
  SlideCTA,
];

/* ------------------------------------------------------------------ */
/*  Deck shell                                                         */
/* ------------------------------------------------------------------ */

export default function DeckPage() {
  const [current, setCurrent] = useState(0);
  const total = SLIDES.length;

  const next = useCallback(
    () => setCurrent((c) => Math.min(c + 1, total - 1)),
    [total],
  );
  const prev = useCallback(
    () => setCurrent((c) => Math.max(c - 1, 0)),
    [],
  );

  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if (e.key === "ArrowRight" || e.key === " " || e.key === "Enter") {
        e.preventDefault();
        next();
      } else if (e.key === "ArrowLeft") {
        e.preventDefault();
        prev();
      }
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [next, prev]);

  const CurrentSlide = SLIDES[current];

  return (
    <div className="relative w-screen h-screen overflow-hidden bg-void select-none">
      {/* Subtle background gradient */}
      <div className="absolute inset-0 bg-gradient-to-br from-void via-onyx/40 to-void pointer-events-none" />

      {/* Slide content */}
      <div
        key={current}
        className="relative z-10 w-full h-full animate-fadeIn"
      >
        <CurrentSlide />
      </div>

      {/* Slide indicator */}
      <div className="absolute bottom-6 right-8 z-20 font-mono text-ash text-sm">
        {current + 1}/{total}
      </div>

      {/* Navigation hint — first slide only */}
      {current === 0 && (
        <div className="absolute bottom-6 left-8 z-20 text-ash/50 text-xs font-mono">
          Arrow keys or Space to navigate
        </div>
      )}

      {/* Fade-in animation */}
      <style jsx>{`
        @keyframes fadeIn {
          from {
            opacity: 0;
            transform: translateY(8px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }
        .animate-fadeIn {
          animation: fadeIn 0.4s ease-out;
        }
      `}</style>
    </div>
  );
}
