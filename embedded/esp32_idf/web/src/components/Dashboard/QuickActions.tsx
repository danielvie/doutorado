import { useState, useRef, useEffect } from "react";
import { bleManager } from "../../services/BleManager";
import { useBleStore } from "../../store/bleStore";
import { Zap, Send, GripVertical } from "lucide-react";
import StatusBox from "./StatusBox";

enum EMATRIX {
  A = "A",
  B = "B",
}

export const QuickActions = () => {
  const [chunk, set_chunk] = useState(10);
  const [cycles, setCycles] = useState(100);
  const [monitor_period_ms, set_monitor_period_ms] = useState(100);
  const [cmd, set_cmd] = useState("");
  const [command_history, set_command_history] = useState<string[]>([]);
  const history_index_ref = useRef(-1);
  const history_ref = useRef<string[]>([]);

  // Keep historyRef in sync with commandHistory state
  useEffect(() => {
    history_ref.current = command_history;
  }, [command_history]);

  const handle_set_chunk = (e: React.ChangeEvent<HTMLInputElement>) =>
    set_chunk(parseInt(e.target.value));
  const handle_set_cycles = (e: React.ChangeEvent<HTMLInputElement>) =>
    setCycles(parseInt(e.target.value));
  const handle_set_monitor_period_ms = (
    e: React.ChangeEvent<HTMLInputElement>,
  ) => set_monitor_period_ms(parseInt(e.target.value));

  const ble_send_command = (cmd: string) => bleManager.send(cmd);

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    const history = history_ref.current;
    if (e.key === "ArrowUp") {
      e.preventDefault();
      if (history.length === 0) return;
      const newIndex = history_index_ref.current + 1;
      if (newIndex < history.length) {
        history_index_ref.current = newIndex;
        set_cmd(history[newIndex]);
      }
    } else if (e.key === "ArrowDown") {
      e.preventDefault();
      if (history.length === 0) return;
      const newIndex = history_index_ref.current - 1;
      if (newIndex >= 0) {
        history_index_ref.current = newIndex;
        set_cmd(history[newIndex]);
      } else {
        history_index_ref.current = -1;
        set_cmd("");
      }
    }
  };

  const handleSend = (e?: React.FormEvent) => {
    e?.preventDefault();
    if (!cmd.trim()) return;
    set_command_history((prev) => [...prev, cmd.trim()]);
    history_index_ref.current = -1;
    bleManager.send(cmd);
    set_cmd("");
  };

  const handle_status_matrix = (matrix: EMATRIX) => {
    ble_send_command(`STATUS_MATRIX:${matrix}`);
  };

  return (
    <div className="panel p-6 flex flex-col gap-6 h-full">
      <div className="flex justify-between items-center border-b border-gray-200 pb-4">
        <div className="flex items-center gap-3">
          <div className="p-1.5 text-gray-400 hover:text-gray-600 cursor-grab active:cursor-grabbing transition-colors" data-swapy-handle>
            <GripVertical size={20} />
          </div>
          <div className="p-2 bg-amber-50 rounded-md text-amber-600">
            <Zap className="w-5 h-5" />
          </div>
          <h2 className="text-xl font-bold text-gray-900">Quick Actions</h2>
        </div>
      </div>

      <StatusBox />

      <div className="flex flex-col gap-8">
        {/* Manual Command */}
        <section className="flex flex-col gap-4">
          <h3 className="text-xs font-bold text-gray-700 uppercase tracking-widest bg-gray-100/50 p-2 rounded-md">
            Manual Command
          </h3>
          <form onSubmit={handleSend} className="flex gap-3">
            <input
              type="text"
              value={cmd}
              onChange={(e) => set_cmd(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="Enter custom command..."
              className="flex-1 font-mono text-sm bg-white border-2 border-gray-200 focus:border-blue-500 rounded-md px-3 py-2 shadow-sm"
            />
            <button
              type="submit"
              className="btn-primary shrink-0 transition-transform active:scale-95 px-6"
            >
              <Send size={18} />
            </button>
          </form>
        </section>

        {/* Parametric Control */}
        <section className="flex flex-col gap-4">
          <h3 className="text-xs font-bold text-gray-700 uppercase tracking-widest bg-gray-100/50 p-2 rounded-md">
            Parameter Matrix
          </h3>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div className="flex flex-col gap-1.5">
              <label className="text-xs text-gray-700 font-bold uppercase ml-1">
                Chunk
              </label>
              <input
                type="number"
                onChange={handle_set_chunk}
                value={chunk}
                className="w-full text-sm font-semibold text-gray-800 bg-gray-50 border-gray-300"
              />
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-xs text-gray-700 font-bold uppercase ml-1">
                Cycles
              </label>
              <input
                type="number"
                onChange={handle_set_cycles}
                value={cycles}
                className="w-full text-sm font-semibold text-gray-800 bg-gray-50 border-gray-300"
              />
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-xs text-gray-700 font-bold uppercase ml-1">
                Monitor (ms)
              </label>
              <input
                type="number"
                onChange={handle_set_monitor_period_ms}
                value={monitor_period_ms}
                className="w-full text-sm font-semibold text-gray-800 bg-gray-50 border-gray-300"
              />
            </div>
          </div>
        </section>

        {/* Global Controls */}
        <section className="flex flex-col gap-4">
          <h3 className="text-xs font-bold text-gray-700 uppercase tracking-widest bg-gray-100/50 p-2 rounded-md">
            Global Execution
          </h3>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
            <button
              onClick={() => ble_send_command("START")}
              className="btn-success text-sm py-2"
            >
              START
            </button>
            <button
              onClick={() => ble_send_command("STOP")}
              className="btn-danger text-sm py-2"
            >
              STOP
            </button>
            <button
              onClick={() => ble_send_command("ON")}
              className="btn-primary text-sm py-2"
            >
              ON
            </button>
            <button
              onClick={() => ble_send_command("OFF")}
              className="btn-secondary text-sm py-2 bg-gray-200 hover:bg-gray-300 text-gray-800"
            >
              OFF
            </button>
            <button
              onClick={() => ble_send_command("BLINK")}
              className="btn bg-amber-500 text-white hover:bg-amber-600 text-sm py-2"
            >
              BLINK
            </button>
            <button
              onClick={() => ble_send_command("STATUS")}
              className="btn-secondary text-sm py-2 text-gray-800"
            >
              STATUS
            </button>
          </div>
        </section>

        {/* Diagnostic Data */}
        <section className="flex flex-col gap-4">
          <h3 className="text-xs font-bold text-gray-700 uppercase tracking-widest bg-gray-100/50 p-2 rounded-md">
            Diagnostic & Dataset
          </h3>
          <div className="grid grid-cols-2 gap-3">
            <button
              onClick={() => handle_status_matrix(EMATRIX.A)}
              className="btn-secondary text-xs font-bold text-gray-800"
            >
              MATRIX A
            </button>
            <button
              onClick={() => handle_status_matrix(EMATRIX.B)}
              className="btn-secondary text-xs font-bold text-gray-800"
            >
              MATRIX B
            </button>
            <button
              onClick={() => ble_send_command("PRINT_DATASET_A")}
              className="btn-secondary text-xs font-bold text-gray-800"
            >
              DATASET A
            </button>
            <button
              onClick={() => ble_send_command("PRINT_DATASET_B")}
              className="btn-secondary text-xs font-bold text-gray-800"
            >
              DATASET B
            </button>
          </div>
        </section>

        {/* System Config */}
        <section className="flex flex-col gap-4">
          <h3 className="text-xs font-bold text-gray-700 uppercase tracking-widest bg-gray-100/50 p-2 rounded-md">
            System Configuration
          </h3>
          <div className="flex flex-wrap gap-2">
            {[
              {
                cmd: "CONTROL_ON",
                label: "Control On",
                color:
                  "text-green-800 bg-green-100 border-green-300 hover:bg-green-200",
              },
              {
                cmd: "CONTROL_OFF",
                label: "Control Off",
                color:
                  "text-red-800 bg-red-100 border-red-300 hover:bg-red-200",
              },
              {
                cmd: "SET_PRINT_ON",
                label: "Print On",
                color:
                  "text-blue-800 bg-blue-100 border-blue-300 hover:bg-blue-200",
              },
              {
                cmd: "SET_PRINT_OFF",
                label: "Print Off",
                color:
                  "text-gray-800 bg-gray-200 border-gray-300 hover:bg-gray-300",
              },
              {
                cmd: "BLE_READ_ON",
                label: "BLE Read On",
                color:
                  "text-amber-800 bg-amber-100 border-amber-300 hover:bg-amber-200",
              },
              {
                cmd: "BLE_READ_OFF",
                label: "BLE Read Off",
                color:
                  "text-gray-800 bg-gray-200 border-gray-300 hover:bg-gray-300",
              },
            ].map((item) => (
              <button
                key={item.cmd}
                onClick={() => ble_send_command(item.cmd)}
                className={`px-4 py-2 rounded-md font-bold text-xs border transition-colors uppercase ${item.color} shadow-sm`}
              >
                {item.label}
              </button>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
};
