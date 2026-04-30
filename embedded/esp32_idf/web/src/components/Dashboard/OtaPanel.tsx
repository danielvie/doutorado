import React from "react";
import { Upload, Cpu, CheckCircle, AlertCircle, Loader2 } from "lucide-react";
import { OtaManager } from "../../services/OtaManager";
import { useBleStore } from "../../store/bleStore";
import { DashboardItem } from "./DashboardItem";
import { PanelSize } from "./SizeSelector";

export const OtaPanel: React.FC<{
  id: string;
  instanceId: string;
  currentSize?: PanelSize;
  onSizeChange?: (size: PanelSize) => void;
}> = ({ id, instanceId, currentSize = "1x1", onSizeChange = () => {} }) => {
  const [file, setFile] = React.useState<File | null>(null);
  const [isFlashing, setIsFlashing] = React.useState(false);
  const [progress, setProgress] = React.useState(0);
  const [status, setStatus] = React.useState<"idle" | "success" | "error">("idle");
  const isConnected = useBleStore((s) => s.isConnected);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setFile(e.target.files[0]);
      setStatus("idle");
    }
  };

  const handleFlash = async () => {
    if (!file || !isConnected) return;
    
    try {
      setIsFlashing(true);
      setStatus("idle");
      setProgress(0);
      
      await OtaManager.flash(file, (p) => setProgress(p));
      
      setStatus("success");
    } catch (err) {
      console.error("OTA failed", err);
      setStatus("error");
    } finally {
      setIsFlashing(false);
    }
  };

  return (
    <DashboardItem
      id={id}
      instanceId={instanceId}
      title="BLE OTA Flasher"
      currentSize={currentSize}
      onSizeChange={onSizeChange}
    >
      <div className="p-4 flex flex-col gap-4 h-full">
        <div className="flex flex-col gap-2">
          <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">
            Firmware Binary (.bin)
          </label>
          <div className="flex items-center gap-2">
            <input
              type="file"
              accept=".bin"
              onChange={handleFileChange}
              disabled={isFlashing}
              className="hidden"
              id="ota-file-input"
            />
            <label
              htmlFor="ota-file-input"
              className={`flex-1 flex items-center justify-center gap-2 p-3 border-2 border-dashed rounded-lg cursor-pointer transition-all ${
                file 
                  ? "border-blue-200 bg-blue-50 text-blue-700" 
                  : "border-gray-200 hover:border-gray-300 text-gray-500"
              } ${isFlashing ? "opacity-50 cursor-not-allowed" : ""}`}
            >
              <Upload size={18} />
              <span className="text-sm font-medium truncate">
                {file ? file.name : "Select .bin file"}
              </span>
            </label>
          </div>
        </div>

        <button
          onClick={handleFlash}
          disabled={!file || !isConnected || isFlashing}
          className={`w-full p-4 rounded-xl font-bold flex items-center justify-center gap-3 shadow-lg transition-all active:scale-95 ${
            !file || !isConnected
              ? "bg-gray-100 text-gray-400 cursor-not-allowed shadow-none"
              : "bg-gradient-to-br from-indigo-600 to-blue-700 text-white hover:shadow-indigo-200/50"
          }`}
        >
          {isFlashing ? (
            <Loader2 className="animate-spin" size={20} />
          ) : (
            <Cpu size={20} />
          )}
          {isFlashing ? `FLASHING ${progress}%` : "START FLASHING"}
        </button>

        {status === "success" && (
          <div className="flex items-center gap-2 text-green-600 bg-green-50 p-3 rounded-lg border border-green-100 animate-in fade-in slide-in-from-top-2">
            <CheckCircle size={18} />
            <span className="text-sm font-medium">Update successful! ESP32 is rebooting.</span>
          </div>
        )}

        {status === "error" && (
          <div className="flex items-center gap-2 text-red-600 bg-red-50 p-3 rounded-lg border border-red-100 animate-in fade-in slide-in-from-top-2">
            <AlertCircle size={18} />
            <span className="text-sm font-medium">Update failed. Check console for details.</span>
          </div>
        )}

        {!isConnected && (
          <div className="text-[10px] text-center text-orange-600 font-bold uppercase tracking-tight">
            Connect via BLE to enable OTA
          </div>
        )}
      </div>
    </DashboardItem>
  );
};
