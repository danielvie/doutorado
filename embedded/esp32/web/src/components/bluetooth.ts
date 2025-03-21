const SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

let bluetoothDevice: any = null;
let gattServer = null;
let characteristic: any = null;

let _updateStatus: any = null

let is_listening = false;
let listen_interval:any;


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

export function bt_is_connected() {
    return (bluetoothDevice)
}

export function toggleListening(probe: CallableFunction):boolean {
    is_listening = !is_listening
    if (is_listening) {
        // btn_receive.textContent = "Stop Listening"
        listen_messages(probe)
    } else {
        // btn_receive.textContent = "Start Listening"
        clearInterval(listen_interval) // stop listenning
    }
    return is_listening
}

export async function listen_messages(probe: CallableFunction) {
    const regex = /an2:([\d.]+), an3:([\d.]+), an4:([\d.]+), an5:([\d.]+), an6:([\d.]+)/;
    listen_interval = setInterval(async () => {
        if (characteristic) {
            try {
                const value = await characteristic.readValue()
                const decoder = new TextDecoder()
                const message = decoder.decode(value)

                // updateStatus(`Received message: ${message}`)
                const match = message.match(regex);
                
                if (match) {
                    const an2 = match[1];
                    const an3 = match[2];
                    const an4 = match[3];
                    const an5 = match[4];
                    const an6 = match[5];
                    
                    const results = {
                        an2,
                        an3,
                        an4,
                        an5,
                        an6,
                    }
                    probe(results)
                    
                    // div_an2.textContent = an2;
                    // div_an3.textContent = an3;
                    // div_an4.textContent = an4;
                    // div_an5.textContent = an5;
                    // div_an6.textContent = an6;
                    
                    // saving time series
                    // analog_values_an4.push(an4)
                    // analog_values_an5.push(an5)
                    // analog_values_an6.push(an6)
                    // div_analog_an4.innerText += ` ${an4},`
                    // div_analog_an5.innerText += ` ${an5},`
                    // div_analog_an6.innerText += ` ${an6},`
                    
                }

            } catch (err:any) {
                updateStatus(`Receive failed: ${err.message}`, true)
            }
        }
    }, 500);
}