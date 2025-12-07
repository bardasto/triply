"use client";

import { useState, useRef, TouchEvent } from "react";
import Image from "next/image";
import { Heart, Trash2, MapPin, Clock, Star, ChevronLeft, ChevronRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import type { UserTripCard } from "@/types/user-trip";

export type Trip = UserTripCard;

interface MyTripCardProps {
  trip: Trip;
  onFavoriteToggle?: (id: string) => void;
  onDelete?: (id: string) => void;
  onClick?: (trip: Trip) => void;
}

// Theme constants matching Flutter
const THEME = {
  cardBorderRadius: 24,
  gridCardBorderRadius: 20,
  indicatorHeight: 2.5,
  maxCarouselImages: 4,
};

export function MyTripCard({ trip, onFavoriteToggle, onDelete, onClick }: MyTripCardProps) {
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [imageError, setImageError] = useState(false);
  const touchStartX = useRef<number | null>(null);

  // Filter out invalid images
  const images = (trip.images || [])
    .filter((img): img is string => typeof img === "string" && img.trim().length > 0)
    .slice(0, THEME.maxCarouselImages);
  const hasImages = images.length > 0 && !imageError;
  const hasMultipleImages = images.length > 1;

  // Ensure currentImageIndex is within bounds
  const safeImageIndex = images.length > 0 ? Math.min(currentImageIndex, images.length - 1) : 0;

  const nextImage = (e?: React.MouseEvent) => {
    e?.stopPropagation();
    setCurrentImageIndex((prev) => (prev + 1) % images.length);
  };

  const prevImage = (e?: React.MouseEvent) => {
    e?.stopPropagation();
    setCurrentImageIndex((prev) => (prev - 1 + images.length) % images.length);
  };

  // Touch handlers for swipe
  const handleTouchStart = (e: TouchEvent<HTMLDivElement>) => {
    touchStartX.current = e.touches[0].clientX;
  };

  const handleTouchEnd = (e: TouchEvent<HTMLDivElement>) => {
    if (touchStartX.current === null || !hasMultipleImages) return;

    const touchEndX = e.changedTouches[0].clientX;
    const diff = touchStartX.current - touchEndX;
    const minSwipeDistance = 50;

    if (Math.abs(diff) > minSwipeDistance) {
      if (diff > 0) {
        nextImage();
      } else {
        prevImage();
      }
    }

    touchStartX.current = null;
  };

  const formatPrice = (price: number, currency: string) => {
    const symbol = currency === "EUR" ? "€" : "$";
    return `${symbol}${price}`;
  };

  const formatDuration = (days: number) => {
    return days === 1 ? "1 day" : `${days} days`;
  };

  return (
    <article
      className="group cursor-pointer"
      onClick={() => onClick?.(trip)}
    >
      {/* Image Section - Separate rounded block with shadow */}
      {/* Height: 300px on mobile, 220px on desktop */}
      <div
        className="relative overflow-hidden shadow-lg shadow-black/10 h-[300px] md:h-[220px]"
        style={{ borderRadius: THEME.cardBorderRadius }}
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
            <MapPin className="h-10 w-10 text-white/50" />
          </div>
        )}

        {/* Gradient overlay for indicators */}
        {hasMultipleImages && (
          <div
            className="absolute left-0 right-0 bottom-0 h-[60px] pointer-events-none"
            style={{
              background: "linear-gradient(to bottom, transparent, rgba(0,0,0,0.6))"
            }}
          />
        )}

        {/* Navigation arrows - always visible on mobile, hover on desktop */}
        {hasMultipleImages && (
          <>
            <Button
              variant="ghost"
              size="icon"
              className={cn(
                "absolute left-3 top-1/2 -translate-y-1/2 h-8 w-8 rounded-full bg-black/30 backdrop-blur-md text-white hover:bg-black/50 z-10",
                "md:opacity-0 md:group-hover:opacity-100 transition-opacity",
                currentImageIndex === 0 && "opacity-30 cursor-not-allowed"
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
                "absolute right-3 top-1/2 -translate-y-1/2 h-8 w-8 rounded-full bg-black/30 backdrop-blur-md text-white hover:bg-black/50 z-10",
                "md:opacity-0 md:group-hover:opacity-100 transition-opacity",
                currentImageIndex === images.length - 1 && "opacity-30 cursor-not-allowed"
              )}
              onClick={nextImage}
              disabled={currentImageIndex === images.length - 1}
            >
              <ChevronRight className="h-4 w-4" />
            </Button>
          </>
        )}

        {/* Bar indicators - Flutter style */}
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

        {/* Delete button - top left */}
        <button
          className={cn(
            "absolute top-3 left-3 p-2 rounded-full bg-black/30 backdrop-blur-md text-white z-10",
            "md:opacity-0 md:group-hover:opacity-100 transition-opacity hover:bg-black/50"
          )}
          onClick={(e) => {
            e.stopPropagation();
            onDelete?.(trip.id);
          }}
        >
          <Trash2 className="h-5 w-5" />
        </button>

        {/* Favorite button - top right */}
        <button
          className="absolute top-3 right-3 p-2 rounded-full bg-black/30 backdrop-blur-md z-10 hover:bg-black/50 transition-colors"
          onClick={(e) => {
            e.stopPropagation();
            onFavoriteToggle?.(trip.id);
          }}
        >
          <Heart
            className={cn(
              "h-5 w-5 transition-colors",
              trip.is_favorite ? "fill-red-500 text-red-500" : "text-white"
            )}
          />
        </button>
      </div>

      {/* Info Section - On dark background, no card wrapper */}
      <div className="pt-3">
        {/* Title + Rating row */}
        <div className="flex items-start justify-between gap-2">
          <h3 className="font-semibold text-[17px] md:text-[15px] text-white leading-tight line-clamp-1 flex-1">
            {trip.title}
          </h3>
          {trip.rating > 0 && (
            <div className="flex items-center gap-1 flex-shrink-0">
              <Star className="h-3.5 w-3.5 text-amber-400 fill-amber-400" />
              <span className="text-[15px] md:text-[14px] font-semibold text-white">
                {trip.rating.toFixed(1)}
              </span>
            </div>
          )}
        </div>

        {/* Location */}
        <p className="text-[15px] md:text-[13px] text-white/70 mt-1 line-clamp-1">
          {trip.city}, {trip.country}
        </p>

        {/* Duration + Price row */}
        <div className="flex items-center gap-3 mt-1.5">
          {trip.duration_days > 0 && (
            <div className="flex items-center gap-1 text-white/60">
              <Clock className="h-3.5 w-3.5" />
              <span className="text-sm md:text-xs">{formatDuration(trip.duration_days)}</span>
            </div>
          )}
          {trip.price > 0 && (
            <span className="text-[15px] md:text-[13px] font-semibold text-white">
              {formatPrice(trip.price, trip.currency)}
            </span>
          )}
        </div>
      </div>
    </article>
  );
}

