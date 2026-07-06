import { create } from "zustand";
import { useBleStore } from "./bleStore";

// Structured device state decoded from the firmware's status packet.
// "UNKNOWN" means no status has been received yet (or since reconnect).

// Full decode of the AnalogStatus proto message.
export interface AnalogStatusSnapshot {
    seq: number;
    valid: boolean;
    ageUs: number;
    controlMaxAgeUs: number;
    minSnapshotAgeUs: number;
    acquisitionMode: number;
    lutReady: boolean;
    targetTriplesPerCycle: number;
    measuredTriplesPerSecond: number;
    rawAn3: number;
    rawAn5: number;
    rawAn6: number;
    calAn3: number;
    calAn5: number;
    calAn6: number;
    latencyMinUs: number;
    latencyAvgUs: number;
    latencyP95Us: number;
    latencyMaxUs: number;
    ageUsedMaxUs: number;
    ageUsedCount: number;
    missCount: number;
    consecutiveMisses: number;
    overflowCount: number;
    samplesRead: number;
    samplesRejected: number;
    channelOrderAnomalies: number;
    partialTriples: number;
    frameDrops: number;
    poolFlushes: number;
    frameTsFallbacks: number;
    faultCode: number;
}

export interface DeviceStatusSnapshot {
    signalState: "RUNNING" | "IDLE" | "UNKNOWN";
    engine: "CPU" | "DMA" | "UNKNOWN";
    controlState: "ON" | "OFF" | "UNKNOWN";
    bleReadState: string;
    activeSet: string;
    ledMode: string;
    alpha: number | null;
    matrixAValid: boolean;
    matrixBValid: boolean;
    currentCycles: number;
    totalCycles: number;
    monitorMs: number;
    deadTimeUs: number;
    deadTimeTailOverheadCycles: number;
    edgeOverheadUpCycles: number;
    edgeOverheadDownCycles: number;
    adcMinUs: number;
    adcMaxUs: number;
    adcAvgUs: number;
    congested: boolean;
    analogValid: boolean | null;
    analogFaultCode: number;
    analog: AnalogStatusSnapshot | null;
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
    activeSet: "UNKNOWN",
    ledMode: "UNKNOWN",
    alpha: null,
    matrixAValid: false,
    matrixBValid: false,
    currentCycles: 0,
    totalCycles: 0,
    monitorMs: 0,
    deadTimeUs: 0,
    deadTimeTailOverheadCycles: 0,
    edgeOverheadUpCycles: 0,
    edgeOverheadDownCycles: 0,
    adcMinUs: 0,
    adcMaxUs: 0,
    adcAvgUs: 0,
    congested: false,
    analogValid: null,
    analogFaultCode: 0,
    analog: null,
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
