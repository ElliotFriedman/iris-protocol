import { type FC } from 'react'

interface StatusBadgeProps {
  status: 'executed' | 'blocked' | 'active' | 'inactive'
}

const statusConfig = {
  executed: { label: 'Executed', bg: 'rgba(0,232,143,0.12)', color: 'var(--color-mint)' },
  blocked: { label: 'Blocked', bg: 'rgba(255,59,92,0.12)', color: 'var(--color-signal-red)' },
  active: { label: 'Active', bg: 'rgba(0,232,143,0.12)', color: 'var(--color-mint)' },
  inactive: { label: 'Inactive', bg: 'rgba(138,138,154,0.12)', color: 'var(--color-ash)' },
}

const StatusBadge: FC<StatusBadgeProps> = ({ status }) => {
  const config = statusConfig[status]
  return (
    <span
      className="inline-flex items-center px-2 py-0.5 font-mono text-xs font-medium"
      style={{
        backgroundColor: config.bg,
        color: config.color,
        borderRadius: 4,
      }}
    >
      {config.label}
    </span>
  )
}

export default StatusBadge
