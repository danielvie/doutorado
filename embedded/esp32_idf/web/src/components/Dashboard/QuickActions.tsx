import { useState } from "react";
import { bleManager } from "../../services/BleManager";
import { useBleStore } from "../../store/bleStore";
import { Send } from "lucide-react";
import { PanelSize } from "./SizeSelector";
import { DashboardItem } from "./DashboardItem";

export const QuickActions: React.FC<{
  id: string;
  instanceId: string;
  currentSize?: PanelSize;
  onSizeChange?: (size: PanelSize) => void;
}> = ({ id, instanceId, currentSize = "1x1", onSizeChange = () => {} }) => {
  const alpha = useBleStore((s) => s.alpha);
  const setAlpha = useBleStore((s) => s.setAlpha);
  const [cycles, setCycles] = useState(100);
  const monitor_period_ms = useBleStore((s) => s.monitorPeriodMs);
  const set_monitor_period_ms = useBleStore((s) => s.setMonitorPeriodMs);

  const handle_set_cycles = (e: React.ChangeEvent<HTMLInputElement>) =>
    setCycles(parseInt(e.target.value));
  const handle_set_monitor_period_ms = (
    e: React.ChangeEvent<HTMLInputElement>,
  ) => set_monitor_period_ms(parseInt(e.target.value));

  const ble_send_command = (name: string, payload: Record<string, unknown> = {}) =>
    bleManager.sendCommand(name, payload);

  const handle_set_alpha = (a: string) => {
    setAlpha(a.toString());
    ble_send_command("signal.set_alpha", { alpha: Number(a) });
  };

  return (
    <DashboardItem
      id={id}
      instanceId={instanceId}
      title="Quick Actions"
      currentSize={currentSize}
      onSizeChange={onSizeChange}
      expandable={false}
    >
      <div className="flex flex-col gap-4 pr-2">
        {/* Global Controls */}
          <section className="flex flex-col gap-2">
            <h3 className="text-[10px] font-bold text-gray-700 uppercase tracking-widest bg-gray-200/50 p-1.5 rounded-md">
              Global Execution
            </h3>
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
              <button
                onClick={() => ble_send_command("signal.start")}
                className="btn-success text-sm py-2"
              >
                START
              </button>
              <button
                onClick={() => ble_send_command("signal.stop")}
                className="btn-danger text-sm py-2"
              >
                STOP
              </button>
              <button
                onClick={() => ble_send_command("led.on")}
                className="btn-primary text-sm py-2"
              >
                ON
              </button>
              <button
                onClick={() => ble_send_command("led.off")}
                className="btn-secondary text-sm py-2 bg-gray-200 hover:bg-gray-300 text-gray-800"
              >
                OFF
              </button>
              <button
                onClick={() => ble_send_command("led.blink")}
                className="btn bg-amber-500 text-white hover:bg-amber-600 text-sm py-2"
              >
                BLINK
              </button>
              <button
                onClick={() => ble_send_command("system.get_status")}
                className="btn-secondary text-sm py-2 text-gray-800"
              >
                STATUS
              </button>
            </div>

            {/* Alpha Quick Selection */}
            <div className="flex flex-col gap-1.5 mt-1">
              <div className="flex items-center gap-1.5 ml-1">
                <span className="text-[10px] font-bold text-gray-500 uppercase tracking-tighter">
                  Alpha Presets
                </span>
              </div>
              <div className="grid grid-cols-5 gap-1.5">
                {[
                  "0.1",
                  Math.max(0.1, parseFloat(alpha) - 0.1).toFixed(1),
                  alpha,
                  Math.min(0.9, parseFloat(alpha) + 0.1).toFixed(1),
                  "0.9",
                ].map((val, idx) => (
                  <button
                    key={idx}
                    onClick={() => handle_set_alpha(val)}
                    className={`py-1 rounded font-bold text-[10px] border transition-all ${
                      parseFloat(val) === parseFloat(alpha)
                        ? "bg-blue-600 text-white border-blue-600 shadow-sm scale-105 z-10 cursor-default"
                        : "bg-white text-gray-700 border-gray-300 hover:bg-gray-50 cursor-pointer"
                    }`}
                  >
                    {val}
                  </button>
                ))}
              </div>
            </div>
          </section>

          {/* Diagnostic Data */}
          <section className="flex flex-col gap-2">
            <h3 className="text-[10px] font-bold text-gray-700 uppercase tracking-widest bg-gray-200/50 p-1.5 rounded-md">
              Diagnostic & Dataset
            </h3>
            <div className="grid grid-cols-2 gap-3">
              <button
                onClick={() => ble_send_command("debug.matrix_a")}
                className="btn-secondary text-xs font-bold text-gray-800"
              >
                MATRIX A
              </button>
              <button
                onClick={() => ble_send_command("debug.matrix_b")}
                className="btn-secondary text-xs font-bold text-gray-800"
              >
                MATRIX B
              </button>
              <button
                onClick={() => ble_send_command("debug.dataset_a")}
                className="btn-secondary text-xs font-bold text-gray-800"
              >
                DATASET A
              </button>
              <button
                onClick={() => ble_send_command("debug.dataset_b")}
                className="btn-secondary text-xs font-bold text-gray-800"
              >
                DATASET B
              </button>
              <button
                onClick={() => ble_send_command("debug.signal_timing")}
                className="btn-secondary text-xs font-bold text-gray-800"
              >
                TIMING
              </button>
            </div>
          </section>

          {/* Parametric Control */}
          <section className="flex flex-col gap-2">
            <h3 className="text-[10px] font-bold text-gray-700 uppercase tracking-widest bg-gray-200/50 p-1.5 rounded-md">
              Parametric Control
            </h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
              <div className="flex flex-col gap-1.5">
                <label className="text-xs text-gray-700 font-bold uppercase ml-1">
                  Cycles
                </label>
                <div className="flex gap-1 p-1">
                  <input
                    type="number"
                    onChange={handle_set_cycles}
                    value={cycles}
                    className="flex-1 min-w-0 text-sm font-semibold text-gray-800 bg-white border border-gray-300 hover:border-gray-400 focus:border-blue-500 focus:ring-0 outline-none px-2 h-8 shadow-none transition-none rounded"
                  />
                  <button
                    onClick={() =>
                      ble_send_command("signal.set_cycle_interval", { cycles })
                    }
                    className="w-8 h-8 flex items-center justify-center bg-indigo-50 text-indigo-600 rounded border border-indigo-100 hover:bg-indigo-100 transition-colors shrink-0"
                    title="Send Cycles"
                  >
                    <Send size={12} />
                  </button>
                </div>
              </div>
              <div className="flex flex-col gap-1.5">
                <label className="text-xs text-gray-700 font-bold uppercase ml-1">
                  Monitor (ms)
                </label>
                <div className="flex gap-1 p-1">
                  <input
                    type="number"
                    step={10}
                    onChange={handle_set_monitor_period_ms}
                    value={monitor_period_ms}
                    className="flex-1 min-w-0 text-sm font-semibold text-gray-800 bg-white border border-gray-300 hover:border-gray-400 focus:border-blue-500 focus:ring-0 outline-none px-2 h-8 shadow-none transition-none rounded"
                  />
                  <button
                    onClick={() =>
                      ble_send_command("analog.set_monitor_period", {
                        period_ms: monitor_period_ms,
                      })
                    }
                    className="w-8 h-8 flex items-center justify-center bg-indigo-50 text-indigo-600 rounded border border-indigo-100 hover:bg-indigo-100 transition-colors shrink-0"
                    title="Send Monitor"
                  >
                    <Send size={12} />
                  </button>
                </div>
              </div>
            </div>
          </section>

          {/* System Config */}
          <section className="flex flex-col gap-2">
            <h3 className="text-[10px] font-bold text-gray-700 uppercase tracking-widest bg-gray-200/50 p-1.5 rounded-md">
              System Configuration
            </h3>
            <div className="flex flex-wrap gap-2">
              <button
                onClick={() =>
                  ble_send_command("signal.set_cycle_interval", { cycles })
                }
                className="px-3 py-1.5 rounded-md font-bold text-[10px] border transition-colors uppercase text-indigo-800 bg-indigo-50 border-indigo-200 hover:bg-indigo-100 shadow-sm"
              >
                SET CYCLES: {cycles}
              </button>
              <button
                onClick={() =>
                  ble_send_command("analog.set_monitor_period", {
                    period_ms: monitor_period_ms,
                  })
                }
                className="px-3 py-1.5 rounded-md font-bold text-[10px] border transition-colors uppercase text-indigo-800 bg-indigo-50 border-indigo-200 hover:bg-indigo-100 shadow-sm"
              >
                SET MONITOR: {monitor_period_ms}ms
              </button>
              <button
                onClick={() => ble_send_command("control.enable")}
                className="px-3 py-1.5 rounded-md font-bold text-[10px] border transition-colors uppercase text-green-800 bg-green-100 border-green-300 hover:bg-green-200 shadow-sm"
              >
                Control On
              </button>
              <button
                onClick={() => ble_send_command("control.disable")}
                className="px-3 py-1.5 rounded-md font-bold text-[10px] border transition-colors uppercase text-red-800 bg-red-100 border-red-300 hover:bg-red-200 shadow-sm"
              >
                Control Off
              </button>
              <button
                onClick={() => ble_send_command("analog.ble_read_enable")}
                className="px-3 py-1.5 rounded-md font-bold text-[10px] border transition-colors uppercase text-amber-800 bg-amber-100 border-amber-300 hover:bg-amber-200 shadow-sm"
              >
                BLE Read On
              </button>
              <button
                onClick={() => ble_send_command("analog.ble_read_disable")}
                className="px-3 py-1.5 rounded-md font-bold text-[10px] border transition-colors uppercase text-gray-800 bg-gray-200 border-gray-300 hover:bg-gray-300 shadow-sm"
              >
                BLE Read Off
              </button>
              <button
                onClick={() => ble_send_command("system.list_commands")}
                className="px-3 py-1.5 rounded-md font-bold text-[10px] border transition-colors uppercase text-green-800 bg-green-100 border-green-300 hover:bg-green-200 shadow-sm"
              >
                List Commands
              </button>
            </div>
          </section>
        </div>
    </DashboardItem>
  );
};
