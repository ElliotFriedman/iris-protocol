import { type FC, useState, useMemo } from 'react'
import { Activity as ActivityIcon, Filter, ExternalLink } from 'lucide-react'
import StatusBadge from '../components/StatusBadge'
import { mockActivity } from '../lib/mock-data'
import { truncateAddress, formatDate } from '../lib/utils'

type StatusFilter = 'all' | 'executed' | 'blocked'

const ActivityLog: FC = () => {
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all')
  const [agentFilter, setAgentFilter] = useState('')

  const uniqueAgents = useMemo(
    () => [...new Set(mockActivity.map((a) => a.agentName))],
    []
  )

  const filteredActivity = useMemo(() => {
    return mockActivity.filter((event) => {
      if (statusFilter !== 'all' && event.status !== statusFilter) return false
      if (agentFilter && event.agentName !== agentFilter) return false
      return true
    })
  }, [statusFilter, agentFilter])

  return (
    <div className="flex flex-col gap-8">
      {/* Header */}
      <div>
        <h1 className="font-mono text-2xl font-semibold text-bone mb-1">Activity Log</h1>
        <p className="text-sm text-ash">Agent execution and enforcement events</p>
      </div>

      {/* Filters */}
      <div className="flex items-center gap-3">
        <div className="flex items-center gap-2 text-ash text-sm">
          <Filter size={16} strokeWidth={1.5} />
          Filters:
        </div>

        <div className="flex items-center gap-1 p-0.5 border border-graphite" style={{ borderRadius: 6 }}>
          {(['all', 'executed', 'blocked'] as StatusFilter[]).map((status) => (
            <button
              key={status}
              onClick={() => setStatusFilter(status)}
              className="px-3 py-1.5 text-xs font-medium cursor-pointer border-0 transition-colors capitalize"
              style={{
                borderRadius: 4,
                backgroundColor: statusFilter === status ? 'var(--color-graphite)' : 'transparent',
                color: statusFilter === status ? 'var(--color-bone)' : 'var(--color-ash)',
              }}
            >
              {status}
            </button>
          ))}
        </div>

        <select
          value={agentFilter}
          onChange={(e) => setAgentFilter(e.target.value)}
          className="px-3 py-1.5 text-xs text-bone border border-graphite cursor-pointer outline-none"
          style={{
            borderRadius: 4,
            backgroundColor: 'var(--color-obsidian)',
          }}
        >
          <option value="">All Agents</option>
          {uniqueAgents.map((name) => (
            <option key={name} value={name}>{name}</option>
          ))}
        </select>
      </div>

      {/* Table */}
      <div
        className="border border-graphite overflow-hidden"
        style={{ borderRadius: 8, backgroundColor: 'var(--color-obsidian)' }}
      >
        <table className="w-full" style={{ borderCollapse: 'collapse' }}>
          <thead>
            <tr className="border-b border-graphite">
              <th className="px-4 py-3 text-left text-xs font-medium text-ash uppercase tracking-wider font-mono">
                Timestamp
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium text-ash uppercase tracking-wider font-mono">
                Agent
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium text-ash uppercase tracking-wider font-mono">
                Action
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium text-ash uppercase tracking-wider font-mono">
                Value
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium text-ash uppercase tracking-wider font-mono">
                Status
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium text-ash uppercase tracking-wider font-mono">
                Tx Hash
              </th>
            </tr>
          </thead>
          <tbody>
            {filteredActivity.map((event) => (
              <tr key={event.id} className="border-b border-graphite last:border-b-0 hover:bg-void/30">
                <td className="px-4 py-3 font-mono text-xs text-ash whitespace-nowrap">
                  {formatDate(event.timestamp)}
                </td>
                <td className="px-4 py-3">
                  <div>
                    <div className="text-sm text-bone">{event.agentName}</div>
                    <div className="font-mono text-xs text-ash">{truncateAddress(event.agent)}</div>
                  </div>
                </td>
                <td className="px-4 py-3 font-mono text-sm text-bone">
                  {event.action}
                </td>
                <td className="px-4 py-3 font-mono text-sm" style={{ color: 'var(--color-cyan)' }}>
                  {event.value}
                </td>
                <td className="px-4 py-3">
                  <div className="flex flex-col gap-1">
                    <StatusBadge status={event.status} />
                    {event.reason && (
                      <span className="text-xs" style={{ color: 'var(--color-signal-red)' }}>
                        {event.reason}
                      </span>
                    )}
                  </div>
                </td>
                <td className="px-4 py-3">
                  <a
                    href={`https://etherscan.io/tx/${event.txHash}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-1 font-mono text-xs no-underline hover:text-bone transition-colors"
                    style={{ color: 'var(--color-iris)' }}
                  >
                    {truncateAddress(event.txHash)}
                    <ExternalLink size={12} strokeWidth={1.5} />
                  </a>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {filteredActivity.length === 0 && (
          <div className="flex flex-col items-center justify-center py-12 gap-2">
            <ActivityIcon size={24} strokeWidth={1.5} className="text-ash" />
            <span className="text-sm text-ash">No activity matches your filters</span>
          </div>
        )}
      </div>
    </div>
  )
}

export default ActivityLog
