import React from 'react';
import { Line } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  LineElement,
  PointElement,
  LinearScale,
  CategoryScale,
  Title,
  Tooltip,
  Legend,
  Filler,
} from 'chart.js';

// Register Chart.js components
ChartJS.register(LineElement, PointElement, LinearScale, CategoryScale, Title, Tooltip, Legend, Filler);

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
  title = "Real-time Value Monitor",
}) => {
  // Extract latest values from the dataset for display in the digital readout
  // Empty strings are used as defaults if no data is available
  let v1 = '';
  let v2 = '';
  let v3 = '';
  if (data.length) {
    v1 = data[data.length - 1].an3.toFixed(2); // Format VR value to 2 decimal places
    v2 = data[data.length - 1].an5.toFixed(2); // Format V_C1 value to 2 decimal places
    v3 = data[data.length - 1].an6.toFixed(2); // Format V_C2 value to 2 decimal places
  }

  // Configure the Chart.js data structure for the line chart
  const chartData = {
    labels: data.map(d => d.time), // Use timestamps as X-axis labels
    datasets: [
      {
        label: 'an3 -> VR',  // Voltage reference
        data: data.map(d => d.an3),
        borderColor: '#8884d8', // Purple line
        borderWidth: 2,
        pointRadius: 0, // Hide individual data points for smoother appearance
        fill: false,    // Don't fill area under the line
      },
      {
        label: 'an5 -> v_c1',  // Voltage across capacitor 1
        data: data.map(d => d.an5),
        borderColor: '#82ca9d', // Green line
        borderWidth: 2,
        pointRadius: 0, // Hide individual data points for smoother appearance
        fill: false,    // Don't fill area under the line
      },
      {
        label: 'an6 -> v_c2',  // Voltage across capacitor 2
        data: data.map(d => d.an6),
        borderColor: '#ff7300', // Orange line
        borderWidth: 2,
        pointRadius: 0, // Hide individual data points for smoother appearance
        fill: false,    // Don't fill area under the line
      },
    ],
  };

  return (
    <div className="w-full h-96 p-4 mb-10">
      {/* Chart title */}
      <h2 className="text-xl font-bold mb-4">{title}</h2>
      
      {/* Digital readouts for the latest values of each measurement */}
      <div>
        <span className='w-28 inline-block text-right'>an5 {`->`} V_C1:</span>
        <span className='w-12 inline-block text-right ml-3'>{v2}</span>
      </div>
      <div>
        <span className='w-28 inline-block text-right'>an6 {`->`} V_C2:</span>
        <span className='w-12 inline-block text-right ml-3'>{v3}</span>
      </div>
      <div>
        <span className='w-28 inline-block text-right'>an3 {`->`} VR:</span>
        <span className='w-12 inline-block text-right ml-3'>{v1}</span>
      </div>
      
      {/* The actual chart component */}
      <div className="h-full">
        <Line data={chartData}/>
      </div>
    </div>
  );
};

export default RealTimeChart;