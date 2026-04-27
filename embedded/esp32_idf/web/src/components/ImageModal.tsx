import React from "react";
import { X, ChevronRight, ChevronLeft } from "lucide-react";

type ImagePage = {
  id: string;
  title: string;
  src: string;
};

type ImageModalProps = {
  isOpen: boolean;
  onClose: () => void;
  images: ImagePage[];
};

export default function ImageModal({ isOpen, onClose, images }: ImageModalProps) {
  const [pageIndex, setPageIndex] = React.useState(0);

  if (!isOpen || images.length === 0) return null;

  const currentPage = images[pageIndex];

  const next = () => setPageIndex((prev) => (prev + 1) % images.length);
  const prev = () => setPageIndex((prev) => (prev - 1 + images.length) % images.length);

  return (
    <div 
      className="fixed inset-0 z-[100] flex items-center justify-center bg-black/95 backdrop-blur-xl transition-all duration-300 animate-in fade-in"
      onClick={onClose}
    >
      {/* Close Button */}
      <button
        onClick={onClose}
        className="absolute top-6 right-6 p-2 bg-white/10 hover:bg-white/20 text-white rounded-full transition-colors z-[110] shadow-xl border border-white/10"
        title="Close (Esc)"
      >
        <X size={24} />
      </button>

      {/* Navigation - Left */}
      <button
        onClick={(e) => { e.stopPropagation(); prev(); }}
        className="absolute left-6 top-1/2 -translate-y-1/2 p-4 bg-white/5 hover:bg-blue-600 text-white rounded-full transition-all z-[110] hover:scale-110 active:scale-95 group"
      >
        <ChevronLeft size={32} className="group-hover:translate-x-[-2px] transition-transform" />
      </button>

      {/* Navigation - Right */}
      <button
        onClick={(e) => { e.stopPropagation(); next(); }}
        className="absolute right-6 top-1/2 -translate-y-1/2 p-4 bg-white/5 hover:bg-blue-600 text-white rounded-full transition-all z-[110] hover:scale-110 active:scale-95 group"
      >
        <ChevronRight size={32} className="group-hover:translate-x-[2px] transition-transform" />
      </button>

      {/* Content Container */}
      <div 
        className="relative w-full h-full max-w-[95vw] max-h-[90vh] flex flex-col items-center justify-center"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Title Indicator */}
        <div className="absolute -top-12 left-1/2 -translate-x-1/2 flex flex-col items-center gap-1">
          <span className="text-blue-500 text-[10px] font-bold uppercase tracking-[0.3em]">Hardware Visualization</span>
          <h2 className="text-white text-xl font-bold tracking-tight">{currentPage.title}</h2>
        </div>

        <div className="relative w-full h-full flex items-center justify-center overflow-hidden rounded-2xl shadow-2xl border border-white/10 bg-gray-900/30">
          <img
            key={currentPage.src}
            src={currentPage.src}
            alt={currentPage.title}
            className="max-h-full w-full object-contain animate-in zoom-in-95 duration-500"
          />
        </div>

        {/* Dots Indicator */}
        <div className="absolute -bottom-10 left-1/2 -translate-x-1/2 flex gap-3">
          {images.map((_, i) => (
            <div 
              key={i}
              className={`h-1.5 rounded-full transition-all duration-300 ${
                i === pageIndex ? "w-8 bg-blue-500" : "w-2 bg-white/20"
              }`}
            />
          ))}
        </div>
      </div>
    </div>
  );
}
