import { create } from "zustand";
import { useBleStore } from "./bleStore";

// Structured device state decoded from the firmware's status packet.
// "UNKNOWN" means no status has been received yet (or since reconnect).
export interface DeviceStatusSnapshot {
    signalState: "RUNNING" | "IDLE" | "UNKNOWN";
    engine: "CPU" | "DMA" | "UNKNOWN";
    controlState: "ON" | "OFF" | "UNKNOWN";
    bleReadState: string;
    alpha: number | null;
    currentCycles: number;
    totalCycles: number;
    deadTimeUs: number;
    congested: boolean;
    analogValid: boolean | null;
    analogFaultCode: number;
}

interface DeviceState extends DeviceStatusSnapshot {
    lastStatusAt: number | null;

    applyStatus: (snapshot: Partial<DeviceStatusSnapshot>) => void;
    resetStatus: () => void;
}

const INITIAL: DeviceStatusSnapshot = {
    signalState: "UNKNOWN",
    engine: "UNKNOWN",
    controlState: "UNKNOWN",
    bleReadState: "UNKNOWN",
    alpha: null,
    currentCycles: 0,
    totalCycles: 0,
    deadTimeUs: 0,
    congested: false,
    analogValid: null,
    analogFaultCode: 0,
};

export const useDeviceStore = create<DeviceState>((set) => ({
    ...INITIAL,
    lastStatusAt: null,

    applyStatus: (snapshot) =>
        set({ ...snapshot, lastStatusAt: Date.now() }),
    resetStatus: () => set({ ...INITIAL, lastStatusAt: null }),
}));

// The device state is only trustworthy while connected; drop back to UNKNOWN
// on disconnect instead of showing the last known state as if it were live.
useBleStore.subscribe((state, prevState) => {
    if (prevState.isConnected && !state.isConnected) {
        useDeviceStore.getState().resetStatus();
    }
});
