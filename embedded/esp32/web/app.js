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

const div_an2 = document.getElementById('div-an2');
const div_an3 = document.getElementById('div-an3');
const div_an4 = document.getElementById('div-an4');
const div_an5 = document.getElementById('div-an5');
const div_an6 = document.getElementById('div-an6');

const in_time = document.getElementById('in-time')
const in_mode = document.getElementById('in-mode')
const in_mul = document.getElementById('in-mul')
const in_alpha = document.getElementById('in-alpha')

const btn_start = document.getElementById('btn-start')
const btn_stop = document.getElementById('btn-stop')
const btn_high = document.getElementById('btn-high')
const btn_signal_1 = document.getElementById('btn-signal-1')
const btn_signal_2 = document.getElementById('btn-signal-2')
const btn_signal_send = document.getElementById('btn-signal-send')
const btn_alpha = document.getElementById('btn-alpha')

const btn_receive = document.getElementById('btn-receive')

const btn_div10 = document.getElementById('btn-div10')
const btn_mul10 = document.getElementById('btn-mul10')
const btn_signal_calc = document.getElementById('btn-signal-calc')

const btn_copy_values = document.getElementById('btn-copy-values')

const div_analog_an4 = document.getElementById('analog-an4')
const div_analog_an5 = document.getElementById('analog-an5')
const div_analog_an6 = document.getElementById('analog-an6')

const analog_values_an4 = []
const analog_values_an5 = []
const analog_values_an6 = []

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

btn_alpha.addEventListener('click', async() => {
    
    alpha = parseFloat(in_alpha.value)
    
    _create_signal(alpha)

})

function _create_signal(alpha) {
    
    let E = 5
    let C1 = 470e-6
    let C2 = 470e-6
    let L = 100*1e-3
    let R = 22
    
    let n = 3 // number of switch cells
    let T = 0.28*1e-3 // period of cycle
    
    let iMax = E/R
    let iLref = iMax*alpha // current setpoint
    
    console.log(`iMax: ${iMax}, iLref: ${iLref}`)
    
    let res = industrial_solution(alpha, n, T)
    
    const {Omega, dtSwitch} = res
    
    // set values in time and modes
    const dtSwitch_us = dtSwitch.map(v => v*1e6)
    in_time.value = dtSwitch_us.map(Math.round).join(", ")
    in_mode.value = Omega.map(v => v-1).join(", ")
}

function industrial_solution(alpha, nSwitches, T) {
    
    // Step 1: Define t0,i; ton,i; toff,i and initial state of the ith switch cell
    let t0 = Array(nSwitches).fill(0)
    let ton = Array(nSwitches).fill(0)
    let toff = Array(nSwitches).fill(0)
    let initialState = Array(nSwitches).fill(0)
    for (let i = 0; i < nSwitches; i++) {
        t0[i] = i*T/nSwitches
        toff[i] = (t0[i] + alpha*T/2) % T
        ton[i] = (t0[i] + T - alpha*T/2) % T
        
        // note that ton[i] is never equal to toff[i] with 0 < alpha < 1
        if (ton[i] < toff[i]) {
            initialState[i] = 0;
        } else {
            initialState[i] = 1;
        }
    }
    
    // Step 2: Obtain switching times
    let tSwitch_unsorted = [...ton, ...toff]
    const indexSort = Array.from(tSwitch_unsorted.keys())
    
    indexSort.sort((a, b) => tSwitch_unsorted[a] - tSwitch_unsorted[b]);
    let tSwitch = indexSort.map(i => tSwitch_unsorted[i])
    
    // Step 3: obtain mode sequence in binary coding form
    // note that the final state is equal to the initial state

    let OmegaBin = []
    OmegaBin.push(initialState)
    
    let aux = [...Array(nSwitches).keys()]
    const SwitchUnsorted = [...aux, ...aux]
    const SwitchId = indexSort.map(i => SwitchUnsorted[i])

    for (let i = 0; i < (2*nSwitches)-1; i++) {
        let previousState = OmegaBin[i];
        let SwitchToChange = SwitchId[i];
        let newState = [...previousState];

        newState[SwitchToChange] = 1 - previousState[SwitchToChange]
        OmegaBin.push(newState);
    }
    
    // Step 4: Convert the mode sequence to decimal form
    const Omega = []

    const bin2dec = (bin) => {
        return bin.reverse().reduce((acc, value, idx) => acc + value*Math.pow(2, idx))
    }

    for (let i = 0; i < 2*nSwitches; i++) {
        Omega.push(1 + bin2dec(OmegaBin[i]))
    }
    
    // Step 5: Convert tSwitch to dtSwitch assuming that the final switching
    // time will be shifted to t = T
    
    let dtSwitch = [0, ...tSwitch].map((value, idx, arr) => value - arr[idx-1]).slice(1)
    dtSwitch[0] = dtSwitch[0] + T - tSwitch[tSwitch.length-1]

    const res = {
        "Omega": Omega,
        "dtSwitch": dtSwitch,
        "tSwitch": tSwitch
    }

    return res
}

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

btn_copy_values.addEventListener('click', () => {
    const an4 = div_analog_an4.innerText
    const an5 = div_analog_an5.innerText
    const an6 = div_analog_an6.innerText
    
    // creating message
    const message = `an4 = [${an4}]
an5 = [${an5}]
an6 = [${an6}]`
    
    // coping values
    navigator.clipboard.writeText(message)
        .then(() => console.log('values copied!!'))
        .catch(() => console.error('values NOT copied!!'))
    
})

btn_div10.addEventListener('click', () => {
    _multiply_time(0.1)
})

btn_mul10.addEventListener('click', () => {
    _multiply_time(10.0)
})

btn_signal_1.click()

let is_listening = false;
let listen_interval;

function toggleListening() {
    is_listening = !is_listening
    if (is_listening) {
        btn_receive.textContent = "Stop Listening"
        listen_messages()
    } else {
        btn_receive.textContent = "Start Listening"
        clearInterval(listen_interval) // stop listenning
    }
}

btn_receive.addEventListener('click', async () => {
    if (!bluetoothDevice || !bluetoothDevice.gatt.connected) {
        await connectDevice();
    }
    toggleListening()
})

async function listen_messages() {

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
                    
                    div_an2.textContent = an2;
                    div_an3.textContent = an3;
                    div_an4.textContent = an4;
                    div_an5.textContent = an5;
                    div_an6.textContent = an6;
                    
                    // saving time series
                    // analog_values_an4.push(an4)
                    // analog_values_an5.push(an5)
                    // analog_values_an6.push(an6)
                    div_analog_an4.innerText += ` ${an4},`
                    div_analog_an5.innerText += ` ${an5},`
                    div_analog_an6.innerText += ` ${an6},`
                    
                }

            } catch (err) {
                updateStatus(`Receive failed: ${err.message}`, true)
            }
        }
    }, 1000);
}