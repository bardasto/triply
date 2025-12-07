"use client";

import { useState, useRef, TouchEvent } from "react";
import Image from "next/image";
import Link from "next/link";
import { Heart, Star, Clock, MapPin, ChevronLeft, ChevronRight } from "lucide-react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import type { Trip, TripImage } from "@/types/trip";

interface DBTripCardProps {
  trip: Trip;
  className?: string;
  priority?: boolean;
}

// Theme constants matching Flutter / My Trips design
const THEME = {
  cardBorderRadius: 20,
  indicatorHeight: 2.5,
  maxCarouselImages: 4,
};

/**
 * Format price for display
 */
function formatPrice(price: string | number | null, currency: string): string {
  if (!price) return "";

  if (typeof price === "string") {
    return price;
  }

  const symbol = currency === "EUR" ? "€" : "$";
  return `${symbol}${price}`;
}

/**
 * Format duration for display
 */
function formatDuration(duration: string | number | null): string {
  if (!duration) return "";

  if (typeof duration === "string") {
    return duration;
  }

  if (duration === 1) return "1 day";
  return `${duration} days`;
}

/**
 * Get image URL from TripImage or string
 */
function getImageUrl(image: TripImage | string): string {
  if (typeof image === "string") return image;
  return image.url;
}

export function DBTripCard({ trip, className, priority = false }: DBTripCardProps) {
  const [isLiked, setIsLiked] = useState(trip.isFavorite);
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [imageError, setImageError] = useState(false);
  const touchStartX = useRef<number | null>(null);

  // Get images array - use hero image as fallback, limit to 4 images
  const tripImages = trip.images && trip.images.length > 0
    ? trip.images.slice(0, THEME.maxCarouselImages)
    : trip.heroImageUrl
      ? [trip.heroImageUrl]
      : [];

  const hasImages = tripImages.length > 0 && !imageError;
  const hasMultipleImages = tripImages.length > 1;
  const safeImageIndex = tripImages.length > 0 ? Math.min(currentImageIndex, tripImages.length - 1) : 0;
  const currentImageUrl = hasImages ? getImageUrl(tripImages[safeImageIndex]) : "";

  const nextImage = (e?: React.MouseEvent) => {
    e?.preventDefault();
    e?.stopPropagation();
    setCurrentImageIndex((prev) => (prev + 1) % tripImages.length);
  };

  const prevImage = (e?: React.MouseEvent) => {
    e?.preventDefault();
    e?.stopPropagation();
    setCurrentImageIndex((prev) => (prev - 1 + tripImages.length) % tripImages.length);
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

  return (
    <article
      className={cn("group cursor-pointer", className)}
    >
      <Link href={`/trips/${trip.id}`} className="block">
        {/* Image - Square aspect ratio with carousel */}
        <div
          className="relative overflow-hidden shadow-md shadow-black/10 aspect-square"
          style={{ borderRadius: THEME.cardBorderRadius }}
          onTouchStart={handleTouchStart}
          onTouchEnd={handleTouchEnd}
        >
          {hasImages ? (
            <Image
              src={currentImageUrl}
              alt={trip.title}
              fill
              priority={priority && currentImageIndex === 0}
              className="object-cover"
              sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 25vw"
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
                  currentImageIndex === tripImages.length - 1 && "opacity-30 cursor-not-allowed"
                )}
                onClick={nextImage}
                disabled={currentImageIndex === tripImages.length - 1}
              >
                <ChevronRight className="h-4 w-4" />
              </Button>
            </>
          )}

          {/* Bar indicators */}
          {hasMultipleImages && (
            <div className="absolute bottom-2 left-2 right-2 md:bottom-3 md:left-3 md:right-3 flex gap-1 z-10">
              {tripImages.map((_, index) => (
                <button
                  key={index}
                  onClick={(e) => {
                    e.preventDefault();
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
              e.preventDefault();
              e.stopPropagation();
              setIsLiked(!isLiked);
            }}
          >
            <Heart
              className={cn(
                "h-4 w-4 md:h-5 md:w-5 transition-colors",
                isLiked ? "fill-red-500 text-red-500" : "text-white"
              )}
            />
          </button>
        </div>

        {/* Info section - matching My Trips design */}
        <div className="pt-2 md:pt-3 space-y-0.5 md:space-y-1">
          {/* Title - 2 lines max */}
          <h3 className="font-semibold text-foreground text-sm md:text-base leading-tight line-clamp-2 group-hover:text-primary transition-colors">
            {trip.title}
          </h3>

          {/* Location */}
          <p className="text-xs md:text-sm text-muted-foreground line-clamp-1">
            {trip.city}{trip.country && `, ${trip.country}`}
          </p>

          {/* Rating + Duration row */}
          <div className="flex items-center gap-2 text-xs md:text-sm">
            {trip.rating && trip.rating > 0 && (
              <div className="flex items-center gap-0.5 md:gap-1">
                <Star className="h-3 w-3 md:h-3.5 md:w-3.5 text-amber-400 fill-amber-400" />
                <span className="font-semibold text-foreground">{trip.rating.toFixed(1)}</span>
              </div>
            )}
            {trip.durationDays && (typeof trip.durationDays === "string" || trip.durationDays > 0) && (
              <div className="flex items-center gap-0.5 md:gap-1 text-muted-foreground">
                <Clock className="h-3 w-3 md:h-3.5 md:w-3.5" />
                <span>{formatDuration(trip.durationDays)}</span>
              </div>
            )}
          </div>

          {/* Price */}
          {trip.price && (
            <p className="text-[13px] md:text-[15px] font-semibold text-foreground">
              {formatPrice(trip.price, trip.currency)}
            </p>
          )}
        </div>
      </Link>
    </article>
  );
}

// Skeleton component for loading state
export function DBTripCardSkeleton() {
  return (
    <div>
      <div
        className="bg-muted animate-pulse aspect-square"
        style={{ borderRadius: THEME.cardBorderRadius }}
      />
      <div className="pt-2 md:pt-3 space-y-1.5">
        <div className="h-4 w-full bg-muted rounded animate-pulse" />
        <div className="h-3 w-2/3 bg-muted rounded animate-pulse" />
        <div className="h-3 w-1/3 bg-muted rounded animate-pulse" />
      </div>
    </div>
  );
}
