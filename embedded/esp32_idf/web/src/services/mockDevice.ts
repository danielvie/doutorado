import { useUiStore } from "../store/uiStore";
import { useBleStore } from "../store/bleStore";
import { useDeviceStore } from "../store/deviceStore";
import type { AnalogStatusSnapshot } from "../store/deviceStore";

// Mock-mode device status emulator. While Mock is on it plays the role of
// the firmware control loop: every signal cycle the loop takes one analog
// snapshot through the age gate, so age_used_count grows cycle by cycle and
// age_used_max_us tracks the worst accepted age (always within budget,
// mirroring the firmware invariant age_used_max_us <= control_max_age_us).
const TICK_MS = 100;
const CYCLE_MS = 10; // emulated signal cycle period → cycles consumed per tick
const MIN_SNAPSHOT_AGE_US = 120;
const CONTROL_MAX_AGE_US = 500;

let interval: ReturnType<typeof setInterval> | null = null;

const startMockStatus = () => {
    let t = 0;
    let seq = 0;
    let currentCycles = 0;
    let ageUsedCount = 0;
    let ageUsedMaxUs = 0;
    let samplesRead = 0;

    const tick = () => {
        t += TICK_MS / 1000;
        const cyclesThisTick = TICK_MS / CYCLE_MS;

        // One snapshot accepted per cycle; ages sit near the floor with
        // jitter and the occasional excursion toward (but under) the budget.
        for (let i = 0; i < cyclesThisTick; i++) {
            const spike = Math.random() < 0.02;
            const age = spike
                ? CONTROL_MAX_AGE_US - 30 - Math.floor(Math.random() * 60)
                : MIN_SNAPSHOT_AGE_US + Math.floor(Math.random() * 180);
            ageUsedCount += 1;
            ageUsedMaxUs = Math.max(ageUsedMaxUs, age);
        }

        seq += cyclesThisTick;
        currentCycles = (currentCycles + cyclesThisTick) % 100;
        samplesRead += cyclesThisTick * 3;

        const rawAn3 = Math.round(2048 + Math.sin(t) * 1000);
        const rawAn5 = Math.round(2048 + Math.sin(t * 2 + Math.PI / 4) * 500);
        const rawAn6 = Math.round(2048 + Math.sin(t * 0.5) * 1500);
        const toCal = (raw: number) => (raw / 4095) * 3.3;

        const alpha = parseFloat(useBleStore.getState().alpha);
        const analog: AnalogStatusSnapshot = {
            seq,
            valid: true,
            ageUs:
                MIN_SNAPSHOT_AGE_US + Math.floor(Math.random() * 180),
            controlMaxAgeUs: CONTROL_MAX_AGE_US,
            minSnapshotAgeUs: MIN_SNAPSHOT_AGE_US,
            acquisitionMode: 1,
            lutReady: true,
            targetTriplesPerCycle: 4,
            measuredTriplesPerSecond:
                4000 + Math.floor(Math.random() * 40) - 20,
            rawAn3,
            rawAn5,
            rawAn6,
            calAn3: toCal(rawAn3),
            calAn5: toCal(rawAn5),
            calAn6: toCal(rawAn6),
            latencyMinUs: 105,
            latencyAvgUs: 180 + Math.floor(Math.random() * 10),
            latencyP95Us: 240 + Math.floor(Math.random() * 15),
            latencyMaxUs: 480,
            ageUsedMaxUs,
            ageUsedCount,
            missCount: 0,
            consecutiveMisses: 0,
            overflowCount: 0,
            samplesRead,
            samplesRejected: 0,
            channelOrderAnomalies: 0,
            partialTriples: 0,
            frameDrops: 0,
            poolFlushes: 0,
            frameTsFallbacks: 0,
            faultCode: 0,
        };

        useDeviceStore.getState().applyStatus({
            signalState: "RUNNING",
            engine: "DMA",
            controlState: "ON",
            bleReadState: "READING",
            activeSet: "A",
            ledMode: "NORMAL",
            alpha: Number.isFinite(alpha) ? alpha : 0.5,
            matrixAValid: true,
            matrixBValid: false,
            currentCycles,
            totalCycles: 100,
            monitorMs: useBleStore.getState().monitorPeriodMs,
            deadTimeUs: 2,
            deadTimeTailOverheadCycles: 24,
            edgeOverheadUpCycles: 0,
            edgeOverheadDownCycles: 24,
            adcMinUs: 105,
            adcMaxUs: 480,
            adcAvgUs: 180,
            congested: false,
            analogValid: true,
            analogFaultCode: 0,
            analog,
        });
    };

    tick();
    interval = setInterval(tick, TICK_MS);
};

const stopMockStatus = () => {
    if (interval) {
        clearInterval(interval);
        interval = null;
    }
    // Only wipe the emulated state when there is no real device behind it.
    if (!useBleStore.getState().isConnected) {
        useDeviceStore.getState().resetStatus();
    }
};

useUiStore.subscribe((state, prevState) => {
    if (state.isMocking && !prevState.isMocking) startMockStatus();
    if (!state.isMocking && prevState.isMocking) stopMockStatus();
});
