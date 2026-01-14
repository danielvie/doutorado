// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.

import React, { useCallback, useMemo, useRef } from "react";
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

// --- Types ---

export interface DataPoint {
  time: string;
  an3: number;
  an5: number;
  an6: number;
}

interface RealTimeChartProps {
  data: DataPoint[];
  analog_scale: number;
  filter_alpha: number;
  title?: string;
}

// --- Helper Components ---

/** * specialized sub-component to display a single row
 * to keep the main render method clean.
 */
const MetricDisplay: React.FC<{
  label: string;
  value: string;
  scaledValue: string;
}> = ({ label, value, scaledValue }) => (
  <div className="flex justify-start items-center mb-1">
    <span className="w-32 text-right font-medium text-text">{label}:</span>
    <span className="w-48 text-right ml-3 font-mono text-text-shade">
      {value} <span className="text-text-shade">({scaledValue})</span>
    </span>
  </div>
);

// --- Main Component ---

const RealTimeChart: React.FC<RealTimeChartProps> = ({
  data,
  analog_scale,
  filter_alpha,
  title = "Real-time Value Monitor",
}) => {
  // Use useRef to store filter state per-component instance without triggering re-renders
  const filterState = useRef<{ [key: string]: number }>({});

  /**
   * Applies an exponential moving average (Low Pass Filter).
   * Note: This function mutates filterState.current.
   */

  const applyLowPassFilter = useCallback(
    (value: number, key: string): number => {
      // alpha = (1/10)^(filter_alpha)
      const alpha = Math.min(Math.pow(10, -filter_alpha), 1.0);

      // Initialize if key doesn't exist
      if (!(key in filterState.current)) {
        filterState.current[key] = value;
        return value;
      }

      // Formula: filtered = alpha * current + (1 - alpha) * previous
      const previous = filterState.current[key];
      const filtered = alpha * value + (1 - alpha) * previous;

      // Update state
      filterState.current[key] = filtered;
      return filtered;
    },
    [filter_alpha],
  );

  // Get the latest data point (or undefined if empty)
  const latestData = data.length > 0 ? data[data.length - 1] : null;

  // Process current display values
  // We do this inside the render body because it's fast, but only if we have data.
  const displayValues = useMemo(() => {
    if (!latestData)
      return {
        v1: "0.00",
        v2: "0.00",
        v3: "0.00",
        v1s: "0.00",
        v2s: "0.00",
        v3s: "0.00",
      };

    // Helper to calculate raw filtered and scaled filtered
    const process = (raw: number, key: string) => {
      const filtered = applyLowPassFilter(raw, key);
      const scaled = filtered * analog_scale;
      return {
        val: filtered.toFixed(2),
        sc: scaled.toFixed(2),
      };
    };

    const d1 = process(latestData.an3, "an3"); // VR
    const d2 = process(latestData.an5, "an5"); // V_C1
    const d3 = process(latestData.an6, "an6"); // V_C2

    return {
      v1: d1.val,
      v1s: d1.sc,
      v2: d2.val,
      v2s: d2.sc,
      v3: d3.val,
      v3s: d3.sc,
    };
  }, [latestData, analog_scale, applyLowPassFilter]);

  // Chart Configuration
  const chartData: ChartData<"line"> = useMemo(
    () => ({
      labels: data.map((d) => d.time),
      datasets: [
        {
          label: "an5 -> V_C1",
          data: data.map((d) => d.an5),
          borderColor: "#82ca9d",
          borderWidth: 2,
          pointRadius: 0,
          tension: 0,
        },
        {
          label: "an6 -> V_C2",
          data: data.map((d) => d.an6),
          borderColor: "#ff7300",
          borderWidth: 2,
          pointRadius: 0,
          tension: 0,
        },
        {
          label: "an3 -> VR",
          data: data.map((d) => d.an3),
          borderColor: "#8884d8",
          borderWidth: 2,
          pointRadius: 0,
          tension: 0,
        },
      ],
    }),
    [data],
  );

  const options: ChartOptions<"line"> = useMemo(() => {
    const scaleStyle = {
      ticks: { color: "#c8c8c8" }, // Text color
      grid: { color: "#555555" }, // Grid line color
      border: { color: "#444444" }, // Axis line color
    };

    return {
      animation: false,
      responsive: true,
      maintainAspectRatio: false,
      interaction: {
        mode: "index",
        intersect: false,
      },
      plugins: {
        legend: {
          position: "top" as const,
          labels: {
            color: "#c8c8c8", // Change this hex code to your desired color (e.g., white, gray)
            font: {
              size: 12, // Optional: Adjust font size
            },
          },
        },
      },
      scales: {
        x: {
          ticks: {
            ...scaleStyle,
            maxTicksLimit: 10,
          },
        }, // Optimization for high data volume
        y: scaleStyle,
      },
    };
  }, []);

  return (
    <div className="w-full h-full p-4 bg-panel-background rounded-md flex flex-col">
      <h2 className="text-xl font-bold mb-4 text-text">{title}</h2>

      {/* Digital Readout Section */}
      <div className="mb-6 px-2">
        <MetricDisplay
          label="an5 -> V_C1"
          value={displayValues.v2}
          scaledValue={displayValues.v2s}
        />
        <MetricDisplay
          label="an6 -> V_C2"
          value={displayValues.v3}
          scaledValue={displayValues.v3s}
        />
        <MetricDisplay
          label="an3 -> VR"
          value={displayValues.v1}
          scaledValue={displayValues.v1s}
        />
      </div>

      {/* Chart Section */}
      <div className="bg-gray-shade p-3 rounded-md flex-grow min-h-[250px]">
        <Line data={chartData} options={options} />
      </div>
    </div>
  );
};

export default RealTimeChart;
