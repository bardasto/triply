"use client";

import { useState, useRef, useLayoutEffect, useEffect } from "react";
import Image from "next/image";
import { Button } from "@/components/ui/button";
import { DraggableBottomSheet } from "@/components/features/trips/trip-details/draggable-bottom-sheet";
import {
  MapPin,
  Clock,
  Star,
  Check,
  ChevronDown,
  Calendar,
  DollarSign,
  Bookmark,
  Share2,
  X,
  Building2,
  Utensils,
  Navigation,
  ChevronLeft,
  ChevronRight,
  Images,
} from "lucide-react";
import { cn } from "@/lib/utils";
import type { AITripResponse, AITripDay, AITripPlace } from "@/types/ai-response";
import { ChatTripMap } from "./chat-trip-map";
import { FullscreenPhotoGallery } from "@/components/features/trips/trip-details/fullscreen-photo-gallery";

// Animated collapse component
function AnimatedCollapse({ isOpen, children }: { isOpen: boolean; children: React.ReactNode }) {
  const contentRef = useRef<HTMLDivElement>(null);
  const wrapperRef = useRef<HTMLDivElement>(null);

  useLayoutEffect(() => {
    const wrapper = wrapperRef.current;
    const content = contentRef.current;
    if (!wrapper || !content) return;

    if (isOpen) {
      const contentHeight = content.scrollHeight;
      wrapper.style.height = `${contentHeight}px`;
      const timer = setTimeout(() => {
        wrapper.style.height = "auto";
      }, 300);
      return () => clearTimeout(timer);
    } else {
      const contentHeight = content.scrollHeight;
      wrapper.style.height = `${contentHeight}px`;
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          wrapper.style.height = "0px";
        });
      });
    }
  }, [isOpen]);

  return (
    <div
      ref={wrapperRef}
      style={{
        height: isOpen ? "auto" : 0,
        overflow: "hidden",
        transition: "height 300ms cubic-bezier(0.4, 0, 0.2, 1)",
      }}
    >
      <div ref={contentRef}>{children}</div>
    </div>
  );
}

// Mobile Image Carousel Component
function MobileImageCarousel({ images, title }: { images: string[]; title: string }) {
  const [currentIndex, setCurrentIndex] = useState(0);
  const touchStartX = useRef<number | null>(null);

  const handleTouchStart = (e: React.TouchEvent) => {
    touchStartX.current = e.touches[0].clientX;
  };

  const handleTouchEnd = (e: React.TouchEvent) => {
    if (touchStartX.current === null) return;
    const touchEndX = e.changedTouches[0].clientX;
    const diff = touchStartX.current - touchEndX;
    const minSwipeDistance = 50;

    if (Math.abs(diff) > minSwipeDistance) {
      if (diff > 0 && currentIndex < images.length - 1) {
        setCurrentIndex(currentIndex + 1);
      } else if (diff < 0 && currentIndex > 0) {
        setCurrentIndex(currentIndex - 1);
      }
    }
    touchStartX.current = null;
  };

  return (
    <div
      className="relative h-[320px] overflow-hidden rounded-b-3xl"
      onTouchStart={handleTouchStart}
      onTouchEnd={handleTouchEnd}
    >
      <Image
        src={images[currentIndex]}
        alt={title}
        fill
        className="object-cover"
      />
      {/* Gradient overlay */}
      <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />

      {/* Bar indicators - only at bottom */}
      {images.length > 1 && (
        <div className="absolute bottom-4 left-4 right-4 flex gap-1.5">
          {images.map((_, idx) => (
            <button
              key={idx}
              onClick={() => setCurrentIndex(idx)}
              className="flex-1 h-[3px] rounded-full transition-all"
              style={{
                backgroundColor: idx === currentIndex ? "white" : "rgba(255,255,255,0.4)",
              }}
            />
          ))}
        </div>
      )}
    </div>
  );
}

