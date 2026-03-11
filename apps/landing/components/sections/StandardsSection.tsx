const ERC_STACK = [
  { number: "4337", name: "Account Abstraction", role: "Smart contract wallet foundation" },
  { number: "7710", name: "Delegations", role: "Onchain permission delegation framework (MetaMask)" },
  { number: "7715", name: "Permission Requests", role: "Standardized permission request flow" },
  { number: "8004", name: "Reputation Registry", role: "Native agent reputation scores (EF dAI)" },
  { number: "8128", name: "Multi-Owner", role: "Multi-party account ownership" },
  { number: "7702", name: "Code Delegation", role: "EOA-to-smart-account migration" },
];

export default function StandardsSection() {
  return (
    <section id="stack" className="py-32 px-6">
      <div className="max-w-6xl mx-auto">
        <h2 className="font-mono text-4xl md:text-5xl font-bold text-bone text-center mb-4">
          Built on Standards
        </h2>
        <p className="text-ash text-center max-w-2xl mx-auto mb-16 text-lg">
          Six ERCs compose to create a trustless agent permission layer.
        </p>

        <div className="grid md:grid-cols-3 gap-4">
          {ERC_STACK.map((erc) => (
            <div
              key={erc.number}
              className="bg-onyx rounded-xl p-6 border border-graphite/40 hover:border-iris-purple/30 transition-all group"
            >
              <div className="flex items-baseline gap-2 mb-3">
                <span className="font-mono text-2xl font-bold text-electric-cyan group-hover:text-bone transition-colors">
                  ERC-{erc.number}
                </span>
              </div>
              <p className="font-mono text-sm text-bone mb-1">{erc.name}</p>
              <p className="text-sm text-ash">{erc.role}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
