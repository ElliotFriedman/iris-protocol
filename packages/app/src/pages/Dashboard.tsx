import { type FC } from 'react'
import { useAccount, useBalance } from 'wagmi'
import { Wallet, KeyRound, Activity as ActivityIcon, ArrowUpRight } from 'lucide-react'
import { Link } from 'react-router-dom'
import IrisAperture from '../components/IrisAperture'
import StatusBadge from '../components/StatusBadge'
import TierBadge from '../components/TierBadge'
import { mockDelegations, mockActivity } from '../lib/mock-data'
import { truncateAddress, formatTimestamp } from '../lib/utils'

const Dashboard: FC = () => {
  const { address, isConnected } = useAccount()
  const { data: balance } = useBalance({ address })

  const activeDelegations = mockDelegations.filter((d) => d.active)
  const recentActivity = mockActivity.slice(0, 5)

  // Determine highest active tier for aperture display
  const highestTier = activeDelegations.reduce((max, d) => Math.max(max, d.tier), 0) as 0 | 1 | 2 | 3

  return (
    <div className="flex flex-col gap-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-mono text-2xl font-semibold text-bone mb-1">Dashboard</h1>
          <p className="text-sm text-ash">Iris Protocol delegation overview</p>
        </div>
        <IrisAperture tier={isConnected ? highestTier : 0} animated size={80} />
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-3 gap-4">
        {/* Balance */}
        <div
          className="flex flex-col gap-3 p-5 border border-graphite"
          style={{ borderRadius: 8, backgroundColor: 'var(--color-obsidian)' }}
        >
          <div className="flex items-center gap-2 text-ash text-sm">
            <Wallet size={20} strokeWidth={1.5} />
            Wallet Balance
          </div>
          <div className="font-mono text-2xl font-semibold" style={{ color: 'var(--color-cyan)' }}>
            {isConnected && balance
              ? `${parseFloat(balance.formatted).toFixed(4)} ${balance.symbol}`
              : '-- ETH'}
          </div>
          {isConnected && address && (
            <span className="font-mono text-xs text-ash">{truncateAddress(address)}</span>
          )}
        </div>

        {/* Active Delegations */}
        <div
          className="flex flex-col gap-3 p-5 border border-graphite"
          style={{ borderRadius: 8, backgroundColor: 'var(--color-obsidian)' }}
        >
          <div className="flex items-center gap-2 text-ash text-sm">
            <KeyRound size={20} strokeWidth={1.5} />
            Active Delegations
          </div>
          <div className="font-mono text-2xl font-semibold" style={{ color: 'var(--color-cyan)' }}>
            {activeDelegations.length}
          </div>
          <span className="text-xs text-ash">{mockDelegations.length} total configured</span>
        </div>

        {/* Activity */}
        <div
          className="flex flex-col gap-3 p-5 border border-graphite"
          style={{ borderRadius: 8, backgroundColor: 'var(--color-obsidian)' }}
        >
          <div className="flex items-center gap-2 text-ash text-sm">
            <ActivityIcon size={20} strokeWidth={1.5} />
            Recent Executions
          </div>
          <div className="font-mono text-2xl font-semibold" style={{ color: 'var(--color-cyan)' }}>
            {mockActivity.filter((a) => a.status === 'executed').length}
          </div>
          <span className="text-xs" style={{ color: 'var(--color-signal-red)' }}>
            {mockActivity.filter((a) => a.status === 'blocked').length} blocked
          </span>
        </div>
      </div>

      {/* Active Delegations List */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-mono text-lg font-semibold text-bone">Active Delegations</h2>
          <Link
            to="/agents"
            className="flex items-center gap-1 text-sm no-underline hover:text-bone transition-colors"
            style={{ color: 'var(--color-iris)' }}
          >
            View All <ArrowUpRight size={14} strokeWidth={1.5} />
          </Link>
        </div>
        <div className="flex flex-col gap-2">
          {activeDelegations.map((d) => (
            <Link
              key={d.id}
              to={`/delegate/${d.agentAddress}`}
              className="flex items-center justify-between p-4 border border-graphite no-underline text-bone hover:border-iris transition-colors"
              style={{ borderRadius: 8, backgroundColor: 'var(--color-obsidian)' }}
            >
              <div className="flex items-center gap-4">
                <div>
                  <span className="text-sm font-medium">{d.agentName}</span>
                  <div className="font-mono text-xs text-ash mt-0.5">
                    {truncateAddress(d.agentAddress)}
                  </div>
                </div>
              </div>
              <div className="flex items-center gap-4">
                <TierBadge tier={d.tier} />
                <div className="text-right">
                  <div className="font-mono text-sm" style={{ color: 'var(--color-cyan)' }}>
                    {d.dailyCap} ETH/day
                  </div>
                </div>
              </div>
            </Link>
          ))}
        </div>
      </div>

      {/* Recent Activity */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-mono text-lg font-semibold text-bone">Recent Activity</h2>
          <Link
            to="/activity"
            className="flex items-center gap-1 text-sm no-underline hover:text-bone transition-colors"
            style={{ color: 'var(--color-iris)' }}
          >
            View All <ArrowUpRight size={14} strokeWidth={1.5} />
          </Link>
        </div>
        <div className="flex flex-col gap-1">
          {recentActivity.map((event) => (
            <div
              key={event.id}
              className="flex items-center justify-between p-3 border border-graphite"
              style={{ borderRadius: 8, backgroundColor: 'var(--color-obsidian)' }}
            >
              <div className="flex items-center gap-4">
                <StatusBadge status={event.status} />
                <div>
                  <span className="text-sm">{event.agentName}</span>
                  <span className="text-ash text-sm mx-2">&middot;</span>
                  <span className="font-mono text-sm text-ash">{event.action}</span>
                </div>
              </div>
              <div className="flex items-center gap-4">
                <span className="font-mono text-sm" style={{ color: 'var(--color-cyan)' }}>
                  {event.value}
                </span>
                <span className="text-xs text-ash">{formatTimestamp(event.timestamp)}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

export default Dashboard
