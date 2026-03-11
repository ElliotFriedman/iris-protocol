"use client";

import { ReactNode } from "react";
import { DemoProvider } from "@/lib/demo-context";
import Header from "@/components/Header";

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
