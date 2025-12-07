"use client";

import { useState, useEffect } from "react";
import { Star, MapPin, Clock, ChevronDown, Navigation, Utensils, Building2 } from "lucide-react";
import { cn } from "@/lib/utils";
import { DraggableBottomSheet } from "./draggable-bottom-sheet";
import { BottomSheetImageGallery } from "./bottom-sheet-image-gallery";
import { AnimatedCollapse } from "./animated-collapse";
import { parseOpeningHours } from "./utils";
import type { POIMarker } from "@/components/features/trips/trip-map";
import type { TripPlace } from "@/types/user-trip";
import type { TripPlace as PublicTripPlace } from "@/types/trip";

interface PlaceDetailsBottomSheetProps {
  isOpen: boolean;
  onClose: () => void;
  poi: POIMarker | null;
  placeData?: TripPlace | PublicTripPlace | null;
}

export function PlaceDetailsBottomSheet({
  isOpen,
  onClose,
  poi,
  placeData,
}: PlaceDetailsBottomSheetProps) {
  const [showFullDescription, setShowFullDescription] = useState(false);
  const [isHoursExpanded, setIsHoursExpanded] = useState(false);

  useEffect(() => {
    setShowFullDescription(false);
    setIsHoursExpanded(false);
  }, [poi?.id]);

  if (!poi) return null;

  const name = poi.name;
  const imageUrl = poi.imageUrl || (placeData as TripPlace)?.image_url || (placeData as PublicTripPlace)?.imageUrl;
  const rating = poi.rating || placeData?.rating;
  const category = poi.category || placeData?.category;
  const address = poi.address || placeData?.address;
  const description = placeData?.description || "";
  const price = placeData?.price;
  const cuisine = placeData?.cuisine;

  // Collect all images
  const allImages: string[] = [];
  if (imageUrl) allImages.push(imageUrl);
  const placeImages = (placeData as TripPlace)?.images || (placeData as PublicTripPlace)?.images;
  if (placeImages && Array.isArray(placeImages)) {
    for (const img of placeImages) {
      const url = typeof img === "string" ? img : (img as { url?: string })?.url;
      if (url && !allImages.includes(url)) allImages.push(url);
    }
  }

  const openingHours = (placeData as TripPlace)?.opening_hours || (placeData as PublicTripPlace)?.openingHours;
  const { status: hoursStatus, statusColor: hoursStatusColor, weekdayHours } = parseOpeningHours(openingHours);
  const hasDetailedHours = weekdayHours.length > 0;

  const shouldTruncate = description.length > 150;
  const displayDescription = shouldTruncate && !showFullDescription
    ? description.slice(0, 150) + "..."
    : description;

  const openInMaps = () => {
    if (poi.latitude && poi.longitude) {
      window.open(
        `https://www.google.com/maps/search/?api=1&query=${poi.latitude},${poi.longitude}`,
        "_blank"
      );
    } else if (address) {
      window.open(
        `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(address)}`,
        "_blank"
      );
    }
  };

  return (
    <DraggableBottomSheet isOpen={isOpen} onClose={onClose}>
      {/* Image Gallery - edge to edge, at top */}
      <BottomSheetImageGallery
        images={allImages}
        alt={name}
        onClose={onClose}
        type={poi.type}
      />

      {/* Content below image */}
      <div className="px-4 pb-8">
        {/* Name and rating */}
        <div className="mt-4">
          <div className="flex items-start justify-between gap-3">
            <h3 className="font-semibold text-white text-xl leading-tight">
              {name}
            </h3>
            {rating && rating > 0 && (
              <div className="flex items-center gap-1 flex-shrink-0">
                <Star className="h-5 w-5 text-amber-400 fill-amber-400" />
                <span className="text-base font-medium text-white">{rating.toFixed(1)}</span>
              </div>
            )}
          </div>

          {/* Tags */}
          <div className="flex items-center gap-2 mt-3 flex-wrap">
            {(cuisine || category) && (
              <span className={cn(
                "px-3 py-1.5 rounded-full text-sm font-medium capitalize",
                poi.type === "restaurant"
                  ? "bg-accent/20 text-accent"
                  : "bg-primary/20 text-primary"
              )}>
                {cuisine || category}
              </span>
            )}
            {price && (
              <span className="px-3 py-1.5 bg-green-500/20 text-green-400 rounded-full text-sm font-medium">
                {price}
              </span>
            )}
            <span className="px-3 py-1.5 bg-white/10 text-white/60 rounded-full text-sm">
              Day {poi.day}
            </span>
          </div>
        </div>

        {/* Description with see more/see less */}
        {description && (
          <div className="mt-4">
            <p className="text-base text-white/70 leading-relaxed">
              {displayDescription}
              {shouldTruncate && (
                <button
                  onClick={() => setShowFullDescription(!showFullDescription)}
                  className={cn(
                    "ml-1 text-sm font-medium",
                    poi.type === "restaurant" ? "text-accent" : "text-primary"
                  )}
                >
                  {showFullDescription ? "See less" : "See more"}
                </button>
              )}
            </p>
          </div>
        )}

        {/* Hours & Address grouped */}
        <div className="mt-4 space-y-1">
          {/* Hours - rounded top only */}
          <div className={cn(
            "bg-white/5 overflow-hidden",
            address ? "rounded-t-xl" : "rounded-xl"
          )}>
            <button
              onClick={() => hasDetailedHours && setIsHoursExpanded(!isHoursExpanded)}
              className={cn(
                "w-full flex items-center gap-3 p-4",
                hasDetailedHours && "hover:bg-white/5 cursor-pointer"
              )}
            >
              <Clock className={cn("h-5 w-5 flex-shrink-0", hoursStatusColor)} />
              <span className={cn("text-base flex-1 text-left", hoursStatusColor)}>
                {hoursStatus}
              </span>
              {hasDetailedHours && (
                <ChevronDown
                  className={cn(
                    "h-5 w-5 text-white/50 transition-transform duration-300",
                    isHoursExpanded && "rotate-180"
                  )}
                />
              )}
            </button>

            <AnimatedCollapse isOpen={isHoursExpanded}>
              <div className="px-4 pb-4 space-y-2 border-t border-white/5 pt-2">
                {weekdayHours.map((dayHours, idx) => {
                  const colonIndex = dayHours.indexOf(":");
                  const day = colonIndex > 0 ? dayHours.substring(0, colonIndex).trim() : dayHours;
                  const hours = colonIndex > 0 ? dayHours.substring(colonIndex + 1).trim() : "";
                  return (
                    <div key={idx} className="flex justify-between text-sm">
                      <span className="text-white/60">{day}</span>
                      <span className="text-white/40">{hours}</span>
                    </div>
                  );
                })}
              </div>
            </AnimatedCollapse>
          </div>

          {/* Address - rounded bottom only */}
          {address && (
            <div className="bg-white/5 rounded-b-xl p-4">
              <div className="flex items-start gap-3">
                <MapPin className="h-5 w-5 text-red-400 mt-0.5 flex-shrink-0" />
                <p className="text-base text-white/60 leading-relaxed">{address}</p>
              </div>
            </div>
          )}
        </div>

        {/* Action button */}
        <div className="mt-6">
          <button
            onClick={openInMaps}
            className={cn(
              "w-full flex items-center justify-center gap-2 py-4 px-4 rounded-xl text-base font-medium transition-colors",
              poi.type === "restaurant"
                ? "bg-accent text-white hover:bg-accent/90"
                : "bg-primary text-white hover:bg-primary/90"
            )}
          >
            <Navigation className="h-5 w-5" />
            <span>Get Directions</span>
          </button>
        </div>
      </div>
    </DraggableBottomSheet>
  );
}
