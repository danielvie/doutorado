import React from 'react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  TooltipProps
} from 'recharts';

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

interface CustomTooltipProps extends TooltipProps<any, any> {
  active?: boolean;
  payload?: any[];
  label?: string;
}

const CustomTooltip: React.FC<CustomTooltipProps> = ({ active, payload, label }) => {
  if (active && payload && payload.length) {
    return (
      <div className='bg-white text-black items-start text-left p-2'>
        <p>{payload[0].name}: {payload[0].value.toFixed(2)}</p>
        <p>{payload[1].name}: {payload[1].value.toFixed(2)}</p>
        <p>{payload[2].name}: {payload[2].value.toFixed(2)}</p>
      </div>
    )
  }
  return null
}

const RealTimeChart: React.FC<RealTimeChartProps> = ({ 
  data,
  title = "Real-time Value Monitor"
}) => {
  
  let v1: string = ''
  let v2: string = ''
  let v3: string = ''
  if (data.length) {
    v1 = data[data.length-1].an3.toFixed(2)
    v2 = data[data.length-1].an5.toFixed(2)
    v3 = data[data.length-1].an6.toFixed(2)
  }

  return (
    <div className="w-full h-96 p-4 mb-10">
      <h2 className="text-xl font-bold mb-4">{title}</h2>
      <div>data: {v1}, {v2}, {v3}</div>
      
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
          <Tooltip content={<CustomTooltip/>} />
          <Legend verticalAlign='top' />
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