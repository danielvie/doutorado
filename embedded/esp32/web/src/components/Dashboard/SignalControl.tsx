import { useEffect, useState } from "react";
import { _create_signal } from "../../helper";
import { bleManager } from "../../services/BleManager";
import { useBleStore } from "../../store/bleStore";
import { Upload, Activity } from "lucide-react";

export const SignalControl = () => {
  const { alpha, setAlpha } = useBleStore();
  const [timeStr, setTimeStr] = useState("");
  const [modeStr, setModeStr] = useState("");
  const [binaryData, setBinaryData] = useState({ s1: "", s2: "", s3: "" });
  const [showBinary, setShowBinary] = useState(false);

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
    bleManager.send(`SIGNAL:${timeStr};${modeStr}`);
  };

  return (
    <div className="bg-gray-900 border border-gray-800 rounded-xl p-4 flex flex-col gap-4 shadow-lg">
      <div className="flex items-center gap-2 mb-2 border-b border-gray-800 pb-2">
        <Activity className="w-5 h-5 text-purple-400" />
        <h2 className="font-bold text-lg text-gray-200">Signal Generator</h2>
      </div>

      <div className="flex items-center gap-4">
        <div className="flex-1">
          <label className="text-xs text-gray-500 font-bold uppercase mb-1 block">
            Duty Cycle (Alpha)
          </label>
          <div className="flex items-center gap-2">
            <input
              type="range"
              min="0.1"
              max="0.9"
              step="0.01"
              value={alpha}
              onChange={(e) => setAlpha(e.target.value)}
              className="flex-1 h-2 bg-gray-700 rounded-lg appearance-none cursor-pointer accent-purple-500"
            />
            <input
              type="number"
              value={alpha}
              onChange={(e) => setAlpha(e.target.value)}
              className="w-16 bg-gray-950 border border-gray-700 rounded p-1 text-center font-mono text-sm focus:border-purple-500 focus:outline-none"
            />
          </div>
        </div>
        <button
          onClick={handleUpload}
          className="h-10 px-4 bg-purple-600 hover:bg-purple-700 text-white rounded-lg font-bold flex items-center gap-2 transition-colors shadow-lg shadow-purple-900/20"
        >
          <Upload size={16} />
          UPLOAD
        </button>
      </div>

      <div className="space-y-2">
        <div>
          <div className="flex justify-between text-xs text-gray-500 mb-1">
            <span>TIME VECTOR</span>
            <span>{timeStr.split(", ").length} items</span>
          </div>
          <div className="bg-gray-950 p-2 rounded border border-gray-800 font-mono text-xs text-gray-400 break-all h-16 overflow-y-auto">
            {timeStr}
          </div>
        </div>
        <div>
          <div className="flex justify-between text-xs text-gray-500 mb-1">
            <span>MODE VECTOR</span>
            <div className="flex gap-2">
              <button
                onClick={() => setShowBinary(!showBinary)}
                className="text-purple-400 hover:text-purple-300 underline"
              >
                {showBinary ? "Hide Binary" : "Show Binary"}
              </button>
              <span>{modeStr.split(", ").length} items</span>
            </div>
          </div>
          <div className="bg-gray-950 p-2 rounded border border-gray-800 font-mono text-xs text-gray-400 break-all">
            {modeStr}
          </div>
        </div>

        {showBinary && (
          <div className="grid grid-cols-3 gap-2 mt-2 pt-2 border-t border-gray-800/50 animate-in fade-in slide-in-from-top-1">
            <div className="bg-gray-950/50 p-2 rounded border border-gray-800">
              <div className="text-[10px] text-gray-500 uppercase font-bold mb-1">
                D4 (u_1)
              </div>
              <div className="font-mono text-xs text-emerald-400 break-all tracking-widest leading-loose">
                {binaryData.s1.split("").join(" ")}
              </div>
            </div>
            <div className="bg-gray-950/50 p-2 rounded border border-gray-800">
              <div className="text-[10px] text-gray-500 uppercase font-bold mb-1">
                D5 (u_2)
              </div>
              <div className="font-mono text-xs text-amber-400 break-all tracking-widest leading-loose">
                {binaryData.s2.split("").join(" ")}
              </div>
            </div>
            <div className="bg-gray-950/50 p-2 rounded border border-gray-800">
              <div className="text-[10px] text-gray-500 uppercase font-bold mb-1">
                D6 (u_3)
              </div>
              <div className="font-mono text-xs text-blue-400 break-all tracking-widest leading-loose">
                {binaryData.s3.split("").join(" ")}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
