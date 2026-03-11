"use client";

function getReputationColor(score: number): string {
  if (score >= 75) return "var(--mint)";
  if (score >= 50) return "var(--amber)";
  return "var(--signal-red)";
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
      <div className="flex-1 h-2 bg-obsidian rounded-full overflow-hidden max-w-[100px]">
        <div
          className="h-full rounded-full transition-all duration-200"
          style={{ width: `${score}%`, backgroundColor: color }}
        />
      </div>
      <span className="font-mono text-sm font-bold" style={{ color }}>
        {score}
      </span>
    </div>
  );
}
