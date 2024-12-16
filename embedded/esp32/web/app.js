const SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

let bluetoothDevice = null;
let gattServer = null;
let characteristic = null;

const connectBtn = document.getElementById('connectBtn');
const disconnectBtn = document.getElementById('disconnectBtn');
const controlPanel = document.getElementById('controlPanel');
const sendBtn = document.getElementById('sendBtn');
const commandInput = document.getElementById('commandInput');
const statusDiv = document.getElementById('status');


const in_time = document.getElementById('in-time')
const in_mode = document.getElementById('in-mode')
const in_mul = document.getElementById('in-mul')

const btn_start = document.getElementById('btn-start')
const btn_stop = document.getElementById('btn-stop')
const btn_high = document.getElementById('btn-high')
const btn_signal_1 = document.getElementById('btn-signal-1')
const btn_signal_2 = document.getElementById('btn-signal-2')
const btn_signal_send = document.getElementById('btn-signal-send')

const btn_div10 = document.getElementById('btn-div10')
const btn_mul10 = document.getElementById('btn-mul10')
const btn_signal_calc = document.getElementById('btn-signal-calc')

function updateStatus(message, isError = false) {
    statusDiv.textContent = message;
    statusDiv.style.color = isError ? '#ff5252' : '#03dac6';
    console.log(isError ? 'ERROR: ' + message : message);
}

async function connectDevice() {
    try {
        // Request device
        bluetoothDevice = await navigator.bluetooth.requestDevice({
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
        // controlPanel.style.display = 'block';
        // connectBtn.style.display = 'none';
        // disconnectBtn.style.display = 'block';
    } catch (error) {
        updateStatus(`Connection failed: ${error.message}`, true);
        resetConnection();
    }
}

async function sendCommand() {
    if (!characteristic) {
        updateStatus('Not connected', true);
        return;
    }

    const command = commandInput.value.trim().toUpperCase();
    if (!command) {
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
        const data = encoder.encode(command);

        await characteristic.writeValue(data);
        updateStatus(`Sent command: ${command}`);
        // commandInput.value = ''; // Clear input
    } catch (error) {
        updateStatus(`Send failed: ${error.message}`, true);
        resetConnection();
    }
}

function handleDisconnect() {
    updateStatus('Disconnected from ESP32', true);
    resetConnection();
}

function resetConnection() {
    bluetoothDevice = null;
    gattServer = null;
    characteristic = null;

    // controlPanel.style.display = 'none';
    // connectBtn.style.display = 'block';
    // disconnectBtn.style.display = 'none';
}

async function disconnectDevice() {
    if (bluetoothDevice && bluetoothDevice.gatt.connected) {
        await bluetoothDevice.gatt.disconnect();
    }
    resetConnection();
    updateStatus('Manually disconnected');
}

// Event Listeners
connectBtn.addEventListener('click', connectDevice);
sendBtn.addEventListener('click', sendCommand);
disconnectBtn.addEventListener('click', disconnectDevice);

async function _send_command(command) {
    try {
        // Ensure connection is active
        if (!bluetoothDevice || !bluetoothDevice.gatt.connected) {
            await connectDevice();
        }

        // Convert string to Uint8Array
        const encoder = new TextEncoder();
        const data = encoder.encode(command);

        await characteristic.writeValue(data);
        updateStatus(`Sent "${command}"`);
    } catch (error) {
        updateStatus(`Send failed: ${error.message}`, true);
        resetConnection();
    }
}

btn_start.addEventListener('click', async () => {
    _send_command("START")
})

btn_stop.addEventListener('click', async () => {
    _send_command("STOP")
})

btn_high.addEventListener('click', async () => {
    _send_command("HIGH")
})


function _set_signal_command(time_, mode_) {
    let time = document.getElementById('in-time')
    let mode = document.getElementById('in-mode')
    
    time.value = time_
    mode.value = mode_
}

function _get_signal_command() {
    let time = document.getElementById('in-time').value
    let mode = document.getElementById('in-mode').value
    
    time = time.replace(/\s/g, '')
    mode = mode.replace(/\s/g, '')
    
    return `SIGNAL:${time};${mode}`
}


btn_signal_1.addEventListener('click', () => {
    time = "50, 25, 50, 25, 50, 25"
    mode = "5, 3, 4, 2, 5, 2"
    _set_signal_command(time, mode)
})

btn_signal_2.addEventListener('click', () => {
    time = "50, 50, 50, 50, 50, 50"
    mode = "7, 0, 7, 0, 7, 0"
    _set_signal_command(time, mode)
})

btn_signal_send.addEventListener('click', async() => {
    let msg = _get_signal_command()

    _send_command(msg)
})

function _multiply_time(value) {
    // get time values
    let time  = in_time.value
    let res = time.split(',').map((e) => parseFloat(e*value))

    // write values back
    let res_str = res.map(Math.round).join(', ')
    in_time.value = res_str
}

btn_signal_calc.addEventListener('click', () => {
    // compute values
    let mul   = parseFloat(in_mul.value)
    _multiply_time(mul)
    
    in_mul.value = '1.0'
    console.log('new time signal:', in_time.value)
})

btn_div10.addEventListener('click', () => {
    _multiply_time(0.1)
})

btn_mul10.addEventListener('click', () => {
    _multiply_time(10.0)
})

btn_signal_1.click()