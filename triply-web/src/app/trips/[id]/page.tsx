"use client";

import { useState, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import {
  ArrowLeft,
  Heart,
  Share2,
  MapPin,
  Clock,
  Star,
  Check,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { useAuth } from "@/contexts/auth-context";
import { useUserTrip, useUserTripActions } from "@/hooks/useUserTrips";
import { useTrip } from "@/hooks/useTrips";
import { AuthModal } from "@/components/features/auth/auth-modal";
import { TripMap, type POIMarker } from "@/components/features/trips/trip-map";
import type { TripItinerary, TripPlace } from "@/types/user-trip";
import type { TripDay, TripPlace as PublicTripPlace } from "@/types/trip";

// Import extracted components
import {
  useIsMobile,
  ImageGallery,
  CollapsibleDayItinerary,
  CompactDayPreview,
  PlaceDetailsPanelInline,
  PlaceDetailsBottomSheet,
  TripDetailsSkeleton,
} from "@/components/features/trips/trip-details";

export default function TripDetailsPage() {
  const params = useParams();
  const router = useRouter();
  const tripId = params.id as string;

  const { user, isLoading: authLoading } = useAuth();

  // Try to fetch as user trip first, then as public trip
  const { trip: userTrip, isLoading: userTripLoading } = useUserTrip(user ? tripId : null);
  const { trip: publicTrip, isLoading: publicTripLoading } = useTrip(tripId);

  const { toggleFavorite } = useUserTripActions();
  const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);
  const [openDays, setOpenDays] = useState<Set<number>>(new Set([1])); // First day open by default
  const [selectedMapDay, setSelectedMapDay] = useState<number | null>(1); // Sync with first open day
  const [detailsPOI, setDetailsPOI] = useState<POIMarker | null>(null); // POI for details panel
  const [detailsPlaceData, setDetailsPlaceData] = useState<TripPlace | PublicTripPlace | null>(null);
  const [isBottomSheetOpen, setIsBottomSheetOpen] = useState(false); // For mobile bottom sheet

  const isMobile = useIsMobile();

  // Use user trip if available, otherwise use public trip
  const trip = userTrip || publicTrip;
  const isUserTrip = !!userTrip;

  // Loading logic:
  // - Wait for auth to complete
  // - If user is logged in, wait for userTripLoading first
  // - If no user trip found and user is logged in, also wait for publicTripLoading
  // - If not logged in, just wait for publicTripLoading
  const isLoading = authLoading ||
    (user ? (userTripLoading || (!userTrip && publicTripLoading)) : publicTripLoading);

  const toggleDay = useCallback((dayNumber: number) => {
    setOpenDays(prev => {
      // If clicking on already open day - close it
      if (prev.has(dayNumber)) {
        setSelectedMapDay(null);
        return new Set();
      }
      // Otherwise open only this day (close all others)
      setSelectedMapDay(dayNumber);
      return new Set([dayNumber]);
    });
  }, []);

  // Handle View Details from map - find the full place data
  const handleViewDetails = useCallback((poi: POIMarker) => {
    setDetailsPOI(poi);
    setSelectedMapDay(poi.day);
    setOpenDays(new Set([poi.day]));

    // Find the full place data from itinerary
    // For user trips: itinerary field, for public trips: itinerary field (both use itinerary)
    const itineraryData = isUserTrip
      ? (userTrip as { itinerary?: TripItinerary[] })?.itinerary
      : (publicTrip as { itinerary?: TripDay[] })?.itinerary;

    if (itineraryData) {
      const dayData = itineraryData.find((d: TripItinerary | TripDay) => d.day === poi.day);
      if (dayData) {
        const places = dayData.places || [];
        const restaurants = dayData.restaurants || [];
        const allPlaces = [...places, ...restaurants];
        const placeData = allPlaces.find((p: TripPlace | PublicTripPlace) => {
          const id = (p as TripPlace).poi_id || (p as PublicTripPlace).poiId;
          return id === poi.id || p.name === poi.name;
        });
        setDetailsPlaceData(placeData || null);
      }
    }

    // On mobile, open bottom sheet instead of inline panel
    if (isMobile) {
      setIsBottomSheetOpen(true);
    }
  }, [isUserTrip, userTrip, publicTrip, isMobile]);

  const handleCloseDetails = useCallback(() => {
    setDetailsPOI(null);
    setDetailsPlaceData(null);
  }, []);

  // Handle place click from itinerary on mobile - opens bottom sheet
  const handleMobilePlaceClick = useCallback((place: TripPlace | PublicTripPlace, type: "place" | "restaurant", dayNumber: number, placeIndex: number) => {
    const poi: POIMarker = {
      id: (place as TripPlace).poi_id || (place as PublicTripPlace).poiId || place.name,
      name: place.name,
      latitude: place.latitude || 0,
      longitude: place.longitude || 0,
      type: type,
      day: dayNumber,
      index: placeIndex,
      rating: place.rating,
      category: place.category,
      address: place.address,
      imageUrl: (place as TripPlace).image_url || (place as PublicTripPlace).imageUrl,
    };

    setDetailsPOI(poi);
    setDetailsPlaceData(place);
    setIsBottomSheetOpen(true);
  }, []);

  const handleFavoriteToggle = async () => {
    if (!user) {
      setIsAuthModalOpen(true);
      return;
    }

    if (!userTrip) return;

    const { success } = await toggleFavorite(userTrip.id, !userTrip.is_favorite);
    if (!success) {
      // Could show error toast
    }
  };

  const handleShare = async () => {
    const shareUrl = window.location.href;
    const shareTitle = trip ? (isUserTrip ? (trip as typeof userTrip)?.title : (trip as typeof publicTrip)?.title) : "Trip";

    if (navigator.share) {
      try {
        await navigator.share({
          title: shareTitle || "Trip",
          url: shareUrl,
        });
      } catch {
        // User cancelled
      }
    } else {
      await navigator.clipboard.writeText(shareUrl);
    }
  };

  const formatPrice = (price: number | string | null | undefined, currency: string) => {
    if (!price) return null;
    if (typeof price === "string") return price;
    const symbol = currency === "EUR" ? "€" : "$";
    return `${symbol}${price}`;
  };

  const formatDuration = (days: number | string | null | undefined) => {
    if (!days) return null;
    if (typeof days === "string") return days;
    return days === 1 ? "1 day" : `${days} days`;
  };

  // Get all images with source place names (limit to 2 per place)
  const getAllImages = (): { url: string; placeName?: string }[] => {
    if (!trip) return [];
    const images: { url: string; placeName?: string }[] = [];
    const addedUrls = new Set<string>();

    const addImage = (url: string, placeName?: string) => {
      if (url && !addedUrls.has(url)) {
        addedUrls.add(url);
        images.push({ url, placeName });
      }
    };

    const maxImagesPerPlace = 2;

    if (isUserTrip) {
      const ut = trip as typeof userTrip;
      if (ut?.hero_image_url) addImage(ut.hero_image_url, undefined);
      if (ut?.images) {
        for (const img of ut.images) {
          if (typeof img === "string") addImage(img, undefined);
        }
      }
      if (ut?.itinerary) {
        for (const day of ut.itinerary) {
          // Only places, exclude restaurants
          const places = day.places || [];
          for (const place of places) {
            let placeImageCount = 0;

            if (place.image_url && placeImageCount < maxImagesPerPlace) {
              addImage(place.image_url, place.name);
              placeImageCount++;
            }
            if (place.images && placeImageCount < maxImagesPerPlace) {
              for (const img of place.images) {
                if (placeImageCount >= maxImagesPerPlace) break;
                const url = typeof img === "string" ? img : img?.url;
                if (url && !addedUrls.has(url)) {
                  addImage(url, place.name);
                  placeImageCount++;
                }
              }
            }
          }
        }
      }
    } else {
      const pt = trip as typeof publicTrip;
      if (pt?.heroImageUrl) addImage(pt.heroImageUrl, undefined);
      if (pt?.images) {
        for (const img of pt.images) {
          const url = typeof img === "string" ? img : img.url;
          if (url) addImage(url, undefined);
        }
      }
      // Process itinerary places (exclude restaurants)
      if (pt?.itinerary) {
        for (const day of pt.itinerary) {
          const places = day.places || [];
          for (const place of places) {
            let placeImageCount = 0;

            if (place.imageUrl && placeImageCount < maxImagesPerPlace) {
              addImage(place.imageUrl, place.name);
              placeImageCount++;
            }
            if (place.images && placeImageCount < maxImagesPerPlace) {
              for (const img of place.images) {
                if (placeImageCount >= maxImagesPerPlace) break;
                const url = typeof img === "string" ? img : img.url;
                if (url && !addedUrls.has(url)) {
                  addImage(url, place.name);
                  placeImageCount++;
                }
              }
            }
          }
        }
      }
    }

    return images;
  };

  if (isLoading) {
    return <TripDetailsSkeleton />;
  }

  if (!trip) {
    return (
      <div className="min-h-screen bg-background">
        {/* Header */}
        <div className="fixed top-0 left-0 right-0 z-50 bg-background/80 backdrop-blur-md border-b border-white/10">
          <div className="max-w-7xl mx-auto px-4 h-14 flex items-center">
            <button
              onClick={() => router.back()}
              className="flex items-center gap-2 text-white hover:text-primary transition-colors"
            >
              <ArrowLeft className="h-5 w-5" />
              <span className="font-medium">Back</span>
            </button>
          </div>
        </div>

        <div className="pt-14 flex items-center justify-center min-h-[calc(100vh-56px)]">
          <div className="text-center px-4">
            <h1 className="text-2xl font-bold text-white mb-4">
              Trip not found
            </h1>
            <p className="text-white/70 mb-8">
              This trip doesn&apos;t exist or has been removed.
            </p>
            <Link href="/">
              <Button className="bg-primary hover:bg-primary/90">
                Go Home
              </Button>
            </Link>
          </div>
        </div>
      </div>
    );
  }

  // Extract data based on trip type
  const title = isUserTrip ? (trip as typeof userTrip)?.title : (trip as typeof publicTrip)?.title;
  const city = isUserTrip ? (trip as typeof userTrip)?.city : (trip as typeof publicTrip)?.city;
  const country = isUserTrip ? (trip as typeof userTrip)?.country : (trip as typeof publicTrip)?.country;
  const description = isUserTrip ? (trip as typeof userTrip)?.description : (trip as typeof publicTrip)?.description;
  const rating = isUserTrip ? (trip as typeof userTrip)?.rating : (trip as typeof publicTrip)?.rating;
  const reviews = isUserTrip ? (trip as typeof userTrip)?.reviews : (trip as typeof publicTrip)?.reviews;
  const durationDays = isUserTrip ? (trip as typeof userTrip)?.duration_days : (trip as typeof publicTrip)?.durationDays;
  const price = isUserTrip ? (trip as typeof userTrip)?.price : (trip as typeof publicTrip)?.price;
  const currency = isUserTrip ? ((trip as typeof userTrip)?.currency || "EUR") : ((trip as typeof publicTrip)?.currency || "EUR");
  const activityType = isUserTrip ? (trip as typeof userTrip)?.activity_type : (trip as typeof publicTrip)?.activityType;
  const includes = isUserTrip ? (trip as typeof userTrip)?.includes : (trip as typeof publicTrip)?.includes;
  const highlights = isUserTrip ? (trip as typeof userTrip)?.highlights : (trip as typeof publicTrip)?.highlights;
  const bestSeason = isUserTrip ? (trip as typeof userTrip)?.best_season : (trip as typeof publicTrip)?.bestSeason;
  const itinerary = isUserTrip ? (trip as typeof userTrip)?.itinerary : (trip as typeof publicTrip)?.itinerary;
  const isFavorite = isUserTrip ? (trip as typeof userTrip)?.is_favorite : false;

  const allImages = getAllImages();
  const priceDisplay = formatPrice(price, currency);
  const durationDisplay = formatDuration(durationDays);

  return (
    <div className="min-h-screen bg-background pb-32">
      {/* Fixed Header */}
      <div className="fixed top-0 left-0 right-0 z-50 bg-background/80 backdrop-blur-md border-b border-white/10">
        <div className="px-4 h-14 flex items-center justify-between">
          <button
            onClick={() => router.back()}
            className="flex items-center gap-1.5 text-white hover:text-primary transition-colors"
          >
            <ArrowLeft className="h-5 w-5" />
            <span className="text-sm font-medium">Back</span>
          </button>

          <div className="flex items-center gap-2">
            <Button
              variant="ghost"
              size="icon"
              className="rounded-full"
              onClick={handleShare}
            >
              <Share2 className="h-5 w-5" />
            </Button>
            {isUserTrip && (
              <Button
                variant="ghost"
                size="icon"
                className="rounded-full"
                onClick={handleFavoriteToggle}
              >
                <Heart
                  className={cn(
                    "h-5 w-5 transition-colors",
                    isFavorite ? "fill-red-500 text-red-500" : "text-white"
                  )}
                />
              </Button>
            )}
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="pt-14">
        {/* Image Gallery - Airbnb style */}
        <div className="pt-4">
          <ImageGallery images={allImages} title={title || "Trip"} />
        </div>

        {/* Trip Info */}
        <div className="max-w-4xl mx-auto px-4 sm:px-6 py-6 space-y-6">
          {/* Header Section */}
          <div>
            <h1 className="text-2xl md:text-3xl font-bold text-white leading-tight">
              {title}
            </h1>

            <div className="flex items-center gap-2 mt-2 text-white/70">
              <MapPin className="h-4 w-4" />
              <span>{city}, {country}</span>
            </div>

            <div className="flex items-center gap-4 mt-3 flex-wrap">
              {rating && rating > 0 && (
                <div className="flex items-center gap-1">
                  <Star className="h-4 w-4 text-amber-400 fill-amber-400" />
                  <span className="text-white font-semibold">{rating.toFixed(1)}</span>
                  {reviews && reviews > 0 && (
                    <span className="text-white/60">({reviews} reviews)</span>
                  )}
                </div>
              )}

              {durationDisplay && (
                <div className="flex items-center gap-1 text-white/70">
                  <Clock className="h-4 w-4" />
                  <span>{durationDisplay}</span>
                </div>
              )}

              {priceDisplay && (
                <span className="text-lg font-bold text-white">
                  {priceDisplay}
                </span>
              )}

              {activityType && (
                <span className="px-3 py-1 bg-primary/20 text-primary rounded-full text-sm capitalize">
                  {activityType.replace(/_/g, " ")}
                </span>
              )}
            </div>
          </div>

          {/* Description */}
          {description && (
            <div>
              <h2 className="text-lg font-semibold text-white mb-3">About this trip</h2>
              <p className="text-white/80 leading-relaxed whitespace-pre-line">
                {description}
              </p>
            </div>
          )}

          {/* What's Included */}
          {includes && includes.length > 0 && (
            <div>
              <h2 className="text-lg font-semibold text-white mb-3">What&apos;s Included</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
                {includes.map((item, index) => (
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
          {highlights && highlights.length > 0 && (
            <div>
              <h2 className="text-lg font-semibold text-white mb-3">Highlights</h2>
              <div className="flex flex-wrap gap-2">
                {highlights.map((highlight, index) => (
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

          {/* Best Season */}
          {bestSeason && bestSeason.length > 0 && (
            <div>
              <h2 className="text-lg font-semibold text-white mb-3">Best Time to Visit</h2>
              <div className="flex flex-wrap gap-2">
                {bestSeason.map((season, index) => (
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

        </div>
      </div>

      {/* Itinerary with Map Section */}
      {itinerary && itinerary.length > 0 && (
        <div className="max-w-4xl mx-auto px-4 sm:px-6 pb-6">
          <h2 className="text-lg font-semibold text-white mb-4">Itinerary</h2>

          {/* Mobile Layout - Vertical: Itinerary above Map */}
          {isMobile ? (
            <div className="flex flex-col gap-4">
              {/* Itinerary list - Full width on mobile */}
              <div className="space-y-2">
                {itinerary.map((day, index) => (
                  <CollapsibleDayItinerary
                    key={day.day || index}
                    day={day}
                    isOpen={openDays.has(day.day || index + 1)}
                    onToggle={() => toggleDay(day.day || index + 1)}
                    isMobile={true}
                    onMobilePlaceClick={handleMobilePlaceClick}
                  />
                ))}
              </div>

              {/* Map - Fixed height on mobile */}
              <div className="h-[400px] rounded-2xl overflow-hidden">
                <TripMap
                  itinerary={itinerary}
                  selectedDay={selectedMapDay}
                  onSelectDay={(day) => {
                    setSelectedMapDay(day === 0 ? null : day);
                    if (day > 0) {
                      setOpenDays(new Set([day]));
                    }
                  }}
                  onViewDetails={handleViewDetails}
                  city={city || undefined}
                  country={country || undefined}
                />
              </div>
            </div>
          ) : (
            /* Desktop Layout - Horizontal with three columns */
            <div className="flex gap-3 h-[600px]">
              {/* Itinerary list - Left side (shrinks to mini when details open) */}
              <div
                className={cn(
                  "transition-all duration-500 ease-out overflow-hidden flex-shrink-0",
                  detailsPOI ? "w-[88px]" : "w-1/2"
                )}
              >
                <div className="h-full overflow-y-auto scrollbar-thin pr-1 space-y-2">
                  {detailsPOI ? (
                    // Mini compact view - just Day X + photo grid
                    itinerary.map((day, index) => (
                      <CompactDayPreview
                        key={day.day || index}
                        day={day}
                        isSelected={selectedMapDay === (day.day || index + 1)}
                        onClick={() => {
                          const dayNum = day.day || index + 1;
                          setSelectedMapDay(dayNum);
                          setOpenDays(new Set([dayNum]));
                        }}
                      />
                    ))
                  ) : (
                    // Full view when no details
                    itinerary.map((day, index) => (
                      <CollapsibleDayItinerary
                        key={day.day || index}
                        day={day}
                        isOpen={openDays.has(day.day || index + 1)}
                        onToggle={() => toggleDay(day.day || index + 1)}
                      />
                    ))
                  )}
                </div>
              </div>

              {/* Map - shrinks a bit when details open */}
              <div
                className={cn(
                  "transition-all duration-500 ease-out h-full rounded-2xl overflow-hidden",
                  detailsPOI ? "w-[38%] flex-shrink-0" : "flex-1"
                )}
              >
                <TripMap
                  itinerary={itinerary}
                  selectedDay={selectedMapDay}
                  onSelectDay={(day) => {
                    setSelectedMapDay(day === 0 ? null : day);
                    if (day > 0) {
                      setOpenDays(new Set([day]));
                    }
                  }}
                  onViewDetails={handleViewDetails}
                  city={city || undefined}
                  country={country || undefined}
                />
              </div>

              {/* Details Panel - Right side (larger, appears when POI selected) */}
              <div
                className={cn(
                  "transition-all duration-500 ease-out overflow-hidden h-full",
                  detailsPOI ? "flex-1 opacity-100" : "w-0 opacity-0"
                )}
              >
                <div className="h-full bg-white/5 rounded-2xl border border-white/10 overflow-hidden">
                  <PlaceDetailsPanelInline
                    poi={detailsPOI}
                    placeData={detailsPlaceData}
                    onClose={handleCloseDetails}
                  />
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Mobile Bottom Sheet for Place Details */}
      <PlaceDetailsBottomSheet
        isOpen={isBottomSheetOpen}
        onClose={() => {
          setIsBottomSheetOpen(false);
          setDetailsPOI(null);
          setDetailsPlaceData(null);
        }}
        poi={detailsPOI}
        placeData={detailsPlaceData}
      />

      {/* Auth Modal */}
      <AuthModal
        isOpen={isAuthModalOpen}
        onClose={() => setIsAuthModalOpen(false)}
      />
    </div>
  );
}
