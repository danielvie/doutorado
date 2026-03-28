import { useState } from "react";
import { useBleStore } from "../../store/bleStore";

export default function StatusBox() {
    const { lastStatusMessage } = useBleStore();
    const [isVisible, setIsVisible] = useState(true);

    if (!lastStatusMessage) return null;

    return (
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 text-xs font-mono text-blue-800 break-words mb-4 overflow-hidden relative group">
            <div className="absolute top-0 right-0 p-2 opacity-50">
                <div className="w-2 h-2 rounded-full bg-blue-500 animate-ping mt-1 mr-1"></div>
            </div>
            
            <div className="flex justify-between items-center mb-2">
                <div className="text-blue-700 font-bold uppercase tracking-widest text-xs">Diagnostic Payload</div>
                <button
                    onClick={() => setIsVisible(!isVisible)}
                    className="text-xs text-blue-600 hover:text-blue-800 transition-colors uppercase font-bold tracking-widest bg-blue-100 px-2 py-1 rounded"
                >
                    {isVisible ? "Collapse" : "Expand"}
                </button>
            </div>
            {isVisible && (
                <div className="whitespace-pre-wrap bg-white p-4 rounded-md border border-blue-200 text-sm text-blue-900 leading-relaxed max-h-40 overflow-y-auto mt-3 shadow-inner font-semibold">
                    {lastStatusMessage}
                </div>
            )}
        </div>
    );
}