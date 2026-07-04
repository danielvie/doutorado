import { useState } from "react";
import { createCyclesPayload, signalEdgeOverheadCommands } from "../../helper";
import { bleManager } from "../../services/BleManager";
import { useBleStore } from "../../store/bleStore";
import { Send } from "lucide-react";
import { DashboardItem } from "./DashboardItem";

const number_or_zero = (value: string) => Number.parseInt(value, 10) || 0;

interface ParameterFieldProps {
  label: string;
  value: number;
  min?: number;
  step?: number;
  sendTitle: string;
  onChange: (value: number) => void;
  onSend: () => void;
}

const ParameterField: React.FC<ParameterFieldProps> = ({
  label,
  value,
  min,
  step,
  sendTitle,
  onChange,
  onSend,
}) => (
  <div className="flex flex-col gap-1.5">
    <label className="text-xs text-gray-700 font-bold uppercase ml-1">
      {label}
    </label>
    <div className="flex gap-1 p-1">
      <input
        type="number"
        min={min}
        step={step}
        onChange={(e) => onChange(number_or_zero(e.target.value))}
        value={value}
        className="flex-1 min-w-0 text-sm font-semibold text-gray-800 bg-white border border-gray-300 hover:border-gray-400 focus:border-blue-500 focus:ring-0 outline-none px-2 h-8 shadow-none transition-none rounded"
      />
      <button
        onClick={onSend}
        className="w-8 h-8 flex items-center justify-center bg-indigo-50 text-indigo-600 rounded border border-indigo-100 hover:bg-indigo-100 transition-colors shrink-0"
        title={sendTitle}
      >
        <Send size={12} />
      </button>
    </div>
  </div>
);

export const Parameters: React.FC = () => {
  const [cycles, setCycles] = useState(100);
  const [deadTimeDownTenthsUs, setDeadTimeDownTenthsUs] = useState(20);
  const [edge_overhead_up_cycles, set_edge_overhead_up_cycles] = useState(0);
  const [edge_overhead_down_cycles, set_edge_overhead_down_cycles] =
    useState(24);
  const monitor_period_ms = useBleStore((s) => s.monitorPeriodMs);
  const set_monitor_period_ms = useBleStore((s) => s.setMonitorPeriodMs);

  return (
    <DashboardItem title="Parameters" expandable={false}>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 pr-2">
        <ParameterField
          label="Cycles"
          value={cycles}
          sendTitle="Send Cycles"
          onChange={setCycles}
          onSend={() =>
            bleManager.sendCommand("signal.set_cycle_interval", { cycles })
          }
        />
        <ParameterField
          label="Monitor (ms)"
          value={monitor_period_ms}
          step={10}
          sendTitle="Send Monitor"
          onChange={set_monitor_period_ms}
          onSend={() =>
            bleManager.sendCommand("analog.set_monitor_period", {
              period_ms: monitor_period_ms,
            })
          }
        />
        <ParameterField
          label="Dead Down (0.1 us)"
          value={deadTimeDownTenthsUs}
          min={0}
          sendTitle="Send Falling-Boundary Dead Time"
          onChange={setDeadTimeDownTenthsUs}
          onSend={() =>
            bleManager.sendCommand("signal.set_dead_time_down", {
              time_tenths_us: deadTimeDownTenthsUs,
            })
          }
        />
        <ParameterField
          label="Edge Up Cycles"
          value={edge_overhead_up_cycles}
          min={0}
          sendTitle="Send Rising Edge Overhead"
          onChange={set_edge_overhead_up_cycles}
          onSend={() =>
            bleManager.sendCommand(
              signalEdgeOverheadCommands.up,
              createCyclesPayload(edge_overhead_up_cycles),
            )
          }
        />
        <ParameterField
          label="Edge Down Cycles"
          value={edge_overhead_down_cycles}
          min={0}
          sendTitle="Send Falling Edge Overhead"
          onChange={set_edge_overhead_down_cycles}
          onSend={() =>
            bleManager.sendCommand(
              signalEdgeOverheadCommands.down,
              createCyclesPayload(edge_overhead_down_cycles),
            )
          }
        />
      </div>
    </DashboardItem>
  );
};
