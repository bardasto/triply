"use client";

import { useState, useEffect, useCallback } from "react";
import Image from "next/image";
import { X, ChevronLeft, ChevronRight } from "lucide-react";
import { LottieIcon } from "@/components/ui/lottie-icon";
import { cn } from "@/lib/utils";

// Gallery back button with hover animation
function GalleryBackButton({ onClick }: { onClick: () => void }) {
  const [isHovered, setIsHovered] = useState(false);

  return (
    <button
      onClick={onClick}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      className="flex items-center gap-2 text-white hover:text-primary transition-colors"
    >
      <LottieIcon variant="misc" name="back" size={20} playOnHover isHovered={isHovered} />
      <span className="text-sm font-medium">Gallery</span>
    </button>
  );
}

interface FullscreenPhotoGalleryProps {
  images: string[];
  title: string;
  placeName?: string;
  isOpen: boolean;
  onClose: () => void;
  initialIndex?: number;
  onIndexChange?: (index: number) => void;
  imageSourceNames?: (string | undefined)[];
}

export function FullscreenPhotoGallery({
  images,
  title,
  placeName,
  isOpen,
  onClose,
  initialIndex = 0,
  onIndexChange,
  imageSourceNames,
}: FullscreenPhotoGalleryProps) {
  const [currentIndex, setCurrentIndex] = useState(initialIndex);

  // Filter valid images
  const validImages = images.filter(
    (img) => typeof img === "string" && img.trim().length > 0
  );

  // Reset to initial index when gallery opens
  useEffect(() => {
    if (isOpen) {
      setCurrentIndex(initialIndex);
    }
  }, [isOpen, initialIndex]);

  // Keyboard navigation
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        onClose();
      } else if (e.key === "ArrowLeft") {
        goToPrevious();
      } else if (e.key === "ArrowRight") {
        goToNext();
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, onClose]);

  // Prevent body scroll when gallery is open
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [isOpen]);

  const goToNext = useCallback(() => {
    const newIndex = (currentIndex + 1) % validImages.length;
    setCurrentIndex(newIndex);
    onIndexChange?.(newIndex);
  }, [validImages.length, currentIndex, onIndexChange]);

  const goToPrevious = useCallback(() => {
    const newIndex = (currentIndex - 1 + validImages.length) % validImages.length;
    setCurrentIndex(newIndex);
    onIndexChange?.(newIndex);
  }, [validImages.length, currentIndex, onIndexChange]);

  const goToImage = useCallback((index: number) => {
    if (index === currentIndex) return;
    setCurrentIndex(index);
    onIndexChange?.(index);
  }, [currentIndex, onIndexChange]);

  if (!isOpen || validImages.length === 0) return null;

  // Get the place name for the current image - prioritize imageSourceNames array, then placeName prop, then title
  const currentSourceName = imageSourceNames?.[currentIndex];
  const displayTitle = currentSourceName || placeName || title;

  return (
    <div className="fixed inset-0 z-50 bg-black flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-4 py-3 bg-gradient-to-b from-black/60 to-transparent">
          <GalleryBackButton onClick={onClose} />

          <h2 className="text-white font-medium text-sm truncate max-w-[50%]">
            {displayTitle}
          </h2>

          <button
            onClick={onClose}
            className="p-2 text-white hover:text-white/80 transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Main image container */}
        <div className="flex-1 flex items-center justify-center relative px-16 py-4">
          {/* Navigation buttons */}
          <button
            onClick={goToPrevious}
            className="absolute left-4 top-1/2 -translate-y-1/2 z-10 p-3 rounded-full bg-white/10 hover:bg-white/20 backdrop-blur-sm text-white transition-all"
          >
            <ChevronLeft className="h-6 w-6" />
          </button>

          <button
            onClick={goToNext}
            className="absolute right-4 top-1/2 -translate-y-1/2 z-10 p-3 rounded-full bg-white/10 hover:bg-white/20 backdrop-blur-sm text-white transition-all"
          >
            <ChevronRight className="h-6 w-6" />
          </button>

          {/* Current image with fixed height and variable width based on aspect ratio */}
          <div className="relative w-full h-full flex items-center justify-center">
            <img
              src={validImages[currentIndex]}
              alt={`${displayTitle} - ${currentIndex + 1}`}
              className="max-h-full max-w-full h-[65vh] w-auto object-contain rounded-2xl"
            />
          </div>
        </div>

        {/* Counter */}
        <div className="text-center text-white text-sm font-medium py-2">
          {currentIndex + 1} / {validImages.length}
        </div>

        {/* Thumbnail strip with proper padding for ring */}
        <div className="bg-gradient-to-t from-black/80 to-transparent pt-4 pb-6 px-4">
          <div className="flex items-center justify-center overflow-x-auto scrollbar-hide">
            <div className="flex items-center gap-3 p-2">
              {validImages.map((image, index) => (
                <button
                  key={index}
                  onClick={() => goToImage(index)}
                  className={cn(
                    "relative flex-shrink-0 w-20 h-14 rounded-lg overflow-hidden transition-all duration-200",
                    index === currentIndex
                      ? "ring-2 ring-primary ring-offset-2 ring-offset-black scale-105"
                      : "opacity-60 hover:opacity-100"
                  )}
                >
                  <Image
                    src={image}
                    alt={`Thumbnail ${index + 1}`}
                    fill
                    className="object-cover"
                  />
                </button>
              ))}
            </div>
          </div>
        </div>
    </div>
  );
}
