const ENFORCERS = [
  {
    name: "SpendingCapEnforcer",
    description: "Cumulative budget per period",
    layer: 1,
  },
  {
    name: "SingleTxCapEnforcer",
    description: "Per-transaction value limit",
    layer: 2,
  },
  {
    name: "ContractWhitelistEnforcer",
    description: "Approved protocols only",
    layer: 3,
  },
  {
    name: "FunctionSelectorEnforcer",
    description: "Approved actions only",
    layer: 4,
  },
  {
    name: "TimeWindowEnforcer",
    description: "Operating hours",
    layer: 5,
  },
  {
    name: "CooldownEnforcer",
    description: "Rate limiting for high-value txs",
    layer: 6,
  },
  {
    name: "ReputationGateEnforcer",
    description: "Live reputation threshold",
    layer: 7,
  },
];

const LAYER_COLORS = [
  "border-ash/30 text-ash",
  "border-ash/40 text-ash",
  "border-electric-cyan/20 text-electric-cyan/60",
  "border-electric-cyan/30 text-electric-cyan/70",
  "border-electric-cyan/50 text-electric-cyan/80",
  "border-iris-purple/40 text-iris-light/80",
  "border-iris-purple text-iris-light",
];

export default function DefenseInDepthSection() {
  return (
    <section className="py-32 px-6 overflow-x-hidden">
      <div className="max-w-6xl mx-auto">
        <h2 className="font-mono text-4xl md:text-5xl font-bold text-bone text-center mb-4">
          Defense in Depth
        </h2>
        <p className="text-ash text-center max-w-2xl mx-auto mb-16 text-lg">
          Not one lock &mdash; seven. Each independently enforceable, all composable.
        </p>

        {/* Stacking layers — no stagger on mobile, progressive stagger on desktop */}
        <div className="max-w-3xl mx-auto space-y-3">
          {ENFORCERS.map((enforcer, i) => {
            const inset = (6 - i) * 12;
            return (
              <div
                key={enforcer.name}
                className={`border ${LAYER_COLORS[i]} rounded-xl p-4 md:p-5 bg-onyx transition-all hover:bg-onyx/80 mx-0 md:mx-[var(--inset)]`}
                style={{ "--inset": `${inset}px` } as React.CSSProperties}
              >
                <div className="flex items-center justify-between gap-2 md:gap-4">
                  <div className="flex items-center gap-2 md:gap-3 min-w-0">
                    <span className="font-mono text-xs text-ash/60 w-5 shrink-0">
                      {enforcer.layer}
                    </span>
                    <span className="font-mono text-xs sm:text-sm md:text-base text-bone truncate">
                      {enforcer.name}
                    </span>
                  </div>
                  <span className="text-xs sm:text-sm text-ash text-right shrink-0">
                    {enforcer.description}
                  </span>
                </div>
              </div>
            );
          })}
        </div>

        <p className="text-ash/60 text-center max-w-xl mx-auto mt-12 text-sm font-mono">
          Every enforcer is a standalone smart contract. Compose them per-delegation
          to match your threat model.
        </p>
      </div>
    </section>
  );
}
