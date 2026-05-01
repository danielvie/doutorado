import { useEffect, useRef, useState } from "react";
import { useBleStore } from "../../store/bleStore";
import { Check, ClipboardCopy, Trash2 } from "lucide-react";
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
  const [copiedIndex, setCopiedIndex] = useState<number | null>(null);
  const [copiedAll, setCopiedAll] = useState(false);

  const handleCopy = (log: string, index: number) => {
    navigator.clipboard.writeText(log);
    setCopiedIndex(index);
    setTimeout(() => setCopiedIndex(null), 1500);
  };

  const handleCopyAll = () => {
    navigator.clipboard.writeText([...statusLogs].reverse().join("\n"));
    setCopiedAll(true);
    setTimeout(() => setCopiedAll(false), 1500);
  };

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
        <div className="flex items-center gap-1">
          <button
            onClick={handleCopyAll}
            disabled={statusLogs.length === 0}
            className="text-gray-500 hover:text-blue-700 disabled:text-gray-300 disabled:cursor-not-allowed transition-colors p-1"
            title="Copy all system output"
          >
            {copiedAll ? <Check size={16} /> : <ClipboardCopy size={16} />}
          </button>
          <button
            onClick={clearLogs}
            className="text-gray-500 hover:text-red-600 transition-colors p-1"
            title="Clear Logs"
          >
            <Trash2 size={16} />
          </button>
        </div>
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
            onClick={() => handleCopy(log, i)}
            className="text-gray-800 border-b border-gray-200 pb-2 last:border-0 break-words group font-semibold whitespace-pre-wrap cursor-pointer hover:bg-blue-50/50 rounded transition-colors relative"
            title="Click to copy log"
          >
            <span className="text-gray-500 mr-3">
              [{new Date().toLocaleTimeString()}]
            </span>
            <span className="group-hover:text-blue-700 transition-colors">
              {log}
            </span>
            {copiedIndex === i && (
              <span className="absolute right-2 top-0 text-[10px] text-green-600 font-bold bg-green-50 px-1 rounded animate-bounce">
                COPIED
              </span>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};
