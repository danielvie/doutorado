import { create } from "zustand";

interface BleState {
    isConnected: boolean;
    isConnecting: boolean;
    error: string | null;
    statusLogs: string[];
    systemStatus: string; // e.g. "Ready", "Connected", "Disconnected"
    device: BluetoothDevice | null; // Keep reference if needed for direct ops
    lastStatusMessage: string | null;
    isMockMode: boolean;
    alpha: string;
    showHelp: boolean;

    // Actions
    setLastStatusMessage: (message: string | null) => void;
    setIsConnected: (connected: boolean) => void;
    setIsConnecting: (connecting: boolean) => void;
    setError: (error: string | null) => void;
    addLog: (log: string) => void;
    clearLogs: () => void;
    setSystemStatus: (status: string) => void;
    setDevice: (device: BluetoothDevice | null) => void;
    setMockMode: (isMock: boolean) => void;
    setAlpha: (alpha: string) => void;
    setShowHelp: (show: boolean) => void;
}

export const useBleStore = create<BleState>((set) => ({
    isConnected: false,
    isConnecting: false,
    error: null,
    statusLogs: [],
    systemStatus: "Ready",
    device: null,
    isMockMode: false, // Default to false (Real BLE)
    lastStatusMessage: null,
    showHelp: false,

    setLastStatusMessage: (message) => set({ lastStatusMessage: message }),
    setIsConnected: (connected) => set({ isConnected: connected }),
    setIsConnecting: (connecting) => set({ isConnecting: connecting }),
    setError: (error) => set({ error }),
    addLog: (log) =>
        set((state) => ({ statusLogs: [log, ...state.statusLogs].slice(0, 100) })), // Keep last 100 logs
    clearLogs: () => set({ statusLogs: [] }),
    setSystemStatus: (status) => set({ systemStatus: status }),
    setDevice: (device) => set({ device }),
    setMockMode: (isMock) => set({ isMockMode: isMock }),
    alpha: "0.5",
    setAlpha: (alpha) => set({ alpha }),
    setShowHelp: (show) => set({ showHelp: show }),
}));
