import { useState } from "react";
import {
    ble_send_command,
} from "./bluetooth";
import { _create_signal } from "../helper";

interface IProps {
    alpha: string,
}

enum EMATRIX {
    A,
    B,
}

function Listenner(props: IProps) {

    const [chunk, set_chunk] = useState('1')

    function handle_status_matrix(matrix: EMATRIX) {
        if (matrix == EMATRIX.A) {
            ble_send_command("STATUS_MATRIX_A")
        } 
        if (matrix == EMATRIX.B) {
            ble_send_command("STATUS_MATRIX_B")
        } 
    }

    function handle_set_chunk(e: React.ChangeEvent<HTMLInputElement>) {
        const value = e.target.value
        
        set_chunk(value)
    }
    
    function handle_log_last(chunk: number) {
        ble_send_command(`LOG_LAST_CALC:${chunk}`)
    }

    return <>
        <div className="flex flex-col gap-2">
            <div className="flex items-center gap-2">
                <span>chunk:</span>
                <input type="number" className="h-10 w-14 p-2" onChange={handle_set_chunk} value={chunk} />
            </div>

            <div className="flex gap-2 mt-2">
                <button onClick={() => ble_send_command("STATUS")} className="btn">STATUS</button>
                <button onClick={() => handle_status_matrix(EMATRIX.A)} className="btn">MATRIX A</button>
                <button onClick={() => handle_status_matrix(EMATRIX.B)} className="btn">MATRIX B</button>
                <button onClick={() => ble_send_command("LOG_KOKA")} className="btn">KOKA</button>
                <button onClick={() => ble_send_command("STATUS_DURATION")} className="btn">DURATION</button>

            </div>
            <div className="flex gap-2">
                <button onClick={() => handle_log_last(1)} className="btn">LAST CALC</button>
                <button onClick={() => ble_send_command("LOG_LAST_CALC_ON")} className="btn">LAST CALC ON</button>
                <button onClick={() => ble_send_command("LOG_LAST_CALC_OFF")} className="btn">LAST CALC OFF</button>
            </div>
            <div className="flex gap-2">
                <button onClick={() => ble_send_command("CONTROL_ON")} className="btn">CONTROL ON</button>
                <button onClick={() => ble_send_command("CONTROL_OFF")} className="btn">CONTROL OFF</button>
            </div>
            <div className="flex gap-2">
                <button onClick={() => ble_send_command(`SET_ALPHA:${props.alpha}`)} className="btn">SET ALPHA ({props.alpha})</button>
            </div>
        </div>
    </>
}

export default Listenner;

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