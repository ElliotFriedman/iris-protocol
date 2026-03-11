"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useDemoMode } from "@/lib/demo-context";
import IrisAperture from "./IrisAperture";

const NAV_ITEMS = [
  { label: "Dashboard", href: "/" },
  { label: "Agents", href: "/agents" },
  { label: "Delegate", href: "/delegate" },
];

export default function Header() {
  const pathname = usePathname();
  const { demoMode, setDemoMode } = useDemoMode();

  return (
    <header className="fixed top-0 left-0 right-0 z-50 border-b border-white/5 backdrop-blur-md bg-[#1A1A2E]/90">
      <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
        <div className="flex items-center gap-8">
          <Link href="/" className="flex items-center gap-3">
            <IrisAperture tier={2} size={28} />
            <span className="font-mono font-bold text-white text-lg tracking-tight">
              iris<span className="text-[#00F0FF]">.</span>protocol
            </span>
          </Link>

          <nav className="hidden md:flex items-center gap-1">
            {NAV_ITEMS.map((item) => {
              const isActive = pathname === item.href;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                    isActive
                      ? "bg-[#7B2FBE]/20 text-[#00F0FF]"
                      : "text-gray-400 hover:text-white hover:bg-white/5"
                  }`}
                >
                  {item.label}
                </Link>
              );
            })}
          </nav>
        </div>

        <div className="flex items-center gap-4">
          {/* Demo Mode Toggle */}
          <button
            onClick={() => setDemoMode(!demoMode)}
            className={`flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-mono transition-all ${
              demoMode
                ? "bg-[#00F0FF]/10 text-[#00F0FF] border border-[#00F0FF]/30"
                : "bg-white/5 text-gray-500 border border-white/10"
            }`}
          >
            <div
              className={`w-2 h-2 rounded-full ${demoMode ? "bg-[#00F0FF]" : "bg-gray-600"}`}
            />
            Demo Mode
          </button>

          {/* Wallet connect placeholder */}
          {demoMode ? (
            <div className="px-4 py-2 bg-[#232340] rounded-lg text-sm text-gray-400 font-mono border border-white/5">
              0x1234...5678
            </div>
          ) : (
            <button className="px-4 py-2 bg-[#7B2FBE] hover:bg-[#6B25A8] text-white text-sm font-medium rounded-lg transition-colors">
              Connect Wallet
            </button>
          )}
        </div>
      </div>
    </header>
  );
}
