export default function BuiltBySection() {
  return (
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
  );
}
