import { sendCommand, useIsLive } from "../../services/commands";
import { useBleStore } from "../../store/bleStore";
import { DashboardItem } from "./DashboardItem";

const SectionTitle: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => (
  <h3 className="text-[10px] font-bold text-gray-700 uppercase tracking-widest bg-gray-200/50 p-1.5 rounded-md">
    {children}
  </h3>
);

export const QuickActions: React.FC = () => {
  const engine = useBleStore((s) => s.signalEngine);
  const setEngine = useBleStore((s) => s.setSignalEngine);
  const isLive = useIsLive();

  const ble_send_command = (
    name: string,
    payload: Record<string, unknown> = {},
  ) => sendCommand(name, payload);

  const handle_set_engine = (nextEngine: "cpu" | "dma") => {
    setEngine(nextEngine);
    ble_send_command("signal.engine", { engine: nextEngine });
  };

  return (
    <DashboardItem title="Quick Actions" expandable={false}>
      <fieldset
        disabled={!isLive}
        className={`flex flex-col gap-4 pr-2 transition-opacity ${isLive ? "" : "opacity-50"}`}
      >
        {/* Signal Execution */}
        <section className="flex flex-col gap-2">
          <SectionTitle>Signal</SectionTitle>
          <div className="flex flex-col gap-1.5 mt-1">
            <span className="text-[10px] font-bold text-gray-500 uppercase tracking-tighter ml-1">
              Signal Engine
            </span>
            <div className="grid grid-cols-2 gap-1.5">
              {(["cpu", "dma"] as const).map((value) => (
                <button
                  key={value}
                  onClick={() => handle_set_engine(value)}
                  className={`py-1 rounded font-bold text-[10px] uppercase border transition-all ${
                    value === engine
                      ? "bg-blue-600 text-white border-blue-600 shadow-sm"
                      : "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
                  }`}
                >
                  {value}
                </button>
              ))}
            </div>
          </div>
        </section>

        {/* System Toggles */}
        <section className="flex flex-col gap-2">
          <SectionTitle>System</SectionTitle>
          <div className="flex flex-wrap gap-2">
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
              onClick={() => ble_send_command("led.on")}
              className="px-3 py-1.5 rounded-md font-bold text-[10px] border transition-colors uppercase text-blue-800 bg-blue-100 border-blue-300 hover:bg-blue-200 shadow-sm"
            >
              LED On
            </button>
            <button
              onClick={() => ble_send_command("led.off")}
              className="px-3 py-1.5 rounded-md font-bold text-[10px] border transition-colors uppercase text-gray-800 bg-gray-200 border-gray-300 hover:bg-gray-300 shadow-sm"
            >
              LED Off
            </button>
            <button
              onClick={() => ble_send_command("led.blink")}
              className="px-3 py-1.5 rounded-md font-bold text-[10px] border transition-colors uppercase text-amber-800 bg-amber-100 border-amber-300 hover:bg-amber-200 shadow-sm"
            >
              LED Blink
            </button>
          </div>
        </section>

        {/* Diagnostic Data */}
        <section className="flex flex-col gap-2">
          <SectionTitle>Diagnostic &amp; Dataset</SectionTitle>
          <div className="text-[11px] text-gray-600 font-semibold px-1">
            Control vector: <span className="font-mono">[V_C1, V_C2, VR]</span>
          </div>
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
            <button
              onClick={() => ble_send_command("debug.dataset_active")}
              className="btn-secondary text-xs font-bold text-gray-800"
            >
              SIGNAL
            </button>
          </div>
        </section>
      </fieldset>
    </DashboardItem>
  );
};
