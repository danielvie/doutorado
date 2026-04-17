import React, { useState } from "react";
import {
  ble_connect_device,
  ble_disconnect_device,
  ble_send_command,
} from "./bluetooth";
import { DataPoint } from "./Chart";

interface Props {
  isConnected: boolean;
  data: DataPoint[];
  onClearData: () => void;
  onShowImages: () => void;
}

export const MenuConnectionToolbar: React.FC<Props> = ({
  isConnected,
  data,
  onClearData,
  onShowImages,
}) => {
  const [copyLabel, setCopyLabel] = useState("copy");

  const handleCopy = async () => {
    const format = (arr: any[]) => `[${arr.join(", ")}]`;
    const text =
      `time = ${format(data.map((d) => d.time))};\n` +
      `an3 = ${format(data.map((d) => d.an3))};\n` +
      `an5 = ${format(data.map((d) => d.an5))};\n` +
      `an6 = ${format(data.map((d) => d.an6))};\n`;

    try {
      await navigator.clipboard.writeText(text);
      setCopyLabel("copied!");
      setTimeout(() => setCopyLabel("copy"), 1000);
    } catch (err) {
      console.error("Copy failed", err);
    }
  };

  return (
    <div className="flex flex-wrap gap-2 justify-center items-center">
      <button
        onClick={isConnected ? ble_disconnect_device : ble_connect_device}
        className={`btn ${isConnected ? "danger" : "success"} w-48`}
      >
        {isConnected ? "Disconnect" : "Connect to ESP32"}
      </button>

      <button onClick={() => ble_send_command("STATUS")} className="btn">
        Status
      </button>
      <button onClick={handleCopy} className="btn w-20">
        {copyLabel}
      </button>
      <button onClick={onClearData} className="btn warning">
        Clear Data
      </button>
      <button
        onClick={onShowImages}
        className="text-3xl hover:scale-110 transition-transform ml-2"
        title="Show Images"
      >
        🖼️
      </button>
    </div>
  );
};
