import React, { useState, useRef, useEffect, useMemo } from "react";
import { sendCommand as busSendCommand } from "../../services/commands";
import { Send, History, BookOpen, Search, Play, Copy, Check } from "lucide-react";
import { DashboardItem } from "./DashboardItem";
import { useBleStore } from "../../store/bleStore";
import { useStorage } from "../../useStorage";
import { COMMAND_REFERENCE } from "./commandReference";

const parseCommand = (raw: string) => {
  const trimmed = raw.trim();
  const jsonStart = trimmed.indexOf("{");
  const name = jsonStart >= 0 ? trimmed.slice(0, jsonStart).trim() : trimmed;
  const payload = jsonStart >= 0 ? JSON.parse(trimmed.slice(jsonStart)) : {};
  return { trimmed, name, payload };
};

interface ReferenceItemProps {
  commands: string;
  description: string;
  onRun: (command: string) => void;
  onUse: (command: string) => void;
}

const ReferenceItem: React.FC<ReferenceItemProps> = ({
  commands,
  description,
  onRun,
  onUse,
}) => {
  const [copied, setCopied] = useState(false);

  const handleCopy = (event: React.MouseEvent) => {
    event.stopPropagation();
    navigator.clipboard.writeText(commands);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <li
      className="group relative rounded-md border border-stone-200 bg-white p-3
      transition-all
      hover:border-indigo-200 hover:bg-indigo-50/40 hover:shadow-sm
      active:scale-[0.99]
      "
    >
      <div className="flex justify-between items-start gap-2">
        <strong className="text-indigo-700 block mb-1 font-mono font-semibold break-all">
          {commands}
        </strong>
        <div className="shrink-0 pt-0.5 flex items-center gap-1">
          <button
            type="button"
            onClick={() => onRun(commands)}
            title="Run command"
            aria-label="Run command"
            className="flex h-6 items-center gap-1 rounded-md border border-emerald-300 bg-emerald-50 px-2 text-[10px] font-bold text-emerald-700 shadow-sm transition-all hover:bg-emerald-100 hover:shadow"
          >
            <Play size={12} />
            RUN
          </button>
          <button
            type="button"
            onClick={() => onUse(commands)}
            title="Edit in console input"
            aria-label="Write command to console input"
            className="grid h-6 w-6 place-items-center rounded-md border border-stone-200 bg-white text-stone-500 opacity-0 shadow-sm transition-all hover:border-indigo-300 hover:text-indigo-600 hover:shadow group-hover:opacity-100"
          >
            <span className="text-sm font-bold leading-none">&gt;</span>
          </button>
          <button
            type="button"
            onClick={handleCopy}
            title="Copy command"
            aria-label="Copy command"
            className="grid h-6 w-6 place-items-center rounded-md border border-stone-200 bg-white text-stone-400 opacity-0 shadow-sm transition-all hover:border-stone-300 hover:text-stone-600 hover:shadow group-hover:opacity-100"
          >
            {copied ? (
              <Check
                size={14}
                className="text-emerald-500 animate-in zoom-in duration-200"
              />
            ) : (
              <Copy size={14} />
            )}
          </button>
        </div>
      </div>
      <span className="text-xs text-stone-500 font-sans tracking-wide block">
        {description}
      </span>
      {copied && (
        <div className="absolute -top-2 right-2 bg-emerald-500 text-white text-[10px] font-bold px-1.5 py-0.5 rounded shadow-lg animate-in slide-in-from-bottom-1 duration-200">
          COPIED
        </div>
      )}
    </li>
  );
};

