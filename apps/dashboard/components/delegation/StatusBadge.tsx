"use client";

const STATUS_STYLES: Record<string, string> = {
  active: "bg-green-500/10 text-green-400 border-green-500/20",
  expired: "bg-gray-500/10 text-gray-400 border-gray-500/20",
  revoked: "bg-red-500/10 text-red-400 border-red-500/20",
  degraded: "bg-yellow-500/10 text-yellow-400 border-yellow-500/20",
};

export function StatusBadge({ status, variant = "default" }: { status: string; variant?: "default" | "pill" }) {
  const baseStyles = variant === "pill"
    ? `px-3 py-1 rounded-full text-xs font-mono border ${STATUS_STYLES[status] || STATUS_STYLES.active}`
    : `px-2 py-0.5 rounded text-xs font-mono border ${STATUS_STYLES[status] || STATUS_STYLES.active}`;

  return <span className={baseStyles}>{status}</span>;
}