interface TripDetailsPanelProps {
  trip: AITripResponse | null;
  isOpen: boolean;
  onClose: () => void;
  onSave?: () => void;
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

export function TripDetailsPanel({
  trip,
  isOpen,
  onClose,
  onSave,
}: TripDetailsPanelProps) {
  const [expandedDays, setExpandedDays] = useState<Set<number>>(new Set([1]));
  const [isSaved, setIsSaved] = useState(false);
  const [mapSelectedDay, setMapSelectedDay] = useState<number | null>(null);
  const [targetPlace, setTargetPlace] = useState<{ day: number; index: number } | null>(null);
  const [isGalleryOpen, setIsGalleryOpen] = useState(false);
  const [galleryInitialIndex, setGalleryInitialIndex] = useState(0);
  const isMobile = useIsMobile();

  if (!trip || !isOpen) return null;

  const handleViewPlaceDetails = (day: number, placeIndex: number) => {
    // Close all days and open only the target day
    setExpandedDays(new Set([day]));
    // Set the target place to expand
    setTargetPlace({ day, index: placeIndex });
  };

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

  // Collect all images for gallery with source names
  const getAllImagesWithSources = (): { images: string[]; sourceNames: (string | undefined)[] } => {
    const images: string[] = [];
    const sourceNames: (string | undefined)[] = [];

    if (trip.hero_image_url) {
      images.push(trip.hero_image_url);
      sourceNames.push(trip.title); // Hero image belongs to the trip
    }
    if (trip.images) {
      for (const img of trip.images) {
        if (typeof img === "string" && !images.includes(img)) {
          images.push(img);
          sourceNames.push(trip.title);
        }
      }
    }
    // Extract from itinerary
    if (trip.itinerary) {
      for (const day of trip.itinerary) {
        for (const place of day.places || []) {
          if (place.image_url && !images.includes(place.image_url)) {
            images.push(place.image_url);
            sourceNames.push(place.name);
          }
        }
      }
    }
    return { images, sourceNames };
  };

  const { images: allImages, sourceNames: allSourceNames } = getAllImagesWithSources();
  const images = allImages.slice(0, 5); // Display up to 5 in grid

  const handleOpenGallery = (index: number = 0) => {
    setGalleryInitialIndex(index);
    setIsGalleryOpen(true);
  };
  const totalPlaces = trip.itinerary?.reduce(
    (acc, day) => acc + (day.places?.length || 0),
    0
  ) || 0;

  // Content component to avoid duplication
  const panelContent = (
    <>
      {/* Close button - only on desktop, mobile uses drag to close */}
      {!isMobile && (
        <button
          onClick={onClose}
          className="absolute top-4 right-4 z-50 p-2.5 rounded-full bg-black/40 backdrop-blur-xl text-white hover:bg-black/60 transition-colors"
        >
          <X className="h-5 w-5" />
        </button>
      )}

      <div className={cn("flex-1", !isMobile && "overflow-y-auto")}>
        {/* Hero Image Gallery - Mobile optimized */}
        <div className={cn("relative", !isMobile && "p-4 pb-0")}>
          {images.length > 0 ? (
            isMobile ? (
              // Mobile: Single image carousel
              <MobileImageCarousel images={images} title={trip.title} />
            ) : (
              // Desktop: Grid layout
              <div className="grid grid-cols-4 grid-rows-2 gap-2 h-[340px] overflow-hidden relative">
                {/* Main large image */}
                <button
                  onClick={() => handleOpenGallery(0)}
                  className="col-span-2 row-span-2 relative rounded-xl overflow-hidden cursor-pointer group"
                >
                  <Image
                    src={images[0]}
                    alt={trip.title}
                    fill
                    className="object-cover transition-transform duration-300 group-hover:scale-105"
                  />
                  <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors" />
                </button>
                {/* Smaller images - all with rounded corners */}
                {images.slice(1, 5).map((img, index) => (
                  <button
                    key={index}
                    onClick={() => handleOpenGallery(index + 1)}
                    className="relative overflow-hidden rounded-xl cursor-pointer group"
                  >
                    <Image
                      src={img}
                      alt={`${trip.title} ${index + 2}`}
                      fill
                      className="object-cover transition-transform duration-300 group-hover:scale-105"
                    />
                    <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors" />
                  </button>
                ))}

                {/* View All Photos button */}
                {allImages.length > 0 && (
                  <button
                    onClick={() => handleOpenGallery(0)}
                    className="absolute bottom-3 right-3 z-10 flex items-center gap-1.5 px-3 py-2 bg-black/50 backdrop-blur-md text-white text-sm font-medium rounded-full hover:bg-black/70 transition-colors"
                  >
                    <Images className="h-4 w-4" />
                    <span>{allImages.length} photos</span>
                  </button>
                )}
              </div>
            )
          ) : (
            <div className={cn(
              "bg-gradient-to-br from-primary to-primary/60 flex items-center justify-center",
              isMobile ? "h-[250px]" : "h-[200px] rounded-xl"
            )}>
              <MapPin className="h-12 w-12 text-white/30" />
            </div>
          )}
        </div>

        {/* Content */}
        <div className="px-5 pb-6 pt-5">
          {/* Header */}
          <div className="mb-6">
            <div className="flex items-start justify-between gap-3">
              <div className="flex-1">
                <h2 className="text-2xl font-bold text-white leading-tight">
                  {trip.title}
                </h2>
                <div className="flex items-center gap-1.5 text-white/70 mt-2 text-base">
                  <MapPin className="h-4 w-4" />
                  <span>{trip.city}, {trip.country}</span>
                </div>
              </div>

              {/* Action buttons */}
              <div className="flex items-center gap-2">
                <Button
                  variant="ghost"
                  size="icon"
                  className="h-9 w-9 rounded-full bg-white/10 hover:bg-white/20"
                  onClick={handleShare}
                >
                  <Share2 className="h-4 w-4" />
                </Button>
                <Button
                  variant="ghost"
                  size="icon"
                  className="h-9 w-9 rounded-full bg-white/10 hover:bg-white/20"
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
            <div className="flex items-center gap-4 mt-4 flex-wrap text-base">
              {trip.rating && trip.rating > 0 && (
                <div className="flex items-center gap-1">
                  <Star className="h-4 w-4 text-amber-400 fill-amber-400" />
                  <span className="font-semibold text-white">{trip.rating.toFixed(1)}</span>
                </div>
              )}

              <div className="flex items-center gap-1.5 text-white/70">
                <Clock className="h-4 w-4" />
                <span>{trip.duration_days} {trip.duration_days === 1 ? 'day' : 'days'}</span>
              </div>

              <div className="flex items-center gap-1.5 text-white/70">
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
          </div>

          {/* Description */}
          {trip.description && (
            <div className="mb-6">
              <h3 className="text-base font-semibold text-white mb-2">About this trip</h3>
              <p className="text-white/80 text-base leading-relaxed">{trip.description}</p>
            </div>
          )}

          {/* What's Included */}
          {trip.includes && trip.includes.length > 0 && (
            <div className="mb-6">
              <h3 className="text-base font-semibold text-white mb-3">What&apos;s Included</h3>
              <div className="grid grid-cols-1 gap-2">
                {trip.includes.map((item, index) => (
                  <div key={index} className="flex items-start gap-2.5">
                    <div className="w-5 h-5 rounded-full bg-green-500/20 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <Check className="h-3 w-3 text-green-500" />
                    </div>
                    <span className="text-white/80 text-base">{item}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Highlights */}
          {trip.highlights && trip.highlights.length > 0 && (
            <div className="mb-6">
              <h3 className="text-base font-semibold text-white mb-3">Highlights</h3>
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
              <h3 className="text-base font-semibold text-white mb-3">Itinerary</h3>
              <div className="space-y-2.5">
                {trip.itinerary.map((day) => (
                  <DayCard
                    key={day.day}
                    day={day}
                    isExpanded={expandedDays.has(day.day)}
                    onToggle={() => toggleDay(day.day)}
                    targetPlaceIndex={targetPlace?.day === day.day ? targetPlace.index : null}
                    onTargetPlaceHandled={() => setTargetPlace(null)}
                  />
                ))}
              </div>
            </div>
          )}

          {/* Map with Day Selector */}
          {trip.itinerary && trip.itinerary.length > 0 && (
            <div className="mt-6">
              <h3 className="text-base font-semibold text-white mb-3">Map</h3>

              {isMobile ? (
                // Mobile: Horizontal scrollable day selector above map
                <div className="space-y-3">
                  {/* Horizontal day selector */}
                  <div className="flex gap-2 overflow-x-auto pb-2 -mx-5 px-5 scrollbar-hide">
                    <button
                      onClick={() => setMapSelectedDay(null)}
                      className={cn(
                        "flex-shrink-0 py-2 px-4 rounded-full text-sm font-medium transition-all",
                        mapSelectedDay === null
                          ? "bg-primary text-white"
                          : "bg-white/10 text-white/70"
                      )}
                    >
                      All
                    </button>
                    {trip.itinerary.map((day) => {
                      const isSelected = mapSelectedDay === day.day;
                      return (
                        <button
                          key={day.day}
                          onClick={() => setMapSelectedDay(isSelected ? null : day.day)}
                          className={cn(
                            "flex-shrink-0 py-2 px-4 rounded-full text-sm font-medium transition-all",
                            isSelected
                              ? "bg-primary text-white"
                              : "bg-white/10 text-white/70"
                          )}
                        >
                          Day {day.day}
                        </button>
                      );
                    })}
                  </div>
                  {/* Map */}
                  <ChatTripMap
                    trip={trip}
                    height="h-[300px]"
                    selectedDay={mapSelectedDay}
                    onViewDetails={handleViewPlaceDetails}
                  />
                </div>
              ) : (
                // Desktop: Side-by-side layout
                <div className="flex gap-3">
                  {/* Map */}
                  <div className="flex-1">
                    <ChatTripMap
                      trip={trip}
                      height="h-[500px]"
                      selectedDay={mapSelectedDay}
                      onViewDetails={handleViewPlaceDetails}
                    />
                  </div>

                  {/* Day Sidebar */}
                  <div className="w-24 flex flex-col gap-2">
                    {/* All days button */}
                    <button
                      onClick={() => setMapSelectedDay(null)}
                      className={cn(
                        "w-full py-2.5 px-2 rounded-xl text-xs font-medium transition-all",
                        mapSelectedDay === null
                          ? "bg-primary text-white"
                          : "bg-white/10 text-white/70 hover:bg-white/15"
                      )}
                    >
                      All Days
                    </button>

                    {/* Day buttons */}
                    {trip.itinerary.map((day) => {
                      const isSelected = mapSelectedDay === day.day;
                      const dayPlaces = day.places || [];

                      return (
                        <button
                          key={day.day}
                          onClick={() => setMapSelectedDay(isSelected ? null : day.day)}
                          className={cn(
                            "w-full py-2.5 px-2 rounded-xl text-xs font-medium transition-all",
                            isSelected
                              ? "bg-primary text-white"
                              : "bg-white/10 text-white/70 hover:bg-white/15"
                          )}
                        >
                          <div className="flex flex-col items-center gap-0.5">
                            <span className="font-semibold">Day {day.day}</span>
                            <span className="text-[10px] opacity-70">{dayPlaces.length} places</span>
                          </div>
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Best Season */}
          {trip.best_season && trip.best_season.length > 0 && (
            <div className="mt-6">
              <h3 className="text-base font-semibold text-white mb-3">Best Time to Visit</h3>
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
                  {trip.estimated_cost_min} - {trip.estimated_cost_max}
                </span>
              </div>
            </div>
          )}

          {/* Bottom spacing for mobile safe area */}
          {isMobile && <div className="h-8" />}
        </div>
      </div>
    </>
  );

  // Fullscreen gallery component (shared between mobile and desktop)
  const galleryComponent = (
    <FullscreenPhotoGallery
      images={allImages}
      title={trip.title}
      placeName={trip.city}
      isOpen={isGalleryOpen}
      onClose={() => setIsGalleryOpen(false)}
      initialIndex={galleryInitialIndex}
      onIndexChange={setGalleryInitialIndex}
      imageSourceNames={allSourceNames}
    />
  );

  // Mobile: Full screen draggable sheet from bottom
  if (isMobile) {
    return (
      <>
        <DraggableBottomSheet isOpen={isOpen} onClose={onClose}>
          {/* Drag handle with blur box */}
          <div className="absolute top-3 left-1/2 -translate-x-1/2 z-20 px-4 py-2 bg-black/30 backdrop-blur-md rounded-full">
            <div className="w-10 h-1 bg-white/60 rounded-full" />
          </div>
          {/* Close button */}
          <button
            onClick={onClose}
            className="absolute top-3 right-4 z-20 w-8 h-8 flex items-center justify-center rounded-full bg-black/30 backdrop-blur-md"
          >
            <X className="h-4 w-4 text-white" />
          </button>
          <div className="flex flex-col bg-transparent overflow-hidden relative">
            {panelContent}
          </div>
        </DraggableBottomSheet>
        {galleryComponent}
      </>
    );
  }

  // Desktop: Side panel
  return (
    <>
      <div className="h-full flex flex-col bg-transparent overflow-hidden relative">
        {panelContent}
      </div>
      {galleryComponent}
    </>
  );
}

// Day Card Component with tabs for places/restaurants
interface DayCardProps {
  day: AITripDay;
  isExpanded: boolean;
  onToggle: () => void;
  targetPlaceIndex?: number | null;
  onTargetPlaceHandled?: () => void;
}

function DayCard({ day, isExpanded, onToggle, targetPlaceIndex, onTargetPlaceHandled }: DayCardProps) {
  const [activeTab, setActiveTab] = useState<"places" | "restaurants">("places");
  const [expandedPlaceIndex, setExpandedPlaceIndex] = useState<number | null>(null);

  // Handle target place from map - close all others and open target
  useLayoutEffect(() => {
    if (targetPlaceIndex !== null && targetPlaceIndex !== undefined && isExpanded) {
      // Close any previously expanded place first, then open the target
      setExpandedPlaceIndex(targetPlaceIndex);
      onTargetPlaceHandled?.();
    }
  }, [targetPlaceIndex, isExpanded, onTargetPlaceHandled]);

  // Close expanded place when day collapses
  useLayoutEffect(() => {
    if (!isExpanded) {
      setExpandedPlaceIndex(null);
    }
  }, [isExpanded]);

  // Check if place is a restaurant based on category from backend
  // Backend sets category: "breakfast", "lunch", "dinner" for restaurants, "attraction" for places
  const isRestaurant = (p: AITripPlace): boolean => {
    const category = (p.category || '').toLowerCase();
    return category === 'breakfast' || category === 'lunch' || category === 'dinner';
  };

  // Separate places and restaurants
  const allPlaces = day.places || [];
  const restaurants = allPlaces.filter(isRestaurant);
  const places = allPlaces.filter(p => !isRestaurant(p));

  // Show tabs if we have restaurants
  const hasRestaurants = restaurants.length > 0;
  const displayPlaces = places;

  return (
    <div className="border border-white/10 rounded-2xl overflow-hidden">
      {/* Day header */}
      <button
        onClick={onToggle}
        className="w-full bg-white/5 px-4 py-3 flex items-center justify-between hover:bg-white/[0.07] transition-colors"
      >
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center">
            <span className="text-white font-bold text-sm">{day.day}</span>
          </div>
          <div className="text-left">
            <h3 className="font-semibold text-white text-base">{day.title}</h3>
            <p className="text-xs text-white/50">
              {hasRestaurants
                ? `${displayPlaces.length} places, ${restaurants.length} restaurants`
                : `${allPlaces.length} places`}
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
      <AnimatedCollapse isOpen={isExpanded}>
        <>
          {/* Tabs - only show if we have restaurants */}
          {hasRestaurants && (
            <div className="flex border-b border-white/10">
              <button
                onClick={() => setActiveTab("places")}
                className={cn(
                  "flex-1 py-2.5 px-3 text-sm font-medium transition-colors",
                  activeTab === "places"
                    ? "text-primary border-b-2 border-primary -mb-[1px]"
                    : "text-white/60 hover:text-white"
                )}
              >
                <div className="flex items-center justify-center gap-1.5">
                  <Building2 className="h-3.5 w-3.5" />
                  <span>Places ({displayPlaces.length})</span>
                </div>
              </button>
              <button
                onClick={() => setActiveTab("restaurants")}
                className={cn(
                  "flex-1 py-2.5 px-3 text-sm font-medium transition-colors",
                  activeTab === "restaurants"
                    ? "text-accent border-b-2 border-accent -mb-[1px]"
                    : "text-white/60 hover:text-white"
                )}
              >
                <div className="flex items-center justify-center gap-1.5">
                  <Utensils className="h-3.5 w-3.5" />
                  <span>Restaurants ({restaurants.length})</span>
                </div>
              </button>
            </div>
          )}

          {/* Day description */}
          {day.description && (
            <p className="text-sm text-white/70 px-4 pt-3">{day.description}</p>
          )}

          {/* Content */}
          <div className="p-3 space-y-2">
            {/* If no restaurants detected, show all places without tabs */}
            {!hasRestaurants && allPlaces.map((place, index) => (
              <PlaceCard
                key={place.poi_id || index}
                place={place}
                index={index}
                isExpanded={expandedPlaceIndex === index}
                onToggle={() => setExpandedPlaceIndex(expandedPlaceIndex === index ? null : index)}
              />
            ))}

            {/* If restaurants detected, show places tab */}
            {hasRestaurants && activeTab === "places" && displayPlaces.map((place, index) => (
              <PlaceCard
                key={place.poi_id || index}
                place={place}
                index={index}
                isExpanded={expandedPlaceIndex === index}
                onToggle={() => setExpandedPlaceIndex(expandedPlaceIndex === index ? null : index)}
              />
            ))}

            {/* If restaurants detected, show restaurants tab */}
            {hasRestaurants && activeTab === "restaurants" && restaurants.map((place, index) => (
              <PlaceCard
                key={place.poi_id || index}
                place={place}
                index={index}
                isExpanded={expandedPlaceIndex === (displayPlaces.length + index)}
                onToggle={() => setExpandedPlaceIndex(expandedPlaceIndex === (displayPlaces.length + index) ? null : (displayPlaces.length + index))}
                isRestaurant
              />
            ))}
          </div>
        </>
      </AnimatedCollapse>
    </div>
  );
}

// Expandable Place Card Component
interface PlaceCardProps {
  place: AITripPlace;
  index: number;
  isExpanded: boolean;
  onToggle: () => void;
  isRestaurant?: boolean;
}

function PlaceCard({ place, index, isExpanded, onToggle, isRestaurant }: PlaceCardProps) {
  const [showFullDescription, setShowFullDescription] = useState(false);
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [isHoursExpanded, setIsHoursExpanded] = useState(false);
  const cardRef = useRef<HTMLDivElement>(null);

  // Auto-scroll when expanded
  useLayoutEffect(() => {
    if (isExpanded && cardRef.current) {
      // Delay to allow animation to complete
      setTimeout(() => {
        const element = cardRef.current;
        if (element) {
          const container = element.closest('.overflow-y-auto');
          if (container) {
            const elementRect = element.getBoundingClientRect();
            const containerRect = container.getBoundingClientRect();
            const scrollTop = container.scrollTop + elementRect.top - containerRect.top - 16; // 16px offset from top
            container.scrollTo({
              top: scrollTop,
              behavior: 'smooth',
            });
          } else {
            element.scrollIntoView({
              behavior: 'smooth',
              block: 'start',
            });
          }
        }
      }, 150);
    }
  }, [isExpanded]);

  // Collect all images
  const allImages: string[] = [];
  if (place.image_url) allImages.push(place.image_url);
  if (place.images && Array.isArray(place.images)) {
    for (const img of place.images) {
      const url = typeof img === "string" ? img : (img as { url?: string })?.url;
      if (url && !allImages.includes(url)) allImages.push(url);
    }
  }
  const hasMultipleImages = allImages.length > 1;

  const description = place.description || "";
  const shouldTruncate = description.length > 150;
  const displayDescription = shouldTruncate && !showFullDescription
    ? description.slice(0, 150) + "..."
    : description;

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

  return (
    <div
      ref={cardRef}
      className="bg-white/5 rounded-xl overflow-hidden cursor-pointer hover:bg-white/[0.07] transition-colors"
      onClick={onToggle}
    >
      {/* Compact view */}
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

        {/* Place info - compact */}
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

        {/* Expand indicator */}
        <div className="flex-shrink-0">
          <ChevronDown
            className={cn(
              "h-4 w-4 text-white/50 transition-transform duration-300",
              isExpanded && "rotate-180"
            )}
          />
        </div>
      </div>

      {/* Expanded details */}
      <AnimatedCollapse isOpen={isExpanded}>
        <div className="border-t border-white/5">
          {/* Image Gallery - taller with bar indicators and rounded bottom */}
          {allImages.length > 0 && (
            <div className="relative h-72 overflow-hidden rounded-b-xl">
              <Image
                src={allImages[currentImageIndex]}
                alt={place.name}
                fill
                className="object-cover"
              />
              {hasMultipleImages && (
                <>
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      setCurrentImageIndex((prev) => (prev - 1 + allImages.length) % allImages.length);
                    }}
                    className="absolute left-2 top-1/2 -translate-y-1/2 h-7 w-7 rounded-full bg-black/30 backdrop-blur-md text-white hover:bg-black/50 z-10 flex items-center justify-center"
                  >
                    <ChevronLeft className="h-4 w-4" />
                  </button>
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      setCurrentImageIndex((prev) => (prev + 1) % allImages.length);
                    }}
                    className="absolute right-2 top-1/2 -translate-y-1/2 h-7 w-7 rounded-full bg-black/30 backdrop-blur-md text-white hover:bg-black/50 z-10 flex items-center justify-center"
                  >
                    <ChevronRight className="h-4 w-4" />
                  </button>
                  {/* Bar indicators like Telegram */}
                  <div className="absolute bottom-3 left-3 right-3 flex gap-1 z-10">
                    {allImages.map((_, idx) => (
                      <button
                        key={idx}
                        onClick={(e) => {
                          e.stopPropagation();
                          setCurrentImageIndex(idx);
                        }}
                        className="flex-1 h-0.5 rounded transition-all"
                        style={{
                          backgroundColor: idx === currentImageIndex ? "white" : "rgba(255,255,255,0.3)",
                        }}
                      />
                    ))}
                  </div>
                </>
              )}
            </div>
          )}

          <div className="p-4 space-y-4">
            {/* Header with name, rating, category */}
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
                {place.category && (
                  <span className={cn(
                    "px-2 py-1 rounded-full text-xs capitalize",
                    isRestaurant ? "bg-accent/20 text-accent" : "bg-primary/20 text-primary"
                  )}>
                    {place.category}
                  </span>
                )}
                {place.cuisine && (
                  <span className="px-2 py-1 bg-orange-500/20 text-orange-400 rounded-full text-xs">
                    {place.cuisine}
                  </span>
                )}
                {place.price && (
                  <span className="px-2 py-1 bg-green-500/20 text-green-400 rounded-full text-xs">
                    {place.price}
                  </span>
                )}
                {place.duration_minutes && (
                  <span className="px-2 py-1 bg-white/10 text-white/70 rounded-full text-xs">
                    {place.duration_minutes} min visit
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
                      className="text-primary hover:text-primary/80 ml-1"
                    >
                      {showFullDescription ? "See less" : "See more"}
                    </button>
                  )}
                </p>
              </div>
            )}

            {/* Opening hours & Address - connected blocks */}
            <div className="space-y-[1px]">
              {/* Opening hours / Best time - rounded top only */}
              {(() => {
                // Parse opening_hours - can be string, array, or Google Maps API object
                let hoursArray: string[] = [];
                let openNow: boolean | null = null;

                if (place.opening_hours) {
                  if (typeof place.opening_hours === 'string' && place.opening_hours.length > 0) {
                    hoursArray = [place.opening_hours];
                  } else if (Array.isArray(place.opening_hours) && place.opening_hours.length > 0) {
                    hoursArray = place.opening_hours;
                  } else if (typeof place.opening_hours === 'object' && place.opening_hours !== null) {
                    // Google Maps API format: {open_now: boolean, weekday_text: string[]}
                    const hoursObj = place.opening_hours as { open_now?: boolean; weekday_text?: string[] };
                    openNow = hoursObj.open_now ?? null;
                    if (hoursObj.weekday_text && Array.isArray(hoursObj.weekday_text)) {
                      hoursArray = hoursObj.weekday_text;
                    }
                  }
                }

                const hasOpeningHours = hoursArray.length > 0 || openNow !== null;
                const hasBestTime = place.best_time && place.best_time.length > 0;
                const hasAddress = place.address && place.address.length > 0;
                const hasMultipleHours = hoursArray.length > 1;

                // Determine display text and color
                let displayText = "Hours not available";
                let textColor = "text-white/50";

                if (openNow !== null) {
                  // Google Maps API format with open_now
                  if (openNow) {
                    displayText = "Open now";
                    textColor = "text-green-400";
                  } else {
                    displayText = "Closed";
                    textColor = "text-red-400";
                  }
                } else if (hoursArray.length > 0) {
                  const firstHour = hoursArray[0] || "";
                  if (firstHour.toLowerCase().includes('open')) {
                    displayText = firstHour;
                    textColor = "text-green-400";
                  } else if (firstHour.toLowerCase().includes('closed')) {
                    displayText = firstHour;
                    textColor = "text-red-400";
                  } else {
                    displayText = hasMultipleHours ? "See schedule" : firstHour;
                    textColor = "text-green-400";
                  }
                } else if (hasBestTime) {
                  displayText = `Best time: ${place.best_time}`;
                  textColor = "text-green-400";
                }

                return (
                  <div className={cn(
                    "bg-white/5 overflow-hidden",
                    hasAddress ? "rounded-t-xl" : "rounded-xl"
                  )}>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        if (hasMultipleHours) setIsHoursExpanded(!isHoursExpanded);
                      }}
                      className={cn(
                        "w-full flex items-center gap-3 p-3",
                        hasMultipleHours && "hover:bg-white/5 transition-colors"
                      )}
                    >
                      <Clock className={cn("h-4 w-4 flex-shrink-0", textColor)} />
                      <span className={cn("text-sm font-medium flex-1 text-left", textColor)}>
                        {displayText}
                      </span>
                      {hasMultipleHours && (
                        <ChevronDown
                          className={cn(
                            "h-4 w-4 text-white/50 transition-transform duration-300",
                            isHoursExpanded && "rotate-180"
                          )}
                        />
                      )}
                    </button>

                    {/* Full schedule */}
                    {hasMultipleHours && (
                      <AnimatedCollapse isOpen={isHoursExpanded}>
                        <div className="px-3 pb-3 space-y-2 border-t border-white/5 pt-2">
                          {hoursArray.map((hours, idx) => {
                            const colonIndex = hours.indexOf(":");
                            const day = colonIndex > 0 ? hours.substring(0, colonIndex).trim() : hours;
                            const time = colonIndex > 0 ? hours.substring(colonIndex + 1).trim() : "";
                            return (
                              <div key={idx} className="flex justify-between text-sm">
                                <span className="text-white/70">{day}</span>
                                <span className="text-white/50">{time}</span>
                              </div>
                            );
                          })}
                        </div>
                      </AnimatedCollapse>
                    )}
                  </div>
                );
              })()}

              {/* Address - rounded bottom only */}
              {place.address && (
                <div className="bg-white/5 rounded-b-xl p-3">
                  <div className="flex items-start gap-3">
                    <MapPin className="h-4 w-4 text-red-400 mt-0.5 flex-shrink-0" />
                    <p className="text-sm text-white/70 flex-1">{place.address}</p>
                  </div>
                </div>
              )}
            </div>

            {/* Action buttons */}
            {(place.address || (place.latitude && place.longitude)) && (
              <button
                onClick={openInMaps}
                className="w-full flex items-center justify-center gap-2 bg-primary text-white py-2.5 px-4 rounded-xl text-sm font-medium hover:bg-primary/90 transition-colors"
              >
                <Navigation className="h-4 w-4" />
                <span>Directions</span>
              </button>
            )}
          </div>
        </div>
      </AnimatedCollapse>
    </div>
  );
}
