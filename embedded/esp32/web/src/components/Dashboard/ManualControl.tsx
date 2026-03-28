import { useState, useEffect, useRef } from "react";
import { bleManager } from "../../services/BleManager";
import { useBleStore } from "../../store/bleStore";
import { Send, Terminal as TerminalIcon, Trash2 } from "lucide-react";

export const ManualControl = () => {
    const [cmd, setCmd] = useState("");

    const handleSend = (e?: React.FormEvent) => {
        e?.preventDefault();
        if (!cmd.trim()) return;
        bleManager.send(cmd);
        setCmd("");
    };

    return (
        <div className="panel p-6 flex flex-col gap-6 h-full">
            <div className="flex items-center justify-between border-b border-gray-200 pb-4">
                <div className="flex items-center gap-3">
                    <div className="p-2 bg-blue-50 rounded-md text-blue-600">
                        <TerminalIcon className="w-5 h-5" />
                    </div>
                    <h2 className="text-xl font-bold text-gray-900">Manual Console</h2>
                </div>
                <div className="px-3 py-1 bg-gray-100 rounded-md border border-gray-300">
                    <span className="text-xs font-bold text-gray-700 uppercase tracking-widest">Live Terminal</span>
                </div>
            </div>

            <form onSubmit={handleSend} className="flex gap-3">
                <input
                    type="text"
                    value={cmd}
                    onChange={e => setCmd(e.target.value)}
                    placeholder="Enter command..."
                    className="flex-1 font-mono text-sm"
                />
                <button type="submit" className="btn-primary shrink-0 transition-transform active:scale-95 px-6">
                    <Send size={18} />
                </button>
            </form>

            <LogViewer />
        </div>
    );
};

const LogViewer = () => {
    const { statusLogs, clearLogs } = useBleStore();
    const scrollRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        if (scrollRef.current) {
            scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
        }
    }, [statusLogs]);

    return (
        <div className="flex-1 flex flex-col min-h-[300px] bg-gray-50 rounded-lg border border-gray-300 overflow-hidden shadow-sm">
            <div className="flex justify-between items-center px-4 py-3 border-b border-gray-300 bg-gray-100/80">
                <span className="text-xs text-gray-700 font-bold uppercase tracking-widest">System Output</span>
                <button onClick={clearLogs} className="text-gray-500 hover:text-red-600 transition-colors p-1" title="Clear Logs">
                    <Trash2 size={16} />
                </button>
            </div>
            <div ref={scrollRef} className="flex-1 p-4 overflow-y-auto font-mono text-sm space-y-2">
                {statusLogs.length === 0 && (
                    <div className="h-full flex items-center justify-center">
                        <span className="text-gray-500 italic text-xs uppercase tracking-widest font-semibold">Waiting for bridge connection...</span>
                    </div>
                )}
                {[...statusLogs].reverse().map((log, i) => (
                    <div key={i} className="text-gray-800 border-b border-gray-200 pb-2 last:border-0 break-words group font-semibold">
                        <span className="text-gray-500 mr-3">[{new Date().toLocaleTimeString()}]</span>
                        <span className="group-hover:text-blue-700 transition-colors">{log}</span>
                    </div>
                ))}
            </div>
        </div>
    );
};
