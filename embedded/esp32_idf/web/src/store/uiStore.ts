import { create } from "zustand";

const LOCK_STORAGE_KEY = "dashboard-layout-locked";

interface UiState {
    // Mock mode generates synthetic telemetry without a device; commands are
    // still allowed so panes can be exercised offline.
    isMocking: boolean;
    layoutLocked: boolean;

    setIsMocking: (mocking: boolean) => void;
    setLayoutLocked: (locked: boolean) => void;
}

export const useUiStore = create<UiState>((set) => ({
    isMocking: false,
    layoutLocked: localStorage.getItem(LOCK_STORAGE_KEY) !== "false",

    setIsMocking: (mocking) => set({ isMocking: mocking }),
    setLayoutLocked: (locked) => {
        localStorage.setItem(LOCK_STORAGE_KEY, String(locked));
        set({ layoutLocked: locked });
    },
}));
