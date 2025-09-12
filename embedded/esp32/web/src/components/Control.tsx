import { useEffect, useState } from "react";
import {
    ble_is_connected,
    ble_connect_device,
    ble_disconnect_device,
    ble_send_command,
    ble_set_update_status,
    ble_set_fn_probe,
} from "./bluetooth";
import { _create_signal } from "../helper";
import { DataPoint } from "./Chart";

const initial_time = new Date();

interface IControlProps {
    alpha: string,
    set_alpha: CallableFunction,
    data: DataPoint[],
    set_data: React.Dispatch<React.SetStateAction<DataPoint[]>>,
    set_show_images: React.Dispatch<React.SetStateAction<boolean>>
    analog_scale: number,
    set_analog_scale: CallableFunction,
    filter_alpha: number,
    set_filter_alpha: CallableFunction,
}

function Control(props: IControlProps) {
    const [command_message, set_command_message] = useState("");
    const [copy_label, set_copy_label] = useState("copy");

    const [bin_is_expanded, set_bin_is_expanded] = useState(false);
    const [d4_bin, set_d4_bin] = useState("");
    const [d5_bin, set_d5_bin] = useState("");
    const [d6_bin, set_d6_bin] = useState("");

    const [is_connected, set_is_connected] = useState(false); // New state for connection status
    const [mode, set_mode] = useState("");
    const [status, set_status] = useState(".");
    const [time, set_time] = useState("");

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

    // Monitor connection state
    useEffect(() => {
        compute_alpha(props.alpha);
        ble_set_fn_probe(probe_values);

        // monitor if the BLE is connected
        const interval = setInterval(() => {
            const connected = ble_is_connected();
            set_is_connected(connected);
        }, 1000); // Check every second
        return () => clearInterval(interval);

    }, []);

    function update_status(message: string, _isError = false) {
        set_status(message);
    }

    ble_set_update_status(update_status);


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
        props.set_alpha(value_);

        compute_alpha(value_)
    }

    function update_bin_values(mode: string) {

        const mode_v = mode.split(',')

        const d4: string[] = []
        const d5: string[] = []
        const d6: string[] = []
        mode_v.forEach(el => {
            const value = parseInt(el.trim())
            const value_bin = value.toString(2).padStart(3, '0')
            d4.push(value_bin[2])
            d5.push(value_bin[1])
            d6.push(value_bin[0])
        })

        // set values to d4
        const d4_str = d4.join(', ')
        const d5_str = d5.join(', ')
        const d6_str = d6.join(', ')
        set_d4_bin(d4_str)
        set_d5_bin(d5_str)
        set_d6_bin(d6_str)
    }

    function compute_alpha(alpha: string) {
        const value = parseFloat(alpha);
        const res = _create_signal(value);
        set_time(res.time);
        set_mode(res.mode);
        
        update_bin_values(res.mode);
    }

    function handle_send_command() {
        ble_send_command(command_message);
    }

    function handle_connect() {
        ble_connect_device();
    }

    function handle_disconnect() {
        ble_disconnect_device();
    }

    function handleStart() {
        ble_send_command("START");
    }

    function handle_stop() {
        ble_send_command("STOP");
    }

    function handle_high() {
        ble_send_command("HIGH");
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

    function handle_set_time(e: React.ChangeEvent<HTMLInputElement>) {
        set_time(e.target.value);
    }

    function handle_set_mode(e: React.ChangeEvent<HTMLInputElement>) {
        set_mode(e.target.value);
    }

    function handle_send_signal() {
        const signal = `SIGNAL:${time};${mode}`;
        ble_send_command(signal);
    }

    const mode_bin_values =
        bin_is_expanded
            ? <div className="px-2 text-left">
                <button onClick={() => set_bin_is_expanded(val => !val)} className="btn info my-1">&lt;&lt;</button>
                <div className="flex flex-col gap-2">
                    <div className="flex gap-2">
                        <label className="flex p-2 w-12">D4:</label>
                        <div className="input p-2 w-8/12">
                            {d4_bin}
                        </div>
                    </div>
                    <div className="flex gap-2">
                        <label className="flex p-2 w-12">D5:</label>
                        <div className="input p-2 w-8/12">
                            {d5_bin}
                        </div>
                    </div>
                    <div className="flex gap-2">
                        <label className="flex p-2 w-12">D6:</label>
                        <div className="input p-2 w-8/12">
                            {d6_bin}
                        </div>
                    </div>
                </div>
            </div>
            : <div className="px-2 text-left">
                <button onClick={() => set_bin_is_expanded(val => !val)} className="btn info">&gt;&gt;</button>
            </div>


    return <>
        <div className="w-[600px]">
            <h1 className="title text-4xl font-bold justify-center items-center text-center">
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
                            className="btn success"
                            disabled={is_connected} // Disable when connected
                        >
                            Connect to ESP32
                        </button>
                    )}
                <button onClick={()=>ble_send_command("STATUS")} className="btn">status</button>
                <button onClick={handle_copy} className="btn">{copy_label}</button>
                <button onClick={handle_clear_data} className="btn">clear data</button>
                <button className="text-4xl cursor-pointer" onClick={() => props.set_show_images(true)}>🖼️</button>
            </div>

            <div id="controlPanel" className="flex flex-col gap-2 p-2 rounded-xl">
                <div className="bg-panel p-4 rounded-md">

                    <div className="bg-info w-full h-[2px] my-5"></div>
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
                            className="flex-none ml-2 btn send"
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
                            value={props.alpha}
                            onChange={handle_set_alpha}
                        />
                        <span className="flex-1 h-10"></span>
                    </div>


                <div className="flex gap-2">
                    <label className="flex item-center justify-content mr-4 relative top-2 w-12">
                        time:
                    </label>
                    <input
                        type="text"
                        id="in-time"
                        className="input p-2 w-8/12"
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
                        className="input p-2 w-8/12"
                        placeholder="Enter modes"
                        value={mode}
                        onChange={handle_set_mode}
                    />


                    <button id="btn-signal-send" onClick={handle_send_signal} className="btn send flex-grow">
                        SEND
                    </button>

                </div>
                {mode_bin_values}

                <div className="bg-info w-full h-[2px] my-5"></div>
                    <div className="flex gap-2 justify-center">
                        <button id="btn-start" onClick={handleStart} className="btn">
                            START SIGNAL
                        </button>
                        <button id="btn-stop" onClick={handle_stop} className="btn">
                            LOW
                        </button>
                        <button id="btn-high" onClick={handle_high} className="btn">
                            HIGH
                        </button>
                    </div>
                </div> {/* close panel */}

                <div id="status" className="p-2 rounded-md bg-panel font-bold" >
                    {status} {is_connected ? "(Connected)" : "(Disconnected)"}
                </div>
            </div>

            <div id="analog-an4" className="hidden"></div>
            <div id="analog-an5" className="hidden"></div>
            <div id="analog-an6" className="hidden"></div>
        </div>
    </>
}

export default Control;