export default function TrustProblemSection() {
  return (
    <section id="problem" className="py-32 px-6">
      <div className="max-w-6xl mx-auto">
        <h2 className="font-mono text-4xl md:text-5xl font-bold text-bone text-center mb-6">
          The Trust Problem
        </h2>
        <p className="text-ash text-center max-w-3xl mx-auto mb-12 text-lg">
          Embedded wallet providers require trusting a company with key shards and TEEs.
          For AI agents operating with real economic value, these trust assumptions are
          unacceptable.
        </p>

        {/* Trust gap stats */}
        <div className="grid md:grid-cols-3 gap-4 mb-16">
          <div className="bg-onyx rounded-xl p-6 border border-signal-red/20 text-center">
            <div className="font-mono text-2xl md:text-3xl font-bold text-signal-red mb-2">$47K</div>
            <p className="text-sm text-ash">Lost to a single recursive agent loop &mdash; 11 days undetected</p>
          </div>
          <div className="bg-onyx rounded-xl p-6 border border-signal-red/20 text-center">
            <div className="font-mono text-2xl md:text-3xl font-bold text-signal-red mb-2">42%</div>
            <p className="text-sm text-ash">of consumers fear losing control over AI purchases</p>
            <p className="text-xs text-ash/60 mt-1">Checkout.com</p>
          </div>
          <div className="bg-onyx rounded-xl p-6 border border-signal-red/20 text-center">
            <div className="font-mono text-2xl md:text-3xl font-bold text-signal-red mb-2">97% &rarr; 11%</div>
            <p className="text-sm text-ash">of CFOs understand agent autonomy, but only 11% are testing it</p>
            <p className="text-xs text-ash/60 mt-1">PYMNTS</p>
          </div>
        </div>

        <div className="grid md:grid-cols-2 gap-8">
          {/* Privy / Custodial Side */}
          <div className="bg-onyx rounded-2xl p-8 border border-signal-red/20">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-3 h-3 rounded-full bg-signal-red" />
              <h3 className="font-mono text-xl text-signal-red">Custodial Embedded Wallets</h3>
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
                  <span className="text-signal-red mt-1 text-lg">&#x2717;</span>
                  <div>
                    <span className="text-bone font-medium">{item.label}</span>
                    <p className="text-ash text-sm">{item.desc}</p>
                  </div>
                </li>
              ))}
            </ul>
          </div>

          {/* Iris / Trustless Side */}
          <div className="bg-onyx rounded-2xl p-8 border border-electric-cyan/20">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-3 h-3 rounded-full bg-electric-cyan" />
              <h3 className="font-mono text-xl text-electric-cyan">Iris Protocol</h3>
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
                  <span className="text-electric-cyan mt-1 text-lg">&#x2713;</span>
                  <div>
                    <span className="text-bone font-medium">{item.label}</span>
                    <p className="text-ash text-sm">{item.desc}</p>
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
