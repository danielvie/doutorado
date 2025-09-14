// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.

import React from "react";
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


// Add state to store previous filtered values
let previousFilteredValues: { [key: string]: number } = {};

/**
 * Interface representing a data point for the chart
 * @property time - The timestamp for this data point
 * @property an3 - Value from analog input 3 (represents VR - voltage reference)
 * @property an5 - Value from analog input 5 (represents V_C1 - voltage across capacitor 1)
 * @property an6 - Value from analog input 6 (represents V_C2 - voltage across capacitor 2)
 */
export interface DataPoint {
  time: string;
  an3: number;
  an5: number;
  an6: number;
}

/**
 * Props for the RealTimeChart component
 * @property data - Array of DataPoint objects to display in the chart
 * @property title - Optional title for the chart (defaults to "Real-time Value Monitor")
 */
interface RealTimeChartProps {
  data: DataPoint[];
  analog_scale: number,
  filter_alpha: number,
  title?: string;
}

/**
 * A real-time chart component that displays three analog values over time
 * @param data - Array of DataPoint objects containing the time series data
 * @param title - Optional title for the chart
 * @returns React component with chart and current values display
 */
const RealTimeChart: React.FC<RealTimeChartProps> = ({
  data,
  analog_scale,
  filter_alpha,
  title = "Real-time Value Monitor",
}) => {
  // Extract latest values from the dataset for display in the digital readout
  // Empty strings are used as defaults if no data is available
  let v1 = "";
  let v2 = "";
  let v3 = "";
  if (data.length) {
    v1 = data[data.length - 1].an3.toFixed(2); // Format VR value to 2 decimal places
    v2 = data[data.length - 1].an5.toFixed(2); // Format V_C1 value to 2 decimal places
    v3 = data[data.length - 1].an6.toFixed(2); // Format V_C2 value to 2 decimal places
  }

  // Configure the Chart.js data structure for the line chart
  const chartData = {
    labels: data.map((d) => d.time), // Use timestamps as X-axis labels
    datasets: [
      {
        label: "an3 -> VR", // Voltage reference
        data: data.map((d) => d.an3),
        borderColor: "#8884d8", // Purple line
        borderWidth: 2,
        pointRadius: 0, // Hide individual data points for smoother appearance
        fill: false, // Don't fill area under the line
      },
      {
        label: "an5 -> v_c1", // Voltage across capacitor 1
        data: data.map((d) => d.an5),
        borderColor: "#82ca9d", // Green line
        borderWidth: 2,
        pointRadius: 0, // Hide individual data points for smoother appearance
        fill: false, // Don't fill area under the line
      },
      {
        label: "an6 -> v_c2", // Voltage across capacitor 2
        data: data.map((d) => d.an6),
        borderColor: "#ff7300", // Orange line
        borderWidth: 2,
        pointRadius: 0, // Hide individual data points for smoother appearance
        fill: false, // Don't fill area under the line
      },
    ],
  };
  
  function fun_process_scale(value: string): string {
    const current_value = parseFloat(value)
    if (isNaN(current_value)) {
      return value
    }
    
    return (current_value*analog_scale).toFixed(2)
  }

  function low_band_filter(value: string, key: string = 'default'): string {
    // Parse the input value to a number
    const currentValue = parseFloat(value);
    
    // alpha = (1/10)^(filter_alpha)
    const alpha: number = Math.min(Math.pow(10,-filter_alpha), 1.0)

    // Return original value if parsing failed
    if (isNaN(currentValue)) {
      return value;
    }
    
    // Initialize previous value if this is the first reading for this key
    if (!(key in previousFilteredValues)) {
      previousFilteredValues[key] = currentValue;
      return currentValue.toFixed(2);
    }
    
    // Apply exponential moving average filter
    // Formula: filtered_value = alpha * current_value + (1 - alpha) * previous_filtered_value
    const filteredValue = alpha * currentValue + (1 - alpha) * previousFilteredValues[key];
    
    // Store the filtered value for next iteration
    previousFilteredValues[key] = filteredValue;
    
    // Return the filtered value rounded to 2 decimal places
    return filteredValue.toFixed(2);
  }

  return (
    <div className="w-full h-full p-4 bg-panel rounded-md">
      <h2 className="text-xl font-bold mb-4">{title}</h2>

      <div>
        <span className="w-32 inline-block text-right">an5 {`->`} V_C1:</span>
        <span className="w-24 inline-block text-right ml-3">
          {low_band_filter(v2, 'an5')} ({fun_process_scale(low_band_filter(v2, 'an5_scaled'))})
        </span>
      </div>

      <div>
        <span className="w-32 inline-block text-right">an6 {`->`} V_C2:</span>
        <span className="w-24 inline-block text-right ml-3">
          {low_band_filter(v3, 'an6')} ({fun_process_scale(low_band_filter(v3, 'an6_scaled'))})
        </span>
      </div>

      <div>
        <span className="w-32 inline-block text-right">an3 {`->`} VR:</span>
        <span className="w-24 inline-block text-right ml-3">
          {low_band_filter(v1, 'an3')} ({fun_process_scale(low_band_filter(v1, 'an3_scaled'))})
        </span>
      </div>
      
      <div className="bg-info w-full h-[2px] my-2"></div>

      <div className="bg-gray-4 p-3 rounded-md">
        <Line data={chartData} />
      </div>

      <div className="bg-info w-full h-[2px] my-2"></div>

    </div>
  );
};

export default RealTimeChart;
