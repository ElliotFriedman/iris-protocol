"use client";

import { useEffect, useMemo, useState } from "react";

interface IrisApertureProps {
  tier: number; // 0-3
  size?: number;
  animated?: boolean;
  className?: string;
}

export default function IrisAperture({
  tier,
  size = 200,
  animated = false,
  className = "",
}: IrisApertureProps) {
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);

  const bladeCount = 8;
  // tier 0 = mostly closed (small opening), tier 3 = wide open
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
          fill={`url(#iris-gradient-${i})`}
          stroke="rgba(123, 47, 190, 0.6)"
          strokeWidth="0.5"
          style={{
            transition: "all 0.8s ease-out",
          }}
        />
      );
    }
    return elements;
  }, [tier, size, openness, innerRadius, outerRadius, center]);

  if (!mounted) {
    return (
      <div className={`relative inline-block ${className}`}>
        <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
          <circle cx={center} cy={center} r={outerRadius} fill="#0D0D14" stroke="rgba(123, 47, 190, 0.3)" strokeWidth="1" />
        </svg>
      </div>
    );
  }

  return (
    <div className={`relative inline-block ${className}`}>
      <svg
        width={size}
        height={size}
        viewBox={`0 0 ${size} ${size}`}
        className={animated ? "iris-pulse" : ""}
      >
        <defs>
          {Array.from({ length: bladeCount }, (_, i) => (
            <linearGradient
              key={i}
              id={`iris-gradient-${i}`}
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
          <radialGradient id="iris-glow" cx="50%" cy="50%" r="50%">
            <stop offset="0%" stopColor="#00F0FF" stopOpacity={0.3 + openness * 0.4} />
            <stop offset="60%" stopColor="#7B2FBE" stopOpacity={0.15} />
            <stop offset="100%" stopColor="transparent" stopOpacity="0" />
          </radialGradient>
          <filter id="iris-blur">
            <feGaussianBlur stdDeviation="2" />
          </filter>
        </defs>

        {/* Outer glow ring */}
        <circle
          cx={center}
          cy={center}
          r={outerRadius + 4}
          fill="none"
          stroke="url(#iris-glow)"
          strokeWidth="2"
          opacity={0.5}
          style={{ transition: "all 0.8s ease-out" }}
        />

        {/* Background circle */}
        <circle
          cx={center}
          cy={center}
          r={outerRadius}
          fill="#0D0D14"
          stroke="rgba(123, 47, 190, 0.3)"
          strokeWidth="1"
        />

        {/* Aperture blades */}
        {blades}

        {/* Center glow */}
        <circle
          cx={center}
          cy={center}
          r={innerRadius}
          fill="url(#iris-glow)"
          style={{ transition: "all 0.8s ease-out" }}
        />

        {/* Inner ring */}
        <circle
          cx={center}
          cy={center}
          r={innerRadius}
          fill="none"
          stroke="#00F0FF"
          strokeWidth="1"
          opacity={0.6 + openness * 0.4}
          style={{ transition: "all 0.8s ease-out" }}
        />

        {/* Outer ring */}
        <circle
          cx={center}
          cy={center}
          r={outerRadius}
          fill="none"
          stroke="rgba(123, 47, 190, 0.5)"
          strokeWidth="1.5"
        />
      </svg>

      {/* Tier label */}
      <div
        className="absolute inset-0 flex items-center justify-center"
        style={{ transition: "all 0.8s ease-out" }}
      >
        <span
          className="font-mono text-xs tracking-widest uppercase"
          style={{
            color: openness > 0.5 ? "#00F0FF" : "#7B2FBE",
            fontSize: size * 0.06,
            transition: "color 0.8s ease-out",
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
