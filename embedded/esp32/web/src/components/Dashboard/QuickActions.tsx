import { useState } from "react";
import { bleManager } from "../../services/BleManager";
import { useBleStore } from "../../store/bleStore";
import { Zap } from "lucide-react";
import StatusBox from "./StatusBox";

enum EMATRIX {
  A = "A",
  B = "B",
}

export const QuickActions = () => {
  const { alpha, setAlpha } = useBleStore();
  const [chunk, setChunk] = useState(10);
  const [cycles, setCycles] = useState(100);
  const [monitor_period_ms, setMonitorPeriodMs] = useState(100);

  const handle_set_chunk = (e: React.ChangeEvent<HTMLInputElement>) =>
    setChunk(parseInt(e.target.value));
  const handle_set_cycles = (e: React.ChangeEvent<HTMLInputElement>) =>
    setCycles(parseInt(e.target.value));
  const handle_set_monitor_period_ms = (
    e: React.ChangeEvent<HTMLInputElement>,
  ) => setMonitorPeriodMs(parseInt(e.target.value));

  const ble_send_command = (cmd: string) => bleManager.send(cmd);

  const handle_status_matrix = (matrix: EMATRIX) => {
    ble_send_command(`STATUS_MATRIX:${matrix}`);
  };

  const handle_log_last = (n: number) => {
    ble_send_command(`LOG_LAST:${n}`);
  };

  const handle_set_alpha = (a: string) => {
    setAlpha(a.toString());
    ble_send_command(`SET_ALPHA:${a}`);
  };

  const currentAlpha = parseFloat(alpha);
  const minAlpha = 0.1;
  const maxAlpha = 0.9;

  // Calculate next/prev values, clamping to min/max and formatting to avoid float errors
  const prevAlpha = Math.max(minAlpha, currentAlpha - 0.1).toFixed(1);
  const nextAlpha = Math.min(maxAlpha, currentAlpha + 0.1).toFixed(1);

  return (
    <div className="bg-gray-900 border border-gray-800 rounded-xl p-4 flex flex-col gap-4 shadow-lg">
      <div className="flex justify-between items-center border-b border-gray-800 pb-2">
        <div className="flex items-center gap-2">
          <Zap className="w-5 h-5 text-yellow-400" />
          <h2 className="font-bold text-lg text-gray-200">Quick Actions</h2>
        </div>
      </div>


      <StatusBox />
      <div className="flex flex-col gap-2 quickactions">
        {/* ... (inputs section remains same, I need to match context effectively) */}
        <div className="flex items-center gap-2 text-sm text-gray-400">
          <span>chunk:</span>
          <input
            type="number"
            className="h-8 w-16 p-2 bg-gray-950 border border-gray-700 rounded text-gray-200"
            onChange={handle_set_chunk}
            value={chunk}
          />

          <span>cycles:</span>
          <input
            type="number"
            className="h-8 w-16 p-2 bg-gray-950 border border-gray-700 rounded text-gray-200"
            onChange={handle_set_cycles}
            value={cycles}
          />

          <span>monitor (ms):</span>
          <input
            type="number"
            className="h-8 w-16 p-2 bg-gray-950 border border-gray-700 rounded text-gray-200"
            onChange={handle_set_monitor_period_ms}
            value={monitor_period_ms}
          />
        </div>

        <div className="flex gap-2 mt-2 flex-wrap">
          <button
            onClick={() => ble_send_command("START")}
            className="btn-action bg-green-600"
          >
            START
          </button>
          <button
            onClick={() => ble_send_command("STOP")}
            className="btn-action bg-red-600"
          >
            STOP
          </button>
          <button
            onClick={() => ble_send_command("ON")}
            className="btn-action bg-blue-600"
          >
            ON
          </button>
          <button
            onClick={() => ble_send_command("OFF")}
            className="btn-action bg-gray-600"
          >
            OFF
          </button>
          <button
            onClick={() => ble_send_command("BLINK")}
            className="btn-action bg-purple-600"
          >
            BLINK
          </button>
        </div>

        <div className="flex gap-2 flex-wrap">
          <button
            onClick={() => ble_send_command("STATUS")}
            className="btn-action bg-cyan-700"
          >
            STATUS
          </button>
          <button
            onClick={() => handle_status_matrix(EMATRIX.A)}
            className="btn-action bg-cyan-900"
          >
            MATRIX A
          </button>
          <button
            onClick={() => handle_status_matrix(EMATRIX.B)}
            className="btn-action bg-cyan-900"
          >
            MATRIX B
          </button>
        </div>

        <div className="flex gap-2 flex-wrap">
          <button
            onClick={() => ble_send_command("ACTIVE_DATASET")}
            className="btn-action bg-teal-700"
          >
            DATASET
          </button>

          <button
            onClick={() => ble_send_command("PRINT_DATASET_A")}
            className="btn-action bg-teal-700"
          >
            DATASET A
          </button>

          <button
            onClick={() => ble_send_command("PRINT_DATASET_B")}
            className="btn-action bg-teal-700"
          >
            DATASET B
          </button>
        </div>

        <div className="flex gap-2 flex-wrap">
          <button
            onClick={() => ble_send_command("LOG_KOKA")}
            className="btn-action bg-orange-700"
          >
            KOKA
          </button>
          <button
            onClick={() => ble_send_command("LOG_DURATION")}
            className="btn-action bg-orange-700"
          >
            DURATION
          </button>
        </div>

        <div className="flex gap-2 flex-wrap">
          <button
            onClick={() => handle_log_last(1)}
            className="btn-action bg-indigo-700"
          >
            LAST CALC
          </button>
          <button
            onClick={() => ble_send_command("LOG_LAST_CALC_ON")}
            className="btn-action bg-indigo-900"
          >
            LOG ON
          </button>
          <button
            onClick={() => ble_send_command("LOG_LAST_CALC_OFF")}
            className="btn-action bg-indigo-900"
          >
            LOG OFF
          </button>
        </div>

        <div className="flex gap-2 flex-wrap">
          <button
            onClick={() => ble_send_command("CONTROL_ON")}
            className="btn-action bg-emerald-700"
          >
            CONTROL ON
          </button>
          <button
            onClick={() => ble_send_command("CONTROL_OFF")}
            className="btn-action bg-emerald-900"
          >
            CONTROL OFF
          </button>
          <button
            onClick={() => ble_send_command("SET_PRINT_ON")}
            className="btn-action bg-slate-600"
          >
            PRINT ON
          </button>
          <button
            onClick={() => ble_send_command("SET_PRINT_OFF")}
            className="btn-action bg-slate-700"
          >
            PRINT OFF
          </button>
        </div>

        <div className="flex gap-2 flex-wrap">
          <button
            onClick={() => ble_send_command("BLE_READ_ON")}
            className="btn-action bg-violet-700"
          >
            BLE READ ON
          </button>
          <button
            onClick={() => ble_send_command("BLE_READ_OFF")}
            className="btn-action bg-violet-900"
          >
            BLE READ OFF
          </button>
        </div>

        <div className="flex gap-2 flex-wrap">
          <button
            onClick={() => ble_send_command(`CYCLES:${cycles}`)}
            className="btn-action bg-pink-700"
          >
            SET CYCLES ({cycles})
          </button>
          <button
            onClick={() =>
              ble_send_command(`AN_MONITOR_MS:${monitor_period_ms}`)
            }
            className="btn-action bg-pink-900"
          >
            AN MONITOR ({monitor_period_ms})
          </button>
        </div>

        <div className="flex gap-2 flex-wrap items-center mt-3">
          <span className="text-xs text-gray-500 font-bold uppercase mr-2">
            Alpha:
          </span>

          {/* Min Button */}
          <button
            onClick={() => handle_set_alpha(minAlpha.toString())}
            className="btn-alpha"
            title="Set to Minimum"
          >
            {minAlpha}
          </button>

          {/* Prev Button */}
          <button
            onClick={() => handle_set_alpha(prevAlpha)}
            className="btn-alpha"
            title="Decrease Alpha"
          >
            {prevAlpha}
          </button>

          {/* Current (Middle) Button */}
          <button
            onClick={() => handle_set_alpha(alpha)}
            className="btn-alpha btn-alpha-active ring-2 ring-purple-500 ring-offset-2 ring-offset-gray-900"
            title="Resend Current Alpha"
          >
            {alpha}
          </button>

          {/* Next Button */}
          <button
            onClick={() => handle_set_alpha(nextAlpha)}
            className="btn-alpha"
            title="Increase Alpha"
          >
            {nextAlpha}
          </button>

          {/* Max Button */}
          <button
            onClick={() => handle_set_alpha(maxAlpha.toString())}
            className="btn-alpha"
            title="Set to Maximum"
          >
            {maxAlpha}
          </button>
        </div>
      </div>
    </div>
  );
};
