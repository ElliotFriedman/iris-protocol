export default function TrustProblemSection() {
  return (
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
  );
}
