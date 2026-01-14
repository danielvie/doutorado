//
// --- Sub-Component: Image Modal ---

import { useState } from "react";

type ImageModalProps = {
  isOpen: boolean;
  onClose: () => void;
};

export default function ImageModal({ isOpen, onClose }: ImageModalProps) {
  const [swap, setSwap] = useState(true);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 flex items-center justify-center z-50 p-4 rounded-lg shadow-lg bg-panel/90 backdrop-blur-sm">
      <div
        onClick={onClose}
        className="flex flex-col h-full w-full items-center justify-center space-y-4 cursor-pointer"
      >
        {swap ? (
          <>
            <img
              src="circuit.png"
              alt="Circuit"
              className="max-h-[45%] object-contain"
            />
            <img
              src="hw_esp32_pins.png"
              alt="ESP Pins"
              className="max-h-[45%] object-contain"
            />
          </>
        ) : (
          <img
            src="hw_measure_points.png"
            alt="Measure Points"
            className="h-[90%] border-2 border-gray object-contain"
          />
        )}
      </div>

      {/* Swap Button/Arrow */}
      <button
        onClick={(e) => {
          e.stopPropagation();
          setSwap((prev) => !prev);
        }}
        className="absolute right-8 top-1/2 transform -translate-y-1/2 p-4
        bg-primary  hover:bg-primary-shade
        transition rounded-full"
      >
        <span className="text-2xl">➡</span>
      </button>
    </div>
  );
}