export const Console: React.FC = () => {
  const [cmd, set_cmd] = useState("");
  const [tab, set_tab] = useState<"history" | "reference">("history");
  const [filter, setFilter] = useState("");
  const [command_history, set_command_history] = useStorage<string[]>(
    "manual-command-history",
    [],
  );
  const sharedCommandHistory = useBleStore((state) => state.commandHistory);
  const addCommandHistory = useBleStore((state) => state.addCommandHistory);
  const setSharedCommandHistory = useBleStore(
    (state) => state.setCommandHistory,
  );
  const history_index_ref = useRef(-1);
  const history_ref = useRef<string[]>([]);
  const input_ref = useRef<HTMLInputElement>(null);

  useEffect(() => {
    setSharedCommandHistory(command_history);
  }, []);

  useEffect(() => {
    set_command_history(sharedCommandHistory);
  }, [sharedCommandHistory, set_command_history]);

  // Keep historyRef in sync with commandHistory state
  useEffect(() => {
    history_ref.current = command_history;
  }, [command_history]);

  const filteredCommands = useMemo(() => {
    if (!filter.trim()) return COMMAND_REFERENCE;

    try {
      const regex = new RegExp(filter, "i");
      return COMMAND_REFERENCE.filter((item) => {
        const target = `${item.commands} ${item.description}`;
        return regex.test(target);
      });
    } catch {
      // While the user is typing an incomplete regex, it might be invalid.
      // We return an empty list or handle as no match until the regex is valid.
      return [];
    }
  }, [filter]);

  const send_command = (raw: string) => {
    try {
      const { trimmed, name, payload } = parseCommand(raw);
      addCommandHistory(trimmed);
      busSendCommand(name, payload);
      return true;
    } catch (error) {
      alert(
        `Invalid command JSON: ${error instanceof Error ? error.message : String(error)}`,
      );
      return false;
    }
  };

  const use_command = (command: string) => {
    set_cmd(command);
    history_index_ref.current = -1;
    input_ref.current?.focus();
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    const history = history_ref.current;
    if (e.key === "ArrowUp") {
      e.preventDefault();
      if (history.length === 0) return;
      const newIndex = history_index_ref.current + 1;
      if (newIndex < history.length) {
        history_index_ref.current = newIndex;
        set_cmd(history[newIndex]);
      }
    } else if (e.key === "ArrowDown") {
      e.preventDefault();
      if (history.length === 0) return;
      const newIndex = history_index_ref.current - 1;
      if (newIndex >= 0) {
        history_index_ref.current = newIndex;
        set_cmd(history[newIndex]);
      } else {
        history_index_ref.current = -1;
        set_cmd("");
      }
    }
  };

  const handleSend = (e?: React.FormEvent) => {
    e?.preventDefault();
    if (!cmd.trim()) return;
    history_index_ref.current = -1;
    if (send_command(cmd)) {
      set_cmd("");
    }
  };

  const tab_button_class = (active: boolean) =>
    `flex items-center gap-1.5 px-3 py-1.5 rounded-md text-[11px] font-bold uppercase tracking-widest border transition-colors ${
      active
        ? "bg-indigo-600 text-white border-indigo-600 shadow-sm"
        : "bg-white text-stone-500 border-stone-200 hover:bg-stone-50 hover:text-stone-700"
    }`;

  return (
    <DashboardItem title="Console" expandable={false}>
      <div className="flex-1 flex flex-col gap-3 min-h-0">
        <form onSubmit={handleSend} className="flex gap-2 p-1 shrink-0">
          <div className="relative flex-1">
            <input
              ref={input_ref}
              type="text"
              value={cmd}
              onChange={(e) => set_cmd(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder='system.list_commands or signal.set_alpha {"alpha":0.5}'
              className="w-full font-mono text-sm bg-white border-2 border-gray-200 hover:border-gray-400 focus:border-blue-500 focus:ring-0 outline-none px-3 py-2.5 shadow-none rounded-lg ring-0 transition-none"
            />
            {command_history.length > 0 && (
              <div className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-300 transition-colors pointer-events-none">
                <History size={16} />
              </div>
            )}
          </div>
          <button
            type="submit"
            disabled={!cmd.trim()}
            className="bg-blue-600 hover:bg-blue-700 disabled:bg-gray-300 text-white rounded-lg px-5 py-2.5 transition-all active:scale-95 shadow-md disabled:shadow-none flex items-center justify-center shrink-0"
          >
            <Send size={18} />
          </button>
        </form>

        <div className="flex items-center gap-2 shrink-0 px-1">
          <button
            type="button"
            onClick={() => set_tab("history")}
            className={tab_button_class(tab === "history")}
          >
            <History size={13} />
            History
          </button>
          <button
            type="button"
            onClick={() => set_tab("reference")}
            className={tab_button_class(tab === "reference")}
          >
            <BookOpen size={13} />
            Reference
          </button>
        </div>

        {tab === "history" ? (
          <div className="flex-1 min-h-0 overflow-y-auto bg-gray-900 rounded-lg p-2 font-mono text-xs custom-scrollbar">
            {command_history.length === 0 ? (
              <div className="h-full flex items-center justify-center text-gray-600 italic">
                No history yet
              </div>
            ) : (
              <div className="flex flex-col gap-1">
                {command_history.map((h, i) => (
                  <div
                    key={i}
                    onClick={() => use_command(h)}
                    className="group flex items-center gap-2 text-gray-400 hover:text-blue-400 cursor-pointer p-1 rounded hover:bg-gray-800 transition-colors"
                  >
                    <span className="text-gray-600 font-bold shrink-0">$</span>
                    <span className="break-all">{h}</span>
                  </div>
                ))}
              </div>
            )}
          </div>
        ) : (
          <div className="flex-1 min-h-0 flex flex-col gap-2">
            <div className="relative shrink-0">
              <Search
                size={15}
                className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-stone-400"
              />
              <input
                type="search"
                value={filter}
                onChange={(event) => setFilter(event.target.value)}
                placeholder="Filter commands"
                className="w-full rounded-md border border-stone-200 bg-white py-2 pl-9 pr-3 text-sm font-medium text-stone-800 shadow-sm outline-none transition-colors placeholder:text-stone-400 focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100"
              />
            </div>
            <div className="flex-1 min-h-0 overflow-y-auto pr-2 custom-scrollbar select-text">
              <ul className="text-sm font-mono text-stone-800 flex flex-col gap-2 py-1">
                {filteredCommands.map((item) => (
                  <ReferenceItem
                    key={item.commands}
                    commands={item.commands}
                    description={item.description}
                    onRun={send_command}
                    onUse={use_command}
                  />
                ))}
                {filteredCommands.length === 0 && (
                  <li className="rounded-md border border-dashed border-stone-300 bg-stone-50 p-4 text-center text-xs font-semibold uppercase tracking-wide text-stone-500">
                    No commands found
                  </li>
                )}
              </ul>
            </div>
          </div>
        )}
      </div>
    </DashboardItem>
  );
};
