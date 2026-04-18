import React, { useState } from "react";
import { ble_send_command } from "./bluetooth";

export const MenuControlManual: React.FC = () => {
  const [commandMsg, setCommandMsg] = useState("");

  const sendCommand = () => {
    ble_send_command(commandMsg);
  };

  return (
    <div className="bg-panel-background p-6 rounded-lg shadow-lg border border-gray">
      {/* Command Input */}
      <div className="flex gap-2 mb-2">
        <input
          type="text"
          value={commandMsg}
          onChange={(e) => setCommandMsg(e.target.value)}
          className="flex-1 input px-3 py-2"
          placeholder="Enter command..."
        />
        <button onClick={sendCommand} className="btn send">
          SEND
        </button>
      </div>

      <hr className="border-bar my-6" />

      {/* Quick Actions */}
      <div className="flex gap-2 justify-center">
        <button
          onClick={() => ble_send_command("START")}
          className="btn success px-6"
        >
          START
        </button>
        <button
          onClick={() => ble_send_command("STOP")}
          className="btn danger px-6"
        >
          STOP (Low)
        </button>
        <button
          onClick={() => ble_send_command("HIGH")}
          className="btn info px-6"
        >
          HIGH
        </button>
      </div>
    </div>
  );
};
