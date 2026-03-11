import { type FC } from 'react'

interface IrisApertureProps {
  tier: 0 | 1 | 2 | 3
  animated?: boolean
  size?: number
}

const tierGlowColors = ['#8A8A9A', '#00F0FF', '#7B2FBE', '#FFB800']
const tierApertureRadius = [2, 8, 16, 26]

const IrisAperture: FC<IrisApertureProps> = ({ tier, animated = false, size = 120 }) => {
  const glowColor = tierGlowColors[tier]
  const apertureR = tierApertureRadius[tier]
  const bladeCount = 6
  const cx = 50
  const cy = 50

  const blades = Array.from({ length: bladeCount }, (_, i) => {
    const angle = (i * 360) / bladeCount
    const rad = (angle * Math.PI) / 180
    const outerR = 40
    const innerR = apertureR + 2

    // Each blade is a curved path from the inner aperture to the outer ring
    const startAngle = rad - 0.4
    const endAngle = rad + 0.4
    const midAngle = rad

    const innerX1 = cx + innerR * Math.cos(startAngle)
    const innerY1 = cy + innerR * Math.sin(startAngle)
    const outerX1 = cx + outerR * Math.cos(startAngle + 0.15)
    const outerY1 = cy + outerR * Math.sin(startAngle + 0.15)
    const outerX2 = cx + outerR * Math.cos(endAngle - 0.15)
    const outerY2 = cy + outerR * Math.sin(endAngle - 0.15)
    const innerX2 = cx + innerR * Math.cos(endAngle)
    const innerY2 = cy + innerR * Math.sin(endAngle)

    // Control point for the curve
    const cpR = (outerR + innerR) / 2 + 5
    const cpX = cx + cpR * Math.cos(midAngle)
    const cpY = cy + cpR * Math.sin(midAngle)

    return `M ${innerX1} ${innerY1} Q ${cpX} ${cpY} ${outerX1} ${outerY1} A ${outerR} ${outerR} 0 0 1 ${outerX2} ${outerY2} Q ${cpX} ${cpY} ${innerX2} ${innerY2} A ${innerR} ${innerR} 0 0 0 ${innerX1} ${innerY1}`
  })

  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 100 100"
      style={{ overflow: 'visible' }}
    >
      <defs>
        <radialGradient id={`glow-${tier}`} cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor={glowColor} stopOpacity="0.4" />
          <stop offset="100%" stopColor={glowColor} stopOpacity="0" />
        </radialGradient>
        <filter id={`blur-${tier}`}>
          <feGaussianBlur stdDeviation="2" />
        </filter>
      </defs>

      {/* Glow behind aperture */}
      <circle
        cx={cx}
        cy={cy}
        r={apertureR + 6}
        fill={`url(#glow-${tier})`}
        filter={`url(#blur-${tier})`}
      />

      {/* Aperture opening */}
      <circle
        cx={cx}
        cy={cy}
        r={apertureR}
        fill="none"
        stroke={glowColor}
        strokeWidth="0.5"
        opacity="0.6"
      />

      {/* Blades group with optional rotation */}
      <g style={animated ? {
        transformOrigin: `${cx}px ${cy}px`,
        animation: 'iris-rotate 30s linear infinite',
      } : undefined}>
        {blades.map((d, i) => (
          <path
            key={i}
            d={d}
            fill="#1A1A2E"
            stroke="#2A2A3E"
            strokeWidth="1"
          />
        ))}
      </g>

      {/* Outer ring */}
      <circle
        cx={cx}
        cy={cy}
        r={42}
        fill="none"
        stroke="#2A2A3E"
        strokeWidth="0.75"
      />
      <circle
        cx={cx}
        cy={cy}
        r={44}
        fill="none"
        stroke="#2A2A3E"
        strokeWidth="0.25"
        opacity="0.5"
      />

      {animated && (
        <style>{`
          @keyframes iris-rotate {
            from { transform: rotate(0deg); }
            to { transform: rotate(360deg); }
          }
        `}</style>
      )}
    </svg>
  )
}

export default IrisAperture
