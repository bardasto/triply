"use client";

import { useState, useCallback, useRef } from "react";
import Image from "next/image";
import { ChevronLeft, ChevronRight, MapPin } from "lucide-react";
import { cn } from "@/lib/utils";

interface MobileSwipeableGalleryProps {
  images: string[];
  title: string;
}

export function MobileSwipeableGallery({ images, title }: MobileSwipeableGalleryProps) {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [touchStart, setTouchStart] = useState<number | null>(null);
  const [touchEnd, setTouchEnd] = useState<number | null>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [dragOffset, setDragOffset] = useState(0);
  const containerRef = useRef<HTMLDivElement>(null);

  const validImages = images.filter(
    (img) => typeof img === "string" && img.trim().length > 0
  );

  // Minimum swipe distance to trigger navigation (in pixels)
  const minSwipeDistance = 50;

  const goToNext = useCallback(() => {
    if (currentIndex < validImages.length - 1) {
      setCurrentIndex(currentIndex + 1);
    }
  }, [currentIndex, validImages.length]);

  const goToPrev = useCallback(() => {
    if (currentIndex > 0) {
      setCurrentIndex(currentIndex - 1);
    }
  }, [currentIndex]);

  const handleTouchStart = (e: React.TouchEvent) => {
    setTouchEnd(null);
    setTouchStart(e.targetTouches[0].clientX);
    setIsDragging(true);
  };

  const handleTouchMove = (e: React.TouchEvent) => {
    if (!touchStart) return;
    const currentTouch = e.targetTouches[0].clientX;
    setTouchEnd(currentTouch);

    // Calculate drag offset for visual feedback
    const offset = currentTouch - touchStart;
    // Limit the offset to prevent over-dragging
    const containerWidth = containerRef.current?.offsetWidth || 300;
    const limitedOffset = Math.max(-containerWidth * 0.3, Math.min(containerWidth * 0.3, offset));
    setDragOffset(limitedOffset);
  };

  const handleTouchEnd = () => {
    setIsDragging(false);
    setDragOffset(0);

    if (!touchStart || !touchEnd) return;

    const distance = touchStart - touchEnd;
    const isLeftSwipe = distance > minSwipeDistance;
    const isRightSwipe = distance < -minSwipeDistance;

    if (isLeftSwipe) {
      goToNext();
    } else if (isRightSwipe) {
      goToPrev();
    }

    setTouchStart(null);
    setTouchEnd(null);
  };

  if (validImages.length === 0) {
    return (
      <div className="relative w-full h-[360px] bg-gradient-to-br from-primary to-primary/60 flex items-center justify-center rounded-b-xl">
        <MapPin className="h-16 w-16 text-white/30" />
      </div>
    );
  }

  return (
    <div
      ref={containerRef}
      className="relative w-full h-[360px] overflow-hidden rounded-b-xl"
      onTouchStart={handleTouchStart}
      onTouchMove={handleTouchMove}
      onTouchEnd={handleTouchEnd}
    >
      {/* Current Image with drag feedback */}
      <div
        className={cn(
          "relative w-full h-full",
          !isDragging && "transition-transform duration-300 ease-out"
        )}
        style={{
          transform: `translateX(${dragOffset}px)`,
        }}
      >
        <Image
          src={validImages[currentIndex]}
          alt={`${title} - ${currentIndex + 1}`}
          fill
          className="object-cover"
          priority={currentIndex === 0}
        />
      </div>

      {/* Navigation Arrows */}
      {validImages.length > 1 && (
        <>
          <button
            onClick={(e) => {
              e.stopPropagation();
              goToPrev();
            }}
            className={cn(
              "absolute left-3 top-1/2 -translate-y-1/2 p-2 rounded-full bg-black/30 backdrop-blur-md hover:bg-black/50 transition-all z-10",
              currentIndex === 0 ? "opacity-30 cursor-not-allowed" : "opacity-100"
            )}
            disabled={currentIndex === 0}
          >
            <ChevronLeft className="h-5 w-5 text-white" />
          </button>

          <button
            onClick={(e) => {
              e.stopPropagation();
              goToNext();
            }}
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
        <div className="absolute bottom-0 left-0 right-0 h-16 bg-gradient-to-t from-black/60 to-transparent pointer-events-none z-10" />
      )}

      {/* Telegram-style bar indicators */}
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
