import { useEffect, useState } from "react";
import {
    bt_is_connected,
    connect_device,
    disconnect_device,
    send_command,
    set_update_status,
    toggle_listening,
} from "./bluetooth";
import { _create_signal } from "../helper";
import { DataPoint } from "./Chart";

const initial_time = new Date();

interface IControlProps {
    data: DataPoint[],
    set_data: React.Dispatch<React.SetStateAction<DataPoint[]>>,
    set_show_images: React.Dispatch<React.SetStateAction<boolean>>
    analog_scale: number,
    set_analog_scale: CallableFunction,
    filter_alpha: number,
    set_filter_alpha: CallableFunction,
}

function Control(props: IControlProps) {
    const [alpha, set_alpha] = useState("0.5");
    const [command_message, set_command_message] = useState("");
    const [copy_label, set_copy_label] = useState("copy");
    const [cycle_nrun, set_cycle_nrun] = useState("100");
    const [is_connected, set_is_connected] = useState(false); // New state for connection status
    const [listen_label, set_listen_label] = useState("Start Listening");
    const [mode, set_mode] = useState("");
    const [mul_value, set_mul_value] = useState("1.0");
    const [status, set_status] = useState(".");
    const [time, set_time] = useState("");

    // Monitor connection state
    useEffect(() => {
        handle_compute_alpha();
        const interval = setInterval(() => {
            set_is_connected(bt_is_connected());
        }, 1000); // Check every second
        return () => clearInterval(interval);
    }, []);

    function update_status(message: string, _isError = false) {
        set_status(message);
    }

    set_update_status(update_status);


    function handle_copy() {
        let message: string = "";
        message += `time = [${props.data.map((v) => v.time).join(", ")}];\n`;
        message += `an3 = [${props.data.map((v) => v.an3).join(", ")}];\n`;
        message += `an5 = [${props.data.map((v) => v.an5).join(", ")}];\n`;
        message += `an6 = [${props.data.map((v) => v.an6).join(", ")}];\n`;

        navigator.clipboard.writeText(message)
            .then(() => {
                set_copy_label("copied!");
                setTimeout(() => set_copy_label("copy"), 500);
            });
    }

    function handle_clear_data() {
        props.set_data([]);
    }
        
    function handle_set_command_message(e: React.ChangeEvent<HTMLInputElement>) {
        set_command_message(e.target.value);
    }

    function handle_set_alpha(e: React.ChangeEvent<HTMLInputElement>) {
        const value_ = e.target.value;
        set_alpha(value_);

        const value = parseFloat(value_);
        const res = _create_signal(value);
        set_time(res.time);
        set_mode(res.mode);
    }

    function handle_cycle_nrun(e: React.ChangeEvent<HTMLInputElement>) {
        const value_ = e.target.value;
        set_cycle_nrun(value_);
    }

    function handle_send_cycle_nrun() {
        const command = `CYCLE_NRUN:${cycle_nrun}`;
        send_command(command);
    }

    function handle_compute_alpha() {
        const value = parseFloat(alpha);
        const res = _create_signal(value);
        set_time(res.time);
        set_mode(res.mode);
    }

    function handle_send_command() {
        send_command(command_message);
    }

    function handle_connect() {
        connect_device();
    }

    function handle_disconnect() {
        disconnect_device();
    }

    function handleStart() {
        send_command("START");
    }

    function handle_stop() {
        send_command("STOP");
    }

    function handle_high() {
        send_command("HIGH");
    }

    function probe_values(values: { an3: string; an5: string; an6: string }) {
        const now = new Date();
        const timeStr = (now.getTime() - initial_time.getTime()).toString();

        props.set_data((currentData) => {
            const newData = [...currentData, {
                time: timeStr,
                an6: parseFloat(values.an6), // * 10.0 / 6.0,
                an5: parseFloat(values.an5), // * 10.0 / 6.0,
                an3: parseFloat(values.an3), // * 10.0 / 6.0,
            }];
            return newData;
        });
    }

    async function handle_listen() {
        if (!is_connected) {
            await connect_device();
        }
        const is_listening = toggle_listening(probe_values);
        set_listen_label(is_listening ? "Stop Listening" : "Start Listening");
    }

    function calc_total_time(): string {
        
        let total = 0.0
        time.split(",").forEach(t => {
            const value = parseFloat(t)
            total += value
        })
        
        const T = total.toFixed(1)
        
        return `T: ${T} us`
    }

    function set_signal_1() {
        const _time = "50, 50, 50, 50, 50, 50";
        const _mode = "7, 0, 7, 0, 7, 0";
        set_time(_time);
        set_mode(_mode);
    }

    function set_signal_2() {
        const _time = "50, 50, 50, 50, 50, 50";
        const _mode = "7, 0, 7, 0, 7, 0";
        set_time(_time);
        set_mode(_mode);
    }

    function handle_set_time(e: React.ChangeEvent<HTMLInputElement>) {
        set_time(e.target.value);
    }

    function handle_set_mode(e: React.ChangeEvent<HTMLInputElement>) {
        set_mode(e.target.value);
    }

    function handle_send_signal() {
        const signal = `SIGNAL:${time};${mode}`;
        send_command(signal);
    }

    function handle_set_multiply(e: React.ChangeEvent<HTMLInputElement>) {
        set_mul_value(e.target.value);
    }

    function handle_set_analog_scale(e: React.ChangeEvent<HTMLInputElement>) {
        props.set_analog_scale(e.target.value);
    }

    function handle_set_filter(e: React.ChangeEvent<HTMLInputElement>) {
        props.set_filter_alpha(e.target.value);
    }

    function _multiply_time(value: number) {
        const res = time.split(",").map((e) => parseFloat(e) * value);
        const res_str = res.map(Math.round).join(", ");
        update_status(res_str);
        set_time(res_str);
    }


    return <>
        <div className="w-[600px]">
            <h1 className="text-purple-500 text-4xl font-bold justify-center items-center text-center">
                ESP32 Web Bluetooth Control
            </h1>

            {/* <Menu></Menu> */}

            <div className="flex gap-3 my-5 items-center justify-center">
                {is_connected
                    ? (
                        <button
                            id="disconnectBtn"
                            onClick={handle_disconnect}
                            className="btn danger"
                            disabled={!is_connected} // Disable when disconnected
                        >
                            Disconnect
                        </button>
                    )
                    : (
                        <button
                            id="connectBtn"
                            onClick={handle_connect}
                            className="btn green"
                            disabled={is_connected} // Disable when connected
                        >
                            Connect to ESP32
                        </button>
                    )}
                <button onClick={handle_listen} className="btn">
                    {listen_label}
                </button>
                <button onClick={handle_copy} className="btn">{copy_label}</button>
                <button onClick={handle_clear_data} className="btn">clear data</button>
               <button className="text-4xl" onClick={() => props.set_show_images(true)}>🖼️</button>
            </div>

            <div id="controlPanel" className="bg-panel p-5 rounded-xl">
                <div className="bg-purple-500 w-full h-[2px] mb-4"></div>

                <div className="flex justify-content">
                    <input
                        type="text"
                        id="commandInput"
                        value={command_message}
                        onChange={handle_set_command_message}
                        className="flex-1 bg-panel border-zinc-700 border-[1px] rounded-sm px-3 py-1"
                        placeholder="Enter command"
                    />
                    <button
                        id="sendBtn"
                        onClick={handle_send_command}
                        className="flex-none ml-2 btn"
                    >
                        SEND command
                    </button>
                </div>

                <div className="flex my-4 gap-2">
                    <label className="mr-4 relative top-2 w-12">alpha:</label>
                    <input
                        type="number"
                        step="0.1"
                        id="in-alpha"
                        className="bg-panel border flex-none w-16 px-2 text-center"
                        value={alpha}
                        onChange={handle_set_alpha}
                    />
                    <button
                        id="btn-alpha"
                        className="btn"
                        onClick={handle_compute_alpha}
                    >
                        CALC
                    </button>
                    <span className="flex-1"></span>

                    <label className="mr-4 relative top-2 w-16">cycle_nrun:</label>
                    <input
                        type="number"
                        id="in-alpha"
                        className="bg-panel border flex-none w-24 px-2 text-center"
                        value={cycle_nrun}
                        onChange={handle_cycle_nrun}
                    />
                    <button
                        id="btn-alpha"
                        className="btn"
                        onClick={handle_send_cycle_nrun}
                    >
                        SEND cycle
                    </button>
                </div>

                <div className="flex gap-2">
                    <label className="flex item-center justify-content mr-4 relative top-2 w-12">
                        time:
                    </label>
                    <input
                        type="text"
                        id="in-time"
                        className="input p-2 flex-grow"
                        placeholder="Enter time"
                        value={time}
                        onChange={handle_set_time}
                    />
                    <div className="flex items-center ml-2">
                        ( {calc_total_time()} )
                    </div>
                </div>

                <div className="flex my-4 gap-2">
                    <label
                        htmlFor=""
                        className="flex item-center justify-content mr-4 relative top-2 w-12"
                    >
                        modes:
                    </label>
                    <input
                        type="text"
                        id="in-mode"
                        className="input p-2 flex-grow"
                        placeholder="Enter modes"
                        value={mode}
                        onChange={handle_set_mode}
                    />
                </div>

                <div className="flex my-4 gap-2">
                    <label className="flex item-center justify-content mr-4 relative top-2 w-12">
                        X*time:
                    </label>
                    <input
                        type="text"
                        id="in-mul"
                        className="input p-2 w-16 text-center"
                        placeholder="X*time"
                        value={mul_value}
                        onChange={handle_set_multiply}
                    />
                    <button
                        id="btn-signal-calc"
                        onClick={() => _multiply_time(parseFloat(mul_value))}
                        className="btn"
                    >
                        mult
                    </button>

                    <label className="flex-grow item-center text-right relative top-2 w-20">
                        Scale:
                    </label>
                    <input
                        type="number"
                        id="in-scale"
                        className="input p-2 w-16 text-center"
                        placeholder="analog scale"
                        value={props.analog_scale}
                        onChange={handle_set_analog_scale}
                    />

                    <label className="flex-grow item-center text-right relative top-2 w-20">
                        filter:
                    </label>
                    <input
                        type="number"
                        id="in-scale"
                        className="input p-2 w-16 text-center"
                        placeholder="analog scale"
                        value={props.filter_alpha}
                        onChange={handle_set_filter}
                    />

                    <button id="btn-signal-send" onClick={handle_send_signal} className="btn">
                        SEND
                    </button>
                </div>

                <div className="bg-purple-500 w-full h-[2px] my-5"></div>

                <div className="flex gap-4 justify-center">
                    <button id="btn-signal-1" onClick={set_signal_1} className="btn">
                        SIGNAL 1
                    </button>
                    <button id="btn-signal-2" onClick={set_signal_2} className="btn">
                        SIGNAL 2
                    </button>
                    <button id="btn-start" onClick={handleStart} className="btn">
                        START
                    </button>
                    <button id="btn-stop" onClick={handle_stop} className="btn">
                        LOW
                    </button>
                    <button id="btn-high" onClick={handle_high} className="btn">
                        HIGH
                    </button>
                </div>
            </div>

            <div
                id="status"
                className="w-min-[300px] m-2 p-3 rounded-lg bg-panel font-bold"
            >
                {status} {is_connected ? "(Connected)" : "(Disconnected)"}
            </div>

            <div id="analog-an4" className="hidden"></div>
            <div id="analog-an5" className="hidden"></div>
            <div id="analog-an6" className="hidden"></div>
        </div>
    </>
}

export default Control;