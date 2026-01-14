// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.

import { useState } from "react";
import { ble_send_command } from "./bluetooth";
import { _create_signal } from "../helper";

interface IProps {
  alpha: string;
  set_alpha: CallableFunction;
  status_msg: string;
  set_status_msg: CallableFunction;
}

enum EMATRIX {
  A,
  B,
}

function MenuAdvancedButtons(props: IProps) {
  const [chunk, set_chunk] = useState("1");
  const [cycles, set_cycles] = useState("10000");
  const [monitor_period_ms, set_monitor_period_ms] = useState("500");

  function handle_status_matrix(matrix: EMATRIX) {
    if (matrix == EMATRIX.A) {
      ble_send_command("STATUS_MATRIX_A");
    }
    if (matrix == EMATRIX.B) {
      ble_send_command("STATUS_MATRIX_B");
    }
  }

  function handle_set_chunk(e: React.ChangeEvent<HTMLInputElement>) {
    const value = e.target.value;

    set_chunk(value);
  }

  function handle_set_cycles(e: React.ChangeEvent<HTMLInputElement>) {
    const value = e.target.value;

    set_cycles(value);
  }

  function handle_set_monitor_period_ms(
    e: React.ChangeEvent<HTMLInputElement>,
  ) {
    const value = e.target.value;

    set_monitor_period_ms(value);
  }

  function handle_log_last(chunk: number) {
    ble_send_command(`LOG_LAST_CALC:${chunk}`);
  }

  function handle_set_alpha(new_alpha: string) {
    props.set_alpha(new_alpha);
    ble_send_command(`SET_ALPHA:${new_alpha}`);
  }

  const alpha_min = "0.1";
  const alpha_less2 = Math.max(0.1, parseFloat(props.alpha) - 0.1).toFixed(2);
  const alpha_less = Math.max(0.1, parseFloat(props.alpha) - 0.01).toFixed(2);
  const alpha_more = Math.min(0.9, parseFloat(props.alpha) + 0.01).toFixed(2);
  const alpha_more2 = Math.min(0.9, parseFloat(props.alpha) + 0.1).toFixed(2);
  const alpha_max = "0.9";

  return (
    <>
      <div className="flex flex-col gap-2">
        <div className="flex items-center gap-2">
          <span>chunk:</span>
          <input
            type="number"
            className="h-10 w-14 p-2"
            onChange={handle_set_chunk}
            value={chunk}
          />

          <span>cycle_nrun:</span>
          <input
            id="in-alpha"
            type="number"
            className="h-10 w-20 p-2"
            onChange={handle_set_cycles}
            value={cycles}
          />

          <span>monitor period (ms):</span>
          <input
            id="in-alpha"
            type="number"
            className="h-10 w-20 p-2"
            onChange={handle_set_monitor_period_ms}
            value={monitor_period_ms}
          />
        </div>

        <div className="flex gap-2 mt-2">
          <button onClick={() => ble_send_command("START")} className="btn">
            START
          </button>
          <button onClick={() => ble_send_command("STOP")} className="btn">
            STOP
          </button>
          <button onClick={() => ble_send_command("ON")} className="btn">
            ON
          </button>
          <button onClick={() => ble_send_command("OFF")} className="btn">
            OFF
          </button>
          <button onClick={() => ble_send_command("BLINK")} className="btn">
            BLINK
          </button>
        </div>
        <div className="flex gap-2">
          <button onClick={() => ble_send_command("STATUS")} className="btn">
            STATUS
          </button>
          <button
            onClick={() => handle_status_matrix(EMATRIX.A)}
            className="btn"
          >
            MATRIX A
          </button>
          <button
            onClick={() => handle_status_matrix(EMATRIX.B)}
            className="btn"
          >
            MATRIX B
          </button>
          <button
            onClick={() => ble_send_command("ACTIVE_DATASET")}
            className="btn"
          >
            DATASET
          </button>
        </div>
        <div className="flex gap-2">
          <button onClick={() => ble_send_command("LOG_KOKA")} className="btn">
            KOKA
          </button>
          <button
            onClick={() => ble_send_command("LOG_DURATION")}
            className="btn"
          >
            DURATION
          </button>
        </div>
        <div className="flex gap-2">
          <button onClick={() => handle_log_last(1)} className="btn">
            LAST CALC
          </button>
          <button
            onClick={() => ble_send_command("LOG_LAST_CALC_ON")}
            className="btn"
          >
            LAST CALC ON
          </button>
          <button
            onClick={() => ble_send_command("LOG_LAST_CALC_OFF")}
            className="btn"
          >
            LAST CALC OFF
          </button>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => ble_send_command("CONTROL_ON")}
            className="btn"
          >
            CONTROL ON
          </button>
          <button
            onClick={() => ble_send_command("CONTROL_OFF")}
            className="btn"
          >
            CONTROL OFF
          </button>
          <button
            onClick={() => ble_send_command("SET_PRINT_ON")}
            className="btn"
          >
            PRINT ON
          </button>
          <button
            onClick={() => ble_send_command("SET_PRINT_OFF")}
            className="btn"
          >
            PRINT OFF
          </button>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => ble_send_command("BLE_READ_ON")}
            className="btn"
          >
            BLE_READ_ON
          </button>
          <button
            onClick={() => ble_send_command("BLE_READ_OFF")}
            className="btn"
          >
            BLE_READ_OFF
          </button>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => ble_send_command(`CYCLES:${cycles}`)}
            className="btn"
          >
            SET CYCLES ({cycles})
          </button>
          <button
            onClick={() =>
              ble_send_command(`AN_MONITOR_MS:${monitor_period_ms}`)
            }
            className="btn"
          >
            AN MONITOR MS ({monitor_period_ms})
          </button>
        </div>

        <div className="flex gap-2">
          <button onClick={() => handle_set_alpha(alpha_min)} className="btn">
            {alpha_min}
          </button>
          <button onClick={() => handle_set_alpha(alpha_less2)} className="btn">
            {alpha_less2}
          </button>
          <button onClick={() => handle_set_alpha(alpha_less)} className="btn">
            {alpha_less}
          </button>
          <button
            onClick={() => ble_send_command(`SET_ALPHA:${props.alpha}`)}
            className="btn"
          >
            SET ALPHA ({props.alpha})
          </button>
          <button onClick={() => handle_set_alpha(alpha_more)} className="btn">
            {alpha_more}
          </button>
          <button onClick={() => handle_set_alpha(alpha_more2)} className="btn">
            {alpha_more2}
          </button>
          <button onClick={() => handle_set_alpha(alpha_max)} className="btn">
            {alpha_max}
          </button>
        </div>
      </div>
    </>
  );
}

export default MenuAdvancedButtons;

// "STATUS"
// "STATUS_MATRIX_A"
// "STATUS_MATRIX_B"
// "STATUS_DURATION"
// "LOG_KOKA"
// "TOGGLE_SET"
// "TOGGLE_SET_A"
// "TOGGLE_SET_B"
// "CONTROL_ON"
// "CONTROL_OFF"
// "LOG_LAST_CALC_ON"
// "LOG_LAST_CALC_OFF"
// "LOG_LAST_CALC:"
// "CYCLE_NRUN:"
// "SIGNAL:"
// "MESSAGE_DATA:"
// "MESSAGE_DATA:"
// "SET_ALPHA:"
