import { Bluetooth, Activity, Cpu, AlertTriangle } from "lucide-react";
import { useBleStore } from "../store/bleStore";
import { bleManager } from "../services/BleManager";
import { useDataStore } from "../store/dataStore";
import { useState, useEffect } from "react";
import ImageModal from "./ImageModal";

const ROUTINE_STATUSES = [
  "Ready",
  "Connected",
  "Disconnected",
  "Requesting Device...",
  "Connecting to GATT Server...",
  "Reconnecting to Device...",
];

export const Header = () => {
  const isConnected = useBleStore((s) => s.isConnected);
  const isCongested = useBleStore((s) => s.isCongested);
  const systemStatus = useBleStore((s) => s.systemStatus);
  const monitorPeriodMs = useBleStore((s) => s.monitorPeriodMs);
  const [isMocking, setIsMocking] = useState(false);
  const [showPinsModal, setShowPinsModal] = useState(false);
  const addDataPoint = useDataStore((state) => state.addDataPoint);

  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (isMocking) {
      let t = 0;
      interval = setInterval(() => {
        t += 0.05;
        addDataPoint({
          time: new Date().toLocaleTimeString('en-US', { hour12: false }),
          an3: Math.sin(t) * 10 + 50,
          an5: Math.sin(t * 2 + Math.PI / 4) * 5 + 20,
          an6: Math.sin(t * 0.5) * 15 + 80,
        });
      }, monitorPeriodMs);
    }
    return () => clearInterval(interval);
  }, [isMocking, addDataPoint, monitorPeriodMs]);

  const handleToggleConnection = () => {
    if (isConnected) {
      bleManager.disconnect();
    } else if (systemStatus === "Connection Failed") {
      bleManager.connect({ forceNewDevice: true }).catch(() => {});
    } else {
      bleManager.connect().catch(() => {});
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
    "btn-primary px-4 py-2 text-sm font-bold shadow-sm hover:bg-blue-700 transition-colors flex items-center gap-2 rounded-md";
  let button_text = "Connect";

  if (isConnected) {
    button_class = "btn-danger px-4 py-2 text-sm font-bold shadow-sm flex items-center gap-2 rounded-md";
    button_text = "Disconnect";
  } else if (is_connecting) {
    button_class =
      "btn bg-gray-200 text-gray-500 px-4 py-2 text-sm font-bold shadow-sm cursor-not-allowed flex items-center gap-2 rounded-md";
    button_text = "Connecting...";
  } else if (is_failed) {
    button_class = "btn-warning px-4 py-2 text-sm font-bold shadow-sm flex items-center gap-2 rounded-md";
    button_text = "Retry";
  }

  return (
    <header className="bg-white border-b border-gray-200 py-2 px-4 md:px-6 flex items-center justify-between gap-4 shadow-sm sticky top-0 z-50">
      <div className="flex items-center gap-3 w-full">
        <div className="flex items-center gap-10 w-full">
          <h1 className="text-lg font-bold text-gray-900">ESP32 Dashboard</h1>
          {show_status && (
            <div className="flex flex-grow gap-4 items-center justify-end">
              {isCongested && (
                <div className="flex items-center gap-1.5 px-2 py-0.5 bg-amber-50 text-amber-600 border border-amber-200 rounded text-[10px] font-bold uppercase tracking-wider animate-pulse">
                  <AlertTriangle className="w-3 h-3" />
                  Congested
                </div>
              )}
              <span className="text-xs font-bold text-gray-600/80 uppercase tracking-widest">
                {systemStatus}
              </span>
            </div>
          )}
        </div>
      </div>

      <div className="flex items-center gap-2 shrink-0">
        <button
          onClick={() => setShowPinsModal(true)}
          className="flex items-center gap-2 px-3 py-1.5 bg-gray-50 hover:bg-gray-100 border border-gray-200 rounded-lg cursor-pointer transition-colors select-none"
          title="Show ESP32 Pinout"
        >
          <Cpu className="w-4 h-4 text-blue-600" />
          <span className="text-xs font-bold text-gray-600 uppercase tracking-widest">Hardware</span>
        </button>

        <div 
          onClick={() => setIsMocking(!isMocking)}
          className="flex items-center gap-2 px-3 py-1.5 bg-gray-50 hover:bg-gray-100 
          border border-gray-200 rounded-lg cursor-pointer transition-colors 
          select-none"
        >
          <Activity className={`w-4 h-4 transition-colors ${isMocking ? "text-primary" : "text-gray-400"}`} />
          <span className="text-xs font-bold text-gray-600 uppercase tracking-widest">Mock</span>
          <div
            className={`relative inline-flex h-5 w-9 items-center rounded-full transition-colors ${
              isMocking ? "bg-primary" : "bg-gray-300"
            }`}
          >
            <span
              className={`inline-block h-3.5 w-3.5 transform rounded-full bg-white transition-transform ${
                isMocking ? "translate-x-5" : "translate-x-0.5"
              }`}
            />
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
      </div>

      <ImageModal 
        isOpen={showPinsModal} 
        onClose={() => setShowPinsModal(false)} 
        images={[
          { id: "pinout", title: "ESP32 Pinout", src: "hw_esp32_pins.png" },
          { id: "schematic", title: "Schematic", src: "circuit.png" },
          { id: "measure", title: "Measurement Points", src: "hw_measure_points.png" },
        ]}
      />
    </header>
  );
};
