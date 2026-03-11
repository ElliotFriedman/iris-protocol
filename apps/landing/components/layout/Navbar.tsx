"use client";

import { useState } from "react";
import IrisAperture from "@/components/ui/IrisAperture";

export default function Navbar() {
  const [mobileOpen, setMobileOpen] = useState(false);

  const navLinks = [
    { href: "#problem", label: "Problem" },
    { href: "#solution", label: "Solution" },
    { href: "#stack", label: "ERC Stack" },
    { href: "#reputation", label: "Reputation" },
  ];

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 border-b border-graphite/40 backdrop-blur-md bg-void/80">
      <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <IrisAperture tier={2} size={32} />
          <span className="font-mono font-bold text-bone text-lg">
            iris<span className="text-electric-cyan">.</span>protocol
          </span>
        </div>

        {/* Desktop nav */}
        <div className="hidden md:flex items-center gap-8">
          {navLinks.map((link) => (
            <a
              key={link.href}
              href={link.href}
              className="text-sm font-sans font-medium text-ash hover:text-bone transition-colors"
            >
              {link.label}
            </a>
          ))}
          <a
            href="../app"
            className="px-4 py-2 bg-iris-purple hover:bg-[#8E4FCC] text-bone text-sm font-sans font-medium rounded-[8px] transition-colors"
          >
            Launch App
          </a>
        </div>

        {/* Mobile hamburger */}
        <button
          className="md:hidden flex flex-col gap-1.5 p-2"
          onClick={() => setMobileOpen(!mobileOpen)}
          aria-label={mobileOpen ? "Close menu" : "Open menu"}
          aria-expanded={mobileOpen}
        >
          <span
            className={`block w-5 h-0.5 bg-bone transition-transform ease-out duration-200 ${
              mobileOpen ? "translate-y-2 rotate-45" : ""
            }`}
          />
          <span
            className={`block w-5 h-0.5 bg-bone transition-opacity ease-out duration-200 ${
              mobileOpen ? "opacity-0" : ""
            }`}
          />
          <span
            className={`block w-5 h-0.5 bg-bone transition-transform ease-out duration-200 ${
              mobileOpen ? "-translate-y-2 -rotate-45" : ""
            }`}
          />
        </button>
      </div>

      {/* Mobile menu */}
      {mobileOpen && (
        <div className="md:hidden border-t border-graphite/40 bg-void/95 backdrop-blur-md">
          <div className="px-6 py-4 flex flex-col gap-4">
            {navLinks.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className="text-sm font-sans font-medium text-ash hover:text-bone transition-colors py-2"
                onClick={() => setMobileOpen(false)}
              >
                {link.label}
              </a>
            ))}
            <a
              href="../app"
              className="px-4 py-3 bg-iris-purple hover:bg-[#8E4FCC] text-bone text-sm font-sans font-medium rounded-[8px] transition-colors text-center"
            >
              Launch App
            </a>
          </div>
        </div>
      )}
    </nav>
  );
}
