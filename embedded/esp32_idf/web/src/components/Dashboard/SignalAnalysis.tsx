import React, { useEffect, useMemo, useState } from "react";
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
import { Activity, BrushCleaning } from "lucide-react";
import { PanelSize } from "./SizeSelector";
import { DashboardItem } from "./DashboardItem";

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
  <div className="bg-gray-50 p-2.5 rounded-lg border border-gray-200 flex flex-col gap-0.5 relative overflow-hidden group">
    <div className="absolute top-2 right-2 p-1 text-gray-400 group-hover:text-gray-500 transition-colors">
      {icon}
    </div>
    <span className="text-xs text-gray-600 uppercase font-bold tracking-wider">
      {label}
    </span>
    <span className="text-2xl font-semibold font-mono" style={{ color }}>
      {value}
    </span>
  </div>
);

export const SignalAnalysis: React.FC<{
  id: string;
  instanceId: string;
  currentSize?: PanelSize;
  onSizeChange?: (size: PanelSize) => void;
}> = ({ id, instanceId, currentSize = "2x1", onSizeChange = () => {} }) => {
  const data = useDataStore((s) => s.data);
  const clearData = useDataStore((s) => s.clearData);
  const maxPoints = useDataStore((s) => s.maxPoints);
  const setMaxPoints = useDataStore((s) => s.setMaxPoints);
  const [localMaxPoints, setLocalMaxPoints] = useState(maxPoints);

  // Sync local state if store changes
  useEffect(() => {
    setLocalMaxPoints(maxPoints);
  }, [maxPoints]);

  const handleSetMaxPoints = () => {
    setMaxPoints(Math.max(10, localMaxPoints));
  };


  // Config state
  const [showAn3, setShowAn3] = useState(true);
  const [showAn5, setShowAn5] = useState(true);
  const [showAn6, setShowAn6] = useState(true);

  const latestData =
    data.length > 0 ? data[data.length - 1] : { an3: 0, an5: 0, an6: 0 };

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

  const options: ChartOptions<"line"> = useMemo(
    () => ({
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
          backgroundColor: "rgba(255, 255, 255, 0.9)",
          titleColor: "#4b5563",
          titleFont: { family: "Inter", weight: "bold" },
          bodyColor: "#111827",
          bodyFont: { family: "JetBrains Mono" },
          borderColor: "#e5e7eb",
          borderWidth: 1,
          padding: 12,
          cornerRadius: 8,
        },
      },
      scales: {
        x: {
          ticks: {
            color: "#6b7280",
            maxTicksLimit: 12,
            font: { size: 11, family: "JetBrains Mono" },
          },
          grid: { color: "#e5e7eb", tickLength: 0 },
          border: { display: false },
        },
        y: {
          ticks: {
            color: "#6b7280",
            font: { size: 11, family: "JetBrains Mono" },
          },
          grid: { color: "#e5e7eb" },
          border: { display: false },
        },
      },
    }),
    [],
  );

  return (
    <DashboardItem
      id={id}
      instanceId={instanceId}
      title="Signal Analysis"
      currentSize={currentSize}
      onSizeChange={onSizeChange}
      expandable={true}
    >
      {/* Metrics */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 shrink-0">
          <MetricDisplay
            label="V_C1 Node"
            value={latestData.an5.toFixed(3)}
            color="#10b981"
            icon={<Activity size={20} />}
          />
          <MetricDisplay
            label="V_C2 Node"
            value={latestData.an6.toFixed(3)}
            color="#f59e0b"
            icon={<Activity size={20} />}
          />
          <MetricDisplay
            label="VR Feedback"
            value={latestData.an3.toFixed(3)}
            color="#2563eb"
            icon={<Activity size={20} />}
          />
        </div>

        {/* Chart Area */}
        <div className="bg-white rounded-lg border border-gray-200 relative overflow-hidden p-2 flex-1 min-h-0">
          <Line key={maxPoints} data={chartData} options={options} />
        </div>

        {/* Controls */}
        <div className="flex flex-wrap gap-4 justify-center items-center shrink-0">
          <button
            onClick={() => clearData()}
            className="p-1.5 bg-gray-50 border border-gray-200 hover:bg-red-50 hover:border-red-200 hover:text-red-600 rounded-md text-gray-500 transition-colors mr-2"
            title="Clear data"
          >
            <BrushCleaning size={16} />
          </button>
          <label className="flex items-center gap-2 text-sm text-gray-700 select-none cursor-pointer hover:text-gray-900 transition-colors">
            <input
              type="checkbox"
              checked={showAn5}
              onChange={(e) => setShowAn5(e.target.checked)}
              className="rounded text-green-500 focus:ring-green-500"
            />
            <span className="font-bold uppercase text-xs">V_C1</span>
          </label>
          <label className="flex items-center gap-2 text-sm text-gray-700 select-none cursor-pointer hover:text-gray-900 transition-colors">
            <input
              type="checkbox"
              checked={showAn6}
              onChange={(e) => setShowAn6(e.target.checked)}
              className="rounded text-amber-500 focus:ring-amber-500"
            />
            <span className="font-bold uppercase text-xs">V_C2</span>
          </label>
          <label className="flex items-center gap-2 text-sm text-gray-700 select-none cursor-pointer hover:text-gray-900 transition-colors">
            <input
              type="checkbox"
              checked={showAn3}
              onChange={(e) => setShowAn3(e.target.checked)}
              className="rounded text-blue-600 focus:ring-blue-600"
            />
            <span className="font-bold uppercase text-xs">VR REF</span>
          </label>

          <div className="flex items-center gap-1.5 px-2 py-1 bg-gray-50 border border-gray-200 rounded-md ml-auto">
            <span className="text-[10px] font-bold text-gray-500 uppercase tracking-wider">Window</span>
            <input
              type="number"
              value={localMaxPoints}
              step={10}
              onChange={(e) => setLocalMaxPoints(parseInt(e.target.value) || 0)}
              className="w-24 px-1.5 py-0.5 text-xs font-mono bg-white border border-gray-300 rounded focus:ring-1 focus:ring-blue-500 outline-none transition-all text-center"
              title="Maximum data points to display"
            />
            <button
              onClick={handleSetMaxPoints}
              className="px-2 py-0.5 text-[10px] font-bold bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors uppercase tracking-tighter"
            >
              Set
            </button>
          </div>
        </div>
    </DashboardItem>
  );
};
