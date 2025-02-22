import React from 'react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer
} from 'recharts';

interface DataPoint {
  time: string;
  value1: number;
  value2: number;
  value3: number;
}

interface RealTimeChartProps {
  data: DataPoint[];
  title?: string;
}

const RealTimeChart: React.FC<RealTimeChartProps> = ({ 
  data,
  title = "Real-time Value Monitor"
}) => {
  return (
    <div className="w-full h-96 p-4">
      <h2 className="text-xl font-bold mb-4">{title}</h2>
      <ResponsiveContainer width="100%" height="100%">
        <LineChart data={data}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis 
            dataKey="time"
            interval="preserveStartEnd"
            angle={-45}
            textAnchor="end"
          />
          <YAxis />
          <Tooltip />
          <Legend />
          <Line 
            type="monotone" 
            dataKey="an3" 
            name="an3"
            stroke="#8884d8" 
            strokeWidth={2}
            dot={false}
          />
          <Line 
            type="monotone" 
            dataKey="an5" 
            name="an5"
            stroke="#82ca9d" 
            strokeWidth={2}
            dot={false}
          />
          <Line 
            type="monotone" 
            dataKey="an6" 
            name="an6"
            stroke="#ff7300" 
            strokeWidth={2}
            dot={false}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
};

export default RealTimeChart;