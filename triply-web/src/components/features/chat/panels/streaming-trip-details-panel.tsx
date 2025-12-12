"use client";

import { useState, useEffect, useRef } from "react";
import Image from "next/image";
import { Button } from "@/components/ui/button";
import {
  MapPin,
  Clock,
  Star,
  ChevronDown,
  Calendar,
  Bookmark,
  X,
  Building2,
  Utensils,
} from "lucide-react";
import { LottieIcon } from "@/components/ui/lottie-icon";
import { cn } from "@/lib/utils";
import type { StreamingTripState, StreamingPlace } from "@/types/streaming";
import { streamingStateToTripData } from "@/types/streaming";
import type { AITripResponse, AITripDay } from "@/types/ai-response";

// Skeleton components for loading states
function Skeleton({ className }: { className?: string }) {
  return (
    <div
      className={cn(
        "animate-pulse bg-white/10 rounded",
        className
      )}
    />
  );
}

function ImageSkeleton({ className }: { className?: string }) {
  return (
    <div
      className={cn(
        "animate-pulse bg-white/10",
        className
      )}
    />
  );
}

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

// Hook for simulated progress when real progress is stuck
function useSimulatedProgress(realProgress: number, phase: string, isComplete: boolean) {
  const [simulatedProgress, setSimulatedProgress] = useState(realProgress);
  const lastRealProgressRef = useRef(realProgress);
  const lastUpdateTimeRef = useRef(Date.now());

  useEffect(() => {
    // If real progress changed, update simulated to match
    if (realProgress !== lastRealProgressRef.current) {
      lastRealProgressRef.current = realProgress;
      lastUpdateTimeRef.current = Date.now();
      setSimulatedProgress(realProgress);
      return;
    }

    // Don't simulate if complete
    if (isComplete) return;

    // Simulate slow progress when stuck on long phases
    const interval = setInterval(() => {
      const timeSinceUpdate = Date.now() - lastUpdateTimeRef.current;

      // Start simulating after 2 seconds of no updates
      if (timeSinceUpdate > 2000) {
        setSimulatedProgress(prev => {
          // Calculate max progress based on current phase
          // Don't let simulated progress go too far ahead
          let maxProgress = realProgress + 0.15; // Max 15% ahead of real

          // Cap based on phase to prevent unrealistic jumps
          if (phase === 'skeleton' || phase === 'generating_skeleton') {
            maxProgress = Math.min(maxProgress, 0.45); // Cap at 45% during skeleton
          } else if (phase === 'days' || phase === 'places' || phase === 'assigning_places') {
            maxProgress = Math.min(maxProgress, 0.75); // Cap at 75% during places
          } else if (phase === 'images' || phase === 'loading_images') {
            maxProgress = Math.min(maxProgress, 0.95); // Cap at 95% during images
          }

          // Slow increment - about 1% every 2 seconds
          const increment = 0.005;
          const newProgress = Math.min(prev + increment, maxProgress);

          return newProgress;
        });
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [realProgress, phase, isComplete]);

  return simulatedProgress;
}

interface StreamingTripDetailsPanelProps {
  streamingState: StreamingTripState;
  isOpen: boolean;
  onClose: () => void;
}

export function StreamingTripDetailsPanel({
  streamingState,
  isOpen,
  onClose,
}: StreamingTripDetailsPanelProps) {
  const [expandedDays, setExpandedDays] = useState<Set<number>>(new Set([1]));
  const isMobile = useIsMobile();

  const {
    title,
    description,
    city,
    country,
    durationDays,
    heroImageUrl,
    days,
    places,
    restaurants,
    prices,
    estimatedBudget,
    thematicKeywords,
    isComplete,
    progress,
    phase,
  } = streamingState;

  // Use simulated progress for smoother UX during long AI generation phases
  const displayProgress = useSimulatedProgress(progress, phase, isComplete);

  // Don't render on mobile - mobile uses the card approach
  if (isMobile || !isOpen) return null;

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

  // Calculate total places and restaurants
  const totalPlaces = places.size;
  const totalRestaurants = restaurants.size;

  // Get price display
  const currency = prices?.currency || estimatedBudget.currency || 'EUR';
  const currencySymbol = currency === 'EUR' ? '€' : currency === 'USD' ? '$' : currency;

  // Calculate total price from places
  let totalPrice = 0;
  places.forEach((place) => {
    if (place.price_value && typeof place.price_value === 'number') {
      totalPrice += place.price_value;
    }
  });
  const priceDisplay = totalPrice > 0 ? `${currencySymbol}${totalPrice}` : null;

  // Build images array
  const images: string[] = [];
  if (heroImageUrl) images.push(heroImageUrl);
  places.forEach((place) => {
    if (place.image_url && !images.includes(place.image_url)) {
      images.push(place.image_url);
    }
  });

  // Convert days Map to sorted array
  const daysArray = Array.from(days.entries())
    .sort(([a], [b]) => a - b)
    .map(([dayNum, dayData]) => ({
      day: dayNum,
      ...dayData,
    }));

  // Get places for a specific day
  const getPlacesForDay = (dayNum: number): StreamingPlace[] => {
    const dayPlaces: { index: number; place: StreamingPlace }[] = [];
    places.forEach((place, key) => {
      if (key.startsWith(`${dayNum}-`)) {
        const index = parseInt(key.split('-')[1], 10) || 0;
        dayPlaces.push({ index, place });
      }
    });
    return dayPlaces.sort((a, b) => a.index - b.index).map(p => p.place);
  };

  // Get restaurants for a specific day
  const getRestaurantsForDay = (dayNum: number): StreamingPlace[] => {
    const dayRestaurants: { index: number; restaurant: StreamingPlace }[] = [];
    restaurants.forEach((restaurant, key) => {
      if (key.startsWith(`${dayNum}-`)) {
        const index = parseInt(key.split('-')[1], 10) || 0;
        dayRestaurants.push({ index, restaurant });
      }
    });
    return dayRestaurants.sort((a, b) => a.index - b.index).map(r => r.restaurant);
  };

  return (
    <div className="h-full flex flex-col bg-transparent overflow-hidden relative">
      {/* Close button */}
      <button
        onClick={onClose}
        className="absolute top-4 right-4 z-50 p-2.5 rounded-full bg-black/40 backdrop-blur-xl text-white hover:bg-black/60 transition-colors"
      >
        <X className="h-5 w-5" />
      </button>

      <div className="flex-1 overflow-y-auto">
        {/* Hero Image Gallery */}
        <div className="relative p-4 pb-0">
          {heroImageUrl ? (
            <div className="grid grid-cols-4 grid-rows-2 gap-2 h-[340px] overflow-hidden relative animate-in fade-in duration-500">
              {/* Main large image */}
              <div className="col-span-2 row-span-2 relative rounded-xl overflow-hidden">
                <Image
                  src={heroImageUrl}
                  alt={title || "Trip"}
                  fill
                  className="object-cover"
                />
              </div>
              {/* Smaller images or skeletons */}
              {[0, 1, 2, 3].map((index) => {
                const img = images[index + 1];
                return img ? (
                  <div key={index} className="relative overflow-hidden rounded-xl animate-in fade-in duration-300">
                    <Image
                      src={img}
                      alt={`${title} ${index + 2}`}
                      fill
                      className="object-cover"
                    />
                  </div>
                ) : (
                  <ImageSkeleton key={index} className="rounded-xl" />
                );
              })}
            </div>
          ) : (
            // Full skeleton for image gallery
            <div className="grid grid-cols-4 grid-rows-2 gap-2 h-[340px]">
              <ImageSkeleton className="col-span-2 row-span-2 rounded-xl" />
              <ImageSkeleton className="rounded-xl" />
              <ImageSkeleton className="rounded-xl" />
              <ImageSkeleton className="rounded-xl" />
              <ImageSkeleton className="rounded-xl" />
            </div>
          )}
        </div>

        {/* Content */}
        <div className="px-5 pb-6 pt-5">
          {/* Header */}
          <div className="mb-6">
            <div className="flex items-start justify-between gap-3">
              <div className="flex-1">
                {title ? (
                  <h2 className="text-2xl font-bold text-white leading-tight animate-in fade-in duration-300">
                    {title}
                  </h2>
                ) : (
                  <Skeleton className="h-8 w-3/4" />
                )}
                {city && country ? (
                  <div className="flex items-center gap-1.5 text-white/70 mt-2 text-base animate-in fade-in duration-300">
                    <MapPin className="h-4 w-4" />
                    <span>{city}, {country}</span>
                  </div>
                ) : (
                  <Skeleton className="h-5 w-1/2 mt-2" />
                )}
              </div>

              {/* Action buttons */}
              <div className="flex items-center gap-2">
                <Button
                  variant="ghost"
                  size="icon"
                  className="h-9 w-9 rounded-full bg-white/10 hover:bg-white/20"
                  disabled
                >
                  <LottieIcon variant="misc" name="share" size={18} playOnHover />
                </Button>
                <Button
                  variant="ghost"
                  size="icon"
                  className="h-9 w-9 rounded-full bg-white/10 hover:bg-white/20"
                  disabled
                >
                  <Bookmark className="h-4 w-4" />
                </Button>
              </div>
            </div>

            {/* Stats row */}
            <div className="flex items-center gap-4 mt-4 flex-wrap text-base">
              <div className="flex items-center gap-1">
                <Star className="h-4 w-4 text-amber-400 fill-amber-400" />
                <span className="font-semibold text-white">4.5</span>
              </div>

              {durationDays ? (
                <div className="flex items-center gap-1.5 text-white/70">
                  <Clock className="h-4 w-4" />
                  <span>{durationDays} {durationDays === 1 ? 'day' : 'days'}</span>
                </div>
              ) : (
                <Skeleton className="h-5 w-16" />
              )}

              <div className="flex items-center gap-1.5 text-white/70">
                <Building2 className="h-4 w-4" />
                <span>{totalPlaces} places</span>
              </div>

              {totalRestaurants > 0 && (
                <div className="flex items-center gap-1.5 text-white/70">
                  <Utensils className="h-4 w-4" />
                  <span>{totalRestaurants} restaurants</span>
                </div>
              )}

              {priceDisplay ? (
                <span className="text-lg font-bold text-white">
                  {priceDisplay}
                </span>
              ) : (
                <Skeleton className="h-6 w-16" />
              )}
            </div>
          </div>

          {/* Description - show when available after skeleton phase, or skeleton */}
          <div className="mb-6">
            <h3 className="text-base font-semibold text-white mb-2">About this trip</h3>
            {description && phase !== 'init' && phase !== 'skeleton' ? (
              <p className="text-white/80 text-base leading-relaxed animate-in fade-in duration-300">{description}</p>
            ) : (
              <div className="space-y-2">
                <Skeleton className="h-4 w-full" />
                <Skeleton className="h-4 w-5/6" />
                <Skeleton className="h-4 w-4/6" />
              </div>
            )}
          </div>

          {/* Highlights - show as they arrive */}
          {thematicKeywords && thematicKeywords.length > 0 && (
            <div className="mb-6">
              <h3 className="text-base font-semibold text-white mb-3">Highlights</h3>
              <div className="flex flex-wrap gap-2">
                {thematicKeywords.map((keyword, index) => (
                  <span
                    key={index}
                    className="px-3 py-1.5 bg-white/10 text-white/90 rounded-full text-sm animate-in fade-in duration-300"
                  >
                    {keyword}
                  </span>
                ))}
              </div>
            </div>
          )}

          {/* Itinerary - progressively show days and places */}
          <div>
            <h3 className="text-base font-semibold text-white mb-3">Itinerary</h3>
            <div className="space-y-2.5">
              {daysArray.length > 0 ? (
                <>
                  {/* Show loaded days */}
                  {daysArray.map((day) => (
                    <StreamingDayCard
                      key={day.day}
                      dayNumber={day.day}
                      title={day.title}
                      description={day.description}
                      slotsCount={day.slotsCount}
                      restaurantsCount={day.restaurantsCount}
                      places={getPlacesForDay(day.day)}
                      restaurants={getRestaurantsForDay(day.day)}
                      isExpanded={expandedDays.has(day.day)}
                      onToggle={() => toggleDay(day.day)}
                    />
                  ))}
                  {/* Show skeleton for remaining days if we know the duration */}
                  {durationDays && daysArray.length < durationDays && (
                    Array.from({ length: durationDays - daysArray.length }, (_, i) => (
                      <DayCardSkeleton key={`skeleton-${i}`} dayNumber={daysArray.length + i + 1} />
                    ))
                  )}
                </>
              ) : (
                // Show skeleton days while loading (before any days arrive)
                Array.from({ length: durationDays || 3 }, (_, i) => (
                  <DayCardSkeleton key={`skeleton-${i}`} dayNumber={i + 1} />
                ))
              )}
            </div>
          </div>

          {/* Progress indicator at bottom */}
          {!isComplete && (
            <div className="mt-6 p-4 bg-white/5 rounded-xl border border-white/10">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-white/70">
                  {phase === 'skeleton' || phase === 'generating_skeleton'
                    ? 'Creating structure...'
                    : phase === 'days' || phase === 'places' || phase === 'assigning_places'
                    ? 'Finding places...'
                    : phase === 'images' || phase === 'loading_images'
                    ? 'Loading images...'
                    : 'Generating trip...'}
                </span>
                <span className="text-sm font-medium text-primary">{Math.round(displayProgress * 100)}%</span>
              </div>
              <div className="w-full h-1.5 bg-white/10 rounded-full overflow-hidden">
                <div
                  className="h-full bg-primary rounded-full transition-all duration-500 ease-out"
                  style={{ width: `${displayProgress * 100}%` }}
                />
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// Day Card Skeleton
function DayCardSkeleton({ dayNumber }: { dayNumber: number }) {
  return (
    <div className="border border-white/10 rounded-2xl overflow-hidden">
      <div className="bg-white/5 px-4 py-3 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-primary/50 flex items-center justify-center">
            <span className="text-white font-bold text-sm">{dayNumber}</span>
          </div>
          <div>
            <Skeleton className="h-5 w-32 mb-1" />
            <Skeleton className="h-3 w-20" />
          </div>
        </div>
        <ChevronDown className="h-5 w-5 text-white/30" />
      </div>
    </div>
  );
}

// Streaming Day Card with progressive place loading
interface StreamingDayCardProps {
  dayNumber: number;
  title: string;
  description: string;
  slotsCount: number;
  restaurantsCount?: number;
  places: StreamingPlace[];
  restaurants: StreamingPlace[];
  isExpanded: boolean;
  onToggle: () => void;
}

function StreamingDayCard({
  dayNumber,
  title,
  description,
  slotsCount,
  restaurantsCount = 0,
  places,
  restaurants,
  isExpanded,
  onToggle,
}: StreamingDayCardProps) {
  const [activeTab, setActiveTab] = useState<"places" | "restaurants">("places");
  const loadedPlacesCount = places.length;
  const loadedRestaurantsCount = restaurants.length;
  const remainingPlaceSlots = Math.max(0, slotsCount - loadedPlacesCount);
  const remainingRestaurantSlots = Math.max(0, restaurantsCount - loadedRestaurantsCount);
  const hasRestaurants = restaurantsCount > 0 || restaurants.length > 0;

  return (
    <div className="border border-white/10 rounded-2xl overflow-hidden animate-in fade-in slide-in-from-bottom-2 duration-300">
      {/* Day header */}
      <button
        onClick={onToggle}
        className="w-full bg-white/5 px-4 py-3 flex items-center justify-between hover:bg-white/[0.07] transition-colors"
      >
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center">
            <span className="text-white font-bold text-sm">{dayNumber}</span>
          </div>
          <div className="text-left">
            <h3 className="font-semibold text-white text-base">{title}</h3>
            <p className="text-xs text-white/50">
              {loadedPlacesCount} places{hasRestaurants && `, ${loadedRestaurantsCount} restaurants`}
            </p>
          </div>
        </div>
        <ChevronDown
          className={cn(
            "h-5 w-5 text-white/50 transition-transform duration-300",
            isExpanded && "rotate-180"
          )}
        />
      </button>

      {/* Collapsible content */}
      {isExpanded && (
        <div className="border-t border-white/5">
          {description && (
            <p className="text-sm text-white/70 px-4 pt-3">{description}</p>
          )}

          {/* Tabs for places/restaurants */}
          {hasRestaurants && (
            <div className="flex border-b border-white/10 mx-3 mt-2">
              <button
                onClick={() => setActiveTab("places")}
                className={cn(
                  "flex-1 py-2 px-3 text-xs font-medium transition-colors",
                  activeTab === "places"
                    ? "text-primary border-b-2 border-primary -mb-[1px]"
                    : "text-white/60 hover:text-white"
                )}
              >
                <div className="flex items-center justify-center gap-1">
                  <Building2 className="h-3 w-3" />
                  <span>Places ({loadedPlacesCount})</span>
                </div>
              </button>
              <button
                onClick={() => setActiveTab("restaurants")}
                className={cn(
                  "flex-1 py-2 px-3 text-xs font-medium transition-colors",
                  activeTab === "restaurants"
                    ? "text-accent border-b-2 border-accent -mb-[1px]"
                    : "text-white/60 hover:text-white"
                )}
              >
                <div className="flex items-center justify-center gap-1">
                  <Utensils className="h-3 w-3" />
                  <span>Restaurants ({loadedRestaurantsCount})</span>
                </div>
              </button>
            </div>
          )}

          <div className="p-3 space-y-2">
            {/* Places tab */}
            {activeTab === "places" && (
              <>
                {/* Loaded places */}
                {places.map((place, index) => (
                  <StreamingPlaceCard
                    key={`${dayNumber}-place-${index}`}
                    place={place}
                    index={index}
                  />
                ))}

                {/* Skeleton places for remaining slots */}
                {Array.from({ length: remainingPlaceSlots }, (_, i) => (
                  <PlaceCardSkeleton key={`place-skeleton-${i}`} index={loadedPlacesCount + i} />
                ))}
              </>
            )}

            {/* Restaurants tab */}
            {activeTab === "restaurants" && hasRestaurants && (
              <>
                {/* Loaded restaurants */}
                {restaurants.map((restaurant, index) => (
                  <StreamingPlaceCard
                    key={`${dayNumber}-restaurant-${index}`}
                    place={restaurant}
                    index={index}
                  />
                ))}

                {/* Skeleton restaurants for remaining slots */}
                {Array.from({ length: remainingRestaurantSlots }, (_, i) => (
                  <PlaceCardSkeleton key={`restaurant-skeleton-${i}`} index={loadedRestaurantsCount + i} />
                ))}

                {loadedRestaurantsCount === 0 && remainingRestaurantSlots === 0 && (
                  <p className="text-center text-white/50 py-4 text-sm">
                    No restaurants planned for this day
                  </p>
                )}
              </>
            )}

            {/* Show message when no places */}
            {activeTab === "places" && loadedPlacesCount === 0 && remainingPlaceSlots === 0 && (
              <p className="text-center text-white/50 py-4 text-sm">
                No places planned for this day
              </p>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

// Streaming Place Card
interface StreamingPlaceCardProps {
  place: StreamingPlace;
  index: number;
}

function StreamingPlaceCard({ place, index }: StreamingPlaceCardProps) {
  const isRestaurant = ['breakfast', 'lunch', 'dinner'].includes((place.category || '').toLowerCase());

  return (
    <div className="bg-white/5 rounded-xl overflow-hidden animate-in fade-in slide-in-from-left-2 duration-300">
      <div className="flex items-center gap-3 p-3">
        {/* Place number */}
        <div className={cn(
          "flex-shrink-0 w-6 h-6 rounded-full flex items-center justify-center",
          isRestaurant ? "bg-accent/20" : "bg-primary/20"
        )}>
          <span className={cn(
            "text-xs font-semibold",
            isRestaurant ? "text-accent" : "text-primary"
          )}>{index + 1}</span>
        </div>

        {/* Place image */}
        <div className="flex-shrink-0 w-12 h-12 relative rounded-lg overflow-hidden">
          {place.image_url ? (
            <Image
              src={place.image_url}
              alt={place.name}
              fill
              className="object-cover"
            />
          ) : (
            <div className="w-full h-full bg-gradient-to-br from-primary/30 to-primary/10 flex items-center justify-center">
              {isRestaurant ? (
                <Utensils className="h-4 w-4 text-white/30" />
              ) : (
                <Building2 className="h-4 w-4 text-white/30" />
              )}
            </div>
          )}
        </div>

        {/* Place info */}
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
            {place.duration_minutes && (
              <span className="text-xs text-white/50">{place.duration_minutes} min</span>
            )}
            {place.price && (
              <span className="text-xs font-medium text-white">{place.price}</span>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

// Place Card Skeleton
function PlaceCardSkeleton({ index }: { index: number }) {
  return (
    <div className="bg-white/5 rounded-xl overflow-hidden">
      <div className="flex items-center gap-3 p-3">
        {/* Place number */}
        <div className="flex-shrink-0 w-6 h-6 rounded-full bg-primary/20 flex items-center justify-center">
          <span className="text-xs font-semibold text-primary/50">{index + 1}</span>
        </div>

        {/* Image skeleton */}
        <Skeleton className="flex-shrink-0 w-12 h-12 rounded-lg" />

        {/* Info skeleton */}
        <div className="flex-1 min-w-0">
          <Skeleton className="h-4 w-3/4 mb-1.5" />
          <Skeleton className="h-3 w-1/2" />
        </div>
      </div>
    </div>
  );
}
