const ERC_STACK = [
  { number: "4337", name: "Account Abstraction", role: "Smart contract wallet foundation" },
  { number: "7710", name: "Delegations", role: "Onchain permission delegation framework" },
  { number: "7715", name: "Permission Requests", role: "Standardized permission request flow" },
  { number: "8004", name: "Reputation Registry", role: "Native agent reputation scores" },
  { number: "8128", name: "Multi-Owner", role: "Multi-party account ownership" },
  { number: "7702", name: "Code Delegation", role: "EOA-to-smart-account migration" },
];

export default function StandardsSection() {
  return (
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
  );
}
