import type { Address } from 'viem'

export interface Agent {
  id: string
  name: string
  address: Address
  reputationScore: number
  activeTier: number
  metadataURI: string
  registeredAt: number
  active: boolean
}

export interface Delegation {
  id: string
  agentAddress: Address
  agentName: string
  tier: number
  dailyCap: string
  allowedContracts: Address[]
  timeWindow: { start: number; end: number }
  reputationThreshold: number
  active: boolean
  createdAt: number
}

export interface ActivityEvent {
  id: string
  timestamp: number
  agent: Address
  agentName: string
  action: string
  value: string
  status: 'executed' | 'blocked'
  txHash: string
  reason?: string
}

export const mockAgents: Agent[] = [
  {
    id: '0x01',
    name: 'TradeBot Alpha',
    address: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    reputationScore: 87,
    activeTier: 2,
    metadataURI: 'ipfs://QmAgent1',
    registeredAt: Date.now() - 86400000 * 7,
    active: true,
  },
  {
    id: '0x02',
    name: 'DeFi Harvester',
    address: '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC',
    reputationScore: 94,
    activeTier: 3,
    metadataURI: 'ipfs://QmAgent2',
    registeredAt: Date.now() - 86400000 * 14,
    active: true,
  },
  {
    id: '0x03',
    name: 'Sentinel Watch',
    address: '0x90F79bf6EB2c4f870365E785982E1f101E93b906',
    reputationScore: 62,
    activeTier: 1,
    metadataURI: 'ipfs://QmAgent3',
    registeredAt: Date.now() - 86400000 * 3,
    active: true,
  },
  {
    id: '0x04',
    name: 'Gas Optimizer',
    address: '0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65',
    reputationScore: 45,
    activeTier: 0,
    metadataURI: 'ipfs://QmAgent4',
    registeredAt: Date.now() - 86400000 * 1,
    active: false,
  },
]

export const mockDelegations: Delegation[] = [
  {
    id: '0xd1',
    agentAddress: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    agentName: 'TradeBot Alpha',
    tier: 2,
    dailyCap: '1.5',
    allowedContracts: ['0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48' as Address],
    timeWindow: { start: Date.now() - 86400000, end: Date.now() + 86400000 * 6 },
    reputationThreshold: 70,
    active: true,
    createdAt: Date.now() - 86400000 * 5,
  },
  {
    id: '0xd2',
    agentAddress: '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC',
    agentName: 'DeFi Harvester',
    tier: 3,
    dailyCap: '5.0',
    allowedContracts: [],
    timeWindow: { start: Date.now() - 86400000 * 10, end: Date.now() + 86400000 * 20 },
    reputationThreshold: 85,
    active: true,
    createdAt: Date.now() - 86400000 * 10,
  },
  {
    id: '0xd3',
    agentAddress: '0x90F79bf6EB2c4f870365E785982E1f101E93b906',
    agentName: 'Sentinel Watch',
    tier: 1,
    dailyCap: '0.5',
    allowedContracts: ['0xdAC17F958D2ee523a2206206994597C13D831ec7' as Address],
    timeWindow: { start: Date.now(), end: Date.now() + 86400000 * 3 },
    reputationThreshold: 50,
    active: true,
    createdAt: Date.now() - 86400000 * 2,
  },
]

export const mockActivity: ActivityEvent[] = [
  {
    id: '1',
    timestamp: Date.now() - 300000,
    agent: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    agentName: 'TradeBot Alpha',
    action: 'swap(USDC, ETH)',
    value: '0.42 ETH',
    status: 'executed',
    txHash: '0xabc123def456789012345678901234567890abcdef1234567890abcdef123456',
  },
  {
    id: '2',
    timestamp: Date.now() - 900000,
    agent: '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC',
    agentName: 'DeFi Harvester',
    action: 'deposit(AAVE)',
    value: '2.1 ETH',
    status: 'executed',
    txHash: '0xdef456789012345678901234567890abcdef1234567890abcdef123456abc123',
  },
  {
    id: '3',
    timestamp: Date.now() - 1800000,
    agent: '0x90F79bf6EB2c4f870365E785982E1f101E93b906',
    agentName: 'Sentinel Watch',
    action: 'transfer(0x15d3...)',
    value: '0.8 ETH',
    status: 'blocked',
    txHash: '0x789012345678901234567890abcdef1234567890abcdef123456abc123def456',
    reason: 'SpendingCap exceeded',
  },
  {
    id: '4',
    timestamp: Date.now() - 3600000,
    agent: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    agentName: 'TradeBot Alpha',
    action: 'approve(USDC)',
    value: '0 ETH',
    status: 'executed',
    txHash: '0x012345678901234567890abcdef1234567890abcdef123456abc123def456789',
  },
  {
    id: '5',
    timestamp: Date.now() - 7200000,
    agent: '0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65',
    agentName: 'Gas Optimizer',
    action: 'execute(batch)',
    value: '1.2 ETH',
    status: 'blocked',
    txHash: '0x345678901234567890abcdef1234567890abcdef123456abc123def456789012',
    reason: 'Reputation below threshold',
  },
  {
    id: '6',
    timestamp: Date.now() - 10800000,
    agent: '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC',
    agentName: 'DeFi Harvester',
    action: 'harvest(Compound)',
    value: '0.15 ETH',
    status: 'executed',
    txHash: '0x678901234567890abcdef1234567890abcdef123456abc123def456789012345',
  },
  {
    id: '7',
    timestamp: Date.now() - 14400000,
    agent: '0x90F79bf6EB2c4f870365E785982E1f101E93b906',
    agentName: 'Sentinel Watch',
    action: 'call(0xA0b8...)',
    value: '0.3 ETH',
    status: 'blocked',
    txHash: '0x901234567890abcdef1234567890abcdef123456abc123def456789012345678',
    reason: 'Contract not whitelisted',
  },
  {
    id: '8',
    timestamp: Date.now() - 18000000,
    agent: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    agentName: 'TradeBot Alpha',
    action: 'swap(ETH, DAI)',
    value: '0.65 ETH',
    status: 'executed',
    txHash: '0xabcdef1234567890abcdef123456789012345678901234567890abcdef123456',
  },
]
