import React, { useEffect, useRef, useState } from "react";
import { combine } from "@atlaskit/pragmatic-drag-and-drop/combine";
import {
  draggable,
  dropTargetForElements,
} from "@atlaskit/pragmatic-drag-and-drop/element/adapter";

interface DashboardItemProps {
  id: string;
  instanceId: string;
  children: React.ReactNode;
  className?: string;
}

export const DashboardItem: React.FC<DashboardItemProps> = ({
  id,
  instanceId,
  children,
  className,
}) => {
  const ref = useRef<HTMLDivElement>(null);
  const dragHandleRef = useRef<HTMLDivElement>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [isOver, setIsOver] = useState(false);

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

  return (
    <div
      ref={ref}
      className={`relative h-full rounded-xl
        ${isDragging ? "opacity-40 scale-95 grayscale transition-all duration-300" : "opacity-100"}
        ${isOver ? "ring-2 ring-blue-500 ring-offset-4 bg-blue-50/50" : ""}
        ${className}
      `}
    >
      {/*
        We pass the dragHandleRef down to the children via a cloning trick
        or we can just look for the element with a specific data attribute.
        To keep it simple, we'll tell the children to use a specific ref if they need it.
      */}
      <div className="h-full">
        {React.Children.map(children, (child) => {
          if (React.isValidElement(child)) {
            // @ts-ignore - Injecting the dragHandleRef
            return React.cloneElement(child, { dragHandleRef });
          }
          return child;
        })}
      </div>
    </div>
  );
};
