import React, { useState } from "react";
import { Check, Copy, Search } from "lucide-react";
import { PanelSize } from "./Dashboard/SizeSelector";
import { DashboardItem } from "./Dashboard/DashboardItem";

const COMMANDS = [
  {
    commands: "system.list_commands",
    description: "Lists registered UI commands",
  },
  {
    commands: "system.get_status",
    description: "Requests a structured status notification",
  },
  {
    commands: "signal.start",
    description: "Starts continuous signal execution",
  },
  {
    commands: "signal.stop",
    description: "Stops continuous signal execution",
  },
  {
    commands: 'signal.set_alpha {"alpha":0.5}',
    description: "Loads the precomputed dataset for an alpha value",
  },
  {
    commands: 'signal.set_pattern {"time":"10,20,10,20","mode":"7,0,7,0"}',
    description: "Uploads a custom signal pattern",
  },
  {
    commands: 'signal.set_cycle_interval {"cycles":100}',
    description: "Sets the analog trigger cycle interval",
  },
  {
    commands: 'signal.set_dead_time {"up_cycles":430,"down_cycles":430}',
    description: "Sets complementary switching dead time",
  },
  {
    commands: 'signal.set_dead_time_all {"cycles":430}',
    description: "Sets the same dead time for up and down switching",
  },
  {
    commands: 'analog.set_monitor_period {"period_ms":100}',
    description: "Sets periodic analog telemetry interval",
  },
  {
    commands: "analog.read_once",
    description: "Requests one analog telemetry sample",
  },
  {
    commands: "analog.ble_read_enable",
    description: "Enables continuous BLE analog read state",
  },
  {
    commands: "analog.ble_read_disable",
    description: "Disables continuous BLE analog read state",
  },
  {
    commands: "control.enable",
    description: "Enables closed-loop control",
  },
  {
    commands: "control.disable",
    description: "Disables closed-loop control",
  },
  {
    commands: "led.on",
    description: "Turns the onboard LED on",
  },
  {
    commands: "led.off",
    description: "Turns the onboard LED off",
  },
  {
    commands: 'led.blink {"delay1_ms":100,"delay2_ms":100}',
    description: "Sets LED blink mode, optionally with blink delays",
  },
  {
    commands: "debug.dataset_active",
    description: "Sends the active signal dataset",
  },
  {
    commands: "debug.dataset_a",
    description: "Sends signal dataset A",
  },
  {
    commands: "debug.dataset_b",
    description: "Sends signal dataset B",
  },
  {
    commands: "debug.matrix_a",
    description: "Sends the precomputed matrix for dataset A",
  },
  {
    commands: "debug.matrix_b",
    description: "Sends the precomputed matrix for dataset B",
  },
  {
    commands: "debug.log_duration",
    description: "Sends cycle duration diagnostics",
  },
  {
    commands: 'debug.gpio_set {"port":1,"value":1}',
    description: "Sets one debug GPIO port",
  },
  {
    commands: "debug.all_high",
    description: "Sets all signal GPIO pins high",
  },
  {
    commands: "debug.all_low",
    description: "Sets all signal GPIO pins low",
  },
];

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
      className="bg-gray-50 p-3 rounded-lg 
      shadow-sm hover:shadow-md 
      hover:bg-white transition-all 
      cursor-pointer 
      group relative 
      active:scale-[0.99] 
      border  border-gray-200  border-l-4  
      hover:brightness-95
      "
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
  const [filter, setFilter] = useState("");
  const normalizedFilter = filter.trim().toLowerCase();
  const filteredCommands = normalizedFilter
    ? COMMANDS.filter((item) =>
        `${item.commands} ${item.description}`
          .toLowerCase()
          .includes(normalizedFilter),
      )
    : COMMANDS;

  return (
    <DashboardItem
      id={id}
      instanceId={instanceId}
      title="Help BLE Commands Guide"
      currentSize={currentSize}
      onSizeChange={onSizeChange}
      expandable={false}
    >
      <div className="relative shrink-0">
        <Search
          size={15}
          className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-gray-400"
        />
        <input
          type="search"
          value={filter}
          onChange={(event) => setFilter(event.target.value)}
          placeholder="Filter commands"
          className="w-full rounded-md border border-gray-200 bg-white py-2 pl-9 pr-3 text-sm font-medium text-gray-800 shadow-sm outline-none transition-colors placeholder:text-gray-400 focus:border-blue-400 focus:ring-2 focus:ring-blue-100"
        />
      </div>
      <div className="flex-1 min-h-0 overflow-y-auto pr-2 custom-scrollbar select-text">
        <ul className="text-sm font-mono text-gray-800 flex flex-col gap-3 py-1">
          {filteredCommands.map((item) => (
            <CommandItem
              key={item.commands}
              commands={item.commands}
              description={item.description}
            />
          ))}
          {filteredCommands.length === 0 && (
            <li className="rounded-md border border-dashed border-gray-300 bg-gray-50 p-4 text-center text-xs font-semibold uppercase tracking-wide text-gray-500">
              No commands found
            </li>
          )}
        </ul>
      </div>
    </DashboardItem>
  );
};
