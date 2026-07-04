import React, { useEffect, useState } from "react";
import {
  AlertTriangle,
  Circle,
  Lock,
  LockOpen,
  Play,
  RefreshCw,
  Square,
} from "lucide-react";
import { useBleStore } from "../store/bleStore";
import { useDeviceStore } from "../store/deviceStore";
import { useSessionStore } from "../store/sessionStore";
import { useUiStore } from "../store/uiStore";
import { sendCommand, useIsLive } from "../services/commands";

const STALE_STATUS_MS = 10_000;

type ChipTone = "ok" | "warn" | "danger" | "neutral" | "unknown";

const TONE_CLASSES: Record<ChipTone, string> = {
  ok: "bg-emerald-50 text-emerald-700 border-emerald-200",
  warn: "bg-amber-50 text-amber-700 border-amber-200",
  danger: "bg-red-50 text-red-700 border-red-200",
  neutral: "bg-stone-100 text-stone-600 border-stone-200",
  unknown: "bg-stone-50 text-stone-400 border-stone-200 border-dashed",
};

const StateChip: React.FC<{
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

export const StatusBar: React.FC = () => {
  const isConnected = useBleStore((s) => s.isConnected);
  const device = useDeviceStore();
  const recording = useSessionStore((s) => s.recording);
  const startedAt = useSessionStore((s) => s.startedAt);
  const sampleCount = useSessionStore((s) => s.samples.length);
  const startRecording = useSessionStore((s) => s.startRecording);
  const stopRecording = useSessionStore((s) => s.stopRecording);
  const layoutLocked = useUiStore((s) => s.layoutLocked);
  const setLayoutLocked = useUiStore((s) => s.setLayoutLocked);
  const isMocking = useUiStore((s) => s.isMocking);
  const isLive = useIsLive();

  // Re-render every second so status age and recording duration tick.
  const [, setTick] = useState(0);
  useEffect(() => {
    const interval = setInterval(() => setTick((t) => t + 1), 1000);
    return () => clearInterval(interval);
  }, []);

  // Refresh device state once whenever a connection is established.
  useEffect(() => {
    if (isConnected) {
      sendCommand("system.get_status");
    }
  }, [isConnected]);

  const statusAgeMs = device.lastStatusAt
    ? Date.now() - device.lastStatusAt
    : null;
  const statusStale = statusAgeMs !== null && statusAgeMs > STALE_STATUS_MS;

  const handleStop = async () => {
    await sendCommand("signal.stop");
    // Confirm the device actually stopped instead of trusting the click.
    window.setTimeout(() => sendCommand("system.get_status"), 400);
  };

  const handleStart = async () => {
    await sendCommand("signal.start");
    window.setTimeout(() => sendCommand("system.get_status"), 400);
  };

  const recordingSeconds =
    recording && startedAt ? Math.floor((Date.now() - startedAt) / 1000) : 0;
  const recordingLabel = `${String(Math.floor(recordingSeconds / 60)).padStart(2, "0")}:${String(recordingSeconds % 60).padStart(2, "0")}`;

  const connectionTone: ChipTone = isConnected
    ? "ok"
    : isMocking
      ? "warn"
      : "danger";
  const connectionValue = isConnected
    ? "CONNECTED"
    : isMocking
      ? "MOCK"
      : "OFFLINE";

  const signalTone: ChipTone =
    device.signalState === "RUNNING"
      ? "ok"
      : device.signalState === "IDLE"
        ? "neutral"
        : "unknown";

  return (
    <div className="bg-white/95 backdrop-blur border-b border-stone-200 px-4 md:px-6 py-1.5 flex items-center gap-3 flex-wrap sticky top-[53px] z-40 shadow-sm">
      {/* Run controls: always visible, STOP prominent */}
      <div className="flex items-center gap-1.5">
        <button
          onClick={handleStart}
          disabled={!isLive || device.signalState === "RUNNING"}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-md font-bold text-xs uppercase tracking-wider bg-emerald-600 text-white hover:bg-emerald-700 disabled:bg-stone-200 disabled:text-stone-400 transition-colors shadow-sm"
          title="signal.start"
        >
          <Play size={13} />
          Start
        </button>
        <button
          onClick={handleStop}
          disabled={!isLive}
          className="flex items-center gap-1.5 px-4 py-1.5 rounded-md font-bold text-xs uppercase tracking-wider bg-red-600 text-white hover:bg-red-700 disabled:bg-stone-200 disabled:text-stone-400 transition-colors shadow-md ring-1 ring-red-700/30"
          title="signal.stop"
        >
          <Square size={13} fill="currentColor" />
          Stop
        </button>
        <button
          onClick={() => sendCommand("system.get_status")}
          disabled={!isLive}
          className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-md font-bold text-xs uppercase tracking-wider bg-white text-stone-600 border border-stone-300 hover:bg-stone-50 disabled:text-stone-300 disabled:border-stone-200 transition-colors"
          title="Refresh device state (system.get_status)"
        >
          <RefreshCw size={13} />
        </button>
      </div>

      {/* Device state machine, ground truth from status packets */}
      <div className="flex items-center gap-1.5 flex-wrap">
        <StateChip label="Link" value={connectionValue} tone={connectionTone} />
        <StateChip
          label="Signal"
          value={device.signalState}
          tone={signalTone}
          pulse={device.signalState === "RUNNING"}
        />
        <StateChip
          label="Engine"
          value={device.engine}
          tone={device.engine === "UNKNOWN" ? "unknown" : "neutral"}
        />
        <StateChip
          label="Control"
          value={device.controlState}
          tone={
            device.controlState === "ON"
              ? "ok"
              : device.controlState === "OFF"
                ? "neutral"
                : "unknown"
          }
        />
        <StateChip
          label="Alpha"
          value={device.alpha !== null ? device.alpha.toFixed(2) : "—"}
          tone={device.alpha !== null ? "neutral" : "unknown"}
        />
        {device.congested && (
          <StateChip label="BLE" value="CONGESTED" tone="warn" pulse />
        )}
        {device.analogValid === false && (
          <StateChip
            label="Analog"
            value={`FAULT ${device.analogFaultCode}`}
            tone="danger"
            pulse
          />
        )}
        {statusStale && isConnected && (
          <div className="flex items-center gap-1 text-[10px] font-bold uppercase tracking-wider text-amber-600">
            <AlertTriangle size={12} />
            state {Math.floor((statusAgeMs ?? 0) / 1000)}s old
          </div>
        )}
      </div>

      <div className="flex-1" />

      {/* Session recording */}
      <button
        onClick={() => (recording ? stopRecording() : startRecording())}
        className={`flex items-center gap-1.5 px-3 py-1.5 rounded-md font-bold text-xs uppercase tracking-wider border transition-colors shadow-sm ${
          recording
            ? "bg-red-50 text-red-700 border-red-300 hover:bg-red-100"
            : "bg-white text-stone-600 border-stone-300 hover:bg-stone-50"
        }`}
        title={
          recording
            ? "Stop session recording"
            : "Record telemetry + commands for export"
        }
      >
        <Circle
          size={11}
          fill={recording ? "currentColor" : "none"}
          className={recording ? "animate-pulse" : ""}
        />
        {recording ? `REC ${recordingLabel} · ${sampleCount}` : "REC"}
      </button>

      {/* Layout lock */}
      <button
        onClick={() => setLayoutLocked(!layoutLocked)}
        className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-md font-bold text-xs uppercase tracking-wider border transition-colors ${
          layoutLocked
            ? "bg-stone-100 text-stone-600 border-stone-300"
            : "bg-indigo-50 text-indigo-700 border-indigo-300"
        }`}
        title={
          layoutLocked
            ? "Layout locked — click to allow drag/resize"
            : "Layout editable — click to lock"
        }
      >
        {layoutLocked ? <Lock size={13} /> : <LockOpen size={13} />}
        {layoutLocked ? "Locked" : "Editing"}
      </button>
    </div>
  );
};
