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
        <div className="bg-gray-900 border border-gray-800 rounded-xl p-4 flex flex-col gap-4 shadow-lg h-full">
            <div className="flex items-center gap-2 mb-1 border-b border-gray-800 pb-2">
                <TerminalIcon className="w-5 h-5 text-green-400" />
                <h2 className="font-bold text-lg text-gray-200">Manual Control</h2>
            </div>


            <form onSubmit={handleSend} className="flex gap-2">
                <input
                    type="text"
                    value={cmd}
                    onChange={e => setCmd(e.target.value)}
                    placeholder="Enter command (e.g. STATUS)..."
                    className="flex-1 bg-gray-950 border border-gray-700 rounded-lg px-3 py-2 font-mono text-sm text-green-400 focus:outline-none focus:border-green-500 placeholder-gray-700"
                />
                <button type="submit" className="p-2 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors">
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
        <div className="flex-1 flex flex-col min-h-[200px] bg-gray-950 rounded-lg border border-gray-800 overflow-hidden">
            <div className="flex justify-between items-center px-3 py-1 bg-gray-800/50 border-b border-gray-800">
                <span className="text-xs text-gray-500 font-bold uppercase">System Logs</span>
                <button onClick={clearLogs} className="text-gray-500 hover:text-red-400">
                    <Trash2 size={12} />
                </button>
            </div>
            <div ref={scrollRef} className="flex-1 p-2 overflow-y-auto font-mono text-xs space-y-1 max-h-60">
                {statusLogs.length === 0 && <span className="text-gray-700 italic">No logs...</span>}
                {[...statusLogs].reverse().map((log, i) => (
                    <div key={i} className="text-gray-300 border-b border-gray-800/30 pb-0.5 last:border-0 break-words">
                        <span className="text-gray-600 mr-2">[{new Date().toLocaleTimeString()}]</span>
                        {log}
                    </div>
                ))}
            </div>
        </div>
    );
};


