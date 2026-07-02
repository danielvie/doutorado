import React from "react";
import { Upload, Cpu, CheckCircle, AlertCircle, Loader2, X } from "lucide-react";
import { OtaManager } from "../../services/OtaManager";
import { bleManager } from "../../services/BleManager";
import { useBleStore } from "../../store/bleStore";
import { DashboardItem } from "./DashboardItem";

export const OtaPanel: React.FC = () => {
  const [file, setFile] = React.useState<File | null>(null);
  const [isFlashing, setIsFlashing] = React.useState(false);
  const [progress, setProgress] = React.useState(0);
  const [status, setStatus] = React.useState<"idle" | "success" | "error">("idle");
  const fileInputRef = React.useRef<HTMLInputElement | null>(null);
  const originalTitleRef = React.useRef<string | null>(null);
  const isConnected = useBleStore((s) => s.isConnected);

  React.useEffect(() => {
    if (isFlashing && originalTitleRef.current === null) {
      originalTitleRef.current = document.title;
    }

    if (!isFlashing && originalTitleRef.current !== null) {
      document.title = originalTitleRef.current;
      originalTitleRef.current = null;
    }

    return () => {
      if (originalTitleRef.current !== null) {
        document.title = originalTitleRef.current;
      }
    };
  }, [isFlashing]);

  React.useEffect(() => {
    if (isFlashing && originalTitleRef.current !== null) {
      document.title = `Flashing ${progress}% - ${originalTitleRef.current}`;
    }
  }, [isFlashing, progress]);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setFile(e.target.files[0]);
      setStatus("idle");
    }
  };

  const handleClearFile = () => {
    if (isFlashing) return;

    setFile(null);
    setStatus("idle");
    setProgress(0);
    if (fileInputRef.current) {
      fileInputRef.current.value = "";
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
      try {
        await bleManager.reconnectAfterOta();
      } catch (reconnectErr) {
        console.warn("OTA completed, but reconnect failed", reconnectErr);
      }
    } catch (err) {
      console.error("OTA failed", err);
      setStatus("error");
    } finally {
      setIsFlashing(false);
    }
  };

  return (
    <DashboardItem title="BLE OTA Flasher">
      <div className="p-4 flex flex-col gap-4 h-full">
        <div className="flex flex-col gap-2">
          <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">
            Firmware Binary (.bin)
          </label>
          <div className="flex items-center gap-2">
            <input
              ref={fileInputRef}
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
            {file && (
              <button
                type="button"
                onClick={handleClearFile}
                disabled={isFlashing}
                title="Unselect firmware file"
                aria-label="Unselect firmware file"
                className="shrink-0 p-3 rounded-lg border border-gray-200 text-gray-500 hover:text-red-600 hover:border-red-200 hover:bg-red-50 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
              >
                <X size={18} />
              </button>
            )}
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
