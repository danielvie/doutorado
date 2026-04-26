import React, { useEffect, useRef, useState } from "react";
import { combine } from "@atlaskit/pragmatic-drag-and-drop/combine";
import {
  draggable,
  dropTargetForElements,
} from "@atlaskit/pragmatic-drag-and-drop/element/adapter";
import { GripVertical, Maximize2, Minimize2 } from "lucide-react";
import { PanelSize, SizeSelector } from "./SizeSelector";

interface DashboardItemProps {
  id: string;
  instanceId: string;
  title: string;
  currentSize?: PanelSize;
  onSizeChange?: (size: PanelSize) => void;
  expandable?: boolean;
  children: React.ReactNode;
  className?: string;
}

export const DashboardItem: React.FC<DashboardItemProps> = ({
  id,
  instanceId,
  title,
  currentSize,
  onSizeChange,
  expandable = false,
  children,
  className = "",
}) => {
  const ref = useRef<HTMLDivElement>(null);
  const dragHandleRef = useRef<HTMLDivElement>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [isOver, setIsOver] = useState(false);
  const [isExpanded, setIsExpanded] = useState(false);

  useEffect(() => {
    const el = ref.current;
    const dragHandle = dragHandleRef.current;
    if (!el || !dragHandle) return;

    return combine(
      draggable({
        element: el,
        dragHandle: dragHandle, // Only the grip icon triggers the drag
        getInitialData: () => ({ type: "dashboard-item", id, instanceId }),
        onDragStart: () => setIsDragging(true),
        onDrop: () => setIsDragging(false),
      }),
      dropTargetForElements({
        element: el,
        getData: () => ({ id }),
        canDrop: ({ source }) =>
          source.data.instanceId === instanceId &&
          source.data.type === "dashboard-item" &&
          source.data.id !== id,
        onDragEnter: () => setIsOver(true),
        onDragLeave: () => setIsOver(false),
        onDrop: () => setIsOver(false),
      }),
    );
  }, [id, instanceId]);

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
      {isExpanded && <div className="fixed inset-0 z-[190] bg-slate-900/10" />}
      <div
        ref={ref}
        className={`panel p-3 flex flex-col gap-3 transition-[opacity,transform] duration-300 overflow-hidden
          ${isExpanded ? "fixed top-20 bottom-4 left-4 right-4 lg:top-24 lg:bottom-8 lg:left-8 lg:right-8 z-[200] max-w-none shadow-2xl" : "relative h-full min-h-0"}
          ${isDragging ? "opacity-40 scale-95 grayscale" : "opacity-100"}
          ${isOver ? "ring-2 ring-blue-500 ring-offset-4 bg-blue-50/50" : ""}
          ${className}
        `}
      >
        <div className="flex justify-between items-center shrink-0 border-b border-gray-200 pb-2">
          <div className="flex items-center gap-1.5">
            <div
              ref={dragHandleRef}
              className="p-1.5 text-gray-400 hover:text-gray-600 cursor-grab active:cursor-grabbing transition-colors"
            >
              <GripVertical size={20} />
            </div>
            {currentSize && onSizeChange && (
              <SizeSelector currentSize={currentSize} onSizeChange={onSizeChange} />
            )}
            <h2 className="text-xl font-bold text-gray-900">{title}</h2>
          </div>
          {expandable && (
            <div className="flex gap-2 items-center">
              <button
                onClick={() => setIsExpanded(!isExpanded)}
                className="p-2 bg-gray-50 border border-gray-200 hover:bg-gray-100 rounded-md text-gray-600 transition-colors"
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
