"use client";

import { createContext, useContext, useState, ReactNode } from "react";
import React from "react";

interface DemoContextType {
  demoMode: boolean;
  setDemoMode: (v: boolean) => void;
}

export const DemoContext = createContext<DemoContextType>({
  demoMode: true,
  setDemoMode: () => {},
});

export function DemoProvider({ children }: { children: ReactNode }) {
  const [demoMode, setDemoMode] = useState(true);
  return React.createElement(
    DemoContext.Provider,
    { value: { demoMode, setDemoMode } },
    children
  );
}

export function useDemoMode() {
  return useContext(DemoContext);
}
