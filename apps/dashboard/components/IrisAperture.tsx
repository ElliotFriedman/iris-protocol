"use client";

import { useEffect, useMemo, useState } from "react";

interface IrisApertureProps {
  tier: number;
  size?: number;
  animated?: boolean;
  className?: string;
  interactive?: boolean;
  onTierChange?: (tier: number) => void;
}

export default function IrisAperture({
  tier,
  size = 200,
  animated = false,
  className = "",
  interactive = false,
  onTierChange,
}: IrisApertureProps) {
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);

  const bladeCount = 8;
  const openness = tier / 3;
  const innerRadius = size * 0.08 + openness * size * 0.28;
  const outerRadius = size * 0.45;
  const center = size / 2;

  const blades = useMemo(() => {
    const elements = [];
    for (let i = 0; i < bladeCount; i++) {
      const angle = (i * 360) / bladeCount;
      const nextAngle = ((i + 1) * 360) / bladeCount;
      const rotationOffset = openness * 25;

      const startAngleRad = ((angle + rotationOffset) * Math.PI) / 180;
      const endAngleRad = ((nextAngle + rotationOffset) * Math.PI) / 180;
      const midAngleRad = (startAngleRad + endAngleRad) / 2;

      const outerX1 = center + outerRadius * Math.cos(startAngleRad);
      const outerY1 = center + outerRadius * Math.sin(startAngleRad);
      const outerX2 = center + outerRadius * Math.cos(endAngleRad);
      const outerY2 = center + outerRadius * Math.sin(endAngleRad);

      const innerX = center + innerRadius * Math.cos(midAngleRad);
      const innerY = center + innerRadius * Math.sin(midAngleRad);

      const controlX = center + (outerRadius * 0.7) * Math.cos(midAngleRad);
      const controlY = center + (outerRadius * 0.7) * Math.sin(midAngleRad);

      const path = `M ${outerX1} ${outerY1}
                     Q ${controlX} ${controlY} ${innerX} ${innerY}
                     Q ${controlX} ${controlY} ${outerX2} ${outerY2}
                     A ${outerRadius} ${outerRadius} 0 0 0 ${outerX1} ${outerY1} Z`;

      elements.push(
        <path
          key={i}
          d={path}
          fill={`url(#app-iris-gradient-${i})`}
          stroke="rgba(123, 47, 190, 0.6)"
          strokeWidth="0.5"
          style={{ transition: "all 0.8s cubic-bezier(0.4, 0, 0.2, 1)" }}
        />
      );
    }
    return elements;
  }, [tier, size, openness, innerRadius, outerRadius, center]);

  const handleClick = () => {
    if (interactive && onTierChange) {
      onTierChange(tier < 3 ? tier + 1 : 0);
    }
  };

  if (!mounted) {
    return (
      <div className={`relative inline-block ${className}`}>
        <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
          <circle cx={center} cy={center} r={outerRadius} fill="#0D0D1A" stroke="rgba(123, 47, 190, 0.3)" strokeWidth="1" />
        </svg>
      </div>
    );
  }

  return (
    <div
      className={`relative inline-block ${interactive ? "cursor-pointer" : ""} ${className}`}
      onClick={handleClick}
    >
      <svg
        width={size}
        height={size}
        viewBox={`0 0 ${size} ${size}`}
        className={animated ? "animate-pulse" : ""}
      >
        <defs>
          {Array.from({ length: bladeCount }, (_, i) => (
            <linearGradient
              key={i}
              id={`app-iris-gradient-${i}`}
              x1="0%"
              y1="0%"
              x2="100%"
              y2="100%"
            >
              <stop
                offset="0%"
                stopColor={`hsl(${270 + (i * 40) / bladeCount}, 70%, ${35 + openness * 15}%)`}
              />
              <stop
                offset="100%"
                stopColor={`hsl(${185 + (i * 20) / bladeCount}, 100%, ${40 + openness * 20}%)`}
              />
            </linearGradient>
          ))}
          <radialGradient id="app-iris-glow" cx="50%" cy="50%" r="50%">
            <stop offset="0%" stopColor="#00F0FF" stopOpacity={0.3 + openness * 0.4} />
            <stop offset="60%" stopColor="#7B2FBE" stopOpacity={0.15} />
            <stop offset="100%" stopColor="transparent" stopOpacity="0" />
          </radialGradient>
        </defs>

        <circle
          cx={center}
          cy={center}
          r={outerRadius + 4}
          fill="none"
          stroke="url(#app-iris-glow)"
          strokeWidth="2"
          opacity={0.5}
          style={{ transition: "all 0.8s ease" }}
        />

        <circle
          cx={center}
          cy={center}
          r={outerRadius}
          fill="#0D0D1A"
          stroke="rgba(123, 47, 190, 0.3)"
          strokeWidth="1"
        />

        {blades}

        <circle
          cx={center}
          cy={center}
          r={innerRadius}
          fill="url(#app-iris-glow)"
          style={{ transition: "all 0.8s cubic-bezier(0.4, 0, 0.2, 1)" }}
        />

        <circle
          cx={center}
          cy={center}
          r={innerRadius}
          fill="none"
          stroke="#00F0FF"
          strokeWidth="1"
          opacity={0.6 + openness * 0.4}
          style={{ transition: "all 0.8s ease" }}
        />

        <circle
          cx={center}
          cy={center}
          r={outerRadius}
          fill="none"
          stroke="rgba(123, 47, 190, 0.5)"
          strokeWidth="1.5"
        />
      </svg>

      <div
        className="absolute inset-0 flex items-center justify-center"
        style={{ transition: "all 0.8s ease" }}
      >
        <span
          className="font-mono text-xs tracking-widest uppercase"
          style={{
            color: openness > 0.5 ? "#00F0FF" : "#7B2FBE",
            fontSize: size * 0.06,
            transition: "color 0.8s ease",
          }}
        >
          {tier === 0 && "CLOSED"}
          {tier === 1 && "NARROW"}
          {tier === 2 && "WIDE"}
          {tier === 3 && "OPEN"}
        </span>
      </div>
    </div>
  );
}
