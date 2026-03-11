import { type FC, useState } from 'react'
import { Link } from 'react-router-dom'
import { Bot, Plus, X, ExternalLink } from 'lucide-react'
import ReputationGauge from '../components/ReputationGauge'
import TierBadge from '../components/TierBadge'
import StatusBadge from '../components/StatusBadge'
import { mockAgents } from '../lib/mock-data'
import { truncateAddress } from '../lib/utils'
import { useToast } from '../components/ToastContainer'

const Agents: FC = () => {
  const [showModal, setShowModal] = useState(false)
  const [agentName, setAgentName] = useState('')
  const [metadataURI, setMetadataURI] = useState('')
  const { addToast } = useToast()

  const handleRegister = () => {
    if (!agentName.trim()) return
    addToast('success', `Agent "${agentName}" registered successfully`)
    setShowModal(false)
    setAgentName('')
    setMetadataURI('')
  }

  return (
    <div className="flex flex-col gap-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-mono text-2xl font-semibold text-bone mb-1">My Agents</h1>
          <p className="text-sm text-ash">Manage registered AI agents</p>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="flex items-center gap-2 px-4 py-2.5 text-sm font-medium text-bone border-0 cursor-pointer transition-opacity hover:opacity-90"
          style={{ borderRadius: 6, backgroundColor: 'var(--color-iris)' }}
        >
          <Plus size={18} strokeWidth={1.5} />
          Register New Agent
        </button>
      </div>

      {/* Agent Cards */}
      <div className="grid grid-cols-2 gap-4">
        {mockAgents.map((agent) => (
          <div
            key={agent.id}
            className="flex flex-col gap-4 p-5 border border-graphite"
            style={{ borderRadius: 8, backgroundColor: 'var(--color-obsidian)' }}
          >
            <div className="flex items-start justify-between">
              <div className="flex items-center gap-3">
                <div
                  className="w-10 h-10 flex items-center justify-center border border-graphite"
                  style={{ borderRadius: 8, backgroundColor: 'var(--color-void)' }}
                >
                  <Bot size={20} strokeWidth={1.5} style={{ color: 'var(--color-iris)' }} />
                </div>
                <div>
                  <h3 className="text-sm font-medium text-bone">{agent.name}</h3>
                  <span className="font-mono text-xs text-ash">{truncateAddress(agent.address)}</span>
                </div>
              </div>
              <StatusBadge status={agent.active ? 'active' : 'inactive'} />
            </div>

            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <ReputationGauge score={agent.reputationScore} size={48} />
                <div>
                  <div className="text-xs text-ash">Reputation</div>
                  <div className="font-mono text-sm text-bone">{agent.reputationScore}/100</div>
                </div>
              </div>
              <TierBadge tier={agent.activeTier} />
            </div>

            <div className="flex items-center gap-2 pt-2 border-t border-graphite">
              <Link
                to={`/delegate/${agent.address}`}
                className="flex-1 flex items-center justify-center gap-2 py-2 text-sm text-bone no-underline border border-graphite hover:border-iris transition-colors"
                style={{ borderRadius: 6, backgroundColor: 'var(--color-void)' }}
              >
                Configure
                <ExternalLink size={14} strokeWidth={1.5} />
              </Link>
            </div>
          </div>
        ))}
      </div>

      {/* Register Modal */}
      {showModal && (
        <div
          className="fixed inset-0 flex items-center justify-center"
          style={{ backgroundColor: 'rgba(13,13,20,0.8)', zIndex: 40 }}
          onClick={() => setShowModal(false)}
        >
          <div
            className="w-full max-w-md p-6 border border-graphite"
            style={{ borderRadius: 8, backgroundColor: 'var(--color-obsidian)' }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between mb-6">
              <h2 className="font-mono text-lg font-semibold text-bone">Register New Agent</h2>
              <button
                onClick={() => setShowModal(false)}
                className="text-ash hover:text-bone cursor-pointer bg-transparent border-0 p-0"
              >
                <X size={20} strokeWidth={1.5} />
              </button>
            </div>

            <div className="flex flex-col gap-4">
              <div>
                <label className="block text-sm text-ash mb-1.5">Agent Name</label>
                <input
                  type="text"
                  value={agentName}
                  onChange={(e) => setAgentName(e.target.value)}
                  placeholder="e.g. TradeBot Alpha"
                  className="w-full px-3 py-2.5 text-sm text-bone border border-graphite outline-none focus:border-iris transition-colors"
                  style={{
                    borderRadius: 4,
                    backgroundColor: 'var(--color-void)',
                  }}
                />
              </div>

              <div>
                <label className="block text-sm text-ash mb-1.5">Metadata URI</label>
                <input
                  type="text"
                  value={metadataURI}
                  onChange={(e) => setMetadataURI(e.target.value)}
                  placeholder="ipfs://..."
                  className="w-full px-3 py-2.5 text-sm text-bone font-mono border border-graphite outline-none focus:border-iris transition-colors"
                  style={{
                    borderRadius: 4,
                    backgroundColor: 'var(--color-void)',
                  }}
                />
              </div>

              <button
                onClick={handleRegister}
                className="w-full py-2.5 text-sm font-medium text-bone border-0 cursor-pointer transition-opacity hover:opacity-90 mt-2"
                style={{ borderRadius: 6, backgroundColor: 'var(--color-iris)' }}
              >
                Register Agent
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default Agents
