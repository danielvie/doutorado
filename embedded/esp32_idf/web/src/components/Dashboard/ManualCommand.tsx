import { useState, useRef, useEffect } from "react";
import { bleManager } from "../../services/BleManager";
import { Send, History } from "lucide-react";
import { PanelSize } from "./SizeSelector";
import { DashboardItem } from "./DashboardItem";

export const ManualCommand: React.FC<{
  id: string;
  instanceId: string;
  currentSize?: PanelSize;
  onSizeChange?: (size: PanelSize) => void;
}> = ({ id, instanceId, currentSize = "1x1", onSizeChange = () => {} }) => {
  const [cmd, set_cmd] = useState("");
  const [command_history, set_command_history] = useState<string[]>([]);
  const history_index_ref = useRef(-1);
  const history_ref = useRef<string[]>([]);

  // Keep historyRef in sync with commandHistory state
  useEffect(() => {
    history_ref.current = command_history;
  }, [command_history]);

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    const history = history_ref.current;
    if (e.key === "ArrowUp") {
      e.preventDefault();
      if (history.length === 0) return;
      const newIndex = history_index_ref.current + 1;
      if (newIndex < history.length) {
        history_index_ref.current = newIndex;
        set_cmd(history[newIndex]);
      }
    } else if (e.key === "ArrowDown") {
      e.preventDefault();
      if (history.length === 0) return;
      const newIndex = history_index_ref.current - 1;
      if (newIndex >= 0) {
        history_index_ref.current = newIndex;
        set_cmd(history[newIndex]);
      } else {
        history_index_ref.current = -1;
        set_cmd("");
      }
    }
  };

  const handleSend = (e?: React.FormEvent) => {
    e?.preventDefault();
    if (!cmd.trim()) return;
    const trimmed = cmd.trim();
    set_command_history((prev) => [trimmed, ...prev].slice(0, 50));
    history_index_ref.current = -1;

    const jsonStart = trimmed.indexOf("{");
    const name = jsonStart >= 0 ? trimmed.slice(0, jsonStart).trim() : trimmed;
    try {
      const payload =
        jsonStart >= 0 ? JSON.parse(trimmed.slice(jsonStart)) : {};
      bleManager.sendCommand(name, payload);
    } catch (error: any) {
      alert(`Invalid command JSON: ${error.message}`);
    }
    set_cmd("");
  };

  return (
    <DashboardItem
      id={id}
      instanceId={instanceId}
      title="Console"
      currentSize={currentSize}
      onSizeChange={onSizeChange}
      expandable={false}
    >
      <div className="flex-1 flex flex-col gap-4 min-h-0">
        <form onSubmit={handleSend} className="flex gap-2 p-1">
          <div className="relative flex-1">
            <input
              type="text"
              value={cmd}
              onChange={(e) => set_cmd(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder='system.list_commands or signal.set_alpha {"alpha":0.5}'
              className="w-full font-mono text-sm bg-white border-2 border-gray-200 hover:border-gray-400 focus:border-blue-500 focus:ring-0 outline-none px-3 py-2.5 shadow-none rounded-lg ring-0 transition-none"
            />
            {command_history.length > 0 && (
              <div className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-300 transition-colors pointer-events-none">
                <History size={16} />
              </div>
            )}
          </div>
          <button
            type="submit"
            disabled={!cmd.trim()}
            className="bg-blue-600 hover:bg-blue-700 disabled:bg-gray-300 text-white rounded-lg px-5 py-2.5 transition-all active:scale-95 shadow-md disabled:shadow-none flex items-center justify-center shrink-0"
          >
            <Send size={18} />
          </button>
        </form>

        <div className="flex-1 min-h-0 flex flex-col gap-2">
          <h3 className="text-[10px] font-bold text-gray-500 uppercase tracking-widest flex items-center gap-1.5">
            <History size={12} />
            Command History
          </h3>
          <div className="flex-1 overflow-y-auto bg-gray-900 rounded-lg p-2 font-mono text-xs custom-scrollbar">
            {command_history.length === 0 ? (
              <div className="h-full flex items-center justify-center text-gray-600 italic">
                No history yet
              </div>
            ) : (
              <div className="flex flex-col gap-1">
                {command_history.map((h, i) => (
                  <div
                    key={i}
                    onClick={() => set_cmd(h)}
                    className="group flex items-center gap-2 text-gray-400 hover:text-blue-400 cursor-pointer p-1 rounded hover:bg-gray-800 transition-colors"
                  >
                    <span className="text-gray-600 font-bold shrink-0">
                      $
                    </span>
                    <span className="break-all">{h}</span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </DashboardItem>
  );
};
