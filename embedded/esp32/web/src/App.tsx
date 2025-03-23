import { useState } from "react";
import './App.css'
import { connect_device, disconnect_device, set_update_status, send_command, toggle_listening, bt_is_connected  } from "./components/bluetooth";
import RealtimeChart, { DataPoint } from "./components/Chart";
import { _create_signal } from "./helper";


const initial_time = new Date();

function App() {
  
  const [status, set_status] = useState('.')
  const [command_message, set_command_message] = useState('')
  
  const [time, set_time] = useState('')
  const [mode, set_mode] = useState('')
  const [mul_value, set_mul_value] = useState("1.0")
  
  const [data, set_data] = useState<DataPoint[]>([])
  const [alpha, set_alpha] = useState('0.5')

  const [receive_label, set_receive_label] = useState('Start Listening')

  const [copy_label, set_copy_label] = useState('copy')

  
  const generate_value = () => {
    return Math.sin(Date.now() / 1000) * 5 + Math.random() * 2;
  };


  function update_status(message:string, _isError = false) {
    // statusDiv.textContent = message;
    // statusDiv.style.color = isError ? '#ff5252' : '#03dac6';
    // console.log(isError ? 'ERROR: ' + message : message);
    set_status(message)
  }
  
  set_update_status(update_status)

  function handle_copy() {
    let message: string = ''
    
    message += `time = [${data.map(v => v.time).join(', ')}];\n`;
    message += `an3 = [${data.map(v => v.an3).join(', ')}];\n`;
    message += `an5 = [${data.map(v => v.an5).join(', ')}];\n`;
    message += `an6 = [${data.map(v => v.an6).join(', ')}];\n`;

    navigator.clipboard.writeText(message)
      .then(() => {
        set_copy_label('copied!')
        setTimeout(() => {
          set_copy_label('copy')
        }, 500);
      })
  }

  function handle_set_command_message(e: React.ChangeEvent<HTMLInputElement>) {
    const value = e.target.value
    set_command_message(value)
  }
  
  function handle_set_alpha(e: React.ChangeEvent<HTMLInputElement>) {
    const value = e.target.value
    set_alpha(value)
  }
  
  function handle_compute_alpha() {
    const value = parseFloat(alpha)
    const res = _create_signal(value)

    set_time(res.time)
    set_mode(res.mode)
  }


  function handle_send_command() {
    send_command(command_message)
  }

  function handle_connect() {
    connect_device()
  }

  function handle_disconnect() {
    disconnect_device()
  }
  
  function handleStart() {
    send_command("START")
  }

  function handle_stop() {
    send_command("STOP")
  }
  
  function handle_high() {
    send_command("HIGH")
  }
  
  
  function probe_values(values:{an2: string, an3: string, an4: string, an5: string, an6: string}) {
      const now = new Date();
      const timeStr = (now.getTime()-initial_time.getTime()).toString();
      
      set_data(currentData => {
        const newData = [...currentData, {
          time: timeStr,
          an6: parseFloat(values.an6),
          an5: parseFloat(values.an5),
          an3: parseFloat(values.an3),
        }].slice(-500);
        
        return newData;
      });
  }
  
  async function handle_receive() {
    // if (!bt_is_connected()) {
    //     await connectDevice();
    // }
    const is_listening = toggle_listening(probe_values)
    if (is_listening) {
      set_receive_label("Stop Listening")
    } else {
      set_receive_label("Start Listening")
    }
  }

  function handle_test_receive() {

    setInterval(() => {
      const now = new Date();
      const timeStr = (now.getTime() - initial_time.getTime()).toString();
      
      set_data(currentData => {
        const newData = [...currentData, {
          time: timeStr,
          an3: generate_value(),
          an5: generate_value()*3,
          an6: generate_value()*6
        }];
        
        return newData;
      });
    }, 100);

  }

  function set_signal_1() {
    const _time = "50, 50, 50, 50, 50, 50"
    const _mode = "7, 0, 7, 0, 7, 0"
    set_time(_time)
    set_mode(_mode)
  }

  function set_signal_2() {
    const _time = "50, 50, 50, 50, 50, 50"
    const _mode = "7, 0, 7, 0, 7, 0"
    set_time(_time)
    set_mode(_mode)
  }
  
  function handle_set_time(e: React.ChangeEvent<HTMLInputElement>) {
    set_time(e.target.value)
  }

  function handle_set_mode(e: React.ChangeEvent<HTMLInputElement>) {
    set_mode(e.target.value)
  }
  
  function handle_send_signal() {
    const signal = `SIGNAL:${time};${mode}`
    send_command(signal)
  }

  function handle_set_multiply(e: React.ChangeEvent<HTMLInputElement>) {
    const value = e.target.value
    
    set_mul_value(value)
  }
  
  function _multiply_time(value: number) {
    // split and multiply values
    const res = time.split(',').map((e) => parseFloat(e)*value)
    
    // write values back
    const res_str = res.map(Math.round).join(', ')
    update_status(res_str)
    set_time(res_str)
  }

  return (
    <>
      <div className="grid items-center justify-items-center">
        <div className="w-[600px]">
          <h1 className="text-purple-500 text-4xl font-bold justify-center items-center text-center">ESP32 Web Bluetooth Control</h1>

          <div className="flex  gap-3 my-5 items-center justify-center">
            <button id="connectBtn" onClick={handle_connect} className="btn">Connect to ESP32</button>
            <button id="disconnectBtn" onClick={handle_disconnect} className="btn">Disconnect</button>
            <button onClick={handle_receive} className="btn">{receive_label}</button>
            <button onClick={handle_test_receive} className="btn">test</button>
            <button onClick={handle_copy} className="btn">{copy_label}</button>
          </div>

          <div id="controlPanel" className="bg-panel p-5 rounded-xl">

            <div className="bg-purple-500 w-full h-[2px] mb-4"></div>

            <div className="flex justify-content">
              <input type="text" id="commandInput" value={command_message} onChange={handle_set_command_message} className="flex-1 bg-panel border-zinc-700 border-[1px] rounded-sm px-3 py-1" placeholder="Enter command" />
              <button id="sendBtn" onClick={handle_send_command} className="flex-none ml-2 btn">send</button>
            </div>


            <div className="flex my-4 gap-2">
              <label className="mr-4 relative top-2 w-12">alpha:</label>
              <input type="number" step="0.1" id="in-alpha" className="bg-panel border flex-none w-16 px-2 text-center" value={alpha} onChange={handle_set_alpha} />
              <button itemType="text" id="btn-alpha" className="btn" onClick={handle_compute_alpha}>calc</button>
              <span className="flex-1"></span>
            </div>

            <div className="flex my-4 gap-2">
              <label htmlFor="" className="flex item-center justify-content mr-4 relative top-2 w-12">time:</label>
              <input type="text" id="in-time" className="input p-2 flex-grow" placeholder="Enter time" value={time} onChange={handle_set_time} />
            </div>

            <div className="flex my-4 gap-2">
              <label htmlFor="" className="flex item-center justify-content mr-4 relative top-2 w-12">modes:</label>
              <input type="text" id="in-mode" className="input p-2 flex-grow" placeholder="Enter modes" value={mode} onChange={handle_set_mode} />
            </div>

            <div className="flex my-4 gap-2">
              <label htmlFor="" className="flex item-center justify-content mr-4 relative top-2 w-12">X*time:</label>
              <input type="text" id="in-mul" className="input p-2 w-16 text-center" placeholder="X*time" value={mul_value} onChange={handle_set_multiply} />
              <span className=""></span>
              <button id="btn-div10" onClick={() => _multiply_time(0.1)} className="btn">x1/10</button>
              <button id="btn-mul10" onClick={() => _multiply_time(10.0)} className="btn">x10</button>
              <button id="btn-signal-calc" onClick={() => _multiply_time(parseFloat(mul_value))} className="btn">calc</button>
              <button id="btn-signal-send" onClick={handle_send_signal} className="btn">send signal</button>
            </div>

            <div className="bg-purple-500 w-full h-[2px] my-5"></div>

            <div className="flex gap-4 justify-center">
              <button id="btn-signal-1" onClick={set_signal_1} className="btn">signal 1</button>
              <button id="btn-signal-2" onClick={set_signal_2} className="btn">signal 2</button>
              <button id="btn-start" onClick={handleStart} className="btn">start</button>
              <button id="btn-stop" onClick={handle_stop} className="btn">stop</button>
              <button id="btn-high" onClick={handle_high} className="btn">high</button>
            </div>

          </div>

          <div id="status" className="w-min-[300px] m-2 p-3 rounded-lg bg-panel font-bold">{status}</div>

          <div id="analog-an4" className="hidden"></div>
          <div id="analog-an5" className="hidden"></div>
          <div id="analog-an6" className="hidden"></div>
        </div>
      </div>
      <RealtimeChart data={data.slice(-500)} />
    </>
  )
}

export default App
