export const irisAgentRegistryAbi = [
  {
    type: 'function',
    name: 'registerAgent',
    inputs: [{ name: 'metadataURI', type: 'string' }],
    outputs: [{ name: 'agentId', type: 'bytes32' }],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    name: 'getAgent',
    inputs: [{ name: 'agentId', type: 'bytes32' }],
    outputs: [
      {
        name: '',
        type: 'tuple',
        components: [
          { name: 'owner', type: 'address' },
          { name: 'metadataURI', type: 'string' },
          { name: 'registeredAt', type: 'uint256' },
          { name: 'active', type: 'bool' },
        ],
      },
    ],
    stateMutability: 'view',
  },
  {
    type: 'function',
    name: 'isRegistered',
    inputs: [{ name: 'agentId', type: 'bytes32' }],
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'view',
  },
  {
    type: 'event',
    name: 'AgentRegistered',
    inputs: [
      { name: 'agentId', type: 'bytes32', indexed: true },
      { name: 'owner', type: 'address', indexed: true },
      { name: 'metadataURI', type: 'string', indexed: false },
    ],
  },
] as const

export const irisReputationOracleAbi = [
  {
    type: 'function',
    name: 'getReputationScore',
    inputs: [{ name: 'agentId', type: 'bytes32' }],
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
  },
  {
    type: 'function',
    name: 'submitFeedback',
    inputs: [
      { name: 'agentId', type: 'bytes32' },
      { name: 'positive', type: 'bool' },
    ],
    outputs: [],
    stateMutability: 'nonpayable',
  },
] as const

export const irisDelegationManagerAbi = [
  {
    type: 'function',
    name: 'redeemDelegation',
    inputs: [
      {
        name: 'delegations',
        type: 'tuple[]',
        components: [
          { name: 'delegate', type: 'address' },
          { name: 'delegator', type: 'address' },
          { name: 'authority', type: 'bytes32' },
          { name: 'caveats', type: 'tuple[]', components: [
            { name: 'enforcer', type: 'address' },
            { name: 'terms', type: 'bytes' },
          ]},
          { name: 'salt', type: 'uint256' },
          { name: 'signature', type: 'bytes' },
        ],
      },
      {
        name: 'action',
        type: 'tuple',
        components: [
          { name: 'to', type: 'address' },
          { name: 'value', type: 'uint256' },
          { name: 'data', type: 'bytes' },
        ],
      },
    ],
    outputs: [],
    stateMutability: 'nonpayable',
  },
  {
    type: 'function',
    name: 'getDelegationHash',
    inputs: [
      {
        name: 'delegation',
        type: 'tuple',
        components: [
          { name: 'delegate', type: 'address' },
          { name: 'delegator', type: 'address' },
          { name: 'authority', type: 'bytes32' },
          { name: 'caveats', type: 'tuple[]', components: [
            { name: 'enforcer', type: 'address' },
            { name: 'terms', type: 'bytes' },
          ]},
          { name: 'salt', type: 'uint256' },
          { name: 'signature', type: 'bytes' },
        ],
      },
    ],
    outputs: [{ name: '', type: 'bytes32' }],
    stateMutability: 'view',
  },
  {
    type: 'event',
    name: 'AgentExecuted',
    inputs: [
      { name: 'agent', type: 'address', indexed: true },
      { name: 'to', type: 'address', indexed: true },
      { name: 'value', type: 'uint256', indexed: false },
      { name: 'data', type: 'bytes', indexed: false },
    ],
  },
  {
    type: 'event',
    name: 'ExecutionBlocked',
    inputs: [
      { name: 'agent', type: 'address', indexed: true },
      { name: 'enforcer', type: 'address', indexed: true },
      { name: 'reason', type: 'string', indexed: false },
    ],
  },
] as const

export const irisAccountFactoryAbi = [
  {
    type: 'function',
    name: 'createAccount',
    inputs: [
      { name: 'owner', type: 'address' },
      { name: 'delegationManager', type: 'address' },
      { name: 'salt', type: 'uint256' },
    ],
    outputs: [{ name: '', type: 'address' }],
    stateMutability: 'nonpayable',
  },
] as const
