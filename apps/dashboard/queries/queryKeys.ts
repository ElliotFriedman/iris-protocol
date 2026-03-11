export const queryKeys = {
  delegation: {
    all: ["delegations"] as const,
    byId: (id: string) => ["delegations", id] as const,
  },
  agents: {
    all: ["agents"] as const,
    byId: (id: number) => ["agents", id] as const,
    reputation: (id: number) => ["agents", id, "reputation"] as const,
  },
  wallet: {
    all: ["wallet"] as const,
  },
};
