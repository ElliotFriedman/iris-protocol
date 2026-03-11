"use client";

import { useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useDemoMode } from "@/hooks/useDemoMode";
import IrisAperture from "@/components/ui/IrisAperture";

const NAV_ITEMS = [
  { label: "Dashboard", href: "/" },
  { label: "Agents", href: "/agents" },
  { label: "Delegate", href: "/delegate" },
];

export default function Header() {
  const pathname = usePathname();
  const { demoMode, setDemoMode } = useDemoMode();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  return (
    <header className="fixed top-0 left-0 right-0 z-50 border-b border-graphite backdrop-blur-md bg-obsidian/90">
      <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
        <div className="flex items-center gap-8">
          <Link href="/" className="flex items-center gap-3 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2 rounded-lg">
            <IrisAperture tier={2} size={28} />
            <span className="font-mono font-bold text-bone text-lg tracking-tight">
              iris<span className="text-electric-cyan">.</span>protocol
            </span>
          </Link>

          <nav className="hidden md:flex items-center gap-1">
            {NAV_ITEMS.map((item) => {
              const isActive = pathname === item.href;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2 ${
                    isActive
                      ? "bg-iris-purple/20 text-electric-cyan"
                      : "text-ash hover:text-bone hover:bg-graphite/30"
                  }`}
                >
                  {item.label}
                </Link>
              );
            })}
          </nav>
        </div>

        <div className="flex items-center gap-4">
          <button
            onClick={() => setDemoMode(!demoMode)}
            className={`hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-mono transition-all duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2 ${
              demoMode
                ? "bg-electric-cyan/10 text-electric-cyan border border-electric-cyan/30"
                : "bg-graphite/30 text-ash border border-graphite"
            }`}
          >
            <div
              className={`w-2 h-2 rounded-full ${demoMode ? "bg-electric-cyan" : "bg-ash"}`}
            />
            Demo Mode
          </button>

          {demoMode ? (
            <div className="hidden sm:block px-4 py-2 bg-onyx rounded-lg text-sm text-ash font-mono border border-graphite">
              0x1234...5678
            </div>
          ) : (
            <button className="hidden sm:block px-4 py-2 bg-iris-purple hover:bg-iris-purple/80 text-bone text-sm font-medium rounded-lg transition-colors duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2">
              Connect Wallet
            </button>
          )}

          {/* Mobile hamburger */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="md:hidden flex items-center justify-center w-10 h-10 rounded-lg text-ash hover:text-bone hover:bg-graphite/30 transition-colors duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2"
            aria-label="Toggle navigation menu"
            aria-expanded={mobileMenuOpen}
          >
            {mobileMenuOpen ? (
              <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                <line x1="4" y1="4" x2="16" y2="16" />
                <line x1="16" y1="4" x2="4" y2="16" />
              </svg>
            ) : (
              <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                <line x1="3" y1="5" x2="17" y2="5" />
                <line x1="3" y1="10" x2="17" y2="10" />
                <line x1="3" y1="15" x2="17" y2="15" />
              </svg>
            )}
          </button>
        </div>
      </div>

      {/* Mobile menu dropdown */}
      {mobileMenuOpen && (
        <div className="md:hidden border-t border-graphite bg-obsidian/95 backdrop-blur-md">
          <nav className="flex flex-col px-6 py-4 gap-1">
            {NAV_ITEMS.map((item) => {
              const isActive = pathname === item.href;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={() => setMobileMenuOpen(false)}
                  className={`px-4 py-3 rounded-lg text-sm font-medium transition-colors duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2 ${
                    isActive
                      ? "bg-iris-purple/20 text-electric-cyan"
                      : "text-ash hover:text-bone hover:bg-graphite/30"
                  }`}
                >
                  {item.label}
                </Link>
              );
            })}
          </nav>

          <div className="flex items-center gap-3 px-6 pb-4">
            <button
              onClick={() => setDemoMode(!demoMode)}
              className={`flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-mono transition-all duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2 ${
                demoMode
                  ? "bg-electric-cyan/10 text-electric-cyan border border-electric-cyan/30"
                  : "bg-graphite/30 text-ash border border-graphite"
              }`}
            >
              <div
                className={`w-2 h-2 rounded-full ${demoMode ? "bg-electric-cyan" : "bg-ash"}`}
              />
              Demo Mode
            </button>

            {demoMode ? (
              <div className="px-3 py-1.5 bg-onyx rounded-lg text-xs text-ash font-mono border border-graphite">
                0x1234...5678
              </div>
            ) : (
              <button className="px-3 py-1.5 bg-iris-purple hover:bg-iris-purple/80 text-bone text-xs font-medium rounded-lg transition-colors duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-iris-purple focus-visible:outline-offset-2">
                Connect
              </button>
            )}
          </div>
        </div>
      )}
    </header>
  );
}
