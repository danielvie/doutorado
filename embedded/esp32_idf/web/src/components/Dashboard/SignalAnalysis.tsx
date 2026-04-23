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
import { Maximize2, Minimize2, Activity, GripVertical } from "lucide-react";
import { PanelSize, SizeSelector } from "./SizeSelector";

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
    icon?: React.ReactNode;
}> = ({ label, value, color, icon }) => (
    <div className="bg-gray-50 p-4 rounded-lg border border-gray-200 flex flex-col gap-1 relative overflow-hidden group">
        <div className="absolute top-2 right-2 p-1 text-gray-400 group-hover:text-gray-500 transition-colors">
            {icon}
        </div>
        <span className="text-xs text-gray-600 uppercase font-bold tracking-wider">{label}</span>
        <span className="text-2xl font-semibold font-mono" style={{ color }}>{value}</span>
    </div>
);

export const SignalAnalysis: React.FC<{
    currentSize?: PanelSize;
    onSizeChange?: (size: PanelSize) => void;
    dragHandleRef?: React.RefObject<HTMLDivElement>;
}> = ({ currentSize = '2x1', onSizeChange = () => {}, dragHandleRef }) => {
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
                    label: "V_C1",
                    data: data.map((d) => d.an5),
                    borderColor: "#10b981", // Success Green
                    backgroundColor: "rgba(16, 185, 129, 0.1)",
                    borderWidth: 2,
                    pointRadius: 0,
                    tension: 0.1,
                    hidden: !showAn5,
                    fill: true,
                },
                {
                    label: "V_C2",
                    data: data.map((d) => d.an6),
                    borderColor: "#f59e0b", // Accent Amber
                    backgroundColor: "rgba(245, 158, 11, 0.1)",
                    borderWidth: 2,
                    pointRadius: 0,
                    tension: 0.1,
                    hidden: !showAn6,
                    fill: true,
                },
                {
                    label: "VR",
                    data: data.map((d) => d.an3),
                    borderColor: "#2563eb", // Primary Blue
                    backgroundColor: "rgba(37, 99, 235, 0.1)",
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
                display: false,
            },
            tooltip: {
                backgroundColor: 'rgba(255, 255, 255, 0.9)',
                titleColor: '#4b5563',
                titleFont: { family: 'Inter', weight: 'bold' },
                bodyColor: '#111827',
                bodyFont: { family: 'JetBrains Mono' },
                borderColor: '#e5e7eb',
                borderWidth: 1,
                padding: 12,
                cornerRadius: 8,
            }
        },
        scales: {
            x: {
                ticks: { color: "#6b7280", maxTicksLimit: 12, font: { size: 11, family: 'JetBrains Mono' } },
                grid: { color: "#e5e7eb", tickLength: 0 },
                border: { display: false }
            },
            y: {
                ticks: { color: "#6b7280", font: { size: 11, family: 'JetBrains Mono' } },
                grid: { color: "#e5e7eb" },
                border: { display: false }
            },
        },
    }), []);

    return (
        <div className={`panel p-6 flex flex-col transition-all duration-300 ${isExpanded ? 'fixed inset-4 z-50 h-auto' : 'h-full min-h-[600px]'}`}>
            {/* Header */}
            <div className="flex justify-between items-center mb-6">
                <div className="flex items-center gap-1.5">
                    <div ref={dragHandleRef} className="p-1.5 text-gray-400 hover:text-gray-600 cursor-grab active:cursor-grabbing transition-colors">
                        <GripVertical size={20} />
                    </div>
                    <SizeSelector currentSize={currentSize} onSizeChange={onSizeChange} />
                    <div>
                        <h2 className="text-xl font-bold text-gray-900">Signal Analysis</h2>
                        <div className="flex items-center gap-2">
                             <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></div>
                             <span className="text-xs font-bold text-gray-600 uppercase tracking-widest">Real-time Telemetry</span>
                        </div>
                    </div>
                </div>
                <div className="flex gap-2 items-center">
                    <button onClick={() => setIsExpanded(!isExpanded)} className="p-2 bg-gray-50 border border-gray-200 hover:bg-gray-100 rounded-md text-gray-600 transition-colors">
                        {isExpanded ? <Minimize2 size={18} /> : <Maximize2 size={18} />}
                    </button>
                </div>
            </div>

            {/* Metrics */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
                <MetricDisplay label="V_C1 Node" value={latestData.an5.toFixed(3)} color="#10b981" icon={<Activity size={20} />} />
                <MetricDisplay label="V_C2 Node" value={latestData.an6.toFixed(3)} color="#f59e0b" icon={<Activity size={20} />} />
                <MetricDisplay label="VR Feedback" value={latestData.an3.toFixed(3)} color="#2563eb" icon={<Activity size={20} />} />
            </div>

            {/* Chart Area */}
            <div className="flex-1 min-h-0 bg-white rounded-lg border border-gray-200 relative overflow-hidden p-4">
                <Line data={chartData} options={options} />
            </div>

            {/* Controls */}
            <div className="flex flex-wrap gap-6 mt-6 justify-center items-center">
                <label className="flex items-center gap-2 text-sm text-gray-700 select-none cursor-pointer hover:text-gray-900 transition-colors">
                    <input type="checkbox" checked={showAn5} onChange={(e) => setShowAn5(e.target.checked)} className="rounded text-green-500 focus:ring-green-500" />
                    <span className="font-bold uppercase text-xs">V_C1</span>
                </label>
                <label className="flex items-center gap-2 text-sm text-gray-700 select-none cursor-pointer hover:text-gray-900 transition-colors">
                    <input type="checkbox" checked={showAn6} onChange={(e) => setShowAn6(e.target.checked)} className="rounded text-amber-500 focus:ring-amber-500" />
                    <span className="font-bold uppercase text-xs">V_C2</span>
                </label>
                <label className="flex items-center gap-2 text-sm text-gray-700 select-none cursor-pointer hover:text-gray-900 transition-colors">
                    <input type="checkbox" checked={showAn3} onChange={(e) => setShowAn3(e.target.checked)} className="rounded text-blue-600 focus:ring-blue-600" />
                    <span className="font-bold uppercase text-xs">VR REF</span>
                </label>
            </div>
        </div>
    );
}
