import { create } from "zustand";

export interface DataPoint {
    time: string;
    an3: number;
    an5: number;
    an6: number;
}

interface DataState {
    data: DataPoint[];
    maxPoints: number;

    // Actions
    addDataPoint: (point: DataPoint) => void;
    clearData: () => void;
    setMaxPoints: (max: number) => void;
}

export const useDataStore = create<DataState>((set) => ({
    data: [],
    maxPoints: 1000,

    addDataPoint: (point) =>
        set((state) => {
            // Keep last maxPoints points optimized for chart
            const newData = [...state.data, point];
            if (newData.length > state.maxPoints) {
                return { data: newData.slice(newData.length - state.maxPoints) };
            }
            return { data: newData };
        }),
    clearData: () => set({ data: [] }),
    setMaxPoints: (max) => set((state) => {
        // Trim data if current data exceeds new max
        const newData = state.data.length > max ? state.data.slice(state.data.length - max) : state.data;
        return { maxPoints: max, data: newData };
    }),
}));
