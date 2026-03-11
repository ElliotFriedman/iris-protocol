import IrisAperture from "@/components/ui/IrisAperture";

const SPONSORS = ["Base", "MetaMask", "EF dAI", "Uniswap", "Self Protocol"];

export default function Footer() {
  return (
    <footer className="border-t border-graphite/40 py-16 px-6 bg-void">
      <div className="max-w-6xl mx-auto">
        <div className="flex flex-col md:flex-row items-center justify-between gap-8 mb-12">
          <div className="flex items-center gap-3">
            <IrisAperture tier={2} size={28} />
            <span className="font-mono font-bold text-bone">
              iris<span className="text-electric-cyan">.</span>protocol
            </span>
          </div>

          <div className="flex gap-6">
            <a href="#" className="text-sm text-ash hover:text-bone transition-colors">
              GitHub
            </a>
            <a href="../docs" className="text-sm text-ash hover:text-bone transition-colors">
              Documentation
            </a>
            <a href="../app" className="text-sm text-ash hover:text-bone transition-colors">
              Demo App
            </a>
          </div>
        </div>

        {/* Synthesis badge */}
        <div className="text-center mb-10">
          <span className="inline-block px-4 py-2 bg-onyx rounded-full text-sm font-mono text-ash border border-graphite/40">
            Built at The Synthesis 2026
          </span>
        </div>

        {/* Sponsor logos placeholder */}
        <div className="border-t border-graphite/40 pt-8">
          <p className="text-xs text-ash/60 text-center mb-4 font-mono uppercase tracking-widest">
            Sponsors
          </p>
          <div className="flex flex-wrap items-center justify-center gap-8">
            {SPONSORS.map((name) => (
              <span
                key={name}
                className="font-mono text-sm text-ash/60 hover:text-ash transition-colors"
              >
                {name}
              </span>
            ))}
          </div>
        </div>

        <p className="text-center text-xs text-ash/40 mt-8">
          &copy; 2026 Iris Protocol. All rights reserved.
        </p>
      </div>
    </footer>
  );
}
