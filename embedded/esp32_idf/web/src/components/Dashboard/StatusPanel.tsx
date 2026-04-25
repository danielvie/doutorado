import React from "react";
import { useBleStore } from "../../store/bleStore";
import { PanelSize } from "./SizeSelector";
import { DashboardItem } from "./DashboardItem";

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
    navigator.clipboard.writeText(lastStatusMessage);
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
      <div className="flex-1 min-h-0 flex flex-col relative">
        {lastStatusMessage ? (
          <div className="flex-1 overflow-y-auto pr-1 custom-scrollbar">
            <div 
              onClick={handleCopy}
              className="min-h-full whitespace-pre-wrap bg-white p-4 rounded-lg border border-gray-200 text-sm text-gray-800 leading-relaxed shadow-inner font-mono break-all cursor-pointer hover:border-blue-300 hover:bg-blue-50/20 transition-all relative group"
              title="Click to copy status"
            >
              {copied && (
                <div className="absolute top-2 right-2 bg-green-500 text-white text-[10px] font-bold px-2 py-1 rounded shadow-sm animate-in fade-in zoom-in duration-200">
                  COPIED!
                </div>
              )}
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
