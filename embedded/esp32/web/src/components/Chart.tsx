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

export interface DataPoint {
  time: string;
  an3: number;
  an5: number;
  an6: number;
}

interface RealTimeChartProps {
  data: DataPoint[];
  title?: string;
}

const RealTimeChart: React.FC<RealTimeChartProps> = ({
  data,
  title = "Real-time Value Monitor",
}) => {
  // Extract latest values for display
  let v1 = '';
  let v2 = '';
  let v3 = '';
  if (data.length) {
    v1 = data[data.length - 1].an3.toFixed(2);
    v2 = data[data.length - 1].an5.toFixed(2);
    v3 = data[data.length - 1].an6.toFixed(2);
  }

  // Chart.js data configuration
  const chartData = {
    labels: data.map(d => d.time), // X-axis labels
    datasets: [
      {
        label: 'an3 -> VR',
        data: data.map(d => d.an3),
        borderColor: '#8884d8',
        borderWidth: 2,
        pointRadius: 0, // No dots
        fill: false,
      },
      {
        label: 'an5 -> v_c1',
        data: data.map(d => d.an5),
        borderColor: '#82ca9d',
        borderWidth: 2,
        pointRadius: 0, // No dots
        fill: false,
      },
      {
        label: 'an6 -> v_c2',
        data: data.map(d => d.an6),
        borderColor: '#ff7300',
        borderWidth: 2,
        pointRadius: 0, // No dots
        fill: false,
      },
    ],
  };

  return (
    <div className="w-full h-96 p-4 mb-10">
      <h2 className="text-xl font-bold mb-4">{title}</h2>
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
      <div className="h-full">
        <Line data={chartData}/>
      </div>
    </div>
  );
};

export default RealTimeChart;