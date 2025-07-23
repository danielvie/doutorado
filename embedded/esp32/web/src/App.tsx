import { useState } from "react";
import "./App.css";
import RealtimeChart, { DataPoint } from "./components/Chart";
import { _create_signal } from "./helper";

import Control from "./components/Control";

function App() {

  const [data, set_data] = useState<DataPoint[]>([]);
  const [show_images, set_show_images] = useState(false);
  const [analog_scale, set_analog_scale] = useState(1.0);
  const [filter_alpha, set_filter_alpha] = useState(0);

  return (
    <>

      <div className="flex items-center">
        <div className="flex">
          <Control
            data={data}
            set_data={set_data}
            set_show_images={set_show_images}
            analog_scale={analog_scale}
            set_analog_scale={set_analog_scale}
            filter_alpha={filter_alpha}
            set_filter_alpha={set_filter_alpha}
          ></Control>
        </div>
        <div className="flex w-[600px]  p-4">
          <RealtimeChart 
            data={data.slice(-200)} 
            analog_scale={analog_scale}
            filter_alpha={filter_alpha}
            />
        </div>
      </div>


      {show_images ?
        <div onClick={() => set_show_images(false)} className="fixed inset-0 flex items-center justify-center z-50 p-4 rounded-lg shadow-lg bg-blue-800 bg-opacity-30">
          <div className="flex flex-col space-y-4 items-center">
            <img src="circuit.png" alt="Circuit" className="h-[350px]" />
            <img src="esp_pins.png" alt="ESP Pins" className="max-w-full" />
          </div>
        </div>
        : ""
      }

    </>
  );
}

export default App;
