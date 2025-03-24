const SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

let bluetoothDevice: any = null;
let gattServer = null;
let characteristic: any = null;

let _updateStatus: any = null;
let is_listening = false;

export async function connect_device() {
    try {
        let navigatorObject: any = window.navigator;
        bluetoothDevice = await navigatorObject.bluetooth.requestDevice({
            filters: [{ services: [SERVICE_UUID] }],
        });

        bluetoothDevice.addEventListener('gattserverdisconnected', handle_disconnect);
        gattServer = await bluetoothDevice.gatt.connect();
        const service = await gattServer.getPrimaryService(SERVICE_UUID);
        characteristic = await service.getCharacteristic(CHARACTERISTIC_UUID);

        update_status('Connected to ESP32');
    } catch (error: any) {
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
    is_listening = false; // Reset listening state on disconnect
}

export function set_update_status(_callable: CallableFunction) {
    _updateStatus = _callable;
}

function update_status(message: string, _isError: boolean = false) {
    if (_updateStatus) _updateStatus(message, _isError);
}

function is_disconnected() {
    return !bluetoothDevice || !bluetoothDevice.gatt.connected || !characteristic;
}

export async function send_command(command: string) {
    if (is_disconnected()) {
        update_status('Not connected, attempting to reconnect...', true);
        await connect_device();
        if (is_disconnected()) {
            update_status(`Failed to reconnect, cannot send command: '${command}'`, true);
            return;
        }
    }

    const comm = command.trim().toUpperCase();
    if (!comm) {
        update_status('Please enter a command', true);
        return;
    }

    try {
        const encoder = new TextEncoder();
        const data = encoder.encode(comm);
        await characteristic.writeValue(data);
        update_status(`Sent command: ${comm}`);
    } catch (error: any) {
        update_status(`Send failed: ${error.message}`, true);
        reset_connection();
    }
}

export function bt_is_connected() {
    return bluetoothDevice && bluetoothDevice.gatt.connected;
}

export function toggle_listening(probe: CallableFunction): boolean {
    if (is_disconnected()) {
        update_status('Cannot toggle listening: not connected', true);
        return false;
    }

    is_listening = !is_listening;
    if (is_listening) {
        start_notifications(probe);
    } else {
        stop_notifications();
    }
    return is_listening;
}

async function start_notifications(probe: CallableFunction) {
    if (!characteristic) {
        update_status('No characteristic available', true);
        return;
    }

    try {
        // Start notifications and add event listener
        await characteristic.startNotifications();
        characteristic.addEventListener('characteristicvaluechanged', (event: any) => {
            const value = event.target.value;
            const decoder = new TextDecoder();
            const message = decoder.decode(value);

            const regex = /(\w+):([\d.]+)/g;
            const parsed_data: Record<string, string> = {};
            let match;
            let has_match = false;

            while ((match = regex.exec(message)) !== null) {
                has_match = true;
                const key = match[1];
                const value = match[2];
                parsed_data[key] = value;
            }

            if (has_match) {
                const results = {
                    an3: parsed_data["an3"] || "0",
                    an5: parsed_data["an5"] || "0",
                    an6: parsed_data["an6"] || "0",
                };
                probe(results); // Call the probe callback with new data
            }
        });
        update_status('Started listening for notifications');
    } catch (err: any) {
        update_status(`Failed to start notifications: ${err.message}`, true);
        is_listening = false;
    }
}

async function stop_notifications() {
    if (!characteristic) return;

    try {
        await characteristic.stopNotifications();
        // Note: Event listener remains attached; it will be re-triggered if notifications restart
        update_status('Stopped listening for notifications');
    } catch (err: any) {
        update_status(`Failed to stop notifications: ${err.message}`, true);
    }
}