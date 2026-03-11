import { type FC } from 'react'
import { useAccount } from 'wagmi'
import { Copy, ExternalLink } from 'lucide-react'
import { useToast } from '../components/ToastContainer'
import { truncateAddress } from '../lib/utils'
import {
  IRIS_ACCOUNT_FACTORY,
  IRIS_DELEGATION_MANAGER,
  IRIS_AGENT_REGISTRY,
  IRIS_REPUTATION_ORACLE,
} from '../config/contracts'

const contractInfo = [
  { name: 'IrisAccountFactory', address: IRIS_ACCOUNT_FACTORY },
  { name: 'IrisDelegationManager', address: IRIS_DELEGATION_MANAGER },
  { name: 'IrisAgentRegistry', address: IRIS_AGENT_REGISTRY },
  { name: 'IrisReputationOracle', address: IRIS_REPUTATION_ORACLE },
]

const Settings: FC = () => {
  const { address, isConnected, chain } = useAccount()
  const { addToast } = useToast()

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text)
    addToast('info', 'Copied to clipboard')
  }

  return (
    <div className="flex flex-col gap-8">
      <div>
        <h1 className="font-mono text-2xl font-semibold text-bone mb-1">Settings</h1>
        <p className="text-sm text-ash">Network and contract configuration</p>
      </div>

      {/* Connection Info */}
      <div
        className="p-5 border border-graphite"
        style={{ borderRadius: 8, backgroundColor: 'var(--color-obsidian)' }}
      >
        <h3 className="font-mono text-sm font-semibold text-ash mb-4 uppercase tracking-wider">
          Connection
        </h3>
        <div className="flex flex-col gap-3">
          <div className="flex items-center justify-between">
            <span className="text-sm text-ash">Status</span>
            <span className="font-mono text-sm" style={{ color: isConnected ? 'var(--color-mint)' : 'var(--color-ash)' }}>
              {isConnected ? 'Connected' : 'Disconnected'}
            </span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-sm text-ash">Network</span>
            <span className="font-mono text-sm text-bone">{chain?.name ?? 'N/A'}</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-sm text-ash">Chain ID</span>
            <span className="font-mono text-sm" style={{ color: 'var(--color-cyan)' }}>
              {chain?.id ?? 'N/A'}
            </span>
          </div>
          {address && (
            <div className="flex items-center justify-between">
              <span className="text-sm text-ash">Account</span>
              <button
                onClick={() => copyToClipboard(address)}
                className="flex items-center gap-2 font-mono text-sm text-bone bg-transparent border-0 cursor-pointer hover:text-cyan transition-colors p-0"
              >
                {truncateAddress(address)}
                <Copy size={14} strokeWidth={1.5} />
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Contract Addresses */}
      <div
        className="p-5 border border-graphite"
        style={{ borderRadius: 8, backgroundColor: 'var(--color-obsidian)' }}
      >
        <h3 className="font-mono text-sm font-semibold text-ash mb-4 uppercase tracking-wider">
          Contract Addresses
        </h3>
        <div className="flex flex-col gap-3">
          {contractInfo.map(({ name, address: addr }) => (
            <div key={name} className="flex items-center justify-between">
              <span className="text-sm text-ash">{name}</span>
              <div className="flex items-center gap-2">
                <span className="font-mono text-xs text-bone">{truncateAddress(addr)}</span>
                <button
                  onClick={() => copyToClipboard(addr)}
                  className="text-ash hover:text-bone bg-transparent border-0 cursor-pointer p-0 transition-colors"
                >
                  <Copy size={14} strokeWidth={1.5} />
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

export default Settings
