import React, { useEffect, useMemo, useState } from "react";
import { ble_send_command } from "./bluetooth";
import { _create_signal } from "../helper";

// Helper for Binary Display
const ModeDisplay: React.FC<{
  d4: string;
  d5: string;
  d6: string;
}> = ({ d4, d5, d6 }) => {
  const [expanded, setExpanded] = useState(false);
  return (
    <div className="px-2 text-left mt-2">
      <button
        onClick={() => setExpanded(!expanded)}
        className="btn info mb-2 text-xs"
      >
        {expanded ? "<< Hide Bits" : "Show Bits >>"}
      </button>
      {expanded && (
        <div className="flex flex-col gap-2 bg-gray p-2 rounded">
          {[
            { label: "D4 (u_1)", val: d4 },
            { label: "D5 (u_2)", val: d5 },
            { label: "D6 (u_3)", val: d6 },
          ].map((row) => (
            <div key={row.label} className="flex gap-2 items-center">
              <span className="w-25 font-mono text-sm text-text">
                {row.label}:
              </span>
              <div className="input w-full font-mono text-sm overflow-x-auto">
                {row.val}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

interface Props {
  alpha: string;
  setAlpha: (val: string) => void;
  isConnected: boolean;
}

export const MenuControlSignal: React.FC<Props> = ({
  alpha,
  setAlpha,
  isConnected,
}) => {
  const [timeStr, setTimeStr] = useState("");
  const [modeStr, setModeStr] = useState("");

  // Recalculate signal when alpha changes
  useEffect(() => {
    const val = parseFloat(alpha);
    if (!isNaN(val)) {
      const res = _create_signal(val);
      setTimeStr(res.time);
      setModeStr(res.mode);
    }
  }, [alpha]);

  const totalTime = useMemo(() => {
    return timeStr
      .split(",")
      .reduce((acc, t) => acc + (parseFloat(t) || 0), 0)
      .toFixed(1);
  }, [timeStr]);

  const bin_values = useMemo(() => {
    const modes = modeStr.split(",");
    const d4: string[] = [],
      d5: string[] = [],
      d6: string[] = [];
    modes.forEach((el) => {
      const val = parseInt(el.trim());
      if (!isNaN(val)) {
        const bin = val.toString(2).padStart(3, "0");
        d4.push(bin[2]);
        d5.push(bin[1]);
        d6.push(bin[0]);
      }
    });
    return { d4: d4.join(", "), d5: d5.join(", "), d6: d6.join(", ") };
  }, [modeStr]);

  const handleSendSignal = () => {
    if (!isConnected) return alert("Device not connected");
    ble_send_command(`SIGNAL:${timeStr};${modeStr}`);
  };

  return (
    <div className="bg-panel-background p-6 rounded-lg shadow-lg border border-gray">
      {/* Alpha Input */}
      <div className="flex items-center gap-4 mb-2">
        <label className="w-16 font-bold text-right">Alpha:</label>
        <input
          type="number"
          step="0.1"
          value={alpha}
          onChange={(e) => setAlpha(e.target.value)}
          className="input w-20 text-center font-mono"
        />
      </div>

      {/* Grid Layout for Time/Modes */}
      <div className="grid grid-cols-[4rem_1fr_auto] gap-x-4 gap-y-2 items-center mb-2">
        <label className="font-bold text-right">Time:</label>
        <input
          value={timeStr}
          onChange={(e) => setTimeStr(e.target.value)}
          className="input w-full font-mono text-sm"
        />
        <span className="text-gray-400 text-sm whitespace-nowrap text-right min-w-[100px]">
          Total: {totalTime} µs
        </span>

        <label className="font-bold text-right">Modes:</label>
        <input
          value={modeStr}
          onChange={(e) => setModeStr(e.target.value)}
          className="input w-full font-mono text-sm"
        />
        <button onClick={handleSendSignal} className="btn send min-w-[100px]">
          UPLOAD
        </button>
      </div>

      <div>
        <ModeDisplay {...bin_values} />
      </div>
    </div>
  );
};
