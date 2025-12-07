"use client";

import { useState, useRef, useEffect } from "react";
import Image from "next/image";
import { Star, MapPin, Clock, ChevronDown, Navigation, Utensils } from "lucide-react";
import { cn } from "@/lib/utils";
import { AnimatedCollapse } from "./animated-collapse";
import { ImageSliderGallery } from "./image-slider-gallery";
import { parseOpeningHours } from "./utils";
import type { TripPlace } from "@/types/user-trip";
import type { TripPlace as PublicTripPlace } from "@/types/trip";

interface CompactRestaurantCardProps {
  place: TripPlace | PublicTripPlace;
  dayNumber: number;
  index: number;
  isExpanded: boolean;
  onToggle: () => void;
}

export function CompactRestaurantCard({
  place,
  dayNumber,
  index,
  isExpanded,
  onToggle
}: CompactRestaurantCardProps) {
  const [showFullDescription, setShowFullDescription] = useState(false);
  const [isHoursExpanded, setIsHoursExpanded] = useState(false);
  const cardRef = useRef<HTMLDivElement>(null);

  // Auto-scroll to card when expanded
  useEffect(() => {
    if (isExpanded && cardRef.current) {
      // Small delay to allow animation to start
      const timer = setTimeout(() => {
        cardRef.current?.scrollIntoView({
          behavior: "smooth",
          block: "nearest",
        });
      }, 100);
      return () => clearTimeout(timer);
    }
  }, [isExpanded]);

  // Handle both snake_case (user trips) and camelCase (public trips)
  const imageUrl = (place as TripPlace).image_url ||
                   ((place as TripPlace).images?.[0] as { url?: string })?.url ||
                   (place as PublicTripPlace).imageUrl;
  const openingHours = (place as TripPlace).opening_hours ||
                       (place as PublicTripPlace).openingHours;

  const { status: hoursStatus, statusColor: hoursStatusColor, weekdayHours } = parseOpeningHours(openingHours);
  const hasDetailedHours = weekdayHours.length > 0;

  // Get all images
  const allImages: string[] = [];
  if (imageUrl) allImages.push(imageUrl);
  const placeImages = (place as TripPlace).images || (place as PublicTripPlace).images;
  if (placeImages && Array.isArray(placeImages)) {
    for (const img of placeImages) {
      const url = typeof img === "string" ? img : (img as { url?: string })?.url;
      if (url && !allImages.includes(url)) allImages.push(url);
    }
  }

  const openInMaps = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (place.latitude && place.longitude) {
      window.open(
        `https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}`,
        "_blank"
      );
    } else if (place.address) {
      window.open(
        `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(place.address)}`,
        "_blank"
      );
    }
  };

  const copyAddress = async (e: React.MouseEvent) => {
    e.stopPropagation();
    if (place.address) {
      await navigator.clipboard.writeText(place.address);
    }
  };

  const description = place.description || "";
  const shouldTruncate = description.length > 150;
  const displayDescription = shouldTruncate && !showFullDescription
    ? description.slice(0, 150) + "..."
    : description;

  return (
    <div
      ref={cardRef}
      className="bg-white/5 rounded-xl overflow-hidden cursor-pointer hover:bg-white/[0.07] transition-colors"
      onClick={onToggle}
    >
      {/* Compact view */}
      <div className="flex items-center gap-3 p-3">
        {/* Restaurant icon */}
        <div className="flex-shrink-0 w-6 h-6 rounded-full bg-accent/20 flex items-center justify-center">
          <Utensils className="h-3 w-3 text-accent" />
        </div>

        {/* Restaurant image */}
        <div className="flex-shrink-0 w-12 h-12 relative rounded-lg overflow-hidden">
          {imageUrl ? (
            <Image
              src={imageUrl}
              alt={place.name}
              fill
              className="object-cover"
            />
          ) : (
            <div className="w-full h-full bg-gradient-to-br from-accent/30 to-accent/10 flex items-center justify-center">
              <Utensils className="h-4 w-4 text-white/30" />
            </div>
          )}
        </div>

        {/* Restaurant info - compact */}
        <div className="flex-1 min-w-0">
          <h4 className="font-medium text-white text-sm leading-tight line-clamp-1">
            {place.name}
          </h4>
          <div className="flex items-center gap-2 mt-0.5">
            {place.rating && place.rating > 0 && (
              <div className="flex items-center gap-0.5">
                <Star className="h-3 w-3 text-amber-400 fill-amber-400" />
                <span className="text-xs text-white/70">{place.rating.toFixed(1)}</span>
              </div>
            )}
            {(place.cuisine || place.category) && (
              <span className="text-xs text-white/50 capitalize">
                {place.cuisine || place.category}
              </span>
            )}
          </div>
        </div>

        {/* Expand/collapse indicator */}
        <div className="flex-shrink-0">
          <ChevronDown
            className={cn(
              "h-4 w-4 text-white/50 transition-transform duration-300",
              isExpanded && "rotate-180"
            )}
          />
        </div>
      </div>

      {/* Expanded details with animation */}
      <AnimatedCollapse isOpen={isExpanded}>
        <div className="border-t border-white/5">
          {/* Image Gallery */}
          <ImageSliderGallery
            images={allImages}
            alt={place.name}
            height="h-48"
          />

          <div className="p-4 space-y-4">
            {/* Header with name, rating, cuisine */}
            <div>
              <div className="flex items-start justify-between gap-2">
                <h3 className="font-semibold text-white text-lg leading-tight">
                  {place.name}
                </h3>
                {place.rating && place.rating > 0 && (
                  <div className="flex items-center gap-1 bg-white/10 px-2 py-1 rounded-lg">
                    <Star className="h-4 w-4 text-amber-400 fill-amber-400" />
                    <span className="text-sm font-semibold text-white">{place.rating.toFixed(1)}</span>
                  </div>
                )}
              </div>

              <div className="flex items-center gap-2 mt-2 flex-wrap">
                {(place.cuisine || place.category) && (
                  <span className="px-2 py-1 bg-accent/20 text-accent rounded-full text-xs capitalize">
                    {place.cuisine || place.category}
                  </span>
                )}
                {place.price && (
                  <span className="px-2 py-1 bg-green-500/20 text-green-400 rounded-full text-xs">
                    {place.price}
                  </span>
                )}
              </div>
            </div>

            {/* Description */}
            {description && (
              <div>
                <h4 className="text-sm font-medium text-white/90 mb-1">About</h4>
                <p className="text-sm text-white/70 leading-relaxed">
                  {displayDescription}
                  {shouldTruncate && (
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        setShowFullDescription(!showFullDescription);
                      }}
                      className="text-accent hover:text-accent/80 ml-1"
                    >
                      {showFullDescription ? "See less" : "See more"}
                    </button>
                  )}
                </p>
              </div>
            )}

            {/* Info block - Hours & Address grouped */}
            <div className="space-y-1">
              {/* Opening hours - rounded top only */}
              <div className={cn(
                "bg-white/5 overflow-hidden",
                place.address ? "rounded-t-xl" : "rounded-xl"
              )}>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    if (hasDetailedHours) setIsHoursExpanded(!isHoursExpanded);
                  }}
                  className={cn(
                    "w-full flex items-center gap-3 p-3",
                    hasDetailedHours && "hover:bg-white/5"
                  )}
                >
                  <Clock className={cn("h-4 w-4 flex-shrink-0", hoursStatusColor)} />
                  <span className={cn("text-sm font-medium flex-1 text-left", hoursStatusColor)}>
                    {hoursStatus}
                  </span>
                  {hasDetailedHours && (
                    <ChevronDown
                      className={cn(
                        "h-4 w-4 text-white/50 transition-transform duration-300",
                        isHoursExpanded && "rotate-180"
                      )}
                    />
                  )}
                </button>

                {/* Weekday hours list */}
                <AnimatedCollapse isOpen={isHoursExpanded}>
                  <div className="px-3 pb-3 space-y-2 border-t border-white/5 pt-2">
                    {weekdayHours.map((dayHours, idx) => {
                      const colonIndex = dayHours.indexOf(":");
                      const day = colonIndex > 0 ? dayHours.substring(0, colonIndex).trim() : dayHours;
                      const hours = colonIndex > 0 ? dayHours.substring(colonIndex + 1).trim() : "";
                      return (
                        <div key={idx} className="flex justify-between text-sm">
                          <span className="text-white/70">{day}</span>
                          <span className="text-white/50">{hours}</span>
                        </div>
                      );
                    })}
                  </div>
                </AnimatedCollapse>
              </div>

              {/* Address - rounded bottom only */}
              {place.address && (
                <div className="bg-white/5 rounded-b-xl p-3">
                  <div className="flex items-start gap-3">
                    <MapPin className="h-4 w-4 text-red-400 mt-0.5 flex-shrink-0" />
                    <div className="flex-1">
                      <p className="text-sm text-white/70">{place.address}</p>
                      <button
                        onClick={copyAddress}
                        className="text-xs text-accent hover:text-accent/80 mt-1"
                      >
                        Copy address
                      </button>
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* Action buttons */}
            <div className="flex gap-2">
              {(place.address || (place.latitude && place.longitude)) && (
                <button
                  onClick={openInMaps}
                  className="flex-1 flex items-center justify-center gap-2 bg-accent text-white py-2.5 px-4 rounded-xl text-sm font-medium hover:bg-accent/90 transition-colors"
                >
                  <Navigation className="h-4 w-4" />
                  <span>Directions</span>
                </button>
              )}
            </div>
          </div>
        </div>
      </AnimatedCollapse>
    </div>
  );
}
