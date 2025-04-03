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
        label: 'VR',
        data: data.map(d => d.an3),
        borderColor: '#8884d8',
        borderWidth: 2,
        pointRadius: 0, // No dots
        fill: false,
      },
      {
        label: 'an5',
        data: data.map(d => d.an5),
        borderColor: '#82ca9d',
        borderWidth: 2,
        pointRadius: 0, // No dots
        fill: false,
      },
      {
        label: 'an6',
        data: data.map(d => d.an6),
        borderColor: '#ff7300',
        borderWidth: 2,
        pointRadius: 0, // No dots
        fill: false,
      },
    ],
  };

  // Chart.js options configuration
  const options = {
    responsive: true,
    maintainAspectRatio: false,
    animation: false, // Disable animations for real-time performance
    scales: {
      x: {
        title: { display: true, text: 'Time' },
        ticks: {
          maxTicksLimit: 10, // Limit number of ticks for readability
          autoSkip: true,
          maxRotation: 45,
          minRotation: 45,
        },
        grid: { display: false }, // Optional: disable x-axis grid lines
      },
      y: {
        title: { display: true, text: 'Value' },
        grid: { borderDash: [3, 3] }, // Dashed grid lines like recharts
      },
    },
    plugins: {
      legend: {
        position: 'top' as const, // Match recharts verticalAlign='top'
      },
      tooltip: {
        callbacks: {
          // Custom tooltip to match your recharts version
          label: function (context: any) {
            const datasetLabel = context.dataset.label || '';
            const value = context.parsed.y.toFixed(2);
            return `${datasetLabel}: ${value}`;
          },
        },
      },
    },
  };

  return (
    <div className="w-full h-96 p-4 mb-10">
      <h2 className="text-xl font-bold mb-4">{title}</h2>
      <div>an6: {v3}</div>
      <div>an5: {v2}</div>
      <div>an3: {v1}</div>
      <div className="h-full">
        <Line data={chartData} options={options} />
      </div>
    </div>
  );
};

export default RealTimeChart;