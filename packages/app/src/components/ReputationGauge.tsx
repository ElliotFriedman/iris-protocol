import { type FC } from 'react'

interface ReputationGaugeProps {
  score: number
  size?: number
}

const ReputationGauge: FC<ReputationGaugeProps> = ({ score, size = 56 }) => {
  const strokeWidth = 4
  const radius = (size - strokeWidth) / 2
  const circumference = 2 * Math.PI * radius
  const progress = (score / 100) * circumference
  const color =
    score >= 80 ? 'var(--color-mint)' :
    score >= 50 ? 'var(--color-cyan)' :
    score >= 30 ? 'var(--color-amber)' :
    'var(--color-signal-red)'

  return (
    <div className="relative inline-flex items-center justify-center" style={{ width: size, height: size }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="var(--color-graphite)"
          strokeWidth={strokeWidth}
        />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={color}
          strokeWidth={strokeWidth}
          strokeDasharray={circumference}
          strokeDashoffset={circumference - progress}
          strokeLinecap="round"
        />
      </svg>
      <span
        className="absolute font-mono text-xs font-semibold"
        style={{ color }}
      >
        {score}
      </span>
    </div>
  )
}

export default ReputationGauge
