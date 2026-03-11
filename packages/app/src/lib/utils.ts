export function truncateAddress(address: string): string {
  return `${address.slice(0, 6)}...${address.slice(-4)}`
}

export function formatTimestamp(timestamp: number): string {
  const now = Date.now()
  const diff = now - timestamp
  if (diff < 60000) return 'Just now'
  if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`
  return `${Math.floor(diff / 86400000)}d ago`
}

export function formatDate(timestamp: number): string {
  return new Date(timestamp).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

export const tierNames = ['Observe', 'Transact', 'Manage', 'Autonomous'] as const
export const tierDescriptions = [
  'Read-only access. Agent can observe state but cannot execute transactions.',
  'Basic transactions within strict spending caps and contract whitelist.',
  'Extended permissions with higher caps and broader contract access.',
  'Full delegation with reputation-gated autonomy. Highest trust level.',
] as const
export const tierColors = ['var(--color-ash)', 'var(--color-cyan)', 'var(--color-iris)', 'var(--color-amber)'] as const
