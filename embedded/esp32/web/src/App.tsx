import { useEffect, useState } from "react";
import "./App.css";
import RealtimeChart, { DataPoint } from "./components/Chart";
import { _create_signal } from "./helper";

import Control from "./components/Control";
import AdvancedMenu from "./components/AdvancedMenu";
import { ble_app_set_status_msg } from "./components/bluetooth";

function App() {

  const [has_advanced_menu, set_has_advanced_menu] = useState(true);
  const [advanced_menu_label, set_advanced_menu_label] = useState("advanced menu <<");
  const [chart_label, set_chart_label] = useState("chart <<");
  const [has_chart, set_has_chart] = useState(true);
  const [alpha, set_alpha] = useState("0.5");
  const [data, set_data] = useState<DataPoint[]>([]);
  const [show_images, set_show_images] = useState(false);
  const [analog_scale, set_analog_scale] = useState(1.0);
  const [filter_alpha, set_filter_alpha] = useState(0);
  const [status_msg, set_status_msg] = useState('.');

  useEffect(() => {
    ble_app_set_status_msg(set_status_msg)
  }, [])
  

  function handle_toggle_chart() {
    set_has_chart(v => {
      // adjust label for the advanced menu
      const label = v ? "chart >>" : "chart <<"
      set_chart_label(label)

      // return the toggled value
      return !v
    })
  }

  function handle_toggle_advanced_menu() {
    set_has_advanced_menu((v) => {
      // adjust label for the advanced menu
      const label = v ? "advanced menu >>" : "advanced menu <<"
      set_advanced_menu_label(label)

      // return the toggled value
      return !v
    })
  }

  const col_control = <div>
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

    {/* toggle buttons */}
    <div className="col-span-1 p-2 text-left bg-panel rounded-md flex flex-col gap-2">
      <div>
        <button onClick={handle_toggle_chart} className="btn info">{chart_label}</button>
      </div>
      <div>
        <button onClick={handle_toggle_advanced_menu} className="btn info">{advanced_menu_label}</button>
      </div>
    </div>
  </div>
  
  const col_chart = <div className="col-span-1">
    {has_chart
      ?
      <RealtimeChart
        data={data.slice(-200)}
        analog_scale={analog_scale}
        filter_alpha={filter_alpha}
      />
      : ""
    }
  </div>
  
  const col_advanced_menu = <div className="col-span-1">
    {has_advanced_menu
      ? <AdvancedMenu
        alpha={alpha}
        status_msg={status_msg}
        set_status_msg={set_status_msg}
      ></AdvancedMenu>
      : ""
    }
  </div>
  
  const col_status_msg = <div className="col-span-1">
    <div className="col-span-1 bg-panel rounded-md text-left font-mono whitespace-break-spaces p-3">
      <button onClick={() => set_status_msg("")} className="cursor-pointer">[clear]</button>
      {status_msg}
    </div>
  </div>

  return (
    <>
      {/* {colors} */}
      <div className="grid grid-cols-1 tablet:grid-cols-2 gap-2 p-2 ">
        {/* control */}
        {col_control}

        {/* chart */}
        {col_chart}

        {/* messages */}
        {col_status_msg}

        {/* advanced menu */}
        {col_advanced_menu}


      </div>

      {show_images ?
        <div onClick={() => set_show_images(false)} className="fixed inset-0 flex items-center justify-center z-50 p-4 rounded-lg shadow-lg bg-gray-5/50">
          <div className="flex flex-col space-y-4 items-center">
            <img src="circuit.png" alt="Circuit" className="w-8/12" />
            <img src="esp_pins.png" alt="ESP Pins" className="w-8/12" />
          </div>
        </div>
        : ""
      }

    </>
  );
}

export default App;
