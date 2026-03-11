export default function ReputationSection() {
  return (
    <section id="reputation" className="py-32 px-6 bg-void">
      <div className="max-w-6xl mx-auto">
        <h2 className="font-mono text-4xl md:text-5xl font-bold text-bone text-center mb-4">
          ReputationGateEnforcer
        </h2>
        <p className="text-electric-cyan text-center max-w-2xl mx-auto mb-4 text-xl font-mono">
          A network-level immune system
        </p>
        <p className="text-ash text-center max-w-2xl mx-auto mb-6 text-lg">
          A novel caveat enforcer that queries ERC-8004 reputation in real-time.
          Agent permissions degrade automatically if reputation drops.
        </p>
        <p className="text-ash/80 text-center max-w-3xl mx-auto mb-12 text-base">
          When an agent misbehaves, its reputation drops. Every delegation using
          ReputationGateEnforcer blocks the agent automatically &mdash; no manual revocation
          required. A self-healing trust network.
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
                <div className="bg-onyx border border-iris-purple/30 rounded-xl p-5 text-center min-w-[180px]">
                  <div className="font-mono text-xs text-ash mb-2">STEP {item.step}</div>
                  <div className="font-mono text-sm text-bone mb-1">{item.title}</div>
                  <div className="text-xs text-ash">{item.desc}</div>
                </div>
                {i < 3 && (
                  <span className="hidden md:block text-electric-cyan font-mono text-xl">&rarr;</span>
                )}
              </div>
            ))}
          </div>

          <div className="mt-12 bg-onyx rounded-xl p-6 border border-graphite/40">
            <div className="font-mono text-sm text-ash mb-4">{"// ReputationGateEnforcer.sol"}</div>
            <pre className="font-mono text-sm text-electric-cyan/80 overflow-x-auto">
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
  );
}
