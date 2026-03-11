"use client";

import IrisAperture from "@/components/ui/IrisAperture";

export default function Navbar() {
  return (
    <nav className="fixed top-0 left-0 right-0 z-50 border-b border-white/5 backdrop-blur-md bg-[#0D0D14]/80">
      <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <IrisAperture tier={2} size={32} />
          <span className="font-mono font-bold text-white text-lg tracking-tight">
            iris<span className="text-[#00F0FF]">.</span>protocol
          </span>
        </div>
        <div className="hidden md:flex items-center gap-8">
          <a href="#problem" className="text-sm text-gray-400 hover:text-white transition-colors">
            Problem
          </a>
          <a href="#solution" className="text-sm text-gray-400 hover:text-white transition-colors">
            Solution
          </a>
          <a href="#stack" className="text-sm text-gray-400 hover:text-white transition-colors">
            ERC Stack
          </a>
          <a href="#reputation" className="text-sm text-gray-400 hover:text-white transition-colors">
            Reputation
          </a>
          <a
            href="../app"
            className="px-4 py-2 bg-[#7B2FBE] hover:bg-[#6B25A8] text-white text-sm font-medium rounded-lg transition-colors"
          >
            Launch App
          </a>
        </div>
      </div>
    </nav>
  );
}
