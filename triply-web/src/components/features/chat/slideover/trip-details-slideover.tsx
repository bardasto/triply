"use client";

import { useState } from "react";
import Image from "next/image";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { Button } from "@/components/ui/button";
import {
  MapPin,
  Clock,
  Star,
  Check,
  ChevronDown,
  ChevronUp,
  Calendar,
  DollarSign,
  Bookmark,
  X,
} from "lucide-react";
import { LottieIcon } from "@/components/ui/lottie-icon";
import { cn } from "@/lib/utils";
import type { AITripResponse, AITripDay, AITripPlace } from "@/types/ai-response";

interface TripDetailsSlideoverProps {
  trip: AITripResponse | null;
  isOpen: boolean;
  onClose: () => void;
  onSave?: () => void;
}

export function TripDetailsSlideover({
  trip,
  isOpen,
  onClose,
  onSave,
}: TripDetailsSlideoverProps) {
  const [expandedDays, setExpandedDays] = useState<Set<number>>(new Set([1]));
  const [isSaved, setIsSaved] = useState(false);

  if (!trip) return null;

  const toggleDay = (day: number) => {
    setExpandedDays((prev) => {
      const next = new Set(prev);
      if (next.has(day)) {
        next.delete(day);
      } else {
        next.add(day);
      }
      return next;
    });
  };

  const handleSave = () => {
    setIsSaved(!isSaved);
    onSave?.();
  };

  const handleShare = async () => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: trip.title,
          text: `Check out this trip to ${trip.city}, ${trip.country}!`,
        });
      } catch {
        // User cancelled
      }
    }
  };

  // Collect all images for gallery
  const getAllImages = (): string[] => {
    const images: string[] = [];
    if (trip.hero_image_url) images.push(trip.hero_image_url);
    if (trip.images) {
      for (const img of trip.images) {
        if (typeof img === "string" && !images.includes(img)) {
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
    return images.slice(0, 5);
  };

  const images = getAllImages();
  const totalPlaces = trip.itinerary?.reduce(
    (acc, day) => acc + (day.places?.length || 0),
    0
  ) || 0;

  return (
    <Sheet open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <SheetContent
        side="right"
        className="w-full sm:max-w-xl md:max-w-2xl lg:max-w-3xl p-0 border-white/10 bg-background overflow-hidden"
      >
        {/* Custom close button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 z-50 p-2 rounded-full bg-black/50 backdrop-blur-md text-white hover:bg-black/70 transition-colors"
        >
          <X className="h-4 w-4" />
        </button>

        <div className="h-full overflow-y-auto">
          {/* Hero Image Gallery */}
          <div className="relative">
            {images.length > 0 ? (
              <div className="grid grid-cols-4 grid-rows-2 gap-1 h-[280px]">
                {/* Main large image */}
                <div className="col-span-2 row-span-2 relative">
                  <Image
                    src={images[0]}
                    alt={trip.title}
                    fill
                    className="object-cover"
                  />
                </div>
                {/* Smaller images */}
                {images.slice(1, 5).map((img, index) => (
                  <div key={index} className="relative">
                    <Image
                      src={img}
                      alt={`${trip.title} ${index + 2}`}
                      fill
                      className="object-cover"
                    />
                  </div>
                ))}
              </div>
            ) : (
              <div className="h-[200px] bg-gradient-to-br from-primary to-primary/60 flex items-center justify-center">
                <MapPin className="h-16 w-16 text-white/30" />
              </div>
            )}

            {/* Gradient overlay */}
            <div className="absolute bottom-0 left-0 right-0 h-20 bg-gradient-to-t from-background to-transparent" />
          </div>

          {/* Content */}
          <div className="px-6 pb-8 -mt-8 relative z-10">
            {/* Header */}
            <SheetHeader className="p-0 mb-6">
              <div className="flex items-start justify-between gap-4">
                <div className="flex-1">
                  <SheetTitle className="text-2xl font-bold text-white leading-tight">
                    {trip.title}
                  </SheetTitle>
                  <div className="flex items-center gap-1.5 text-white/70 mt-2">
                    <MapPin className="h-4 w-4" />
                    <span>{trip.city}, {trip.country}</span>
                  </div>
                </div>

                {/* Action buttons */}
                <div className="flex items-center gap-2">
                  <Button
                    variant="ghost"
                    size="icon"
                    className="rounded-full bg-white/10 hover:bg-white/20"
                    onClick={handleShare}
                  >
                    <LottieIcon variant="misc" name="share" size={18} playOnHover />
                  </Button>
                  <Button
                    variant="ghost"
                    size="icon"
                    className="rounded-full bg-white/10 hover:bg-white/20"
                    onClick={handleSave}
                  >
                    <Bookmark
                      className={cn(
                        "h-4 w-4 transition-colors",
                        isSaved ? "fill-primary text-primary" : ""
                      )}
                    />
                  </Button>
                </div>
              </div>

              {/* Stats row */}
              <div className="flex items-center gap-4 mt-4 flex-wrap">
                {trip.rating && trip.rating > 0 && (
                  <div className="flex items-center gap-1">
                    <Star className="h-4 w-4 text-amber-400 fill-amber-400" />
                    <span className="font-semibold text-white">{trip.rating.toFixed(1)}</span>
                  </div>
                )}

                <div className="flex items-center gap-1 text-white/70">
                  <Clock className="h-4 w-4" />
                  <span>{trip.duration_days} {trip.duration_days === 1 ? 'day' : 'days'}</span>
                </div>

                <div className="flex items-center gap-1 text-white/70">
                  <Calendar className="h-4 w-4" />
                  <span>{totalPlaces} places</span>
                </div>

                <span className="text-lg font-bold text-white">
                  {trip.price}
                </span>

                {trip.activity_type && (
                  <span className="px-3 py-1 bg-primary/20 text-primary rounded-full text-sm capitalize">
                    {trip.activity_type.replace(/_/g, " ")}
                  </span>
                )}
              </div>
            </SheetHeader>

            {/* Description */}
            {trip.description && (
              <div className="mb-6">
                <h3 className="text-lg font-semibold text-white mb-2">About this trip</h3>
                <p className="text-white/80 leading-relaxed">{trip.description}</p>
              </div>
            )}

            {/* What's Included */}
            {trip.includes && trip.includes.length > 0 && (
              <div className="mb-6">
                <h3 className="text-lg font-semibold text-white mb-3">What&apos;s Included</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
                  {trip.includes.map((item, index) => (
                    <div key={index} className="flex items-start gap-2">
                      <div className="w-5 h-5 rounded-full bg-green-500/20 flex items-center justify-center flex-shrink-0 mt-0.5">
                        <Check className="h-3 w-3 text-green-500" />
                      </div>
                      <span className="text-white/80 text-sm">{item}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Highlights */}
            {trip.highlights && trip.highlights.length > 0 && (
              <div className="mb-6">
                <h3 className="text-lg font-semibold text-white mb-3">Highlights</h3>
                <div className="flex flex-wrap gap-2">
                  {trip.highlights.map((highlight, index) => (
                    <span
                      key={index}
                      className="px-3 py-1.5 bg-white/10 text-white/90 rounded-full text-sm"
                    >
                      {highlight}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {/* Itinerary */}
            {trip.itinerary && trip.itinerary.length > 0 && (
              <div>
                <h3 className="text-lg font-semibold text-white mb-4">Itinerary</h3>
                <div className="space-y-3">
                  {trip.itinerary.map((day) => (
                    <DayCard
                      key={day.day}
                      day={day}
                      isExpanded={expandedDays.has(day.day)}
                      onToggle={() => toggleDay(day.day)}
                    />
                  ))}
                </div>
              </div>
            )}

            {/* Best Season */}
            {trip.best_season && trip.best_season.length > 0 && (
              <div className="mt-6">
                <h3 className="text-lg font-semibold text-white mb-3">Best Time to Visit</h3>
                <div className="flex flex-wrap gap-2">
                  {trip.best_season.map((season, index) => (
                    <span
                      key={index}
                      className="px-3 py-1.5 bg-accent/20 text-accent rounded-full text-sm capitalize"
                    >
                      {season}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {/* Price breakdown */}
            {(trip.estimated_cost_min || trip.estimated_cost_max) && (
              <div className="mt-6 p-4 bg-white/5 rounded-xl border border-white/10">
                <h3 className="text-sm font-semibold text-white mb-2">Estimated Budget</h3>
                <div className="flex items-center gap-2">
                  <DollarSign className="h-5 w-5 text-green-400" />
                  <span className="text-lg font-bold text-white">
                    €{trip.estimated_cost_min} - €{trip.estimated_cost_max}
                  </span>
                </div>
              </div>
            )}
          </div>
        </div>
      </SheetContent>
    </Sheet>
  );
}

// Day Card Component
interface DayCardProps {
  day: AITripDay;
  isExpanded: boolean;
  onToggle: () => void;
}

function DayCard({ day, isExpanded, onToggle }: DayCardProps) {
  return (
    <div className="bg-white/5 border border-white/10 rounded-xl overflow-hidden">
      {/* Header */}
      <button
        className="w-full flex items-center justify-between p-4 hover:bg-white/5 transition-colors"
        onClick={onToggle}
      >
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center">
            <span className="text-primary font-bold">{day.day}</span>
          </div>
          <div className="text-left">
            <h4 className="font-semibold text-white">{day.title}</h4>
            <p className="text-xs text-white/60">{day.places?.length || 0} places</p>
          </div>
        </div>
        {isExpanded ? (
          <ChevronUp className="h-5 w-5 text-white/60" />
        ) : (
          <ChevronDown className="h-5 w-5 text-white/60" />
        )}
      </button>

      {/* Expanded content */}
      {isExpanded && (
        <div className="px-4 pb-4">
          {day.description && (
            <p className="text-sm text-white/70 mb-4 pl-[52px]">{day.description}</p>
          )}

          <div className="space-y-3">
            {day.places?.map((place, index) => (
              <PlaceCard key={place.poi_id || index} place={place} index={index + 1} />
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

// Place Card Component
interface PlaceCardProps {
  place: AITripPlace;
  index: number;
}

function PlaceCard({ place, index }: PlaceCardProps) {
  return (
    <div className="flex gap-3 ml-[52px]">
      {/* Thumbnail */}
      <div className="relative w-16 h-16 rounded-lg overflow-hidden flex-shrink-0">
        {place.image_url ? (
          <Image
            src={place.image_url}
            alt={place.name}
            fill
            className="object-cover"
          />
        ) : (
          <div className="w-full h-full bg-gradient-to-br from-primary/40 to-accent/40 flex items-center justify-center">
            <span className="text-white/50 font-bold">{index}</span>
          </div>
        )}
      </div>

      {/* Info */}
      <div className="flex-1 min-w-0">
        <h5 className="font-medium text-white text-sm line-clamp-1">{place.name}</h5>
        <p className="text-xs text-white/60 capitalize">{place.category}</p>

        <div className="flex items-center gap-2 mt-1 text-xs">
          {place.rating != null && place.rating > 0 && (
            <div className="flex items-center gap-0.5">
              <Star className="h-3 w-3 text-amber-400 fill-amber-400" />
              <span className="text-white">{place.rating.toFixed(1)}</span>
            </div>
          )}

          {place.duration_minutes != null && place.duration_minutes > 0 && (
            <div className="flex items-center gap-0.5 text-white/50">
              <Clock className="h-3 w-3" />
              <span>{place.duration_minutes}min</span>
            </div>
          )}

          {place.price && (
            <span className="font-medium text-white">{place.price}</span>
          )}
        </div>
      </div>
    </div>
  );
}
