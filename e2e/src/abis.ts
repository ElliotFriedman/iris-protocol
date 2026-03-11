// Minimal ABIs for E2E testing — only the functions we call

export const IrisDelegationManagerABI = [
  {
    type: "function",
    name: "getDelegationHash",
    inputs: [
      {
        name: "delegation",
        type: "tuple",
        components: [
          { name: "delegator", type: "address" },
          { name: "delegate", type: "address" },
          { name: "authority", type: "address" },
          {
            name: "caveats",
            type: "tuple[]",
            components: [
              { name: "enforcer", type: "address" },
              { name: "terms", type: "bytes" },
            ],
          },
          { name: "salt", type: "uint256" },
          { name: "signature", type: "bytes" },
        ],
      },
    ],
    outputs: [{ name: "", type: "bytes32" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "redeemDelegation",
    inputs: [
      {
        name: "delegations",
        type: "tuple[]",
        components: [
          { name: "delegator", type: "address" },
          { name: "delegate", type: "address" },
          { name: "authority", type: "address" },
          {
            name: "caveats",
            type: "tuple[]",
            components: [
              { name: "enforcer", type: "address" },
              { name: "terms", type: "bytes" },
            ],
          },
          { name: "salt", type: "uint256" },
          { name: "signature", type: "bytes" },
        ],
      },
      {
        name: "action",
        type: "tuple",
        components: [
          { name: "target", type: "address" },
          { name: "value", type: "uint256" },
          { name: "callData", type: "bytes" },
        ],
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "revokeDelegation",
    inputs: [
      {
        name: "delegation",
        type: "tuple",
        components: [
          { name: "delegator", type: "address" },
          { name: "delegate", type: "address" },
          { name: "authority", type: "address" },
          {
            name: "caveats",
            type: "tuple[]",
            components: [
              { name: "enforcer", type: "address" },
              { name: "terms", type: "bytes" },
            ],
          },
          { name: "salt", type: "uint256" },
          { name: "signature", type: "bytes" },
        ],
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "revokedDelegations",
    inputs: [{ name: "", type: "bytes32" }],
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "domainSeparator",
    inputs: [],
    outputs: [{ name: "", type: "bytes32" }],
    stateMutability: "view",
  },
  {
    type: "event",
    name: "DelegationRedeemed",
    inputs: [
      { name: "delegationHash", type: "bytes32", indexed: true },
      { name: "delegator", type: "address", indexed: true },
      { name: "delegate", type: "address", indexed: true },
    ],
  },
  {
    type: "event",
    name: "DelegationRevoked",
    inputs: [
      { name: "delegationHash", type: "bytes32", indexed: true },
      { name: "delegator", type: "address", indexed: true },
    ],
  },
] as const;

export const IrisAccountFactoryABI = [
  {
    type: "function",
    name: "createAccount",
    inputs: [
      { name: "owner", type: "address" },
      { name: "delegationManager", type: "address" },
      { name: "salt", type: "uint256" },
    ],
    outputs: [{ name: "", type: "address" }],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "getAddress",
    inputs: [
      { name: "owner", type: "address" },
      { name: "delegationManager", type: "address" },
      { name: "salt", type: "uint256" },
    ],
    outputs: [{ name: "", type: "address" }],
    stateMutability: "view",
  },
] as const;

export const IrisAgentRegistryABI = [
  {
    type: "function",
    name: "registerAgent",
    inputs: [{ name: "metadataURI", type: "string" }],
    outputs: [{ name: "agentId", type: "uint256" }],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "getAgent",
    inputs: [{ name: "agentId", type: "uint256" }],
    outputs: [
      {
        name: "info",
        type: "tuple",
        components: [
          { name: "operator", type: "address" },
          { name: "metadataURI", type: "string" },
          { name: "active", type: "bool" },
          { name: "registeredAt", type: "uint256" },
        ],
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "isRegistered",
    inputs: [{ name: "agentId", type: "uint256" }],
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "deactivateAgent",
    inputs: [{ name: "agentId", type: "uint256" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
] as const;

export const IrisReputationOracleABI = [
  {
    type: "function",
    name: "getReputationScore",
    inputs: [{ name: "agentId", type: "uint256" }],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "submitFeedback",
    inputs: [
      { name: "agentId", type: "uint256" },
      { name: "positive", type: "bool" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "addReviewer",
    inputs: [
      { name: "agentId", type: "uint256" },
      { name: "reviewer", type: "address" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
] as const;

export const IrisAccountABI = [
  {
    type: "function",
    name: "owner",
    inputs: [],
    outputs: [{ name: "", type: "address" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "delegationManager",
    inputs: [],
    outputs: [{ name: "", type: "address" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "execute",
    inputs: [
      { name: "target", type: "address" },
      { name: "value", type: "uint256" },
      { name: "data", type: "bytes" },
    ],
    outputs: [{ name: "result", type: "bytes" }],
    stateMutability: "nonpayable",
  },
] as const;

export const MockERC20ABI = [
  {
    type: "function",
    name: "balanceOf",
    inputs: [{ name: "account", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "mint",
    inputs: [
      { name: "to", type: "address" },
      { name: "amount", type: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "transfer",
    inputs: [
      { name: "to", type: "address" },
      { name: "amount", type: "uint256" },
    ],
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "approve",
    inputs: [
      { name: "spender", type: "address" },
      { name: "amount", type: "uint256" },
    ],
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "nonpayable",
  },
] as const;

export const IrisApprovalQueueABI = [
  {
    type: "function",
    name: "submitRequest",
    inputs: [
      { name: "target", type: "address" },
      { name: "callData", type: "bytes" },
      { name: "value", type: "uint256" },
      { name: "delegationHash", type: "bytes32" },
      { name: "delegator", type: "address" },
    ],
    outputs: [{ name: "requestId", type: "bytes32" }],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "approveRequest",
    inputs: [{ name: "requestId", type: "bytes32" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "rejectRequest",
    inputs: [{ name: "requestId", type: "bytes32" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "getRequest",
    inputs: [{ name: "requestId", type: "bytes32" }],
    outputs: [
      {
        name: "",
        type: "tuple",
        components: [
          { name: "agent", type: "address" },
          { name: "target", type: "address" },
          { name: "callData", type: "bytes" },
          { name: "value", type: "uint256" },
          { name: "delegationHash", type: "bytes32" },
          { name: "submittedAt", type: "uint256" },
          { name: "approved", type: "bool" },
          { name: "rejected", type: "bool" },
          { name: "executed", type: "bool" },
        ],
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getPendingRequests",
    inputs: [{ name: "delegator", type: "address" }],
    outputs: [{ name: "", type: "bytes32[]" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "isExpired",
    inputs: [{ name: "requestId", type: "bytes32" }],
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "view",
  },
] as const;
