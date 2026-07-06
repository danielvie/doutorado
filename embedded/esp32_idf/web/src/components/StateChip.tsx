import React from "react";

export type ChipTone = "ok" | "warn" | "danger" | "neutral" | "unknown";

const TONE_CLASSES: Record<ChipTone, string> = {
  ok: "bg-emerald-50 text-emerald-700 border-emerald-200",
  warn: "bg-amber-50 text-amber-700 border-amber-200",
  danger: "bg-red-50 text-red-700 border-red-200",
  neutral: "bg-stone-100 text-stone-600 border-stone-200",
  unknown: "bg-stone-50 text-stone-400 border-stone-200 border-dashed",
};

export const StateChip: React.FC<{
  label: string;
  value: string;
  tone: ChipTone;
  pulse?: boolean;
}> = ({ label, value, tone, pulse = false }) => (
  <div
    className={`flex items-center gap-1.5 px-2 py-1 rounded-md border text-[10px] font-bold uppercase tracking-wider select-none ${TONE_CLASSES[tone]}`}
  >
    <span className="opacity-60">{label}</span>
    <span className={pulse ? "animate-pulse" : ""}>{value}</span>
  </div>
);
