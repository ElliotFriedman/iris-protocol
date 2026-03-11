import IrisAperture from "@/components/ui/IrisAperture";

const SPONSORS = ["Base", "MetaMask", "EF dAI", "Uniswap", "Self Protocol"];

export default function Footer() {
  return (
    <footer className="border-t border-white/5 py-16 px-6 bg-[#0D0D14]">
      <div className="max-w-6xl mx-auto">
        <div className="flex flex-col md:flex-row items-center justify-between gap-8 mb-12">
          <div className="flex items-center gap-3">
            <IrisAperture tier={2} size={28} />
            <span className="font-mono font-bold text-white">
              iris<span className="text-[#00F0FF]">.</span>protocol
            </span>
          </div>

          <div className="flex gap-6">
            <a href="#" className="text-sm text-gray-500 hover:text-white transition-colors">
              GitHub
            </a>
            <a href="../docs" className="text-sm text-gray-500 hover:text-white transition-colors">
              Documentation
            </a>
            <a href="../app" className="text-sm text-gray-500 hover:text-white transition-colors">
              Demo App
            </a>
          </div>
        </div>

        {/* Synthesis badge */}
        <div className="text-center mb-10">
          <span className="inline-block px-4 py-2 bg-[#232340] rounded-full text-sm font-mono text-gray-400 border border-white/5">
            Built at The Synthesis 2026
          </span>
        </div>

        {/* Sponsor logos placeholder */}
        <div className="border-t border-white/5 pt-8">
          <p className="text-xs text-gray-600 text-center mb-4 font-mono uppercase tracking-widest">
            Sponsors
          </p>
          <div className="flex flex-wrap items-center justify-center gap-8">
            {SPONSORS.map((name) => (
              <span
                key={name}
                className="font-mono text-sm text-gray-600 hover:text-gray-400 transition-colors"
              >
                {name}
              </span>
            ))}
          </div>
        </div>

        <p className="text-center text-xs text-gray-700 mt-8">
          &copy; 2026 Iris Protocol. All rights reserved.
        </p>
      </div>
    </footer>
  );
}
