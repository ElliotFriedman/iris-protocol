import { type FC } from 'react'
import { tierNames, tierColors } from '../lib/utils'

interface TierBadgeProps {
  tier: number
}

const TierBadge: FC<TierBadgeProps> = ({ tier }) => {
  const name = tierNames[tier] ?? 'Unknown'
  const color = tierColors[tier] ?? 'var(--color-ash)'

  return (
    <span
      className="inline-flex items-center gap-1.5 px-2 py-0.5 font-mono text-xs font-medium"
      style={{
        color,
        backgroundColor: `color-mix(in srgb, ${color} 12%, transparent)`,
        borderRadius: 4,
      }}
    >
      <span
        className="w-1.5 h-1.5 rounded-full"
        style={{ backgroundColor: color }}
      />
      T{tier} {name}
    </span>
  )
}

export default TierBadge
