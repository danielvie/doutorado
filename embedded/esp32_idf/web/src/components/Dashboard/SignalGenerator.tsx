import { useEffect, useMemo, useState } from "react";
import { _create_signal } from "../../helper";
import { bleManager } from "../../services/BleManager";
import { useBleStore } from "../../store/bleStore";
import { Check, Copy, Upload } from "lucide-react";
import { PanelSize } from "./SizeSelector";
import { DashboardItem } from "./DashboardItem";

export const SignalGenerator: React.FC<{
  id: string;
  instanceId: string;
  currentSize?: PanelSize;
  onSizeChange?: (size: PanelSize) => void;
}> = ({ id, instanceId, currentSize = "1x1", onSizeChange = () => {} }) => {
  const alpha = useBleStore((s) => s.alpha);
  const setAlpha = useBleStore((s) => s.setAlpha);
  const [timeStr, setTimeStr] = useState("");
  const [modeStr, setModeStr] = useState("");
  const [binaryData, setBinaryData] = useState({ s1: "", s2: "", s3: "" });
  const [showBinary, setShowBinary] = useState(false);
  const [isEditingAlpha, setIsEditingAlpha] = useState(false);
  const [tempAlpha, setTempAlpha] = useState(alpha);
  const [copiedVector, setCopiedVector] = useState<
    "time" | "mode" | "combined" | null
  >(null);
  const [isEditingTime, setIsEditingTime] = useState(false);
  const [tempTime, setTempTime] = useState("");
  const [isEditingMode, setIsEditingMode] = useState(false);
  const [tempMode, setTempMode] = useState("");

  // Recalculate signal when alpha changes
  useEffect(() => {
    const val = parseFloat(alpha);
    if (!isNaN(val) && val >= 0.1 && val <= 0.9) {
      const res = _create_signal(val);
      setTimeStr(res.time);
      setModeStr(res.mode);
      setBinaryData(res.binary);
    }
  }, [alpha]);

  const handleUpload = () => {
    bleManager.sendCommand("signal.set_pattern", {
      time: timeStr,
      mode: modeStr,
    });
  };

  const handle_set_alpha = (a: string) => {
    setAlpha(a.toString());
    bleManager.sendCommand("signal.set_alpha", { alpha: Number(a) });
  };

  const copyVector = async (label: "time" | "mode", value: string) => {
    await navigator.clipboard.writeText(`${label}: ${value}`);
    setCopiedVector(label);
    window.setTimeout(() => setCopiedVector(null), 1200);
  };

  const copySignalSummary = async () => {
    await navigator.clipboard.writeText(
      `time: ${timeStr}\nmode: ${modeStr}\nT: ${time_values_sum.toFixed(1)} us`,
    );
    setCopiedVector("combined");
    window.setTimeout(() => setCopiedVector(null), 1200);
  };

  const alphaPresets = [
    "0.1",
    "0.2",
    "0.3",
    "0.4",
    "0.5",
    "0.6",
    "0.7",
    "0.8",
    "0.9",
  ];

  const time_values_sum = useMemo(() => {
    return timeStr
      .split(",")
      .map((value) => parseFloat(value.trim()))
      .filter((value) => !isNaN(value))
      .reduce((sum, value) => sum + value, 0);
  }, [timeStr]);

  return (
    <DashboardItem
      id={id}
      instanceId={instanceId}
      title="Signal Generator"
      currentSize={currentSize}
      onSizeChange={onSizeChange}
      expandable={false}
    >
      <div className="flex-1 min-h-0 overflow-y-auto pr-2 select-text">
        <div className="flex flex-col gap-6">
          <div className="bg-white/70 border border-gray-200 rounded-xl p-4 shadow-sm">
            <div className="flex flex-col gap-4">
              <div className="flex items-end justify-between gap-4">
                <div className="flex flex-col gap-1">
                  <label className="text-xs text-gray-700 font-bold uppercase tracking-widest ml-1">
                    Duty Cycle (Alpha)
                  </label>
                  {isEditingAlpha ? (
                    <input
                      autoFocus
                      className="text-3xl font-bold text-blue-700 leading-none bg-transparent border-b-2 border-blue-500 outline-none w-24"
                      value={tempAlpha}
                      onChange={(e) => setTempAlpha(e.target.value)}
                      onBlur={() => {
                        handle_set_alpha(tempAlpha);
                        setIsEditingAlpha(false);
                      }}
                      onKeyDown={(e) => {
                        if (e.key === "Enter") {
                          handle_set_alpha(tempAlpha);
                          setIsEditingAlpha(false);
                        }
                      }}
                    />
                  ) : (
                    <span
                      className="text-3xl font-bold text-blue-700 leading-none cursor-pointer hover:text-blue-500 transition-colors"
                      onClick={() => {
                        setTempAlpha(alpha);
                        setIsEditingAlpha(true);
                      }}
                    >
                      {alpha}
                    </span>
                  )}
                </div>
              </div>

              <input
                type="range"
                min="0.1"
                max="0.9"
                step="0.01"
                value={alpha}
                onChange={(e) => setAlpha(e.target.value)}
                className="w-full"
              />

              <div className="grid grid-cols-5 grid-rows-2 gap-2">
                {alphaPresets.map((val) => (
                  <button
                    key={val}
                    onClick={() => handle_set_alpha(val)}
                    className={`py-1.5 rounded-md font-bold text-sm transition-colors ${
                      val === alpha
                        ? "bg-blue-600 text-white shadow-md ring-2 ring-blue-600 ring-offset-1 cursor-default"
                        : "bg-white text-gray-800 border border-gray-300 hover:bg-gray-50 shadow-sm cursor-pointer"
                    }`}
                  >
                    {val}
                  </button>
                ))}
              </div>
            </div>
          </div>

          <div className="bg-white/70 border border-gray-200 rounded-xl p-4 shadow-sm">
            <div className="flex flex-col gap-5">
              <div className="flex flex-col gap-2">
                <div className="flex justify-between items-start gap-4 px-1">
                  <div className="flex flex-col gap-1">
                    <span className="text-xs text-gray-700 font-bold uppercase tracking-widest">
                      Time Vector
                    </span>
                    <div className="flex flex-wrap items-center gap-2 text-[11px] font-mono font-semibold text-gray-500">
                      <span>{timeStr.split(", ").length} pts</span>
                      <span className="px-2 py-0.5 rounded-md bg-blue-50 text-blue-700 border border-blue-100">
                        {time_values_sum.toFixed(1)} us
                      </span>
                      <button
                        type="button"
                        onClick={copySignalSummary}
                        className={`h-6 w-6 rounded-md border shadow-sm transition-colors flex items-center justify-center ${
                          copiedVector === "combined"
                            ? "bg-green-50 text-green-700 border-green-300"
                            : "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
                        }`}
                        aria-label="Copy signal summary"
                        title={
                          copiedVector === "combined"
                            ? "Copied signal summary"
                            : "Copy signal summary"
                        }
                      >
                        {copiedVector === "combined" ? (
                          <Check size={13} />
                        ) : (
                          <Copy size={13} />
                        )}
                      </button>
                    </div>
                  </div>
                  <button
                    onClick={handleUpload}
                    className="btn-primary shrink-0 px-6 py-2.5"
                  >
                    <Upload size={18} />
                    SYNC
                  </button>
                </div>
                <div className="flex items-stretch gap-2">
                  {isEditingTime ? (
                    <input
                      autoFocus
                      className="flex-1 min-w-0 bg-white px-4 py-2.5 rounded-md border border-blue-400 font-mono text-xs text-gray-800 outline-none shadow-inner w-full"
                      value={tempTime}
                      onChange={(e) => setTempTime(e.target.value)}
                      onBlur={() => {
                        setTimeStr(tempTime);
                        setIsEditingTime(false);
                      }}
                      onKeyDown={(e) => {
                        if (e.key === "Enter") {
                          setTimeStr(tempTime);
                          setIsEditingTime(false);
                        }
                      }}
                    />
                  ) : (
                    <div
                      className="flex-1 min-w-0 bg-gray-50 px-4 py-2.5 rounded-md border border-gray-300 font-mono text-xs text-gray-800 whitespace-nowrap overflow-x-auto custom-scrollbar shadow-inner cursor-pointer hover:bg-gray-100 transition-colors"
                      onClick={() => {
                        setTempTime(timeStr);
                        setIsEditingTime(true);
                      }}
                    >
                      {timeStr}
                    </div>
                  )}
                  <button
                    type="button"
                    onClick={() => copyVector("time", timeStr)}
                    className={`w-10 shrink-0 rounded-md border shadow-sm transition-colors flex items-center justify-center ${
                      copiedVector === "time"
                        ? "bg-green-50 text-green-700 border-green-300"
                        : "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
                    }`}
                    aria-label="Copy time vector"
                    title={
                      copiedVector === "time"
                        ? "Copied time vector"
                        : "Copy time vector"
                    }
                  >
                    {copiedVector === "time" ? (
                      <Check size={16} />
                    ) : (
                      <Copy size={16} />
                    )}
                  </button>
                </div>
              </div>

              <div className="flex flex-col gap-2">
                <div className="flex justify-between items-start gap-4 px-1">
                  <span className="text-xs text-gray-700 font-bold uppercase tracking-widest">
                    Mode Vector
                  </span>
                  <button
                    onClick={() => setShowBinary(!showBinary)}
                    className="text-xs text-blue-600 hover:text-blue-800 underline uppercase font-bold tracking-widest transition-colors"
                  >
                    {showBinary ? "Hide Binary" : "Show Binary"}
                  </button>
                </div>
                <div className="flex items-stretch gap-2">
                  {isEditingMode ? (
                    <input
                      autoFocus
                      className="flex-1 min-w-0 bg-white px-4 py-2.5 rounded-md border border-blue-400 font-mono text-xs text-gray-800 outline-none shadow-inner w-full"
                      value={tempMode}
                      onChange={(e) => setTempMode(e.target.value)}
                      onBlur={() => {
                        setModeStr(tempMode);
                        setIsEditingMode(false);
                      }}
                      onKeyDown={(e) => {
                        if (e.key === "Enter") {
                          setModeStr(tempMode);
                          setIsEditingMode(false);
                        }
                      }}
                    />
                  ) : (
                    <div
                      className="flex-1 min-w-0 bg-gray-50 px-4 py-2.5 rounded-md border border-gray-300 font-mono text-xs text-gray-800 whitespace-nowrap overflow-x-auto custom-scrollbar shadow-inner cursor-pointer hover:bg-gray-100 transition-colors"
                      onClick={() => {
                        setTempMode(modeStr);
                        setIsEditingMode(true);
                      }}
                    >
                      {modeStr}
                    </div>
                  )}
                  <button
                    type="button"
                    onClick={() => copyVector("mode", modeStr)}
                    className={`w-10 shrink-0 rounded-md border shadow-sm transition-colors flex items-center justify-center ${
                      copiedVector === "mode"
                        ? "bg-green-50 text-green-700 border-green-300"
                        : "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
                    }`}
                    aria-label="Copy mode vector"
                    title={
                      copiedVector === "mode"
                        ? "Copied mode vector"
                        : "Copy mode vector"
                    }
                  >
                    {copiedVector === "mode" ? (
                      <Check size={16} />
                    ) : (
                      <Copy size={16} />
                    )}
                  </button>
                </div>
              </div>
            </div>
          </div>

          {showBinary && (
            <div className="bg-gray-200/60 p-5 rounded-xl border border-gray-300 shadow-sm animate-fade-in-up">
              <h3 className="text-xs font-bold text-gray-900 uppercase tracking-widest mb-4 px-3 py-2 bg-white/80 rounded-md shadow-sm border border-white inline-block">
                Mode &rarr; Binary Mapping
              </h3>
              <div className="bg-white border border-gray-300 rounded-lg overflow-x-auto custom-scrollbar shadow-sm">
                <table className="w-full text-center text-sm font-mono border-collapse">
                  <thead>
                    <tr className="bg-blue-100 border-gray-400 border-b-2">
                      <th className="py-2.5 px-4 text-left font-bold text-blue-800 border-r border-blue-200 bg-blue-100/50 sticky left-0 z-10 w-24 shadow-[2px_0_4px_rgba(0,0,0,0.02)]">
                        MODE
                      </th>
                      {modeStr.split(",").map(
                        (m, idx) =>
                          m.trim() !== "" && (
                            <th
                              key={idx}
                              className="py-2.5 px-3 font-bold text-blue-900 border-r border-blue-200/50 last:border-0 min-w-[40px]"
                            >
                              {m.trim()}
                            </th>
                          ),
                      )}
                    </tr>
                  </thead>
                  <tbody>
                    <tr className="border-b border-gray-200 hover:bg-green-50/50 transition-colors">
                      <td className="py-2 px-4 text-left font-bold text-green-700 border-r border-gray-300 bg-gray-50 sticky left-0 z-10 shadow-[2px_0_4px_rgba(0,0,0,0.02)]">
                        U1{" "}
                        <span className="text-[10px] text-gray-500 ml-1">
                          D4
                        </span>
                      </td>
                      {binaryData.s1.split("").map((bit, idx) => (
                        <td
                          key={idx}
                          className="py-2 px-3 font-semibold text-green-800 border-r border-gray-200 last:border-0"
                        >
                          {bit}
                        </td>
                      ))}
                    </tr>
                    <tr className="border-b border-gray-200 hover:bg-amber-50/50 transition-colors">
                      <td className="py-2 px-4 text-left font-bold text-amber-700 border-r border-gray-300 bg-gray-50 sticky left-0 z-10 shadow-[2px_0_4px_rgba(0,0,0,0.02)]">
                        U2{" "}
                        <span className="text-[10px] text-gray-500 ml-1">
                          D5
                        </span>
                      </td>
                      {binaryData.s2.split("").map((bit, idx) => (
                        <td
                          key={idx}
                          className="py-2 px-3 font-semibold text-amber-800 border-r border-gray-200 last:border-0"
                        >
                          {bit}
                        </td>
                      ))}
                    </tr>
                    <tr className="hover:bg-blue-50/50 transition-colors">
                      <td className="py-2 px-4 text-left font-bold text-blue-700 border-r border-gray-300 bg-gray-50 sticky left-0 z-10 shadow-[2px_0_4px_rgba(0,0,0,0.02)]">
                        U3{" "}
                        <span className="text-[10px] text-gray-500 ml-1">
                          D6
                        </span>
                      </td>
                      {binaryData.s3.split("").map((bit, idx) => (
                        <td
                          key={idx}
                          className="py-2 px-3 font-semibold text-blue-800 border-r border-gray-200 last:border-0"
                        >
                          {bit}
                        </td>
                      ))}
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      </div>
    </DashboardItem>
  );
};
