import { useState, useEffect } from "react";
import './App.css'
import { connect_device, disconnect_device, set_update_status, send_command, toggle_listening, bt_is_connected  } from "./components/bluetooth";
import RealtimeChart, { DataPoint } from "./components/Chart";
import { _create_signal } from "./helper";


const initial_time = new Date();

function App() {
  
  const [status, setStatus] = useState('.')
  const [commandMessage, setCommandMessage] = useState('')
  
  const [time, setTime] = useState('')
  const [mode, setMode] = useState('')
  const [mulValue, setMulValue] = useState("1.0")
  
  const [data, setData] = useState<DataPoint[]>([])
  const [alpha, setAlpha] = useState('0.5')

  const [receiveLabel, setReceiveLabel] = useState('Start Listening')

  const [copyLabel, setCopyLabel] = useState('copy')

  
  const generateValue = () => {
    return Math.sin(Date.now() / 1000) * 5 + Math.random() * 2;
  };


  function updateStatus(message:string, _isError = false) {
    // statusDiv.textContent = message;
    // statusDiv.style.color = isError ? '#ff5252' : '#03dac6';
    // console.log(isError ? 'ERROR: ' + message : message);
    setStatus(message)
  }
  
  set_update_status(updateStatus)

  function handle_copy() {
    let message: string = ''
    
    message += `time = [${data.map(v => v.time).join(', ')}];\n`;
    message += `an3 = [${data.map(v => v.an3).join(', ')}];\n`;
    message += `an5 = [${data.map(v => v.an5).join(', ')}];\n`;
    message += `an6 = [${data.map(v => v.an6).join(', ')}];\n`;

    navigator.clipboard.writeText(message)
      .then(() => {
        setCopyLabel('copied!')
        setTimeout(() => {
          setCopyLabel('copy')
        }, 500);
      })
  }

  function handleSetCommandMessage(e: React.ChangeEvent<HTMLInputElement>) {
    const value = e.target.value
    setCommandMessage(value)
  }
  
  function handle_set_alpha(e: React.ChangeEvent<HTMLInputElement>) {
    const value = e.target.value
    setAlpha(value)
  }
  
  function handle_compute_alpha() {
    const value = parseFloat(alpha)
    const res = _create_signal(value)

    setTime(res.time)
    setMode(res.mode)
  }


  function handleSendCommand() {
    send_command(commandMessage)
  }

  function handleConnect() {
    connect_device()
  }

  function handleDisconnect() {
    disconnect_device()
  }
  
  function handleStart() {
    send_command("START")
  }

  function handleStop() {
    send_command("STOP")
  }
  
  function handleHigh() {
    send_command("HIGH")
  }
  
  
  function probe_values(values:{an2: string, an3: string, an4: string, an5: string, an6: string}) {
      const now = new Date();
      const timeStr = (now.getTime()-initial_time.getTime()).toString();
      
      setData(currentData => {
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
      setReceiveLabel("Stop Listening")
    } else {
      setReceiveLabel("Start Listening")
    }
  }

  function handle_test_receive() {

    setInterval(() => {
      const now = new Date();
      const timeStr = (now.getTime() - initial_time.getTime()).toString();
      
      setData(currentData => {
        const newData = [...currentData, {
          time: timeStr,
          an3: generateValue(),
          an5: generateValue()*3,
          an6: generateValue()*6
        }];
        
        return newData;
      });
    }, 100);

  }

  function setSignal1() {
    const _time = "50, 50, 50, 50, 50, 50"
    const _mode = "7, 0, 7, 0, 7, 0"
    setTime(_time)
    setMode(_mode)
  }

  function setSignal2() {
    const _time = "50, 50, 50, 50, 50, 50"
    const _mode = "7, 0, 7, 0, 7, 0"
    setTime(_time)
    setMode(_mode)
  }
  
  function handleSetTime(e: React.ChangeEvent<HTMLInputElement>) {
    setTime(e.target.value)
  }

  function handleSetMode(e: React.ChangeEvent<HTMLInputElement>) {
    setMode(e.target.value)
  }
  
  function handleSendSignal() {
    const signal = `SIGNAL:${time};${mode}`
    send_command(signal)
  }

  function handleSetMultiply(e: React.ChangeEvent<HTMLInputElement>) {
    const value = e.target.value
    
    setMulValue(value)
  }
  
  function _multiply_time(value: number) {
    // split and multiply values
    const res = time.split(',').map((e) => parseFloat(e)*value)
    
    // write values back
    const res_str = res.map(Math.round).join(', ')
    updateStatus(res_str)
    setTime(res_str)
  }

  return (
    <>
      <div className="grid items-center justify-items-center">
        <div className="w-[600px]">
          <h1 className="text-purple-500 text-4xl font-bold justify-center items-center text-center">ESP32 Web Bluetooth Control</h1>

          <div className="flex  gap-3 my-5 items-center justify-center">
            <button id="connectBtn" onClick={handleConnect} className="btn">Connect to ESP32</button>
            <button id="disconnectBtn" onClick={handleDisconnect} className="btn">Disconnect</button>
            <button onClick={handle_receive} className="btn">{receiveLabel}</button>
            <button onClick={handle_test_receive} className="btn">test</button>
            <button onClick={handle_copy} className="btn">{copyLabel}</button>
          </div>

          <div id="controlPanel" className="bg-panel p-5 rounded-xl">

            <div className="bg-purple-500 w-full h-[2px] mb-4"></div>

            <div className="flex justify-content">
              <input type="text" id="commandInput" value={commandMessage} onChange={handleSetCommandMessage} className="flex-1 bg-panel border-zinc-700 border-[1px] rounded-sm px-3 py-1" placeholder="Enter command" />
              <button id="sendBtn" onClick={handleSendCommand} className="flex-none ml-2 btn">send</button>
            </div>


            <div className="flex my-4 gap-2">
              <label className="mr-4 relative top-2 w-12">alpha:</label>
              <input type="number" step="0.1" id="in-alpha" className="bg-panel border flex-none w-16 px-2 text-center" value={alpha} onChange={handle_set_alpha} />
              <button itemType="text" id="btn-alpha" className="btn" onClick={handle_compute_alpha}>calc</button>
              <span className="flex-1"></span>
            </div>

            <div className="flex my-4 gap-2">
              <label htmlFor="" className="flex item-center justify-content mr-4 relative top-2 w-12">time:</label>
              <input type="text" id="in-time" className="input p-2 flex-grow" placeholder="Enter time" value={time} onChange={handleSetTime} />
            </div>

            <div className="flex my-4 gap-2">
              <label htmlFor="" className="flex item-center justify-content mr-4 relative top-2 w-12">modes:</label>
              <input type="text" id="in-mode" className="input p-2 flex-grow" placeholder="Enter modes" value={mode} onChange={handleSetMode} />
            </div>

            <div className="flex my-4 gap-2">
              <label htmlFor="" className="flex item-center justify-content mr-4 relative top-2 w-12">X*time:</label>
              <input type="text" id="in-mul" className="input p-2 w-16 text-center" placeholder="X*time" value={mulValue} onChange={handleSetMultiply} />
              <span className=""></span>
              <button id="btn-div10" onClick={() => _multiply_time(0.1)} className="btn">x1/10</button>
              <button id="btn-mul10" onClick={() => _multiply_time(10.0)} className="btn">x10</button>
              <button id="btn-signal-calc" onClick={() => _multiply_time(parseFloat(mulValue))} className="btn">calc</button>
              <button id="btn-signal-send" onClick={handleSendSignal} className="btn">send signal</button>
            </div>

            <div className="bg-purple-500 w-full h-[2px] my-5"></div>

            <div className="flex gap-4 justify-center">
              <button id="btn-signal-1" onClick={setSignal1} className="btn">signal 1</button>
              <button id="btn-signal-2" onClick={setSignal2} className="btn">signal 2</button>
              <button id="btn-start" onClick={handleStart} className="btn">start</button>
              <button id="btn-stop" onClick={handleStop} className="btn">stop</button>
              <button id="btn-high" onClick={handleHigh} className="btn">high</button>
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
