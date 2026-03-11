import { type FC, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { ArrowLeft, Shield, ShieldCheck, ShieldAlert, Zap } from 'lucide-react'
import IrisAperture from '../components/IrisAperture'
import TierBadge from '../components/TierBadge'
import StatusBadge from '../components/StatusBadge'
import { useToast } from '../components/ToastContainer'
import { mockAgents, mockDelegations } from '../lib/mock-data'
import { truncateAddress, tierNames, tierDescriptions, tierColors } from '../lib/utils'

const tierIcons = [Shield, ShieldCheck, ShieldAlert, Zap]

const DelegationConfig: FC = () => {
  const { agentAddress } = useParams<{ agentAddress: string }>()
  const { addToast } = useToast()

  const agent = mockAgents.find((a) => a.address.toLowerCase() === agentAddress?.toLowerCase())
  const delegation = mockDelegations.find((d) => d.agentAddress.toLowerCase() === agentAddress?.toLowerCase())

  const [selectedTier, setSelectedTier] = useState<number>(delegation?.tier ?? 0)
  const [dailyCap, setDailyCap] = useState(parseFloat(delegation?.dailyCap ?? '1'))
  const [reputationThreshold, setReputationThreshold] = useState(delegation?.reputationThreshold ?? 50)
  const [allowedContracts, setAllowedContracts] = useState(
    delegation?.allowedContracts.join('\n') ?? ''
  )
  const [timeWindowDays, setTimeWindowDays] = useState(7)

  if (!agent) {
    return (
      <div className="flex flex-col items-center justify-center gap-4 py-20">
        <p className="text-ash text-lg">Agent not found</p>
        <Link to="/agents" className="text-sm no-underline" style={{ color: 'var(--color-iris)' }}>
          Back to Agents
        </Link>
      </div>
    )
  }

  const handleGrant = () => {
    addToast('success', `Delegation granted to ${agent.name} at Tier ${selectedTier}`)
  }

  const handleRevoke = () => {
    addToast('warning', `Delegation revoked for ${agent.name}`)
  }

  return (
    <div className="flex flex-col gap-8">
      {/* Back link */}
      <Link
        to="/agents"
        className="flex items-center gap-2 text-sm text-ash no-underline hover:text-bone transition-colors"
      >
        <ArrowLeft size={16} strokeWidth={1.5} />
        Back to Agents
      </Link>

      {/* Agent Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <IrisAperture tier={selectedTier as 0 | 1 | 2 | 3} animated size={64} />
          <div>
            <h1 className="font-mono text-2xl font-semibold text-bone mb-1">{agent.name}</h1>
            <span className="font-mono text-sm text-ash">{truncateAddress(agent.address)}</span>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <TierBadge tier={agent.activeTier} />
          <StatusBadge status={delegation?.active ? 'active' : 'inactive'} />
        </div>
      </div>

      {/* Current Delegation Status */}
      {delegation && (
        <div
          className="p-5 border border-graphite"
          style={{ borderRadius: 8, backgroundColor: 'var(--color-obsidian)' }}
        >
          <h3 className="font-mono text-sm font-semibold text-ash mb-3 uppercase tracking-wider">
            Current Delegation
          </h3>
          <div className="grid grid-cols-4 gap-4">
            <div>
              <div className="text-xs text-ash mb-1">Tier</div>
              <TierBadge tier={delegation.tier} />
            </div>
            <div>
              <div className="text-xs text-ash mb-1">Daily Cap</div>
              <div className="font-mono text-sm" style={{ color: 'var(--color-cyan)' }}>
                {delegation.dailyCap} ETH
              </div>
            </div>
            <div>
              <div className="text-xs text-ash mb-1">Rep. Threshold</div>
              <div className="font-mono text-sm" style={{ color: 'var(--color-cyan)' }}>
                {delegation.reputationThreshold}
              </div>
            </div>
            <div>
              <div className="text-xs text-ash mb-1">Whitelisted</div>
              <div className="font-mono text-sm" style={{ color: 'var(--color-cyan)' }}>
                {delegation.allowedContracts.length} contracts
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Tier Selector */}
      <div>
        <h2 className="font-mono text-lg font-semibold text-bone mb-4">Trust Tier</h2>
        <div className="grid grid-cols-4 gap-3">
          {[0, 1, 2, 3].map((tier) => {
            const Icon = tierIcons[tier]
            const isSelected = selectedTier === tier
            return (
              <button
                key={tier}
                onClick={() => setSelectedTier(tier)}
                className="flex flex-col items-start gap-3 p-4 border text-left cursor-pointer transition-colors"
                style={{
                  borderRadius: 8,
                  backgroundColor: isSelected ? 'var(--color-void)' : 'var(--color-obsidian)',
                  borderColor: isSelected ? tierColors[tier] : 'var(--color-graphite)',
                  borderWidth: isSelected ? 2 : 1,
                }}
              >
                <div className="flex items-center gap-2">
                  <Icon
                    size={20}
                    strokeWidth={1.5}
                    style={{ color: tierColors[tier] }}
                  />
                  <span className="font-mono text-sm font-semibold" style={{ color: tierColors[tier] }}>
                    T{tier}
                  </span>
                </div>
                <span className="font-mono text-sm font-medium text-bone">
                  {tierNames[tier]}
                </span>
                <span className="text-xs text-ash leading-relaxed">
                  {tierDescriptions[tier]}
                </span>
              </button>
            )
          })}
        </div>
      </div>

      {/* Custom Config */}
      <div>
        <h2 className="font-mono text-lg font-semibold text-bone mb-4">Configuration</h2>
        <div
          className="p-5 border border-graphite flex flex-col gap-5"
          style={{ borderRadius: 8, backgroundColor: 'var(--color-obsidian)' }}
        >
          {/* Daily Cap Slider */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <label className="text-sm text-ash">Daily Spending Cap</label>
              <span className="font-mono text-sm" style={{ color: 'var(--color-cyan)' }}>
                {dailyCap.toFixed(1)} ETH
              </span>
            </div>
            <input
              type="range"
              min="0.1"
              max="10"
              step="0.1"
              value={dailyCap}
              onChange={(e) => setDailyCap(parseFloat(e.target.value))}
              className="w-full accent-iris"
              style={{ accentColor: 'var(--color-iris)' }}
            />
            <div className="flex justify-between text-xs text-ash mt-1">
              <span>0.1 ETH</span>
              <span>10 ETH</span>
            </div>
          </div>

          {/* Reputation Threshold */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <label className="text-sm text-ash">Reputation Threshold</label>
              <span className="font-mono text-sm" style={{ color: 'var(--color-cyan)' }}>
                {reputationThreshold}
              </span>
            </div>
            <input
              type="range"
              min="0"
              max="100"
              step="5"
              value={reputationThreshold}
              onChange={(e) => setReputationThreshold(parseInt(e.target.value))}
              className="w-full"
              style={{ accentColor: 'var(--color-iris)' }}
            />
            <div className="flex justify-between text-xs text-ash mt-1">
              <span>0 (any)</span>
              <span>100</span>
            </div>
          </div>

          {/* Time Window */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <label className="text-sm text-ash">Time Window</label>
              <span className="font-mono text-sm" style={{ color: 'var(--color-cyan)' }}>
                {timeWindowDays} days
              </span>
            </div>
            <input
              type="range"
              min="1"
              max="90"
              step="1"
              value={timeWindowDays}
              onChange={(e) => setTimeWindowDays(parseInt(e.target.value))}
              className="w-full"
              style={{ accentColor: 'var(--color-iris)' }}
            />
            <div className="flex justify-between text-xs text-ash mt-1">
              <span>1 day</span>
              <span>90 days</span>
            </div>
          </div>

          {/* Allowed Contracts */}
          <div>
            <label className="block text-sm text-ash mb-1.5">
              Allowed Contracts <span className="text-xs">(one per line)</span>
            </label>
            <textarea
              value={allowedContracts}
              onChange={(e) => setAllowedContracts(e.target.value)}
              rows={3}
              placeholder="0x..."
              className="w-full px-3 py-2.5 text-sm text-bone font-mono border border-graphite outline-none focus:border-iris transition-colors resize-none"
              style={{
                borderRadius: 4,
                backgroundColor: 'var(--color-void)',
              }}
            />
          </div>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex items-center gap-3">
        <button
          onClick={handleGrant}
          className="flex-1 py-3 text-sm font-medium text-bone border-0 cursor-pointer transition-opacity hover:opacity-90"
          style={{ borderRadius: 6, backgroundColor: 'var(--color-iris)' }}
        >
          Grant Delegation
        </button>
        <button
          onClick={handleRevoke}
          className="px-6 py-3 text-sm font-medium border cursor-pointer transition-colors hover:border-signal-red"
          style={{
            borderRadius: 6,
            backgroundColor: 'transparent',
            borderColor: 'var(--color-graphite)',
            color: 'var(--color-signal-red)',
          }}
        >
          Revoke
        </button>
      </div>
    </div>
  )
}

export default DelegationConfig
