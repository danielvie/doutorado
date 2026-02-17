import { useState } from "react";
import { useBleStore } from "../../store/bleStore";

export default function StatusBox() {
    const { lastStatusMessage } = useBleStore();
    const [isVisible, setIsVisible] = useState(true);

    if (!lastStatusMessage) return null;

    return (
        <div className="bg-blue-950/30 border border-blue-900/50 rounded-lg p-3 text-xs font-mono text-blue-200 break-words mb-2 overflow-x-auto">
            <div className="flex justify-between items-center mb-1">
                <div className="text-gray-500 font-bold uppercase text-[10px]">Last Status</div>
                <button
                    onClick={() => setIsVisible(!isVisible)}
                    className="text-[10px] text-blue-400 hover:text-blue-300 underline"
                >
                    {isVisible ? "Hide" : "Show"}
                </button>
            </div>
            {isVisible && <div className="whitespace-pre-wrap">{lastStatusMessage}</div>}
        </div>
    );
};