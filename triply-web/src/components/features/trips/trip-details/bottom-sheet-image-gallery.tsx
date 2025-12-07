"use client";

import { useState, useRef } from "react";
import Image from "next/image";
import { ChevronLeft, ChevronRight, Building2, Utensils, X } from "lucide-react";
import { cn } from "@/lib/utils";

interface BottomSheetImageGalleryProps {
  images: string[];
  alt: string;
  onClose: () => void;
  type: "place" | "restaurant";
}

export function BottomSheetImageGallery({
  images,
  alt,
  onClose,
  type,
}: BottomSheetImageGalleryProps) {
  const [currentIndex, setCurrentIndex] = useState(0);
  const prevImagesLength = useRef(images.length);

  // Reset index when images change
  if (images.length !== prevImagesLength.current) {
    prevImagesLength.current = images.length;
    if (currentIndex >= images.length) {
      setCurrentIndex(0);
    }
  }

  const validImages = images.filter(
    (img) => typeof img === "string" && img.trim().length > 0
  );

  if (validImages.length === 0) {
    return (
      <div className="relative w-full h-[280px] bg-white/5 flex items-center justify-center">
        <Building2 className="h-16 w-16 text-white/20" />
        {/* Close button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 p-2 rounded-full bg-black/30 backdrop-blur-md border border-white/20 hover:bg-black/50 transition-colors z-20"
        >
          <X className="h-5 w-5 text-white" />
        </button>
        {/* Drag handle */}
        <div className="absolute top-3 left-1/2 -translate-x-1/2 w-12 h-1 rounded-full bg-white/30 z-20" />
      </div>
    );
  }

  const goToNext = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (currentIndex < validImages.length - 1) {
      setCurrentIndex(currentIndex + 1);
    }
  };

  const goToPrev = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (currentIndex > 0) {
      setCurrentIndex(currentIndex - 1);
    }
  };

  return (
    <div className="relative w-full h-[280px]">
      {/* Current Image - full width, edge to edge */}
      <div className="relative w-full h-full">
        <Image
          src={validImages[currentIndex]}
          alt={`${alt} - ${currentIndex + 1}`}
          fill
          className="object-cover"
        />
      </div>

      {/* Drag handle - on top of image */}
      <div className="absolute top-3 left-1/2 -translate-x-1/2 w-12 h-1 rounded-full bg-white/50 z-20" />

      {/* Close X button - blurred background like Flutter */}
      <button
        onClick={onClose}
        className="absolute top-3 right-4 p-2 rounded-full bg-black/30 backdrop-blur-md border border-white/20 hover:bg-black/50 transition-colors z-20"
      >
        <X className="h-5 w-5 text-white" />
      </button>

      {/* Type badge */}
      <div className={cn(
        "absolute top-3 left-4 flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium z-10",
        type === "restaurant"
          ? "bg-accent/90 text-white"
          : "bg-primary/90 text-white"
      )}>
        {type === "restaurant" ? (
          <Utensils className="h-3.5 w-3.5" />
        ) : (
          <Building2 className="h-3.5 w-3.5" />
        )}
        <span className="capitalize">{type}</span>
      </div>

      {/* Navigation Arrows */}
      {validImages.length > 1 && (
        <>
          <button
            onClick={goToPrev}
            className={cn(
              "absolute left-3 top-1/2 -translate-y-1/2 p-2 rounded-full bg-black/30 backdrop-blur-md hover:bg-black/50 transition-all z-10",
              currentIndex === 0 ? "opacity-30 cursor-not-allowed" : "opacity-100"
            )}
            disabled={currentIndex === 0}
          >
            <ChevronLeft className="h-5 w-5 text-white" />
          </button>

          <button
            onClick={goToNext}
            className={cn(
              "absolute right-3 top-1/2 -translate-y-1/2 p-2 rounded-full bg-black/30 backdrop-blur-md hover:bg-black/50 transition-all z-10",
              currentIndex === validImages.length - 1 ? "opacity-30 cursor-not-allowed" : "opacity-100"
            )}
            disabled={currentIndex === validImages.length - 1}
          >
            <ChevronRight className="h-5 w-5 text-white" />
          </button>
        </>
      )}

      {/* Bottom gradient for indicators */}
      {validImages.length > 1 && (
        <div className="absolute bottom-0 left-0 right-0 h-16 bg-linear-to-t from-black/60 to-transparent pointer-events-none z-10" />
      )}

      {/* Bar indicators */}
      {validImages.length > 1 && (
        <div className="absolute bottom-3 left-4 right-4 flex gap-1 z-20">
          {validImages.map((_, idx) => (
            <button
              key={idx}
              onClick={(e) => {
                e.stopPropagation();
                setCurrentIndex(idx);
              }}
              className="flex-1 h-0.5 rounded-full transition-all duration-300"
              style={{
                backgroundColor: idx === currentIndex ? 'white' : 'rgba(255, 255, 255, 0.3)',
              }}
            />
          ))}
        </div>
      )}
    </div>
  );
}
