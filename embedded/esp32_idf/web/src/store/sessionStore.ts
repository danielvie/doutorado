import { create } from "zustand";
import { useDataStore, type DataPoint } from "./dataStore";

// Session recording: captures every telemetry sample and every sent command
// with wall-clock timestamps so an experiment run can be exported and
// reproduced (D2).

export interface RecordedCommand {
    at: number; // epoch ms
    name: string;
    payload: Record<string, unknown>;
}

export interface RecordedSample {
    at: number; // epoch ms
    time: string; // device-relative time label as charted
    an3: number; // VR
    an5: number; // V_C1
    an6: number; // V_C2
}

interface SessionState {
    recording: boolean;
    startedAt: number | null;
    stoppedAt: number | null;
    samples: RecordedSample[];
    commands: RecordedCommand[];

    startRecording: () => void;
    stopRecording: () => void;
    clearSession: () => void;
    recordCommand: (name: string, payload: Record<string, unknown>) => void;
    recordSample: (point: DataPoint) => void;
}

export const useSessionStore = create<SessionState>((set, get) => ({
    recording: false,
    startedAt: null,
    stoppedAt: null,
    samples: [],
    commands: [],

    startRecording: () =>
        set({
            recording: true,
            startedAt: Date.now(),
            stoppedAt: null,
            samples: [],
            commands: [],
        }),
    stopRecording: () => set({ recording: false, stoppedAt: Date.now() }),
    clearSession: () =>
        set({
            recording: false,
            startedAt: null,
            stoppedAt: null,
            samples: [],
            commands: [],
        }),
    recordCommand: (name, payload) => {
        if (!get().recording) return;
        set((state) => ({
            commands: [...state.commands, { at: Date.now(), name, payload }],
        }));
    },
    recordSample: (point) => {
        if (!get().recording) return;
        set((state) => ({
            samples: [...state.samples, { at: Date.now(), ...point }],
        }));
    },
}));

// Capture chart telemetry as it arrives, regardless of which component is
// mounted. dataStore appends one point per packet, so diffing the tail of
// consecutive states is enough.
useDataStore.subscribe((state, prevState) => {
    if (state.data === prevState.data) return;
    const last = state.data[state.data.length - 1];
    const prevLast = prevState.data[prevState.data.length - 1];
    if (last && last !== prevLast) {
        useSessionStore.getState().recordSample(last);
    }
});

const downloadBlob = (content: string, filename: string, mime: string) => {
    const blob = new Blob([content], { type: mime });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = filename;
    anchor.click();
    URL.revokeObjectURL(url);
};

const sessionStamp = (startedAt: number | null) =>
    new Date(startedAt ?? Date.now())
        .toISOString()
        .replace(/[:.]/g, "-")
        .slice(0, 19);

export const exportSessionCsv = () => {
    const { samples, commands, startedAt } = useSessionStore.getState();
    const rows: string[] = ["epoch_ms,type,time,v_c1_an5,v_c2_an6,vr_an3,command,payload"];
    const events = [
        ...samples.map((s) => ({ at: s.at, sample: s, command: null as RecordedCommand | null })),
        ...commands.map((c) => ({ at: c.at, sample: null as RecordedSample | null, command: c })),
    ].sort((a, b) => a.at - b.at);

    for (const event of events) {
        if (event.sample) {
            const s = event.sample;
            rows.push(`${s.at},telemetry,${s.time},${s.an5},${s.an6},${s.an3},,`);
        } else if (event.command) {
            const c = event.command;
            const payload = JSON.stringify(c.payload).replace(/"/g, '""');
            rows.push(`${c.at},command,,,,,${c.name},"${payload}"`);
        }
    }
    downloadBlob(rows.join("\n"), `session-${sessionStamp(startedAt)}.csv`, "text/csv");
};

export const exportSessionJson = () => {
    const { samples, commands, startedAt, stoppedAt } = useSessionStore.getState();
    const session = {
        started_at: startedAt ? new Date(startedAt).toISOString() : null,
        stopped_at: stoppedAt ? new Date(stoppedAt).toISOString() : null,
        channel_map: { an5: "V_C1", an6: "V_C2", an3: "VR" },
        commands,
        samples,
    };
    downloadBlob(
        JSON.stringify(session, null, 2),
        `session-${sessionStamp(startedAt)}.json`,
        "application/json",
    );
};
