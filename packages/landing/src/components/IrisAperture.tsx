import { useEffect, useState } from 'react';

interface IrisApertureProps {
  size?: number;
  tier?: number; // 0-3
  animate?: boolean;
  animationDuration?: number;
  color?: string;
  className?: string;
}

/**
 * 6-blade iris aperture SVG.
 * `tier` controls how open the aperture is:
 *   0 = fully closed, 3 = wide open
 * When `animate` is true the aperture opens from closed to the target tier.
 */
export default function IrisAperture({
  size = 300,
  tier = 2,
  animate = false,
  animationDuration = 4000,
  color = '#7B2FBE',
  className = '',
}: IrisApertureProps) {
  const [currentOpen, setCurrentOpen] = useState(animate ? 0 : tier);

  useEffect(() => {
    if (!animate) {
      setCurrentOpen(tier);
      return;
    }
    // animate from 0 to tier over animationDuration using requestAnimationFrame
    const start = performance.now();
    let raf: number;
    const step = (now: number) => {
      const elapsed = now - start;
      const progress = Math.min(elapsed / animationDuration, 1);
      // ease-out cubic
      const eased = 1 - Math.pow(1 - progress, 3);
      setCurrentOpen(eased * tier);
      if (progress < 1) {
        raf = requestAnimationFrame(step);
      }
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [animate, tier, animationDuration]);

  const bladeCount = 6;
  const cx = 150;
  const cy = 150;
  const radius = 120;

  // openness: 0 = blades fully cover center, 3 = blades barely overlap
  const openFraction = currentOpen / 3; // 0..1
  // The blade offset from center — higher = more open
  const bladeOffset = openFraction * radius * 0.75;

  const blades = [];
  for (let i = 0; i < bladeCount; i++) {
    const angle = (i * 360) / bladeCount;
    const rad = (angle * Math.PI) / 180;

    // Blade is a curved shape originating from outside, covering toward center
    // We shift each blade outward as openness increases
    const ox = Math.cos(rad) * bladeOffset;
    const oy = Math.sin(rad) * bladeOffset;

    // Each blade is a sector-like curved shape
    const a1 = rad - 0.52;
    const a2 = rad + 0.52;

    const innerR = 8 + bladeOffset * 0.5;
    const outerR = radius;

    const x1 = cx + ox + Math.cos(a1) * outerR;
    const y1 = cy + oy + Math.sin(a1) * outerR;
    const x2 = cx + ox + Math.cos(a2) * outerR;
    const y2 = cy + oy + Math.sin(a2) * outerR;
    const x3 = cx + ox + Math.cos(a2) * innerR;
    const y3 = cy + oy + Math.sin(a2) * innerR;
    const x4 = cx + ox + Math.cos(a1) * innerR;
    const y4 = cy + oy + Math.sin(a1) * innerR;

    const d = [
      `M ${x1} ${y1}`,
      `A ${outerR} ${outerR} 0 0 1 ${x2} ${y2}`,
      `L ${x3} ${y3}`,
      `A ${innerR} ${innerR} 0 0 0 ${x4} ${y4}`,
      'Z',
    ].join(' ');

    blades.push(
      <path
        key={i}
        d={d}
        fill={color}
        opacity={0.85}
        stroke={color}
        strokeWidth="0.5"
      />
    );
  }

  return (
    <svg
      className={className}
      width={size}
      height={size}
      viewBox="0 0 300 300"
      xmlns="http://www.w3.org/2000/svg"
    >
      {/* Outer ring */}
      <circle
        cx={cx}
        cy={cy}
        r={radius + 10}
        fill="none"
        stroke={color}
        strokeWidth="1.5"
        opacity="0.3"
      />
      <circle
        cx={cx}
        cy={cy}
        r={radius + 14}
        fill="none"
        stroke={color}
        strokeWidth="0.5"
        opacity="0.15"
      />
      {/* Blades */}
      {blades}
      {/* Center glow */}
      <circle
        cx={cx}
        cy={cy}
        r={Math.max(4, bladeOffset * 0.4)}
        fill={color}
        opacity={0.2 + openFraction * 0.4}
      >
        {animate && (
          <animate
            attributeName="opacity"
            values={`${0.2 + openFraction * 0.4};${0.5 + openFraction * 0.3};${0.2 + openFraction * 0.4}`}
            dur="3s"
            repeatCount="indefinite"
          />
        )}
      </circle>
    </svg>
  );
}
