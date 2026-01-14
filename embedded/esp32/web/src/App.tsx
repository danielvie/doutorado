// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.
// src/App.tsx

import { useCallback, useEffect, useState } from "react";
import "./App.css";

// Components
import RealtimeChart, { DataPoint } from "./components/Chart";
import MenuAdvancedButtons from "./components/MenuAdvancedButtons";
import ImageModal from "./components/ImageModal";

// New Modular Components
import { MenuConnectionToolbar } from "./components/MenuConnectionToolbar";
import { MenuControlSignal } from "./components/MenuControlSignal";
import { MenuControlManual } from "./components/MenuControlManual";

// Services
import {
  ble_app_set_status_msg,
  ble_set_fn_probe,
  ble_is_connected,
  ble_set_update_status,
} from "./components/bluetooth";

const initial_time = new Date();

function App() {
  // --- UI State ---
  const [showAdvanced, setShowAdvanced] = useState(true);
  const [showChart, setShowChart] = useState(true);
  const [showImages, setShowImages] = useState(false);

  // --- Logic State ---
  const [isConnected, setIsConnected] = useState(false);
  const [connStatusText, setConnStatusText] = useState("Ready");
  const [statusMsg, setStatusMsg] = useState(".");

  const [alpha, setAlpha] = useState("0.5");
  const [data, setData] = useState<DataPoint[]>([]);

  // Chart Config
  const [analogScale] = useState(1.0); // If you need setters, add them
  const [filterAlpha] = useState(0);

  // --- 1. Global BLE Setup ---
  useEffect(() => {
    // A. Bind Loggers
    ble_app_set_status_msg(setStatusMsg);
    ble_set_update_status(setConnStatusText);

    // B. Connection Polling (Global)
    const interval = setInterval(() => {
      setIsConnected(ble_is_connected());
    }, 1000);

    return () => clearInterval(interval);
  }, []);

  // --- 2. Data Ingestion ---
  const handleProbeData = useCallback(
    (values: { an3: string; an5: string; an6: string }) => {
      const timeOffset = (
        new Date().getTime() - initial_time.getTime()
      ).toString();
      setData((prev) => [
        ...prev,
        {
          time: timeOffset,
          an3: parseFloat(values.an3),
          an5: parseFloat(values.an5),
          an6: parseFloat(values.an6),
        },
      ]);
    },
    [],
  );

  useEffect(() => {
    ble_set_fn_probe(handleProbeData);
  }, [handleProbeData]);

  // --- Render ---
  return (
    <>
      <div className="grid grid-cols-1 tablet:grid-cols-2 gap-4 p-4 max-w-[1600px] mx-auto">
        {/* === Left Column: CONTROLS === */}
        <div className="flex flex-col gap-2">
          <h1 className="text-4xl font-bold text-center mb-2">
            ESP32 Web Control
          </h1>

          {/* 1. Global Toolbar */}
          <MenuConnectionToolbar
            isConnected={isConnected}
            data={data}
            onClearData={() => setData([])}
            onShowImages={() => setShowImages(true)}
          />

          {/* 2. Specific Controls */}
          <MenuControlManual />

          <MenuControlSignal
            alpha={alpha}
            setAlpha={setAlpha}
            isConnected={isConnected}
          />

          {/* 3. View Toggles */}
          <div className="p-3 bg-panel-background rounded-md flex gap-2 shadow-sm">
            <button
              onClick={() => setShowChart((p) => !p)}
              className="btn info flex-1"
            >
              {showChart ? "Chart >>" : "Chart <<"}
            </button>
            <button
              onClick={() => setShowAdvanced((p) => !p)}
              className="btn info flex-1"
            >
              {showAdvanced ? "Advanced Menu >>" : "Advanced Menu <<"}
            </button>
          </div>

          {/* 4. Connection Footer */}
          <div
            className={`px-3 py-1 rounded text-center font-bold transition-colors ${
              isConnected
                ? "bg-green-900/50 text-green-200"
                : "bg-red-900/50 text-red-200"
            }`}
          >
            Status: {connStatusText} —{" "}
            {isConnected ? "CONNECTED" : "DISCONNECTED"}
          </div>
        </div>

        {/* === Right Column: DATA & LOGS === */}
        <div className="flex flex-col gap-2">
          {/* Chart */}
          {showChart && (
            <div className="h-96 tablet:h-auto min-h-[400px]">
              <RealtimeChart
                data={data.slice(-500)}
                analog_scale={analogScale}
                filter_alpha={filterAlpha}
              />
            </div>
          )}

          {/* System Log */}
          <div className="bg-panel-background rounded-md p-3 shadow-sm border border-gray">
            <div className="flex justify-between items-center mb-2 border-b border-bar pb-1">
              <span className="text-xs text-text-shade uppercase font-bold">
                System Log
              </span>
              <button
                onClick={() => setStatusMsg("")}
                className="text-xs text-accent hover:text-accent-shade"
              >
                [Clear]
              </button>
            </div>
            <div className="font-mono text-left text-sm whitespace-pre-wrap text-text min-h-[3rem] max-h-40 overflow-y-auto">
              {statusMsg?.trim().slice(0, 1000) || (
                <span className="text-text-shade italic">No messages...</span>
              )}
            </div>
          </div>

          {/* Advanced Menu */}
          {showAdvanced && (
            <div className="bg-panel-background rounded-md p-4 shadow-sm">
              <MenuAdvancedButtons
                alpha={alpha}
                set_alpha={setAlpha}
                status_msg={statusMsg}
                set_status_msg={setStatusMsg}
              />
            </div>
          )}
        </div>
      </div>

      {/* Overlays */}
      <ImageModal isOpen={showImages} onClose={() => setShowImages(false)} />
    </>
  );
}

export default App;
