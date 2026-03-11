import type { Address } from 'viem'

interface DeploymentManifest {
  chainId: number
  contracts: Record<string, { address: string }>
}

// Import deployment addresses - in production this would be loaded dynamically
const deployments: DeploymentManifest = {
  chainId: 31337,
  contracts: {
    IrisAccountFactory: { address: '0x5FbDB2315678afecb367f032d93F642f64180aa3' },
    IrisDelegationManager: { address: '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512' },
    IrisAgentRegistry: { address: '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0' },
    IrisReputationOracle: { address: '0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9' },
    SpendingCapEnforcer: { address: '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9' },
    ContractWhitelistEnforcer: { address: '0x5FC8d32690cc91D4c39d9d3abcBD16989F875707' },
    TimeWindowEnforcer: { address: '0x0165878A594ca255338adfa4d48449f69242Eb8F' },
    ReputationGateEnforcer: { address: '0xa513E6E4b8f2a923D98304ec87F64353C4D5C853' },
  },
}

export function getContractAddress(name: string): Address {
  const contract = deployments.contracts[name]
  if (!contract) throw new Error(`Contract ${name} not found in deployment manifest`)
  return contract.address as Address
}

export const IRIS_ACCOUNT_FACTORY = getContractAddress('IrisAccountFactory')
export const IRIS_DELEGATION_MANAGER = getContractAddress('IrisDelegationManager')
export const IRIS_AGENT_REGISTRY = getContractAddress('IrisAgentRegistry')
export const IRIS_REPUTATION_ORACLE = getContractAddress('IrisReputationOracle')
export const SPENDING_CAP_ENFORCER = getContractAddress('SpendingCapEnforcer')
export const CONTRACT_WHITELIST_ENFORCER = getContractAddress('ContractWhitelistEnforcer')
export const TIME_WINDOW_ENFORCER = getContractAddress('TimeWindowEnforcer')
export const REPUTATION_GATE_ENFORCER = getContractAddress('ReputationGateEnforcer')
