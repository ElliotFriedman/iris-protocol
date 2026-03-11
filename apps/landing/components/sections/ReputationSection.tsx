export default function ReputationSection() {
  return (
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
  );
}
