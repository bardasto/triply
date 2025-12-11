"use client";

import { useState, useRef, useEffect, TouchEvent } from "react";
import Image from "next/image";
import Link from "next/link";
import {
  MapPin,
  Clock,
  Star,
  ChevronLeft,
  ChevronRight,
  ChevronRight as ExpandIcon,
  Calendar,
  Bookmark,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import type { AITripResponse } from "@/types/ai-response";

// Hook to detect mobile
function useIsMobile() {
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    const checkMobile = () => setIsMobile(window.innerWidth < 768);
    checkMobile();
    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  return isMobile;
}

interface ChatTripCardProps {
  trip: AITripResponse;
  savedTripId?: string | null;
  onExpand?: () => void;
  onSave?: () => void;
  className?: string;
}

const THEME = {
  cardBorderRadius: 20,
  indicatorHeight: 2.5,
  maxCarouselImages: 4,
};

export function ChatTripCard({ trip, savedTripId, onExpand, onSave, className }: ChatTripCardProps) {
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [imageError, setImageError] = useState(false);
  const [isSaved, setIsSaved] = useState(false);
  const touchStartX = useRef<number | null>(null);
  const isMobile = useIsMobile();

  // Guard against missing trip data
  if (!trip) {
    return null;
  }

  // Collect images: hero image + itinerary place images
  const collectImages = (): string[] => {
    const images: string[] = [];

    if (trip.hero_image_url) {
      images.push(trip.hero_image_url);
    }

    if (trip.images) {
      for (const img of trip.images) {
        if (typeof img === 'string' && !images.includes(img)) {
          images.push(img);
        }
      }
    }

    // Extract from itinerary
    if (trip.itinerary) {
      for (const day of trip.itinerary) {
        for (const place of day.places || []) {
          if (place.image_url && !images.includes(place.image_url)) {
            images.push(place.image_url);
          }
        }
      }
    }

    return images.slice(0, THEME.maxCarouselImages);
  };

  const images = collectImages();
  const hasImages = images.length > 0 && !imageError;
  const hasMultipleImages = images.length > 1;
  const safeImageIndex = images.length > 0 ? Math.min(currentImageIndex, images.length - 1) : 0;

  const nextImage = (e?: React.MouseEvent) => {
    e?.stopPropagation();
    setCurrentImageIndex((prev) => (prev + 1) % images.length);
  };

  const prevImage = (e?: React.MouseEvent) => {
    e?.stopPropagation();
    setCurrentImageIndex((prev) => (prev - 1 + images.length) % images.length);
  };

  const handleTouchStart = (e: TouchEvent<HTMLDivElement>) => {
    touchStartX.current = e.touches[0].clientX;
  };

  const handleTouchEnd = (e: TouchEvent<HTMLDivElement>) => {
    if (touchStartX.current === null || !hasMultipleImages) return;

    const touchEndX = e.changedTouches[0].clientX;
    const diff = touchStartX.current - touchEndX;
    const minSwipeDistance = 50;

    if (Math.abs(diff) > minSwipeDistance) {
      if (diff > 0) nextImage();
      else prevImage();
    }

    touchStartX.current = null;
  };

  const handleSave = (e: React.MouseEvent) => {
    e.stopPropagation();
    setIsSaved(!isSaved);
    onSave?.();
  };

  const totalPlaces = trip.itinerary?.reduce(
    (acc, day) => acc + (day.places?.length || 0),
    0
  ) || 0;

  // On mobile with savedTripId, use Link for navigation
  const shouldUseLink = isMobile && savedTripId;

  const handleCardClick = () => {
    if (!shouldUseLink) {
      onExpand?.();
    }
  };

  const cardContent = (
    <div
      className={cn(
        "group bg-white/5 border border-white/10 overflow-hidden cursor-pointer hover:bg-white/[0.07] transition-colors",
        className
      )}
      style={{ borderRadius: THEME.cardBorderRadius }}
      onClick={handleCardClick}
    >
      {/* Image Section */}
      <div
        className="relative h-[200px] overflow-hidden"
        onTouchStart={handleTouchStart}
        onTouchEnd={handleTouchEnd}
      >
        {hasImages ? (
          <Image
            src={images[safeImageIndex]}
            alt={trip.title}
            fill
            className="object-cover"
            onError={() => setImageError(true)}
          />
        ) : (
          <div className="absolute inset-0 flex items-center justify-center bg-gradient-to-br from-primary to-primary/60">
            <MapPin className="h-12 w-12 text-white/50" />
          </div>
        )}

        {/* Gradient overlay */}
        <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />

        {/* Navigation arrows - always visible on mobile, hover on desktop */}
        {hasMultipleImages && (
          <>
            <Button
              variant="ghost"
              size="icon"
              className={cn(
                "absolute left-2 top-1/2 -translate-y-1/2 h-7 w-7 rounded-full bg-black/30 backdrop-blur-md text-white hover:bg-black/50 z-10",
                "md:opacity-0 md:group-hover:opacity-100 transition-opacity",
                currentImageIndex === 0 && "!opacity-30 cursor-not-allowed"
              )}
              onClick={prevImage}
              disabled={currentImageIndex === 0}
            >
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <Button
              variant="ghost"
              size="icon"
              className={cn(
                "absolute right-2 top-1/2 -translate-y-1/2 h-7 w-7 rounded-full bg-black/30 backdrop-blur-md text-white hover:bg-black/50 z-10",
                "md:opacity-0 md:group-hover:opacity-100 transition-opacity",
                currentImageIndex === images.length - 1 && "!opacity-30 cursor-not-allowed"
              )}
              onClick={nextImage}
              disabled={currentImageIndex === images.length - 1}
            >
              <ChevronRight className="h-4 w-4" />
            </Button>
          </>
        )}

        {/* Bar indicators */}
        {hasMultipleImages && (
          <div className="absolute bottom-3 left-3 right-3 flex gap-1 z-10">
            {images.map((_, index) => (
              <button
                key={index}
                onClick={(e) => {
                  e.stopPropagation();
                  setCurrentImageIndex(index);
                }}
                className="flex-1 transition-all duration-300"
                style={{
                  height: THEME.indicatorHeight,
                  borderRadius: 2,
                  backgroundColor: index === safeImageIndex ? "white" : "rgba(255,255,255,0.3)",
                }}
                aria-label={`View image ${index + 1}`}
              />
            ))}
          </div>
        )}

        {/* Save button */}
        <button
          className="absolute top-3 right-3 p-2 rounded-full bg-black/30 backdrop-blur-md z-10 hover:bg-black/50 transition-colors"
          onClick={handleSave}
        >
          <Bookmark
            className={cn(
              "h-4 w-4 transition-colors",
              isSaved ? "fill-primary text-primary" : "text-white"
            )}
          />
        </button>

        {/* Activity type badge */}
        {trip.activity_type && (
          <span className="absolute top-3 left-3 px-2.5 py-1 bg-primary/90 text-white text-xs font-medium rounded-full capitalize">
            {trip.activity_type.replace(/_/g, " ")}
          </span>
        )}
      </div>

      {/* Info Section */}
      <div className="p-3 space-y-2">
        {/* Title */}
        <h3 className="font-semibold text-white text-base leading-tight line-clamp-2">
          {trip.title}
        </h3>

        {/* Location */}
        <div className="flex items-center gap-1.5 text-white/70 text-sm">
          <MapPin className="h-3.5 w-3.5 flex-shrink-0" />
          <span className="line-clamp-1">{trip.city}, {trip.country}</span>
        </div>

        {/* Stats row */}
        <div className="flex items-center gap-3 text-sm">
          {trip.rating && trip.rating > 0 && (
            <div className="flex items-center gap-1">
              <Star className="h-3.5 w-3.5 text-amber-400 fill-amber-400" />
              <span className="font-semibold text-white">{trip.rating.toFixed(1)}</span>
            </div>
          )}

          <div className="flex items-center gap-1 text-white/60">
            <Clock className="h-3.5 w-3.5" />
            <span>{trip.duration_days} {trip.duration_days === 1 ? 'day' : 'days'}</span>
          </div>

          <div className="flex items-center gap-1 text-white/60">
            <Calendar className="h-3.5 w-3.5" />
            <span>{totalPlaces} places</span>
          </div>
        </div>

        {/* Price + Expand button */}
        <div className="flex items-center justify-between">
          <span className="text-lg font-bold text-white">
            {trip.price}
          </span>

          <Button
            variant="ghost"
            size="sm"
            className="text-primary hover:text-primary hover:bg-primary/10 gap-1 px-2"
            onClick={(e) => {
              e.stopPropagation();
              if (!shouldUseLink) {
                onExpand?.();
              }
            }}
          >
            View Details
            <ExpandIcon className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </div>
  );

  // Wrap with Link on mobile when savedTripId is available
  if (shouldUseLink) {
    return (
      <Link href={`/trips/${savedTripId}`} className="block">
        {cardContent}
      </Link>
    );
  }

  return cardContent;
}

// Compact version for inline display
export function ChatTripCardCompact({ trip, onExpand }: ChatTripCardProps) {
  // Guard against missing trip data
  if (!trip) {
    return null;
  }

  return (
    <div
      className="group flex items-center gap-3 p-3 bg-white/5 border border-white/10 rounded-xl cursor-pointer hover:bg-white/[0.07] transition-colors"
      onClick={onExpand}
    >
      {/* Thumbnail */}
      <div className="relative w-16 h-16 rounded-lg overflow-hidden flex-shrink-0">
        {trip.hero_image_url ? (
          <Image
            src={trip.hero_image_url}
            alt={trip.title}
            fill
            className="object-cover"
          />
        ) : (
          <div className="w-full h-full bg-gradient-to-br from-primary to-primary/60 flex items-center justify-center">
            <MapPin className="h-6 w-6 text-white/50" />
          </div>
        )}
      </div>

      {/* Info */}
      <div className="flex-1 min-w-0">
        <h4 className="font-medium text-white text-sm line-clamp-1">{trip.title}</h4>
        <p className="text-xs text-white/60 mt-0.5">{trip.city}, {trip.country}</p>
        <div className="flex items-center gap-2 mt-1 text-xs">
          <span className="text-white/60">{trip.duration_days}d</span>
          <span className="font-semibold text-white">{trip.price}</span>
        </div>
      </div>

      {/* Arrow */}
      <ExpandIcon className="h-4 w-4 text-white/40 group-hover:text-primary transition-colors" />
    </div>
  );
}
