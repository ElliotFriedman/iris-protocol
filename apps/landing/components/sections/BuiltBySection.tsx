export default function BuiltBySection() {
  return (
    <section className="py-32 px-6">
      <div className="max-w-4xl mx-auto text-center">
        <h2 className="font-mono text-4xl md:text-5xl font-bold text-bone mb-12">
          Built by
        </h2>

        <div className="bg-onyx rounded-2xl p-8 border border-graphite/40 inline-block text-left max-w-lg w-full">
          <div className="flex items-center gap-4 mb-6">
            <div className="w-16 h-16 rounded-full bg-iris-purple flex items-center justify-center">
              <span className="font-mono text-xl font-bold text-bone">E</span>
            </div>
            <div>
              <h3 className="font-mono text-xl text-bone">Elliot</h3>
              <p className="text-sm text-ash">Smart Contract Security &amp; Infrastructure</p>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4 mb-6">
            {[
              { value: "67+", label: "Contracts Deployed" },
              { value: "$2B+", label: "TVL Secured" },
              { value: "0", label: "Security Incidents" },
              { value: "Kleidi", label: "Founder" },
            ].map((stat) => (
              <div key={stat.label} className="bg-void rounded-lg p-3">
                <div className="font-mono text-lg text-electric-cyan">{stat.value}</div>
                <div className="text-xs text-ash">{stat.label}</div>
              </div>
            ))}
          </div>

          <p className="text-sm text-ash">
            Stanford Blockchain Review &middot; Protocol infrastructure engineer
          </p>
        </div>
      </div>
    </section>
  );
}
