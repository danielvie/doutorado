import React from "react";
import { useBleStore } from "../../store/bleStore";
import { bleManager } from "../../services/BleManager";
import { PanelSize } from "./SizeSelector";
import { DashboardItem } from "./DashboardItem";

import { Copy, Check, RefreshCw, Trash2 } from "lucide-react";

export const StatusPanel: React.FC<{
  id: string;
  instanceId: string;
  currentSize?: PanelSize;
  onSizeChange?: (size: PanelSize) => void;
}> = ({ id, instanceId, currentSize = "1x1", onSizeChange = () => {} }) => {
  const lastStatusMessage = useBleStore((s) => s.lastStatusMessage);
  const lastStatusCommand = useBleStore((s) => s.lastStatusCommand);
  const autoRequestStatus = useBleStore((s) => s.autoRequestStatus);
  const setAutoRequestStatus = useBleStore((s) => s.setAutoRequestStatus);
  const isConnected = useBleStore((s) => s.isConnected);
  const clearLastStatusMessage = useBleStore((s) => s.clearLastStatusMessage);
  const [copied, setCopied] = React.useState(false);
  const rerunCommand = lastStatusCommand ?? {
    name: "system.get_status",
    payload: {},
  };

  // Auto-request status effect
  React.useEffect(() => {
    if (!autoRequestStatus || !isConnected) return;
    
    const interval = setInterval(() => {
      bleManager.sendCommand(rerunCommand.name, rerunCommand.payload);
    }, 2000);
    
    return () => clearInterval(interval);
  }, [autoRequestStatus, isConnected, rerunCommand.name, rerunCommand.payload]);

  const handleCopy = () => {
    if (!lastStatusMessage) return;
    const cleanMessage = lastStatusMessage
      .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]/g, "")
      .trim();
    navigator.clipboard.writeText(cleanMessage);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const rerunLastStatusCommand = () => {
    bleManager.sendCommand(rerunCommand.name, rerunCommand.payload);
  };

  return (
    <DashboardItem
      id={id}
      instanceId={instanceId}
      title="Status"
      currentSize={currentSize}
      onSizeChange={onSizeChange}
      expandable={false}
    >
      <div className="flex-1 min-h-0 flex flex-col relative group">
        {lastStatusMessage ? (
          <div className="flex-1 overflow-y-auto pr-1 custom-scrollbar relative">
            <div className="min-h-full whitespace-pre-wrap bg-white pt-14 p-4 pr-10 rounded-lg border border-gray-200 text-sm text-gray-800 leading-relaxed shadow-inner font-mono break-all transition-all relative select-text cursor-text">
              <button
                onClick={handleCopy}
                className={`absolute top-2 right-2 p-2 rounded-md border transition-all flex items-center gap-1.5 shadow-sm active:scale-95 ${
                  copied
                    ? "bg-green-50 border-green-200 text-green-600"
                    : "bg-gray-50 border-gray-200 text-gray-500 hover:text-blue-600 hover:bg-white hover:border-blue-200"
                }`}
                title="Copy Status"
              >
                {copied ? <Check size={14} /> : <Copy size={14} />}
                {copied && (
                  <span className="text-[10px] font-bold uppercase tracking-wider">
                    Copied
                  </span>
                )}
              </button>
              <div className="absolute top-2 right-14 flex items-center gap-1">
                <button
                  onClick={clearLastStatusMessage}
                  className="p-2 rounded-md border bg-red-50 border-red-200 text-red-600 hover:bg-red-100 hover:border-red-300 transition-all flex items-center gap-1.5 shadow-sm active:scale-95 text-[10px] font-bold uppercase tracking-wider select-none"
                  title="Clear Status"
                >
                  <Trash2 size={14} />
                  CLEAR
                </button>
                <button
                  onClick={() => setAutoRequestStatus(!autoRequestStatus)}
                  className={`p-2 rounded-md border transition-all flex items-center gap-1.5 shadow-sm active:scale-95 text-[10px] font-bold uppercase tracking-wider select-none ${
                    autoRequestStatus
                      ? "bg-orange-50 border-orange-200 text-orange-600"
                      : "bg-gray-50 border-gray-200 text-gray-400"
                  }`}
                  title={`Auto rerun ${rerunCommand.name}`}
                >
                  Auto
                </button>
                <button
                  onClick={rerunLastStatusCommand}
                  className="p-2 rounded-md border bg-blue-50 border-blue-200 text-blue-600 hover:bg-blue-100 hover:border-blue-300 transition-all flex items-center gap-1.5 shadow-sm active:scale-95 text-[10px] font-bold uppercase tracking-wider select-none"
                  title={`Rerun ${rerunCommand.name}`}
                >
                  <RefreshCw size={14} />
                  RERUN
                </button>
              </div>
              {lastStatusMessage
                .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]/g, "")
                .trim()}
              
              <div className="mt-6 pt-4 border-t border-gray-100 flex justify-end sticky bottom-0 bg-white/80 backdrop-blur-sm -mx-4 px-4 pb-2">
                <button
                  onClick={handleCopy}
                  className={`p-2 px-4 rounded-md border transition-all flex items-center gap-2 shadow-sm active:scale-95 ${
                    copied
                      ? "bg-green-50 border-green-200 text-green-600"
                      : "bg-gray-50 border-gray-200 text-gray-500 hover:text-blue-600 hover:bg-white hover:border-blue-200"
                  }`}
                  title="Copy Status"
                >
                  {copied ? <Check size={16} /> : <Copy size={16} />}
                  <span className="text-[11px] font-bold uppercase tracking-wider">
                    {copied ? "Copied to Clipboard" : "Copy Full Status"}
                  </span>
                </button>
              </div>
            </div>
          </div>
        ) : (
          <div className="flex-1 flex items-center justify-center text-gray-400 text-sm italic bg-gray-50/50 rounded-lg border border-dashed border-gray-200">
            Waiting for diagnostic data...
          </div>
        )}
      </div>
    </DashboardItem>
  );
};
