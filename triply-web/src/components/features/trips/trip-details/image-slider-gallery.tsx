"use client";

import { useState, useRef } from "react";
import Image from "next/image";
import { ChevronLeft, ChevronRight, Building2 } from "lucide-react";
import { cn } from "@/lib/utils";

interface ImageSliderGalleryProps {
  images: string[];
  alt: string;
  height?: string;
  badge?: React.ReactNode;
  onImageClick?: (e: React.MouseEvent) => void;
  rounded?: boolean;
  className?: string;
}

export function ImageSliderGallery({
  images,
  alt,
  height = "h-48",
  badge,
  onImageClick,
  rounded = true,
  className,
}: ImageSliderGalleryProps) {
  const [currentIndex, setCurrentIndex] = useState(0);
  const containerRef = useRef<HTMLDivElement>(null);
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
      <div className={cn("relative w-full overflow-hidden bg-white/5 flex items-center justify-center", height, rounded && "rounded-xl", className)}>
        <Building2 className="h-12 w-12 text-white/20" />
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

  const handleAreaClick = (e: React.MouseEvent) => {
    if (validImages.length <= 1) {
      onImageClick?.(e);
      return;
    }

    const rect = containerRef.current?.getBoundingClientRect();
    if (!rect) return;

    const clickX = e.clientX - rect.left;
    const width = rect.width;

    // Click on left third goes back, right third goes forward, middle opens fullscreen
    if (clickX < width / 3) {
      goToPrev(e);
    } else if (clickX > (width * 2) / 3) {
      goToNext(e);
    } else {
      onImageClick?.(e);
    }
  };

  return (
    <div
      ref={containerRef}
      className={cn("relative w-full overflow-hidden group cursor-pointer", height, rounded && "rounded-xl", className)}
      onClick={handleAreaClick}
    >
      {/* Current Image */}
      <div className="relative w-full h-full">
        <Image
          src={validImages[currentIndex]}
          alt={`${alt} - ${currentIndex + 1}`}
          fill
          className="object-cover transition-opacity duration-300"
        />
      </div>

      {/* Badge (type indicator) */}
      {badge}

      {/* Navigation Arrows - only show when more than 1 image */}
      {validImages.length > 1 && (
        <>
          {/* Left Arrow */}
          <button
            onClick={goToPrev}
            className={cn(
              "absolute left-2 top-1/2 -translate-y-1/2 p-1.5 rounded-full bg-black/30 backdrop-blur-md hover:bg-black/50 transition-all",
              currentIndex === 0 ? "opacity-30 cursor-not-allowed" : "opacity-0 group-hover:opacity-100"
            )}
            disabled={currentIndex === 0}
          >
            <ChevronLeft className="h-4 w-4 text-white" />
          </button>

          {/* Right Arrow */}
          <button
            onClick={goToNext}
            className={cn(
              "absolute right-2 top-1/2 -translate-y-1/2 p-1.5 rounded-full bg-black/30 backdrop-blur-md hover:bg-black/50 transition-all",
              currentIndex === validImages.length - 1 ? "opacity-30 cursor-not-allowed" : "opacity-0 group-hover:opacity-100"
            )}
            disabled={currentIndex === validImages.length - 1}
          >
            <ChevronRight className="h-4 w-4 text-white" />
          </button>
        </>
      )}

      {/* Bottom gradient for indicators visibility */}
      {validImages.length > 1 && (
        <div className="absolute bottom-0 left-0 right-0 h-16 bg-linear-to-t from-black/60 to-transparent pointer-events-none" />
      )}

      {/* Bar Indicators (Telegram-style) */}
      {validImages.length > 1 && (
        <div className="absolute bottom-3 left-3 right-3 flex gap-1">
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
