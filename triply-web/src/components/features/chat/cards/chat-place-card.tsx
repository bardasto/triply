"use client";

import { useState, useRef, TouchEvent } from "react";
import Image from "next/image";
import {
  MapPin,
  Star,
  ChevronLeft,
  ChevronRight,
  ChevronRight as ExpandIcon,
  Bookmark,
  ExternalLink,
  Clock,
  DollarSign,
  Utensils,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import type { AIPlace, AISinglePlaceResponse } from "@/types/ai-response";

interface ChatPlaceCardProps {
  placeResponse: AISinglePlaceResponse;
  onExpand?: () => void;
  onSave?: () => void;
  className?: string;
}

interface SinglePlaceCardProps {
  place: AIPlace;
  isMain?: boolean;
  onExpand?: () => void;
  onSave?: () => void;
  className?: string;
}

const THEME = {
  cardBorderRadius: 20,
  indicatorHeight: 2.5,
  maxCarouselImages: 4,
};

// Helper to get place type icon
function getPlaceTypeIcon(placeType: string) {
  switch (placeType.toLowerCase()) {
    case 'restaurant':
    case 'cafe':
    case 'bar':
      return Utensils;
    default:
      return MapPin;
  }
}

// Helper to format price level
function formatPriceLevel(level?: number): string {
  if (!level) return '';
  return '$'.repeat(Math.min(level, 4));
}

// Single Place Card Component
export function SinglePlaceCard({
  place,
  isMain = false,
  onExpand,
  onSave,
  className,
}: SinglePlaceCardProps) {
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [imageError, setImageError] = useState(false);
  const [isSaved, setIsSaved] = useState(false);
  const touchStartX = useRef<number | null>(null);

  // Collect images
  const images: string[] = [];
  if (place.imageUrl) images.push(place.imageUrl);
  if (place.images) {
    for (const img of place.images) {
      if (img.url && !images.includes(img.url)) {
        images.push(img.url);
      }
    }
  }
  const displayImages = images.slice(0, THEME.maxCarouselImages);
  const hasImages = displayImages.length > 0 && !imageError;
  const hasMultipleImages = displayImages.length > 1;
  const safeImageIndex = displayImages.length > 0 ? Math.min(currentImageIndex, displayImages.length - 1) : 0;

  const nextImage = (e?: React.MouseEvent) => {
    e?.stopPropagation();
    setCurrentImageIndex((prev) => (prev + 1) % displayImages.length);
  };

  const prevImage = (e?: React.MouseEvent) => {
    e?.stopPropagation();
    setCurrentImageIndex((prev) => (prev - 1 + displayImages.length) % displayImages.length);
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

  const PlaceIcon = getPlaceTypeIcon(place.placeType);

  return (
    <div
      className={cn(
        "group bg-white/5 border border-white/10 overflow-hidden cursor-pointer hover:bg-white/[0.07] transition-colors",
        isMain ? "col-span-2 row-span-2" : "",
        className
      )}
      style={{ borderRadius: THEME.cardBorderRadius }}
      onClick={onExpand}
    >
      {/* Image Section */}
      <div
        className={cn(
          "relative overflow-hidden",
          isMain ? "h-[200px]" : "h-[140px]"
        )}
        onTouchStart={handleTouchStart}
        onTouchEnd={handleTouchEnd}
      >
        {hasImages ? (
          <Image
            src={displayImages[safeImageIndex]}
            alt={place.name}
            fill
            className="object-cover"
            onError={() => setImageError(true)}
          />
        ) : (
          <div className="absolute inset-0 flex items-center justify-center bg-gradient-to-br from-primary to-primary/60">
            <PlaceIcon className="h-10 w-10 text-white/50" />
          </div>
        )}

        {/* Gradient overlay */}
        <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />

        {/* Navigation arrows (main card only) */}
        {isMain && hasMultipleImages && (
          <>
            <Button
              variant="ghost"
              size="icon"
              className={cn(
                "absolute left-2 top-1/2 -translate-y-1/2 h-7 w-7 rounded-full bg-black/30 backdrop-blur-md text-white hover:bg-black/50 z-10",
                "opacity-0 group-hover:opacity-100 transition-opacity",
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
                "opacity-0 group-hover:opacity-100 transition-opacity",
                currentImageIndex === displayImages.length - 1 && "!opacity-30 cursor-not-allowed"
              )}
              onClick={nextImage}
              disabled={currentImageIndex === displayImages.length - 1}
            >
              <ChevronRight className="h-4 w-4" />
            </Button>
          </>
        )}

        {/* Bar indicators (main card only) */}
        {isMain && hasMultipleImages && (
          <div className="absolute bottom-3 left-3 right-3 flex gap-1 z-10">
            {displayImages.map((_, index) => (
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

        {/* Save button (main card only) */}
        {isMain && (
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
        )}

        {/* Place type badge */}
        <span className="absolute top-3 left-3 px-2.5 py-1 bg-white/90 text-gray-900 text-xs font-medium rounded-full capitalize">
          {place.placeType}
        </span>
      </div>

      {/* Info Section */}
      <div className={cn("p-3", isMain ? "space-y-2" : "space-y-1")}>
        {/* Name */}
        <h3 className={cn(
          "font-semibold text-white leading-tight",
          isMain ? "text-base line-clamp-2" : "text-sm line-clamp-1"
        )}>
          {place.name}
        </h3>

        {/* Location */}
        <div className="flex items-center gap-1.5 text-white/70 text-xs">
          <MapPin className="h-3 w-3 flex-shrink-0" />
          <span className="line-clamp-1">{place.city}, {place.country}</span>
        </div>

        {/* Stats row */}
        <div className="flex items-center gap-2 text-xs">
          {place.rating != null && place.rating > 0 && (
            <div className="flex items-center gap-0.5">
              <Star className="h-3 w-3 text-amber-400 fill-amber-400" />
              <span className="font-semibold text-white">{place.rating.toFixed(1)}</span>
            </div>
          )}

          {place.priceLevel && (
            <span className="text-green-400 font-medium">
              {formatPriceLevel(place.priceLevel)}
            </span>
          )}

          {place.cuisineTypes && place.cuisineTypes.length > 0 && (
            <span className="text-white/60 line-clamp-1">
              {place.cuisineTypes[0]}
            </span>
          )}
        </div>

        {/* Price + CTA (main card only) */}
        {isMain && (
          <>
            {place.estimatedPrice && (
              <div className="flex items-center gap-1 text-sm">
                <DollarSign className="h-3.5 w-3.5 text-white/60" />
                <span className="font-semibold text-white">{place.estimatedPrice}</span>
              </div>
            )}

            {/* Description preview */}
            {place.description && (
              <p className="text-xs text-white/60 line-clamp-2 mt-1">
                {place.description}
              </p>
            )}

            {/* Expand button */}
            <Button
              variant="ghost"
              size="sm"
              className="w-full mt-2 text-primary hover:text-primary hover:bg-primary/10 gap-1"
              onClick={(e) => {
                e.stopPropagation();
                onExpand?.();
              }}
            >
              View Details
              <ExpandIcon className="h-4 w-4" />
            </Button>
          </>
        )}
      </div>
    </div>
  );
}

// Main Chat Place Card with alternatives
export function ChatPlaceCard({
  placeResponse,
  onExpand,
  onSave,
  className,
}: ChatPlaceCardProps) {
  // Guard against missing data
  if (!placeResponse || !placeResponse.place) {
    return null;
  }

  const mainPlace = placeResponse.place;
  const alternatives = placeResponse.alternatives || [];
  const hasAlternatives = alternatives.length > 0;

  return (
    <div className={cn("space-y-3", className)}>
      {/* Main recommendation */}
      <SinglePlaceCard
        place={mainPlace}
        isMain
        onExpand={onExpand}
        onSave={onSave}
      />

      {/* Alternatives */}
      {hasAlternatives && (
        <div className="space-y-2">
          <p className="text-xs text-white/50 font-medium uppercase tracking-wider">
            Also Consider
          </p>
          <div className="grid grid-cols-2 gap-2">
            {alternatives.slice(0, 2).map((alt, index) => (
              <SinglePlaceCard
                key={alt.id || index}
                place={alt}
                onExpand={onExpand}
              />
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

// Compact version for inline display
export function ChatPlaceCardCompact({
  placeResponse,
  onExpand,
}: ChatPlaceCardProps) {
  // Guard against missing data
  if (!placeResponse || !placeResponse.place) {
    return null;
  }

  const place = placeResponse.place;

  return (
    <div
      className="group flex items-center gap-3 p-3 bg-white/5 border border-white/10 rounded-xl cursor-pointer hover:bg-white/[0.07] transition-colors"
      onClick={onExpand}
    >
      {/* Thumbnail */}
      <div className="relative w-14 h-14 rounded-lg overflow-hidden flex-shrink-0">
        {place.imageUrl ? (
          <Image
            src={place.imageUrl}
            alt={place.name}
            fill
            className="object-cover"
          />
        ) : (
          <div className="w-full h-full bg-gradient-to-br from-primary to-primary/60 flex items-center justify-center">
            <Utensils className="h-5 w-5 text-white/50" />
          </div>
        )}
      </div>

      {/* Info */}
      <div className="flex-1 min-w-0">
        <h4 className="font-medium text-white text-sm line-clamp-1">{place.name}</h4>
        <p className="text-xs text-white/60 mt-0.5 line-clamp-1">
          {place.placeType} • {place.city}
        </p>
        <div className="flex items-center gap-2 mt-1 text-xs">
          {place.rating != null && place.rating > 0 && (
            <div className="flex items-center gap-0.5">
              <Star className="h-3 w-3 text-amber-400 fill-amber-400" />
              <span className="text-white">{place.rating.toFixed(1)}</span>
            </div>
          )}
          {place.estimatedPrice && (
            <span className="font-semibold text-white">{place.estimatedPrice}</span>
          )}
        </div>
      </div>

      {/* Arrow */}
      <ExpandIcon className="h-4 w-4 text-white/40 group-hover:text-primary transition-colors" />
    </div>
  );
}