// Compact version for grid view - matching Flutter CompactTripCard
// Square image with carousel and info below
export function CompactTripCard({ trip, onFavoriteToggle, onClick }: MyTripCardProps) {
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [imageError, setImageError] = useState(false);
  const touchStartX = useRef<number | null>(null);

  // Filter valid images
  const images = (trip.images || [])
    .filter((img): img is string => typeof img === "string" && img.trim().length > 0)
    .slice(0, THEME.maxCarouselImages);
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
    if (Math.abs(diff) > 50) {
      if (diff > 0) nextImage();
      else prevImage();
    }
    touchStartX.current = null;
  };

  const formatPrice = (price: number, currency: string) => {
    const symbol = currency === "EUR" ? "€" : "$";
    return `${symbol}${price}`;
  };

  const formatDuration = (days: number) => {
    return days === 1 ? "1 day" : `${days} days`;
  };

  return (
    <div
      className="group cursor-pointer"
      onClick={() => onClick?.(trip)}
    >
      {/* Image - Square aspect ratio with carousel */}
      <div
        className="relative overflow-hidden shadow-md shadow-black/10 aspect-square md:rounded-[24px]"
        style={{ borderRadius: THEME.gridCardBorderRadius }}
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
            <MapPin className="h-8 w-8 md:h-12 md:w-12 text-white/50" />
          </div>
        )}

        {/* Gradient overlay for indicators */}
        {hasMultipleImages && (
          <div
            className="absolute left-0 right-0 bottom-0 h-[50px] pointer-events-none"
            style={{ background: "linear-gradient(to bottom, transparent, rgba(0,0,0,0.5))" }}
          />
        )}

        {/* Navigation arrows - always visible on mobile, hover on desktop */}
        {hasMultipleImages && (
          <>
            <Button
              variant="ghost"
              size="icon"
              className={cn(
                "absolute left-2 top-1/2 -translate-y-1/2 h-7 w-7 md:h-8 md:w-8 rounded-full bg-black/30 backdrop-blur-md text-white hover:bg-black/50 z-10",
                "md:opacity-0 md:group-hover:opacity-100 transition-opacity",
                currentImageIndex === 0 && "opacity-30 cursor-not-allowed"
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
                "absolute right-2 top-1/2 -translate-y-1/2 h-7 w-7 md:h-8 md:w-8 rounded-full bg-black/30 backdrop-blur-md text-white hover:bg-black/50 z-10",
                "md:opacity-0 md:group-hover:opacity-100 transition-opacity",
                currentImageIndex === images.length - 1 && "opacity-30 cursor-not-allowed"
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
          <div className="absolute bottom-2 left-2 right-2 md:bottom-3 md:left-3 md:right-3 flex gap-1 z-10">
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

        {/* Favorite button */}
        <button
          className="absolute top-2 right-2 md:top-3 md:right-3 p-1.5 md:p-2 rounded-full bg-black/30 backdrop-blur-md z-10 hover:bg-black/50 transition-colors"
          onClick={(e) => {
            e.stopPropagation();
            onFavoriteToggle?.(trip.id);
          }}
        >
          <Heart
            className={cn(
              "h-4 w-4 md:h-5 md:w-5 transition-colors",
              trip.is_favorite ? "fill-red-500 text-red-500" : "text-white"
            )}
          />
        </button>
      </div>

      {/* Info section - larger text on desktop */}
      <div className="pt-2 md:pt-3 space-y-0.5 md:space-y-1">
        {/* Title - 2 lines max */}
        <h3 className="font-semibold text-white text-sm md:text-base leading-tight line-clamp-2">
          {trip.title}
        </h3>

        {/* Location */}
        <p className="text-xs md:text-sm text-white/70 line-clamp-1">
          {trip.city}, {trip.country}
        </p>

        {/* Rating + Duration row */}
        <div className="flex items-center gap-2 text-xs md:text-sm">
          {trip.rating > 0 && (
            <div className="flex items-center gap-0.5 md:gap-1">
              <Star className="h-3 w-3 md:h-3.5 md:w-3.5 text-amber-400 fill-amber-400" />
              <span className="font-semibold text-white">{trip.rating.toFixed(1)}</span>
            </div>
          )}
          {trip.duration_days > 0 && (
            <div className="flex items-center gap-0.5 md:gap-1 text-white/50">
              <Clock className="h-3 w-3 md:h-3.5 md:w-3.5" />
              <span>{formatDuration(trip.duration_days)}</span>
            </div>
          )}
        </div>

        {/* Price */}
        {trip.price > 0 && (
          <p className="text-[13px] md:text-[15px] font-semibold text-white">
            {formatPrice(trip.price, trip.currency)}
          </p>
        )}
      </div>
    </div>
  );
}

// Skeleton for loading state
export function MyTripCardSkeleton() {
  return (
    <div>
      <div
        className="bg-white/5 animate-pulse h-[300px] md:h-[220px]"
        style={{ borderRadius: THEME.cardBorderRadius }}
      />
      <div className="pt-3 space-y-2">
        <div className="h-5 w-3/4 bg-white/5 rounded animate-pulse" />
        <div className="h-4 w-1/2 bg-white/5 rounded animate-pulse" />
        <div className="flex items-center gap-3">
          <div className="h-4 w-16 bg-white/5 rounded animate-pulse" />
          <div className="h-4 w-12 bg-white/5 rounded animate-pulse" />
        </div>
      </div>
    </div>
  );
}

// Compact skeleton for grid view
export function CompactTripCardSkeleton() {
  return (
    <div>
      <div
        className="bg-white/5 animate-pulse aspect-square"
        style={{ borderRadius: THEME.gridCardBorderRadius }}
      />
      <div className="pt-2 space-y-1.5">
        <div className="h-4 w-full bg-white/5 rounded animate-pulse" />
        <div className="h-3 w-2/3 bg-white/5 rounded animate-pulse" />
        <div className="h-3 w-1/3 bg-white/5 rounded animate-pulse" />
      </div>
    </div>
  );
}
