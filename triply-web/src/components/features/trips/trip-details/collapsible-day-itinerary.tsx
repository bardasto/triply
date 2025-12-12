"use client";

import { useState, useMemo } from "react";
import { ChevronDown, Building2, Utensils } from "lucide-react";
import { cn } from "@/lib/utils";
import { AnimatedCollapse } from "./animated-collapse";
import { AnimatedPlaceList } from "./animated-place-list";
import type { TripItinerary, TripPlace } from "@/types/user-trip";
import type { TripDay, TripPlace as PublicTripPlace } from "@/types/trip";

// Restaurant categories to filter
const RESTAURANT_CATEGORIES = ["breakfast", "lunch", "dinner"];

// Check if a place is a restaurant based on category
function isRestaurantCategory(place: TripPlace | PublicTripPlace): boolean {
  const category = place.category?.toLowerCase() || "";
  return RESTAURANT_CATEGORIES.includes(category);
}

// Filter places excluding restaurants
function filterPlacesExcludingRestaurants(places: (TripPlace | PublicTripPlace)[]): (TripPlace | PublicTripPlace)[] {
  return places.filter(place => !isRestaurantCategory(place));
}

// Get restaurants from places list
function getRestaurantsFromPlaces(places: (TripPlace | PublicTripPlace)[]): (TripPlace | PublicTripPlace)[] {
  return places.filter(place => isRestaurantCategory(place));
}

interface CollapsibleDayItineraryProps {
  day: TripItinerary | TripDay;
  isOpen: boolean;
  onToggle: () => void;
  isMobile?: boolean;
  onMobilePlaceClick?: (place: TripPlace | PublicTripPlace, type: "place" | "restaurant", dayNumber: number, placeIndex: number) => void;
  // Animation state for modifications
  removingPlaceIds?: Set<string>;
  removingRestaurantIds?: Set<string>;
  addingPlaceIds?: Set<string>;
  addingRestaurantIds?: Set<string>;
}

export function CollapsibleDayItinerary({
  day,
  isOpen,
  onToggle,
  isMobile = false,
  onMobilePlaceClick,
  removingPlaceIds = new Set(),
  removingRestaurantIds = new Set(),
  addingPlaceIds = new Set(),
  addingRestaurantIds = new Set(),
}: CollapsibleDayItineraryProps) {
  const [activeTab, setActiveTab] = useState<"places" | "restaurants">("places");
  const [expandedPlaceIndex, setExpandedPlaceIndex] = useState<number | null>(null);
  const [expandedRestaurantIndex, setExpandedRestaurantIndex] = useState<number | null>(null);

  // Get raw data from day
  const rawPlaces = day.places || [];
  const rawRestaurants = day.restaurants || [];

  // Filter and combine places/restaurants like Flutter does
  const { places, restaurants } = useMemo(() => {
    // Filter places to exclude restaurants (by category)
    const filteredPlaces = filterPlacesExcludingRestaurants(rawPlaces);

    // Get restaurants from places array (by category) + existing restaurants array
    const restaurantsFromPlaces = getRestaurantsFromPlaces(rawPlaces);
    const combinedRestaurants = [...restaurantsFromPlaces, ...rawRestaurants];

    return {
      places: filteredPlaces,
      restaurants: combinedRestaurants,
    };
  }, [rawPlaces, rawRestaurants]);

  const hasPlaces = places.length > 0;
  const hasRestaurants = restaurants.length > 0;

  return (
    <div className="border border-white/10 rounded-2xl overflow-hidden">
      {/* Day header - clickable to collapse/expand */}
      <button
        onClick={onToggle}
        className="w-full bg-white/5 px-4 py-3 flex items-center justify-between hover:bg-white/[0.07] transition-colors"
      >
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center">
            <span className="text-white font-bold text-sm">{day.day}</span>
          </div>
          <div className="text-left">
            <h3 className="font-semibold text-white text-base">
              Day {day.day}: {day.title}
            </h3>
            <p className="text-xs text-white/50">
              {places.length} places, {restaurants.length} restaurants
            </p>
          </div>
        </div>
        <ChevronDown
          className={cn(
            "h-5 w-5 text-white/50 transition-transform duration-300",
            isOpen && "rotate-180"
          )}
        />
      </button>

      {/* Collapsible content with animation */}
      <AnimatedCollapse isOpen={isOpen}>
        <>
          {/* Tabs */}
          {(hasPlaces || hasRestaurants) && (
            <div className="flex border-b border-white/10">
              {hasPlaces && (
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
                    <span>Places ({places.length})</span>
                  </div>
                </button>
              )}
              {hasRestaurants && (
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
              )}
            </div>
          )}

          {/* Content */}
          <div className="p-3 space-y-2">
            {activeTab === "places" && hasPlaces && (
              <AnimatedPlaceList
                places={places}
                dayNumber={day.day}
                type="place"
                expandedIndex={expandedPlaceIndex}
                onToggle={(index) => {
                  setExpandedPlaceIndex(expandedPlaceIndex === index ? null : index);
                }}
                isMobile={isMobile}
                onMobilePlaceClick={onMobilePlaceClick}
                removingIds={removingPlaceIds}
                addingIds={addingPlaceIds}
              />
            )}

            {activeTab === "restaurants" && hasRestaurants && (
              <AnimatedPlaceList
                places={restaurants}
                dayNumber={day.day}
                type="restaurant"
                expandedIndex={expandedRestaurantIndex}
                onToggle={(index) => {
                  setExpandedRestaurantIndex(expandedRestaurantIndex === index ? null : index);
                }}
                isMobile={isMobile}
                onMobilePlaceClick={onMobilePlaceClick}
                removingIds={removingRestaurantIds}
                addingIds={addingRestaurantIds}
              />
            )}

            {!hasPlaces && !hasRestaurants && (
              <p className="text-center text-white/50 py-4 text-sm">
                No activities planned for this day
              </p>
            )}
          </div>
        </>
      </AnimatedCollapse>
    </div>
  );
}
