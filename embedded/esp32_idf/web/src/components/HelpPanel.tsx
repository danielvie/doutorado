import { GripVertical } from "lucide-react";
import { PanelSize, SizeSelector } from "./Dashboard/SizeSelector";

export const HelpPanel: React.FC<{
  currentSize?: PanelSize;
  onSizeChange?: (size: PanelSize) => void;
  dragHandleRef?: React.RefObject<HTMLDivElement>;
}> = ({ currentSize = "1x1", onSizeChange = () => {}, dragHandleRef }) => {
  return (
    <div className="panel p-6 flex flex-col gap-6 h-full min-h-0">
      <div className="flex justify-between items-center border-b border-gray-200 pb-4">
        <div className="flex items-center gap-1.5">
          <div
            ref={dragHandleRef}
            className="p-1.5 text-gray-400 hover:text-gray-600 cursor-grab active:cursor-grabbing transition-colors"
          >
            <GripVertical size={20} />
          </div>
          <SizeSelector currentSize={currentSize} onSizeChange={onSizeChange} />
          <div className="p-2 bg-purple-50 rounded-md text-purple-600 ml-1.5">
            <span className="text-xl">📖</span>
          </div>
          <h2 className="text-xl font-bold text-gray-900">
            BLE Commands Guide
          </h2>
        </div>
      </div>

      <div className="flex-1 min-h-0 overflow-y-auto pr-2">
        <ul className="text-sm font-mono text-gray-800 flex flex-col gap-3">
          <li className="bg-gray-50 p-3 rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-shadow">
            <strong className="text-purple-700 block mb-1">
              blink, blink:delay, blink:d1,d2
            </strong>
            <span className="text-xs text-gray-600 font-sans tracking-wide">
              Controls LED blink patterns
            </span>
          </li>
          <li className="bg-gray-50 p-3 rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-shadow">
            <strong className="text-purple-700 block mb-1">
              port:N,val | port:N,high | port:N,low
            </strong>
            <span className="text-xs text-gray-600 font-sans tracking-wide">
              Directly controls digital ports
            </span>
          </li>
          <li className="bg-gray-50 p-3 rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-shadow">
            <strong className="text-purple-700 block mb-1">
              cycles:N, us_delay:N, us_delay_up:N
            </strong>
            <span className="text-xs text-gray-600 font-sans tracking-wide">
              Adjusts control timing cycles
            </span>
          </li>
          <li className="bg-gray-50 p-3 rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-shadow">
            <strong className="text-purple-700 block mb-1">
              an_monitor_ms:N
            </strong>
            <span className="text-xs text-gray-600 font-sans tracking-wide">
              Sets analog read monitor period
            </span>
          </li>
          <li className="bg-gray-50 p-3 rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-shadow">
            <strong className="text-purple-700 block mb-1">
              on, off, read, status, log_duration
            </strong>
            <span className="text-xs text-gray-600 font-sans tracking-wide">
              Global readout and state control
            </span>
          </li>
          <li className="bg-gray-50 p-3 rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-shadow">
            <strong className="text-purple-700 block mb-1">
              active_dataset, print_dataset_a/b
            </strong>
            <span className="text-xs text-gray-600 font-sans tracking-wide">
              Dataset debug printing
            </span>
          </li>
          <li className="bg-gray-50 p-3 rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-shadow">
            <strong className="text-purple-700 block mb-1">
              SIGNAL:..., SET_ALPHA:val
            </strong>
            <span className="text-xs text-gray-600 font-sans tracking-wide">
              Signal update and alpha parameter
            </span>
          </li>
          <li className="bg-gray-50 p-3 rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-shadow">
            <strong className="text-purple-700 block mb-1">
              status_matrix_a, status_matrix_b
            </strong>
            <span className="text-xs text-gray-600 font-sans tracking-wide">
              Retrieves matrix configuration
            </span>
          </li>
          <li className="bg-gray-50 p-3 rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-shadow">
            <strong className="text-purple-700 block mb-1">
              ble_read_on, ble_read_off
            </strong>
            <span className="text-xs text-gray-600 font-sans tracking-wide">
              Toggles diagnostic analog reads via BLE
            </span>
          </li>
          <li className="bg-gray-50 p-3 rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-shadow">
            <strong className="text-purple-700 block mb-1">
              high, low, start, stop
            </strong>
            <span className="text-xs text-gray-600 font-sans tracking-wide">
              Controls continuous signal execution
            </span>
          </li>
          <li className="bg-gray-50 p-3 rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-shadow">
            <strong className="text-purple-700 block mb-1">
              control_on, control_off
            </strong>
            <span className="text-xs text-gray-600 font-sans tracking-wide">
              Feedback loop mode switching
            </span>
          </li>
        </ul>
      </div>
    </div>
  );
};
