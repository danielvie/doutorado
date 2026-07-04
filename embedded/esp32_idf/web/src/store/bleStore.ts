import { create } from "zustand";

interface BleState {
    isConnected: boolean;
    isConnecting: boolean;
    error: string | null;
    statusLogs: string[];
    systemStatus: string; // e.g. "Ready", "Connected", "Disconnected"
    device: BluetoothDevice | null; // Keep reference if needed for direct ops
    lastStatusMessage: string | null;
    lastStatusCommand: { name: string; payload: Record<string, unknown> } | null;
    alpha: string;
    showHelp: boolean;
    monitorPeriodMs: number;
    signalEngine: "cpu" | "dma";
    isCongested: boolean;
    autoRequestStatus: boolean;
    commandHistory: string[];
    commandError: string | null;

    // Actions
    setLastStatusMessage: (message: string | null) => void;
    setLastStatusCommand: (command: { name: string; payload: Record<string, unknown> } | null) => void;
    setIsConnected: (connected: boolean) => void;
    setIsConnecting: (connecting: boolean) => void;
    setError: (error: string | null) => void;
    addLog: (log: string) => void;
    clearLogs: () => void;
    setSystemStatus: (status: string) => void;
    setDevice: (device: BluetoothDevice | null) => void;
    setAlpha: (alpha: string) => void;
    setShowHelp: (show: boolean) => void;
    setMonitorPeriodMs: (ms: number) => void;
    setSignalEngine: (engine: "cpu" | "dma") => void;
    setIsCongested: (congested: boolean) => void;
    setAutoRequestStatus: (auto: boolean) => void;
    addCommandHistory: (command: string) => void;
    setCommandHistory: (history: string[]) => void;
    setCommandError: (error: string | null) => void;
    clearLastStatusMessage: () => void;
}

export const useBleStore = create<BleState>((set) => ({
    isConnected: false,
    isConnecting: false,
    error: null,
    statusLogs: [],
    systemStatus: "Ready",
    device: null,
    lastStatusMessage: null,
    lastStatusCommand: null,
    showHelp: false,
    monitorPeriodMs: 100,
    signalEngine: "cpu",
    isCongested: false,
    autoRequestStatus: false,
    commandHistory: [],
    commandError: null,

    setLastStatusMessage: (message) => set({ lastStatusMessage: message }),
    setLastStatusCommand: (command) => set({ lastStatusCommand: command }),
    setIsConnected: (connected) => set({ isConnected: connected }),
    setIsConnecting: (connecting) => set({ isConnecting: connecting }),
    setError: (error) => set({ error }),
    addLog: (log) =>
        set((state) => ({ statusLogs: [log, ...state.statusLogs].slice(0, 100) })), // Keep last 100 logs
    clearLogs: () => set({ statusLogs: [] }),
    setSystemStatus: (status) => set({ systemStatus: status }),
    setDevice: (device) => set({ device }),
    alpha: "0.5",
    setAlpha: (alpha) => set({ alpha }),
    setShowHelp: (show) => set({ showHelp: show }),
    setMonitorPeriodMs: (ms) => set({ monitorPeriodMs: ms }),
    setSignalEngine: (engine) => set({ signalEngine: engine }),
    setIsCongested: (congested) => set({ isCongested: congested }),
    setAutoRequestStatus: (auto) => set({ autoRequestStatus: auto }),
    addCommandHistory: (command) =>
        set((state) => ({
            commandHistory: [
                command,
                ...state.commandHistory.filter((item) => item !== command),
            ].slice(0, 50),
        })),
    setCommandHistory: (history) => set({ commandHistory: history.slice(0, 50) }),
    setCommandError: (error) => set({ commandError: error }),
    clearLastStatusMessage: () => set({ lastStatusMessage: null }),
}));
