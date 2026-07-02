import React, { useEffect, useState } from "react";
import { GripVertical, Maximize2, Minimize2 } from "lucide-react";

interface DashboardItemProps {
  title: string;
  expandable?: boolean;
  children: React.ReactNode;
  className?: string;
}

export const DashboardItem: React.FC<DashboardItemProps> = ({
  title,
  expandable = false,
  children,
  className = "",
}) => {
  const [isExpanded, setIsExpanded] = useState(false);

  useEffect(() => {
    const body_overflow_previous = document.body.style.overflow;
    if (isExpanded) {
      document.body.style.overflow = "hidden";
    }
    return () => {
      document.body.style.overflow = body_overflow_previous;
    };
  }, [isExpanded]);

  return (
    <>
      {isExpanded && <div className="fixed inset-0 z-[190] bg-stone-900/20" />}
      <div
        className={`panel p-3 flex flex-col gap-3 transition-[opacity,transform] duration-300 overflow-hidden
          ${isExpanded ? "fixed top-20 bottom-4 left-4 right-4 lg:top-24 lg:bottom-8 lg:left-8 lg:right-8 z-[200] max-w-none shadow-2xl" : "relative h-full min-h-0"}
          ${className}
        `}
      >
        <div className="flex justify-between items-center shrink-0 border-b border-stone-200 pb-2">
          <div className="flex items-center gap-1.5">
            {!isExpanded && (
              <div className="rgl-drag-handle p-1.5 text-stone-400 hover:text-indigo-600 cursor-grab active:cursor-grabbing transition-colors">
                <GripVertical size={20} />
              </div>
            )}
            <h2 className="text-xl font-bold text-stone-800">{title}</h2>
          </div>
          {expandable && (
            <div className="flex gap-2 items-center">
              <button
                onClick={() => setIsExpanded(!isExpanded)}
                className="p-2 bg-stone-50 border border-stone-200 hover:bg-stone-100 rounded-md text-stone-600 transition-colors"
                title={isExpanded ? "Exit fullscreen" : "Open fullscreen"}
              >
                {isExpanded ? <Minimize2 size={18} /> : <Maximize2 size={18} />}
              </button>
            </div>
          )}
        </div>

        <div className="flex-1 min-h-0 overflow-y-auto flex flex-col gap-4">
          {children}
        </div>
      </div>
    </>
  );
};
