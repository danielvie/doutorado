import { Bluetooth } from "lucide-react";
import { useBleStore } from "../store/bleStore";
import { bleManager } from "../services/BleManager";

const ROUTINE_STATUSES = [
  "Ready",
  "Connected",
  "Disconnected",
  "Requesting Device...",
  "Connecting to GATT Server...",
  "Reconnecting to Device...",
];

export const Header = () => {
  const { isConnected, systemStatus } = useBleStore();

  const handleToggleConnection = () => {
    if (isConnected) {
      bleManager.disconnect();
    } else {
      bleManager.connect();
    }
  };

  const is_connecting = [
    "Requesting Device...",
    "Connecting to GATT Server...",
    "Reconnecting to Device...",
  ].includes(systemStatus);

  const is_failed = systemStatus === "Connection Failed";
  const show_status = !ROUTINE_STATUSES.includes(systemStatus);

  let button_class =
    "btn-primary px-4 py-2 text-sm font-bold shadow-sm hover:bg-blue-700 transition-colors";
  let button_text = "Connect";

  if (isConnected) {
    button_class = "btn-danger px-4 py-2 text-sm font-bold shadow-sm";
    button_text = "Disconnect";
  } else if (is_connecting) {
    button_class =
      "btn bg-gray-200 text-gray-500 px-4 py-2 text-sm font-bold shadow-sm cursor-not-allowed";
    button_text = "Connecting...";
  } else if (is_failed) {
    button_class = "btn-warning px-4 py-2 text-sm font-bold shadow-sm";
    button_text = "Retry";
  }

  return (
    <header className="bg-white border-b border-gray-200 py-2 px-4 md:px-6 flex items-center justify-between gap-4 shadow-sm sticky top-0 z-50">
      <div className="flex items-center gap-3 w-full">
        <div className="flex items-center gap-10 w-full">
          <h1 className="text-lg font-bold text-gray-900">ESP32 Dashboard</h1>
          {show_status && (
            <div className="flex flex-grow gap-2 items-center justify-end">
              <span className="text-xs font-bold text-gray-600/80 uppercase tracking-widest">
                {systemStatus}
              </span>
            </div>
          )}
        </div>
      </div>

      <button
        onClick={handleToggleConnection}
        disabled={is_connecting}
        className={button_class}
      >
        <Bluetooth className="w-4 h-4" />
        {button_text}
      </button>
    </header>
  );
};
