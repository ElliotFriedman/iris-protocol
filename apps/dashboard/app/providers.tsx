"use client";

import { ReactNode } from "react";
import { DemoProvider } from "@/hooks/useDemoMode";
import Header from "@/components/layout/Header";

export function Providers({ children }: { children: ReactNode }) {
  return (
    <DemoProvider>
      <Header />
      <main className="pt-16 min-h-screen">
        {children}
      </main>
    </DemoProvider>
  );
}
