import React, { useEffect, useState } from "react";
import { Circle, Download, FileJson, Trash2 } from "lucide-react";
import { DashboardItem } from "./DashboardItem";
import {
  exportSessionCsv,
  exportSessionJson,
  useSessionStore,
} from "../../store/sessionStore";

const Stat: React.FC<{ label: string; value: string }> = ({
  label,
  value,
}) => (
  <div className="bg-gray-50 p-2.5 rounded-lg border border-gray-200 flex flex-col gap-0.5">
    <span className="text-[10px] text-gray-500 uppercase font-bold tracking-wider">
      {label}
    </span>
    <span className="text-lg font-semibold font-mono text-gray-800">
      {value}
    </span>
  </div>
);

export const SessionPanel: React.FC = () => {
  const recording = useSessionStore((s) => s.recording);
  const startedAt = useSessionStore((s) => s.startedAt);
  const stoppedAt = useSessionStore((s) => s.stoppedAt);
  const samples = useSessionStore((s) => s.samples);
  const commands = useSessionStore((s) => s.commands);
  const startRecording = useSessionStore((s) => s.startRecording);
  const stopRecording = useSessionStore((s) => s.stopRecording);
  const clearSession = useSessionStore((s) => s.clearSession);

  // Ticks once per second while recording so the duration stat advances;
  // Date.now() alone would be memoized by the React Compiler.
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    if (!recording) return;
    const interval = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(interval);
  }, [recording]);

  const hasData = samples.length > 0 || commands.length > 0;
  const durationSeconds = startedAt
    ? Math.max(0, Math.floor(((stoppedAt ?? now) - startedAt) / 1000))
    : 0;

  return (
    <DashboardItem title="Session" expandable={false}>
      <div className="flex flex-col gap-3 flex-1 min-h-0">
        <div className="flex items-center gap-2 shrink-0">
          <button
            onClick={() => (recording ? stopRecording() : startRecording())}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-md font-bold text-xs uppercase tracking-wider border transition-colors shadow-sm ${
              recording
                ? "bg-red-50 text-red-700 border-red-300 hover:bg-red-100"
                : "bg-emerald-600 text-white border-emerald-600 hover:bg-emerald-700"
            }`}
          >
            <Circle
              size={11}
              fill={recording ? "currentColor" : "none"}
              className={recording ? "animate-pulse" : ""}
            />
            {recording ? "Stop Recording" : "Start Recording"}
          </button>
          <button
            onClick={clearSession}
            disabled={!hasData || recording}
            className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-md font-bold text-xs uppercase tracking-wider bg-white text-stone-500 border border-stone-300 hover:bg-red-50 hover:text-red-600 hover:border-red-200 disabled:text-stone-300 disabled:hover:bg-white disabled:border-stone-200 transition-colors"
            title="Discard recorded session"
          >
            <Trash2 size={13} />
          </button>
          <div className="flex-1" />
          <button
            onClick={exportSessionCsv}
            disabled={!hasData}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-md font-bold text-xs uppercase tracking-wider bg-indigo-50 text-indigo-700 border border-indigo-200 hover:bg-indigo-100 disabled:bg-stone-50 disabled:text-stone-300 disabled:border-stone-200 transition-colors"
            title="Export merged telemetry + command timeline as CSV"
          >
            <Download size={13} />
            CSV
          </button>
          <button
            onClick={exportSessionJson}
            disabled={!hasData}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-md font-bold text-xs uppercase tracking-wider bg-indigo-50 text-indigo-700 border border-indigo-200 hover:bg-indigo-100 disabled:bg-stone-50 disabled:text-stone-300 disabled:border-stone-200 transition-colors"
            title="Export full session (metadata, commands, samples) as JSON"
          >
            <FileJson size={13} />
            JSON
          </button>
        </div>

        <div className="grid grid-cols-3 gap-2 shrink-0">
          <Stat
            label="Duration"
            value={
              startedAt
                ? `${Math.floor(durationSeconds / 60)}:${String(durationSeconds % 60).padStart(2, "0")}`
                : "—"
            }
          />
          <Stat label="Samples" value={String(samples.length)} />
          <Stat label="Commands" value={String(commands.length)} />
        </div>

        <div className="flex-1 min-h-0 flex flex-col gap-1.5">
          <h3 className="text-[10px] font-bold text-gray-500 uppercase tracking-widest shrink-0">
            Command Timeline
          </h3>
          <div className="flex-1 min-h-0 overflow-y-auto bg-gray-900 rounded-lg p-2 font-mono text-xs custom-scrollbar">
            {commands.length === 0 ? (
              <div className="h-full flex items-center justify-center text-gray-600 italic">
                {recording
                  ? "Recording… commands you send will appear here"
                  : "No session recorded"}
              </div>
            ) : (
              <div className="flex flex-col gap-1">
                {commands.map((c, i) => (
                  <div key={i} className="flex items-baseline gap-2 p-1 text-gray-400">
                    <span className="text-gray-600 shrink-0">
                      {new Date(c.at).toLocaleTimeString("en-US", {
                        hour12: false,
                      })}
                    </span>
                    <span className="text-blue-400 break-all">
                      {c.name}
                      {Object.keys(c.payload).length > 0 &&
                        ` ${JSON.stringify(c.payload)}`}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </DashboardItem>
  );
};
