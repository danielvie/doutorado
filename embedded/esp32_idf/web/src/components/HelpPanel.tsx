import React, { useState } from "react";
import { Check, Copy } from "lucide-react";
import { PanelSize } from "./Dashboard/SizeSelector";
import { DashboardItem } from "./Dashboard/DashboardItem";

const CommandItem: React.FC<{ commands: string; description: string }> = ({
  commands,
  description,
}) => {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(commands);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <li
      onClick={handleCopy}
      className="bg-gray-50 p-3 rounded-lg border border-gray-200 shadow-sm hover:shadow-md hover:bg-white transition-all cursor-pointer group relative active:scale-[0.98] border-l-4 border-l-transparent hover:border-l-purple-500"
      title="Click to copy command"
    >
      <div className="flex justify-between items-start gap-2">
        <strong className="text-purple-700 block mb-1 font-mono break-all group-hover:text-purple-800">
          {commands}
        </strong>
        <div className="shrink-0 pt-0.5">
          {copied ? (
            <Check size={14} className="text-green-500 animate-in zoom-in duration-200" />
          ) : (
            <Copy size={14} className="text-gray-300 group-hover:text-gray-400 opacity-0 group-hover:opacity-100 transition-all" />
          )}
        </div>
      </div>
      <span className="text-xs text-gray-600 font-sans tracking-wide block">
        {description}
      </span>
      {copied && (
        <div className="absolute -top-2 right-2 bg-green-500 text-white text-[10px] font-bold px-1.5 py-0.5 rounded shadow-lg animate-in slide-in-from-bottom-1 duration-200">
          COPIED
        </div>
      )}
    </li>
  );
};

export const HelpPanel: React.FC<{
  id: string;
  instanceId: string;
  currentSize?: PanelSize;
  onSizeChange?: (size: PanelSize) => void;
}> = ({ id, instanceId, currentSize = "1x1", onSizeChange = () => {} }) => {
  return (
    <DashboardItem
      id={id}
      instanceId={instanceId}
      title="BLE Commands Guide"
      currentSize={currentSize}
      onSizeChange={onSizeChange}
      expandable={false}
    >
      <div className="flex-1 min-h-0 overflow-y-auto pr-2 custom-scrollbar">
        <ul className="text-sm font-mono text-gray-800 flex flex-col gap-3 py-1">
          <CommandItem
            commands="blink, blink:delay, blink:d1,d2"
            description="Controls LED blink patterns"
          />
          <CommandItem
            commands="port:N,val | port:N,high | port:N,low"
            description="Directly controls digital ports"
          />
          <CommandItem
            commands="cycles:N, us_delay:N, us_delay_up:N"
            description="Adjusts control timing cycles"
          />
          <CommandItem
            commands="an_monitor_ms:N"
            description="Sets analog read monitor period"
          />
          <CommandItem
            commands="on, off, read, status, log_duration"
            description="Global readout and state control"
          />
          <CommandItem
            commands="active_dataset, print_dataset_a/b"
            description="Dataset debug printing"
          />
          <CommandItem
            commands="SIGNAL:..., SET_ALPHA:val"
            description="Signal update and alpha parameter"
          />
          <CommandItem
            commands="status_matrix_a, status_matrix_b"
            description="Retrieves matrix configuration"
          />
          <CommandItem
            commands="ble_read_on, ble_read_off"
            description="Toggles diagnostic analog reads via BLE"
          />
          <CommandItem
            commands="high, low, start, stop"
            description="Controls continuous signal execution"
          />
          <CommandItem
            commands="control_on, control_off"
            description="Feedback loop mode switching"
          />
        </ul>
      </div>
    </DashboardItem>
  );
};
