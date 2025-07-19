import { useState } from "react";
import "./App.css";
import RealtimeChart, { DataPoint } from "./components/Chart";
import { _create_signal } from "./helper";

import Control from "./components/Control";

function App() {
  const [data, set_data] = useState<DataPoint[]>([]);

  const [show_images, set_show_images] = useState(false);
  

  return (
    <>
      <div className="flex">
        <div className="flex">
          <Control data={data} set_data={set_data} set_show_images={set_show_images}></Control>
        </div>
        <div className="flex">
          <RealtimeChart data={data.slice(-200)} />
        </div>
      </div>


      {show_images ?
        <div onClick={() => set_show_images(false)} className="fixed inset-0 flex items-center justify-center z-50 p-4 rounded-lg shadow-lg">
          <div className="flex flex-col space-y-4 items-center">
            <img src="circuit.png" alt="Circuit" className="max-w-full" />
            <img src="esp_pins.png" alt="ESP Pins" className="max-w-full" />
          </div>
        </div>
        : ""
      }

    </>
  );
}

export default App;
