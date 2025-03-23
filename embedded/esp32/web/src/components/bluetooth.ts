const SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

let bluetoothDevice: any = null;
let gattServer = null;
let characteristic: any = null;

let _updateStatus: any = null

let is_listening = false;
let listen_interval:any;


export async function connect_device() {
    try {
        // Request device
        let navigatorObject: any = window.navigator
        bluetoothDevice = await navigatorObject.bluetooth.requestDevice({
            filters: [{ services: [SERVICE_UUID] }]
        });

        // Add disconnect event listener
        bluetoothDevice.addEventListener('gattserverdisconnected', handle_disconnect);

        // Connect to GATT server
        gattServer = await bluetoothDevice.gatt.connect();

        // Get service and characteristic
        const service = await gattServer.getPrimaryService(SERVICE_UUID);
        characteristic = await service.getCharacteristic(CHARACTERISTIC_UUID);

        update_status('Connected to ESP32');
    } catch (error:any) {
        update_status(`Connection failed: ${error.message}`, true);
        reset_connection();
    }
}

export async function disconnect_device() {
    if (bluetoothDevice && bluetoothDevice.gatt.connected) {
        await bluetoothDevice.gatt.disconnect();
    }
    reset_connection();
    update_status('Manually disconnected');
}

function handle_disconnect() {
    update_status('Disconnected from ESP32', true);
    reset_connection();
}

function reset_connection() {
    bluetoothDevice = null;
    gattServer = null;
    characteristic = null;
}

// function updateStatus(message, isError = false) {
export function set_update_status(_callable: CallableFunction) {
    _updateStatus = _callable
}

function update_status(message:string, _isError: boolean = false) {
    _updateStatus(message)
}

function is_disconnected() {
    return !characteristic;
}

export async function send_command(command: string) {
    if (is_disconnected()) {
        // update_status(`Not connected\ncommand: '${command}'`, true);
        // console.log(`"${command}"`);
        // return;
        await connect_device();
    }

    const comm = command.trim().toUpperCase();
    if (!comm) {
        update_status('Please enter a command', true);
        return;
    }

    try {
        // Ensure connection is active
        if (!bluetoothDevice || !bluetoothDevice.gatt.connected) {
            await connect_device();
        }

        // Convert string to Uint8Array
        const encoder = new TextEncoder();
        const data = encoder.encode(comm);

        await characteristic.writeValue(data);
        update_status(`Sent command: ${comm}`);
        // commandInput.value = ''; // Clear input
    } catch (error: any) {
        update_status(`Send failed: ${error.message}`, true);
        reset_connection();
    }
}

export function bt_is_connected() {
    return (bluetoothDevice)
}

export function toggle_listening(probe: CallableFunction):boolean {
    is_listening = !is_listening
    if (is_listening) {
        listen_messages(probe)
    } else {
        clearInterval(listen_interval) // stop listenning
    }
    return is_listening
}

export async function listen_messages(probe: CallableFunction) {
    const regex = /(\w+):([\d.]+)/g;
    const parsed_data: Record<string, number> = {};
    let match;

    listen_interval = setInterval(async () => {
        if (characteristic) {
            try {
                const value = await characteristic.readValue()
                const decoder = new TextDecoder()
                const message = decoder.decode(value)

                // updateStatus(`Received message: ${message}`)
                let has_match = false;
                while ((match = regex.exec(message)) !== null) {
                    if (match) {
                        has_match = true
                    }
                    const key = match[1];
                    const value = parseFloat(match[2]);
                    parsed_data[key] = value;
                }
                
                if (has_match) {
                    const an3 = parsed_data["an3"];
                    const an5 = parsed_data["an5"];
                    const an6 = parsed_data["an6"];
                    
                    const results = {
                        an3,
                        an5,
                        an6,
                    }
                    probe(results)
                }

            } catch (err:any) {
                update_status(`Receive failed: ${err.message}`, true)
            }
        }
    }, 500);
}