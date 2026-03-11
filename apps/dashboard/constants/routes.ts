export const ROUTES = {
  home: "/",
  agents: "/agents",
  delegate: "/delegate",
  delegation: (id: string) => `/delegations/${id}`,
} as const;
