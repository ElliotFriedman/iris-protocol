"use client";

function getReputationColor(score: number): string {
  if (score >= 75) return "#00F0FF";
  if (score >= 50) return "#F0C000";
  return "#FF4444";
}

export function ReputationBadge({ score }: { score: number }) {
  const color = getReputationColor(score);
  return (
    <span className="font-mono text-sm" style={{ color }}>
      {score}
    </span>
  );
}

export function ReputationBar({ score }: { score: number }) {
  const color = getReputationColor(score);
  return (
    <div className="flex items-center gap-3">
      <div className="flex-1 h-2 bg-[#1A1A2E] rounded-full overflow-hidden max-w-[100px]">
        <div
          className="h-full rounded-full transition-all"
          style={{ width: `${score}%`, backgroundColor: color }}
        />
      </div>
      <span className="font-mono text-sm font-bold" style={{ color }}>
        {score}
      </span>
    </div>
  );
}
