"use client";

const STATUS_STYLES: Record<string, string> = {
  active: "bg-mint/10 text-mint border-mint/20",
  expired: "bg-ash/10 text-ash border-ash/20",
  revoked: "bg-signal-red/10 text-signal-red border-signal-red/20",
  degraded: "bg-amber/10 text-amber border-amber/20",
};

export function StatusBadge({ status, variant = "default" }: { status: string; variant?: "default" | "pill" }) {
  const baseStyles = variant === "pill"
    ? `px-3 py-1 rounded-full text-xs font-mono border ${STATUS_STYLES[status] || STATUS_STYLES.active}`
    : `px-2 py-0.5 rounded text-xs font-mono border ${STATUS_STYLES[status] || STATUS_STYLES.active}`;

  return <span className={baseStyles}>{status}</span>;
}
