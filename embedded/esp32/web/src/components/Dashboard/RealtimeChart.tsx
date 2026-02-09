import React, { useMemo, useState } from "react";
import { Line } from "react-chartjs-2";
import {
    CategoryScale,
    Chart as ChartJS,
    Filler,
    Legend,
    LinearScale,
    LineElement,
    PointElement,
    Title,
    Tooltip,
    ChartOptions,
    ChartData,
} from "chart.js";
import { useDataStore } from "../../store/dataStore";
import { Maximize2, Minimize2, Activity } from "lucide-react";

// Register Chart.js components
ChartJS.register(
    LineElement,
    PointElement,
    LinearScale,
    CategoryScale,
    Title,
    Tooltip,
    Legend,
    Filler,
);

const MetricDisplay: React.FC<{
    label: string;
    value: string;
    color: string;
}> = ({ label, value, color }) => (
    <div className="flex flex-col bg-gray-900 border border-gray-800 rounded-lg p-3 min-w-[120px]">
        <span className="text-xs text-gray-500 uppercase font-bold mb-1">{label}</span>
        <span className="text-xl font-mono" style={{ color }}>{value}</span>
    </div>
);

export const RealtimeChart = () => {
    const { data } = useDataStore();
    const [isExpanded, setIsExpanded] = useState(false);

    // Config state
    const [showAn3, setShowAn3] = useState(true);
    const [showAn5, setShowAn5] = useState(true);
    const [showAn6, setShowAn6] = useState(true);

    const latestData = data.length > 0 ? data[data.length - 1] : { an3: 0, an5: 0, an6: 0 };

    const chartData: ChartData<"line"> = useMemo(
        () => ({
            labels: data.map((d) => d.time),
            datasets: [
                {
                    label: "an5 (V_C1)",
                    data: data.map((d) => d.an5),
                    borderColor: "#10b981", // Emerald 500
                    backgroundColor: "rgba(16, 185, 129, 0.1)",
                    borderWidth: 2,
                    pointRadius: 0,
                    tension: 0.1,
                    hidden: !showAn5,
                    fill: true,
                },
                {
                    label: "an6 (V_C2)",
                    data: data.map((d) => d.an6),
                    borderColor: "#f59e0b", // Amber 500
                    backgroundColor: "rgba(245, 158, 11, 0.1)",
                    borderWidth: 2,
                    pointRadius: 0,
                    tension: 0.1,
                    hidden: !showAn6,
                    fill: true,
                },
                {
                    label: "an3 (VR)",
                    data: data.map((d) => d.an3),
                    borderColor: "#8b5cf6", // Violet 500
                    backgroundColor: "rgba(139, 92, 246, 0.1)",
                    borderWidth: 2,
                    pointRadius: 0,
                    tension: 0.1,
                    hidden: !showAn3,
                    fill: true,
                },
            ],
        }),
        [data, showAn3, showAn5, showAn6],
    );

    const options: ChartOptions<"line"> = useMemo(() => ({
        animation: false,
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
            mode: "index",
            intersect: false,
        },
        plugins: {
            legend: {
                display: false, // Custom legend below
            },
            tooltip: {
                backgroundColor: 'rgba(17, 24, 39, 0.9)',
                titleColor: '#9ca3af',
                bodyColor: '#f3f4f6',
                borderColor: '#374151',
                borderWidth: 1,
            }
        },
        scales: {
            x: {
                ticks: { color: "#6b7280", maxTicksLimit: 8 },
                grid: { color: "#374151", tickLength: 0 },
                border: { display: false }
            },
            y: {
                ticks: { color: "#6b7280" },
                grid: { color: "#374151" },
                border: { display: false }
            },
        },
    }), []);

    return (
        <div className={`bg-gray-900 border border-gray-800 rounded-xl p-4 flex flex-col shadow-xl transition-all duration-300 ${isExpanded ? 'fixed inset-4 z-50 h-auto' : 'h-full min-h-[500px]'}`}>
            {/* Header */}
            <div className="flex justify-between items-center mb-4">
                <div className="flex items-center gap-2">
                    <Activity className="w-5 h-5 text-blue-400" />
                    <h2 className="font-bold text-lg text-gray-200">Live Monitor</h2>
                </div>
                <div className="flex gap-2">
                    <button onClick={() => setIsExpanded(!isExpanded)} className="p-2 hover:bg-gray-800 rounded-lg text-gray-400 hover:text-white transition-colors">
                        {isExpanded ? <Minimize2 size={18} /> : <Maximize2 size={18} />}
                    </button>
                </div>
            </div>

            {/* Metrics */}
            <div className="grid grid-cols-3 gap-2 mb-4">
                <MetricDisplay label="an5 (V_C1)" value={latestData.an5.toFixed(2)} color="#10b981" />
                <MetricDisplay label="an6 (V_C2)" value={latestData.an6.toFixed(2)} color="#f59e0b" />
                <MetricDisplay label="an3 (VR)" value={latestData.an3.toFixed(2)} color="#8b5cf6" />
            </div>

            {/* Chart Area */}
            <div className="flex-1 min-h-0 bg-gray-950/50 rounded-lg p-2 border border-gray-800/50 relative">
                <Line data={chartData} options={options} />
            </div>

            {/* Controls */}
            <div className="flex gap-4 mt-4 justify-center">
                <label className="flex items-center gap-2 text-sm text-gray-400 cursor-pointer hover:text-white select-none">
                    <input type="checkbox" checked={showAn5} onChange={(e) => setShowAn5(e.target.checked)} className="accent-emerald-500" />
                    <span className="w-3 h-3 rounded-full bg-emerald-500"></span>
                    V_C1
                </label>
                <label className="flex items-center gap-2 text-sm text-gray-400 cursor-pointer hover:text-white select-none">
                    <input type="checkbox" checked={showAn6} onChange={(e) => setShowAn6(e.target.checked)} className="accent-amber-500" />
                    <span className="w-3 h-3 rounded-full bg-amber-500"></span>
                    V_C2
                </label>
                <label className="flex items-center gap-2 text-sm text-gray-400 cursor-pointer hover:text-white select-none">
                    <input type="checkbox" checked={showAn3} onChange={(e) => setShowAn3(e.target.checked)} className="accent-violet-500" />
                    <span className="w-3 h-3 rounded-full bg-violet-500"></span>
                    VR
                </label>
            </div>
        </div>
    );
}
