import { useState } from "react";
import "./App.css";
import RealtimeChart, { DataPoint } from "./components/Chart";
import { _create_signal } from "./helper";

import Control from "./components/Control";
import Listenner from "./components/Listenner";

function App() {

  const [has_advanced_menu, set_has_advanced_menu] = useState(false);
  const [alpha, set_alpha] = useState("0.5");
  const [data, set_data] = useState<DataPoint[]>([]);
  const [show_images, set_show_images] = useState(false);
  const [analog_scale, set_analog_scale] = useState(1.0);
  const [filter_alpha, set_filter_alpha] = useState(0);

  return (
    <>
      <div className="grid grid-cols-2 gap-0 p-2">
        <div className="">
          <Control
            alpha={alpha}
            set_alpha={set_alpha}
            data={data}
            set_data={set_data}
            set_show_images={set_show_images}
            analog_scale={analog_scale}
            set_analog_scale={set_analog_scale}
            filter_alpha={filter_alpha}
            set_filter_alpha={set_filter_alpha}
          ></Control>
        </div>
        <div className="p-4">
          <RealtimeChart
            data={data.slice(-200)}
            analog_scale={analog_scale}
            filter_alpha={filter_alpha}
          />
        </div>
        <div className="col-span-1">
          {has_advanced_menu 
          ? <div>
             <div onClick={() => set_has_advanced_menu((val)=> !val)} className="text-left bg-[#1a1a1a] p-2 rounded-md"><button>advanced menu &lt;&lt; </button></div> 
            <Listenner
              alpha={alpha}
            ></Listenner>
          </div>          
          : <div onClick={() => set_has_advanced_menu((val)=> !val)} className="text-left bg-[#1a1a1a] p-2 rounded-md"><button>advanced menu &gt;&gt;</button></div>
          }
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
