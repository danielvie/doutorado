import { Bluetooth, BluetoothConnected, BluetoothOff } from "lucide-react";
import { useBleStore } from "../store/bleStore";
import { bleManager } from "../services/BleManager";

export const Header = () => {
    const { isConnected, systemStatus, isMockMode } = useBleStore();

    const handleToggleConnection = () => {
        if (isConnected) {
            bleManager.disconnect();
        } else {
            bleManager.connect();
        }
    };

    return (
        <header className="flex flex-col md:flex-row justify-between items-center p-4 bg-gray-900 border-b border-gray-800 shadow-md gap-4">
            <div className="flex items-center gap-3">
                <div className={`p-2 rounded-full ${isConnected ? 'bg-green-900/50' : 'bg-red-900/50'}`}>
                    {isConnected ? <BluetoothConnected className="text-green-400" /> : <BluetoothOff className="text-red-400" />}
                </div>
                <div>
                    <h1 className="text-xl font-bold bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
                        ESP32 Control Center
                    </h1>
                    <div className="flex items-center gap-2 text-xs text-gray-400">
                        <span className={`w-2 h-2 rounded-full ${isConnected ? 'bg-green-500 animate-pulse' : 'bg-red-500'}`}></span>
                        {systemStatus}
                    </div>
                </div>
            </div>

            <div className="flex items-center gap-3">
                <div className="flex items-center gap-2 bg-gray-800 p-1 rounded-lg border border-gray-700">
                    <button
                        onClick={() => bleManager.setMockMode(false)}
                        className={`px-3 py-1 rounded text-xs font-bold transition-all ${!isMockMode ? 'bg-blue-600 text-white shadow-lg' : 'text-gray-400 hover:text-white'}`}
                    >
                        Real BLE
                    </button>
                    <button
                        onClick={() => bleManager.setMockMode(true)}
                        className={`px-3 py-1 rounded text-xs font-bold transition-all ${isMockMode ? 'bg-purple-600 text-white shadow-lg' : 'text-gray-400 hover:text-white'}`}
                    >
                        Mock Mode
                    </button>
                </div>

                <button
                    onClick={handleToggleConnection}
                    className={`flex items-center gap-2 px-6 py-2 rounded-lg font-bold transition-all shadow-lg active:scale-95
                        ${isConnected
                            ? 'bg-red-600 hover:bg-red-700 text-white shadow-red-900/20'
                            : 'bg-green-600 hover:bg-green-700 text-white shadow-green-900/20'}`
                    }
                >
                    <Bluetooth className="w-4 h-4" />
                    {isConnected ? "Disconnect" : "Connect"}
                </button>
            </div>
        </header>
    );
};
