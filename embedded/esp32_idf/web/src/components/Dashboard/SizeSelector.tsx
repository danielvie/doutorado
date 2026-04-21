import React, { useState } from 'react';

export type PanelSize = '1x1' | '2x1' | '3x1';

interface SizeSelectorProps {
  currentSize: PanelSize;
  onSizeChange: (size: PanelSize) => void;
}

export const SizeSelector: React.FC<SizeSelectorProps> = ({ currentSize, onSizeChange }) => {
  const [hoverSize, setHoverSize] = useState<PanelSize | null>(null);
  const [isOpen, setIsOpen] = useState(false);

  const isHighlighted = (w: number) => {
    const target = hoverSize || currentSize;
    const targetW = parseInt(target.split('x')[0]);
    return w <= targetW;
  };

  const getActiveW = () => parseInt(currentSize.split('x')[0]);

  return (
    <div className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className={`p-1.5 rounded-md transition-all border ${isOpen ? 'bg-blue-50 border-blue-200 text-blue-600' : 'text-gray-400 hover:text-blue-600 hover:bg-blue-50 border-transparent hover:border-blue-100'}`}
        title="Change Panel Width"
      >
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
          
          {/* Column 1 fill */}
          <path 
            d="M3 3h6v18H3z" 
            fill={getActiveW() >= 1 ? "currentColor" : "none"} 
            fillOpacity={getActiveW() >= 1 ? "0.2" : "0"}
          />
          {/* Column 2 fill */}
          <path 
            d="M9 3h6v18h-6z" 
            fill={getActiveW() >= 2 ? "currentColor" : "none"} 
            fillOpacity={getActiveW() >= 2 ? "0.2" : "0"}
          />
          {/* Column 3 fill */}
          <path 
            d="M15 3h6v18h-6z" 
            fill={getActiveW() >= 3 ? "currentColor" : "none"} 
            fillOpacity={getActiveW() >= 3 ? "0.2" : "0"}
          />
          
          <line x1="9" y1="3" x2="9" y2="21" />
          <line x1="15" y1="3" x2="15" y2="21" />
        </svg>
      </button>

      {isOpen && (
        <>
          <div className="fixed inset-0 z-[60]" onClick={() => setIsOpen(false)} />
          <div className="absolute left-0 mt-2 bg-white rounded-xl shadow-2xl border border-gray-200 p-4 z-[70] min-w-[160px] animate-fade-in-up">
            <h4 className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-3 text-center">Select Width</h4>
            <div className="flex gap-2 w-fit mx-auto">
              {[1, 2, 3].map(w => {
                  const sizeId = `${w}x1` as PanelSize;
                  const active = isHighlighted(w);
                  return (
                    <button
                      key={sizeId}
                      onMouseEnter={() => setHoverSize(sizeId)}
                      onMouseLeave={() => setHoverSize(null)}
                      onClick={() => {
                        onSizeChange(sizeId);
                        setIsOpen(false);
                      }}
                      className={`w-10 h-8 rounded-md border-2 transition-all duration-200 flex items-center justify-center
                        ${active 
                          ? 'bg-blue-500 border-blue-600 shadow-lg shadow-blue-200 scale-105 z-10' 
                          : 'bg-gray-50 border-gray-200 hover:border-gray-300'
                        }`}
                    >
                      <span className={`text-xs font-bold ${active ? 'text-white' : 'text-gray-400'}`}>
                        {w}x
                      </span>
                    </button>
                  );
                })}
            </div>
          </div>
        </>
      )}
    </div>
  );
};
