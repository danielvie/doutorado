import React from "react";
import { RefreshCw } from "lucide-react";
import { DashboardItem } from "./DashboardItem";
import { StateChip } from "../StateChip";
import { useDeviceStore } from "../../store/deviceStore";
import { useBleStore } from "../../store/bleStore";
import { sendCommand, useIsLive } from "../../services/commands";

const FAULT_NAMES: Record<number, string> = {
  0: "none",
  1: "repeated_miss",
  2: "stale_sample",
  3: "missing_triple",
  4: "dma_overflow",
  5: "calibration_unavailable",
  6: "snapshot_contention",
};

type RowTone = "ok" | "warn" | "danger" | "neutral";

const ROW_VALUE_CLASSES: Record<RowTone, string> = {
  ok: "text-emerald-700",
  warn: "text-amber-700 font-bold",
  danger: "text-red-700 font-bold",
  neutral: "text-stone-800",
};

const Row: React.FC<{
  label: string;
  value: React.ReactNode;
  tone?: RowTone;
}> = ({ label, value, tone = "neutral" }) => (
  <div className="flex items-baseline justify-between gap-3 py-0.5">
    <span className="text-[11px] uppercase tracking-wider text-stone-400 font-bold shrink-0">
      {label}
    </span>
    <span
      className={`text-xs font-mono text-right ${ROW_VALUE_CLASSES[tone]}`}
    >
      {value}
    </span>
  </div>
);

const Section: React.FC<{
  title: string;
  badge?: string;
  badgeTone?: RowTone;
  children: React.ReactNode;
  collapsible?: boolean;
  defaultOpen?: boolean;
}> = ({
  title,
  badge,
  badgeTone = "neutral",
  children,
  collapsible = false,
  defaultOpen = true,
}) => {
  const header = (
    <div className="flex items-center gap-2">
      <span className="text-[11px] uppercase tracking-wider font-bold text-stone-500">
        {title}
      </span>
      {badge && (
        <span
          className={`text-[10px] font-bold px-1.5 py-0.5 rounded ${
            badgeTone === "danger"
              ? "bg-red-100 text-red-700"
              : badgeTone === "warn"
                ? "bg-amber-100 text-amber-700"
                : "bg-stone-100 text-stone-500"
          }`}
        >
          {badge}
        </span>
      )}
    </div>
  );

  if (!collapsible) {
    return (
      <div className="rounded-lg border border-stone-200 bg-white px-3 py-2">
        <div className="border-b border-stone-100 pb-1 mb-1">{header}</div>
        {children}
      </div>
    );
  }

  return (
    <details
      className="rounded-lg border border-stone-200 bg-white px-3 py-2 group"
      open={defaultOpen}
    >
      <summary className="cursor-pointer select-none list-none flex items-center justify-between">
        {header}
        <span className="text-stone-300 text-xs group-open:rotate-90 transition-transform">
          ›
        </span>
      </summary>
      <div className="pt-1 mt-1 border-t border-stone-100">{children}</div>
    </details>
  );
};

