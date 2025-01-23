const SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

let bluetoothDevice: any = null;
let gattServer = null;
let characteristic: any = null;

let _updateStatus: any = null


export async function connectDevice() {
    try {
        // Request device
        let navigatorObject: any = window.navigator
        bluetoothDevice = await navigatorObject.bluetooth.requestDevice({
            filters: [{ services: [SERVICE_UUID] }]
        });

        // Add disconnect event listener
        bluetoothDevice.addEventListener('gattserverdisconnected', handleDisconnect);

        // Connect to GATT server
        gattServer = await bluetoothDevice.gatt.connect();

        // Get service and characteristic
        const service = await gattServer.getPrimaryService(SERVICE_UUID);
        characteristic = await service.getCharacteristic(CHARACTERISTIC_UUID);

        updateStatus('Connected to ESP32');
    } catch (error:any) {
        updateStatus(`Connection failed: ${error.message}`, true);
        resetConnection();
    }
}

export async function disconnectDevice() {
    if (bluetoothDevice && bluetoothDevice.gatt.connected) {
        await bluetoothDevice.gatt.disconnect();
    }
    resetConnection();
    updateStatus('Manually disconnected');
}

function handleDisconnect() {
    updateStatus('Disconnected from ESP32', true);
    resetConnection();
}

function resetConnection() {
    bluetoothDevice = null;
    gattServer = null;
    characteristic = null;
}

// function updateStatus(message, isError = false) {
export function setUpdateStatus(_callable: CallableFunction) {
    _updateStatus = _callable
}

function updateStatus(message:string, isError: boolean = false) {
    _updateStatus(message)
}

export async function sendCommand(command: string) {
    if (!characteristic) {
        updateStatus('Not connected', true);
        return;
    }

    const comm = command.trim().toUpperCase();
    if (!comm) {
        updateStatus('Please enter a command', true);
        return;
    }

    try {
        // Ensure connection is active
        if (!bluetoothDevice || !bluetoothDevice.gatt.connected) {
            await connectDevice();
        }

        // Convert string to Uint8Array
        const encoder = new TextEncoder();
        const data = encoder.encode(comm);

        await characteristic.writeValue(data);
        updateStatus(`Sent command: ${comm}`);
        // commandInput.value = ''; // Clear input
    } catch (error: any) {
        updateStatus(`Send failed: ${error.message}`, true);
        resetConnection();
    }
}