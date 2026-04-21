import { Bluetooth, BluetoothConnected, BluetoothOff } from "lucide-react";
import { useBleStore } from "../store/bleStore";
import { bleManager } from "../services/BleManager";

export const Header = () => {
    const { isConnected, systemStatus } = useBleStore();

    const handleToggleConnection = () => {
        if (isConnected) {
            bleManager.disconnect();
        } else {
            bleManager.connect();
        }
    };

    return (
        <header className="bg-white border-b border-gray-200 py-4 px-6 md:px-10 flex flex-col md:flex-row justify-between items-center gap-4 shadow-sm sticky top-0 z-50">
            <div className="flex items-center gap-4">
                <div className={`p-2 rounded-lg ${isConnected ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                    {isConnected ? <BluetoothConnected size={24} /> : <BluetoothOff size={24} />}
                </div>
                <div>
                    <h1 className="text-2xl font-bold text-gray-900">
                        ESP32 Dashboard
                    </h1>
                    <div className="flex items-center gap-2 mt-0.5">
                        <div className={`w-2.5 h-2.5 rounded-full ${isConnected ? 'bg-green-500 animate-pulse' : 'bg-red-500'}`}></div>
                        <span className="text-xs font-bold text-gray-600 uppercase tracking-widest">{systemStatus}</span>
                    </div>
                </div>
            </div>

            <div className="flex items-center gap-4">
                <button
                    onClick={handleToggleConnection}
                    className={isConnected ? 'btn-danger px-6 py-2.5 text-sm font-bold shadow-md' : 'btn-primary px-6 py-2.5 text-sm font-bold shadow-md hover:bg-blue-700 hover:scale-105 transition-all'}
                >
                    <Bluetooth className="w-5 h-5" />
                    {isConnected ? "Disconnect" : "Connect"}
                </button>
            </div>
        </header>
    );
};
