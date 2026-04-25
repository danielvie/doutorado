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

  return (
    <DashboardItem
      id={id}
      instanceId={instanceId}
      title="Status"
      currentSize={currentSize}
      onSizeChange={onSizeChange}
      expandable={false}
    >
      <div className="flex-1 min-h-0 flex flex-col">
        {lastStatusMessage ? (
          <div className="flex-1 overflow-y-auto pr-1 custom-scrollbar">
            <div className="min-h-full whitespace-pre-wrap bg-white p-4 rounded-lg border border-gray-200 text-sm text-gray-800 leading-relaxed shadow-inner font-mono break-all">
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
