import React from "react";
import { useBleStore } from "../../store/bleStore";
import { PanelSize } from "./SizeSelector";
import { DashboardItem } from "./DashboardItem";

import { Copy, Check } from "lucide-react";

export const StatusPanel: React.FC<{
  id: string;
  instanceId: string;
  currentSize?: PanelSize;
  onSizeChange?: (size: PanelSize) => void;
}> = ({ id, instanceId, currentSize = "1x1", onSizeChange = () => {} }) => {
  const lastStatusMessage = useBleStore((s) => s.lastStatusMessage);
  const [copied, setCopied] = React.useState(false);

  const handleCopy = () => {
    if (!lastStatusMessage) return;
    const cleanMessage = lastStatusMessage.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]/g, "").trim();
    navigator.clipboard.writeText(cleanMessage);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
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
            <div 
              className="min-h-full whitespace-pre-wrap bg-white p-4 pr-10 rounded-lg border border-gray-200 text-sm text-gray-800 leading-relaxed shadow-inner font-mono break-all transition-all relative select-text cursor-text"
            >
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
                {copied && <span className="text-[10px] font-bold uppercase tracking-wider">Copied</span>}
              </button>
              {lastStatusMessage.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]/g, "").trim()}
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