export const DeviceStatusPanel: React.FC = () => {
  const device = useDeviceStore();
  const isConnected = useBleStore((s) => s.isConnected);
  const autoRequestStatus = useBleStore((s) => s.autoRequestStatus);
  const setAutoRequestStatus = useBleStore((s) => s.setAutoRequestStatus);
  const isLive = useIsLive();

  // Auto-refresh always means system.get_status here; one-shot diagnostic
  // reports live in the Diagnostics panel with their own rerun controls.
  React.useEffect(() => {
    if (!autoRequestStatus || !isConnected) return;
    const interval = setInterval(() => {
      sendCommand("system.get_status");
    }, 2000);
    return () => clearInterval(interval);
  }, [autoRequestStatus, isConnected]);

  const analog = device.analog;
  const hasStatus = device.lastStatusAt !== null;

  const faultCode = analog?.faultCode ?? 0;
  const ageOverBudget =
    analog !== null && analog.ageUs > analog.controlMaxAgeUs;
  const ageUsedOverBudget =
    analog !== null &&
    analog.ageUsedCount > 0 &&
    analog.ageUsedMaxUs > analog.controlMaxAgeUs;

  const counters = analog
    ? [
        { label: "Overflows", value: analog.overflowCount },
        { label: "Misses", value: analog.missCount },
        { label: "Consecutive misses", value: analog.consecutiveMisses },
        { label: "Samples rejected", value: analog.samplesRejected },
        { label: "Order anomalies", value: analog.channelOrderAnomalies },
        { label: "Partial triples", value: analog.partialTriples },
        { label: "Frame drops", value: analog.frameDrops },
        { label: "Pool flushes", value: analog.poolFlushes },
        { label: "TS fallbacks", value: analog.frameTsFallbacks },
      ]
    : [];
  const anomalyCount = counters.reduce((sum, c) => sum + c.value, 0);

  return (
    <DashboardItem title="Device Status" expandable={false}>
      {!hasStatus ? (
        <div className="flex-1 flex flex-col items-center justify-center gap-3 text-stone-400 text-sm italic bg-stone-50/50 rounded-lg border border-dashed border-stone-200">
          <span>No device status received yet</span>
          <button
            onClick={() => sendCommand("system.get_status")}
            disabled={!isLive}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-md font-bold text-xs uppercase tracking-wider not-italic bg-white text-stone-600 border border-stone-300 hover:bg-stone-50 disabled:text-stone-300 disabled:border-stone-200 transition-colors"
          >
            <RefreshCw size={13} />
            Request status
          </button>
        </div>
      ) : (
        <div className="flex flex-col gap-2">
          {/* Operational state at a glance */}
          <div className="flex items-center gap-1.5 flex-wrap">
            <StateChip
              label="Signal"
              value={device.signalState}
              tone={
                device.signalState === "RUNNING"
                  ? "ok"
                  : device.signalState === "IDLE"
                    ? "neutral"
                    : "unknown"
              }
              pulse={device.signalState === "RUNNING"}
            />
            <StateChip label="Engine" value={device.engine} tone="neutral" />
            <StateChip
              label="Control"
              value={device.controlState}
              tone={device.controlState === "ON" ? "ok" : "neutral"}
            />
            <StateChip label="Set" value={device.activeSet} tone="neutral" />
            <StateChip
              label="Alpha"
              value={device.alpha !== null ? device.alpha.toFixed(2) : "—"}
              tone={device.alpha !== null ? "neutral" : "unknown"}
            />
            <StateChip
              label="Cycles"
              value={`${device.currentCycles}/${device.totalCycles}`}
              tone="neutral"
            />
            {device.congested && (
              <StateChip label="BLE" value="CONGESTED" tone="warn" pulse />
            )}
            {analog && (
              <StateChip
                label="Analog"
                value={
                  analog.valid
                    ? "VALID"
                    : `FAULT ${FAULT_NAMES[faultCode] ?? faultCode}`
                }
                tone={analog.valid ? "ok" : "danger"}
                pulse={!analog.valid}
              />
            )}
            <div className="flex-1" />
            <button
              onClick={() => setAutoRequestStatus(!autoRequestStatus)}
              className={`px-2 py-1 rounded-md border text-[10px] font-bold uppercase tracking-wider transition-colors ${
                autoRequestStatus
                  ? "bg-orange-50 border-orange-200 text-orange-600"
                  : "bg-stone-50 border-stone-200 text-stone-400 hover:text-stone-600"
              }`}
              title="Auto-refresh system.get_status every 2 s"
            >
              Auto
            </button>
            <button
              onClick={() => sendCommand("system.get_status")}
              disabled={!isLive}
              className="p-1.5 rounded-md border bg-white border-stone-300 text-stone-500 hover:bg-stone-50 disabled:text-stone-300 disabled:border-stone-200 transition-colors"
              title="Refresh (system.get_status)"
            >
              <RefreshCw size={12} />
            </button>
          </div>

          {analog && (
            <Section title="Control loop">
              <Row
                label="Snapshot age"
                value={`${analog.ageUs} us / budget ${analog.controlMaxAgeUs} us (floor ${analog.minSnapshotAgeUs})`}
                tone={ageOverBudget ? "warn" : "ok"}
              />
              <Row
                label="Age gate max"
                value={
                  analog.ageUsedCount > 0
                    ? `${analog.ageUsedMaxUs} us over ${analog.ageUsedCount} used`
                    : "no snapshots used yet"
                }
                tone={
                  analog.ageUsedCount === 0
                    ? "neutral"
                    : ageUsedOverBudget
                      ? "danger"
                      : "ok"
                }
              />
              <Row
                label="ADC latency"
                value={`avg ${device.adcAvgUs} · p95 ${analog.latencyP95Us} · min/max ${device.adcMinUs}/${device.adcMaxUs} us`}
              />
              <Row
                label="Rate"
                value={`${analog.measuredTriplesPerSecond} triples/s (target ${analog.targetTriplesPerCycle}/cycle)`}
              />
              <Row
                label="Fault"
                value={FAULT_NAMES[faultCode] ?? `code ${faultCode}`}
                tone={faultCode === 0 ? "ok" : "danger"}
              />
            </Section>
          )}

          {analog && (
            <Section title="Readings">
              {(
                [
                  ["AN3", analog.rawAn3, analog.calAn3],
                  ["AN5", analog.rawAn5, analog.calAn5],
                  ["AN6", analog.rawAn6, analog.calAn6],
                ] as const
              ).map(([name, raw, cal]) => (
                <Row
                  key={name}
                  label={name}
                  value={`raw ${raw} → ${cal.toFixed(4)}`}
                />
              ))}
            </Section>
          )}

          {analog && (
            <Section
              title="Counters"
              collapsible
              defaultOpen={anomalyCount > 0}
              badge={anomalyCount > 0 ? `${anomalyCount}` : "none"}
              badgeTone={anomalyCount > 0 ? "danger" : "neutral"}
            >
              {counters.map((c) => (
                <Row
                  key={c.label}
                  label={c.label}
                  value={c.value}
                  tone={c.value > 0 ? "warn" : "neutral"}
                />
              ))}
              <Row label="Samples read" value={analog.samplesRead} />
              <Row label="Seq" value={analog.seq} />
            </Section>
          )}

          <Section title="Config" collapsible defaultOpen={false}>
            <Row label="Dead time" value={`${device.deadTimeUs} us`} />
            <Row
              label="Dead tail comp"
              value={`${device.deadTimeTailOverheadCycles} cycles`}
            />
            <Row
              label="Edge comp up/down"
              value={`${device.edgeOverheadUpCycles} / ${device.edgeOverheadDownCycles} cycles`}
            />
            <Row label="Monitor period" value={`${device.monitorMs} ms`} />
            <Row
              label="Matrix A / B"
              value={`${device.matrixAValid ? "valid" : "not valid"} / ${device.matrixBValid ? "valid" : "not valid"}`}
            />
            {analog && (
              <>
                <Row
                  label="Acquisition"
                  value={
                    analog.acquisitionMode === 1 ? "continuous" : "oneshot"
                  }
                />
                <Row
                  label="LUT ready"
                  value={analog.lutReady ? "YES" : "NO"}
                  tone={analog.lutReady ? "neutral" : "warn"}
                />
              </>
            )}
            <Row label="BLE read state" value={device.bleReadState} />
            <Row label="LED mode" value={device.ledMode} />
          </Section>
        </div>
      )}
    </DashboardItem>
  );
};
