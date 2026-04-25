import React from "react";
import { useBleStore } from "../../store/bleStore";
import { GripVertical } from "lucide-react";
import { PanelSize, SizeSelector } from "./SizeSelector";

export const StatusPanel: React.FC<{
  currentSize?: PanelSize;
  onSizeChange?: (size: PanelSize) => void;
}> = ({ currentSize = "1x1", onSizeChange = () => {}, dragHandleRef }) => {
  const { lastStatusMessage } = useBleStore();

  return (
    <div className="panel p-3 flex flex-col gap-3 h-full min-h-0 overflow-hidden">
      <div className="flex justify-between items-center border-b border-gray-200 pb-2">
        <div className="flex items-center gap-1.5">
          <div
            ref={dragHandleRef}
            className="p-1.5 text-gray-400 hover:text-gray-600 cursor-grab active:cursor-grabbing transition-colors"
          >
            <GripVertical size={20} />
          </div>
          <SizeSelector currentSize={currentSize} onSizeChange={onSizeChange} />
          <h2 className="text-xl font-bold text-gray-900">Status</h2>
        </div>
      </div>

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
    </div>
  );
};
