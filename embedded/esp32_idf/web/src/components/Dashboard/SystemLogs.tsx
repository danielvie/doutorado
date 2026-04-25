import { useEffect, useRef } from "react";
import { useBleStore } from "../../store/bleStore";
import { Trash2 } from "lucide-react";
import { PanelSize } from "./SizeSelector";
import { DashboardItem } from "./DashboardItem";

export const SystemLogs: React.FC<{
  id: string;
  instanceId: string;
  currentSize?: PanelSize;
  onSizeChange?: (size: PanelSize) => void;
}> = ({ id, instanceId, currentSize = "1x1", onSizeChange = () => {} }) => {
  return (
    <DashboardItem
      id={id}
      instanceId={instanceId}
      title="System Logs"
      currentSize={currentSize}
      onSizeChange={onSizeChange}
      expandable={false}
    >
      <LogViewer />
    </DashboardItem>
  );
};

const LogViewer: React.FC = () => {
  const statusLogs = useBleStore((s) => s.statusLogs);
  const clearLogs = useBleStore((s) => s.clearLogs);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [statusLogs]);

  return (
    <div className="flex flex-col bg-gray-50 rounded-lg border border-gray-300 overflow-hidden shadow-sm min-h-0 flex-1">
      <div className="flex justify-between items-center px-4 py-3 border-b border-gray-300 bg-gray-100/80">
        <span className="text-xs text-gray-700 font-bold uppercase tracking-widest">
          System Output
        </span>
        <button
          onClick={clearLogs}
          className="text-gray-500 hover:text-red-600 transition-colors p-1"
          title="Clear Logs"
        >
          <Trash2 size={16} />
        </button>
      </div>
      <div
        ref={scrollRef}
        className="flex-1 p-4 overflow-y-auto font-mono text-sm space-y-2"
      >
        {statusLogs.length === 0 && (
          <div className="h-full flex items-center justify-center">
            <span className="text-gray-500 italic text-xs uppercase tracking-widest font-semibold">
              Waiting for bridge connection...
            </span>
          </div>
        )}
        {[...statusLogs].reverse().map((log, i) => (
          <div
            key={i}
            className="text-gray-800 border-b border-gray-200 pb-2 last:border-0 break-words group font-semibold"
          >
            <span className="text-gray-500 mr-3">
              [{new Date().toLocaleTimeString()}]
            </span>
            <span className="group-hover:text-blue-700 transition-colors">
              {log}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
};
