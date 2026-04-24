import React, { useState } from "react";

export type PanelSize =
  | "1x1"
  | "1x2"
  | "1x3"
  | "2x1"
  | "2x2"
  | "2x3"
  | "3x1"
  | "3x2"
  | "3x3";

interface SizeSelectorProps {
  currentSize: PanelSize;
  onSizeChange: (size: PanelSize) => void;
}

export const SizeSelector: React.FC<SizeSelectorProps> = ({
  currentSize,
  onSizeChange,
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const [active_width, active_height] = currentSize.split("x").map(Number);

  const handle_width_change = (width: number) => {
    onSizeChange(`${width}x${active_height}` as PanelSize);
  };

  const handle_height_change = (height: number) => {
    onSizeChange(`${active_width}x${height}` as PanelSize);
    setIsOpen(false);
  };

  return (
    <div className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className={`p-1.5 rounded-md transition-all border ${isOpen ? "bg-blue-50 border-blue-200 text-blue-600" : "text-gray-400 hover:text-blue-600 hover:bg-blue-50 border-transparent hover:border-blue-100"}`}
        title="Change Panel Size"
      >
        <svg
          width="20"
          height="20"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />

          <path
            d="M3 3h6v6H3z"
            fill={
              active_width >= 1 && active_height >= 1 ? "currentColor" : "none"
            }
            fillOpacity={active_width >= 1 && active_height >= 1 ? "0.2" : "0"}
          />
          <path
            d="M9 3h6v6H9z"
            fill={
              active_width >= 2 && active_height >= 1 ? "currentColor" : "none"
            }
            fillOpacity={active_width >= 2 && active_height >= 1 ? "0.2" : "0"}
          />
          <path
            d="M15 3h6v6h-6z"
            fill={
              active_width >= 3 && active_height >= 1 ? "currentColor" : "none"
            }
            fillOpacity={active_width >= 3 && active_height >= 1 ? "0.2" : "0"}
          />
          <path
            d="M3 9h6v6H3z"
            fill={
              active_width >= 1 && active_height >= 2 ? "currentColor" : "none"
            }
            fillOpacity={active_width >= 1 && active_height >= 2 ? "0.2" : "0"}
          />
          <path
            d="M9 9h6v6H9z"
            fill={
              active_width >= 2 && active_height >= 2 ? "currentColor" : "none"
            }
            fillOpacity={active_width >= 2 && active_height >= 2 ? "0.2" : "0"}
          />
          <path
            d="M15 9h6v6h-6z"
            fill={
              active_width >= 3 && active_height >= 2 ? "currentColor" : "none"
            }
            fillOpacity={active_width >= 3 && active_height >= 2 ? "0.2" : "0"}
          />
          <path
            d="M3 15h6v6H3z"
            fill={
              active_width >= 1 && active_height >= 3 ? "currentColor" : "none"
            }
            fillOpacity={active_width >= 1 && active_height >= 3 ? "0.2" : "0"}
          />
          <path
            d="M9 15h6v6H9z"
            fill={
              active_width >= 2 && active_height >= 3 ? "currentColor" : "none"
            }
            fillOpacity={active_width >= 2 && active_height >= 3 ? "0.2" : "0"}
          />
          <path
            d="M15 15h6v6h-6z"
            fill={
              active_width >= 3 && active_height >= 3 ? "currentColor" : "none"
            }
            fillOpacity={active_width >= 3 && active_height >= 3 ? "0.2" : "0"}
          />

          <line x1="9" y1="3" x2="9" y2="21" />
          <line x1="15" y1="3" x2="15" y2="21" />
          <line x1="3" y1="9" x2="21" y2="9" />
          <line x1="3" y1="15" x2="21" y2="15" />
        </svg>
      </button>

      {isOpen && (
        <>
          <div
            className="fixed inset-0 z-[60]"
            onClick={() => setIsOpen(false)}
          />
          <div className="absolute left-0 mt-2 bg-white rounded-xl shadow-2xl border border-gray-200 p-4 z-[70] min-w-[200px] animate-fade-in-up">
            <div className="flex flex-col gap-4">
              <div className="flex flex-col gap-2">
                <span className="text-[10px] font-bold uppercase tracking-widest text-gray-500">
                  Width
                </span>
                <div className="grid grid-cols-3 gap-2">
                  {[1, 2, 3].map((width) => {
                    const is_active = active_width === width;

                    return (
                      <button
                        key={`width-${width}`}
                        onClick={() => handle_width_change(width)}
                        className={`h-9 rounded-md border text-xs font-bold transition-all ${
                          is_active
                            ? "bg-blue-500 border-blue-600 text-white shadow-sm"
                            : "bg-gray-50 border-gray-200 text-gray-600 hover:border-gray-300"
                        }`}
                      >
                        {width}x
                      </button>
                    );
                  })}
                </div>
              </div>

              <div className="flex flex-col gap-2">
                <span className="text-[10px] font-bold uppercase tracking-widest text-gray-500">
                  Height
                </span>
                <div className="grid grid-cols-3 gap-2">
                  {[1, 2, 3].map((height) => {
                    const is_active = active_height === height;

                    return (
                      <button
                        key={`height-${height}`}
                        onClick={() => handle_height_change(height)}
                        className={`h-9 rounded-md border text-xs font-bold transition-all ${
                          is_active
                            ? "bg-blue-500 border-blue-600 text-white shadow-sm"
                            : "bg-gray-50 border-gray-200 text-gray-600 hover:border-gray-300"
                        }`}
                      >
                        x{height}
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  );
};
