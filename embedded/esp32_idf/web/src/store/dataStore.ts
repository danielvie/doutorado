import { create } from "zustand";

export interface DataPoint {
    time: string;
    an3: number;
    an5: number;
    an6: number;
}

interface DataState {
    data: DataPoint[];

    // Actions
    addDataPoint: (point: DataPoint) => void;
    clearData: () => void;
}

export const useDataStore = create<DataState>((set) => ({
    data: [],

    addDataPoint: (point) =>
        set((state) => {
            // Keep last 1000 points optimized for chart
            const newData = [...state.data, point];
            if (newData.length > 1000) {
                return { data: newData.slice(newData.length - 1000) };
            }
            return { data: newData };
        }),
    clearData: () => set({ data: [] }),
}));
