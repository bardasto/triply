"use client";

import { motion, AnimatePresence } from "framer-motion";
import { CompactPlaceCard } from "./compact-place-card";
import { CompactRestaurantCard } from "./compact-restaurant-card";
import type { TripPlace } from "@/types/user-trip";
import type { TripPlace as PublicTripPlace } from "@/types/trip";

interface AnimatedPlaceListProps {
  places: (TripPlace | PublicTripPlace)[];
  dayNumber: number;
  type: "place" | "restaurant";
  expandedIndex: number | null;
  onToggle: (index: number) => void;
  isMobile?: boolean;
  onMobilePlaceClick?: (
    place: TripPlace | PublicTripPlace,
    type: "place" | "restaurant",
    dayNumber: number,
    placeIndex: number
  ) => void;
  // Animation state from streaming
  removingIds?: Set<string>;
  addingIds?: Set<string>;
}

// Animation variants for list items
const itemVariants = {
  // Initial state (before entering)
  initial: {
    opacity: 0,
    height: 0,
    scale: 0.8,
    y: -20,
  },
  // Visible state
  animate: {
    opacity: 1,
    height: "auto" as const,
    scale: 1,
    y: 0,
    transition: {
      type: "spring" as const,
      stiffness: 500,
      damping: 30,
      opacity: { duration: 0.2 },
      height: { duration: 0.3 },
    },
  },
  // Exit state (when removing)
  exit: {
    opacity: 0,
    height: 0,
    scale: 0.8,
    x: -100,
    transition: {
      type: "spring" as const,
      stiffness: 500,
      damping: 30,
      opacity: { duration: 0.2 },
      height: { duration: 0.3, delay: 0.1 },
    },
  },
};

// Highlight animation for newly added items
const highlightVariants = {
  initial: {
    boxShadow: "0 0 0 0 rgba(147, 51, 234, 0)",
  },
  highlight: {
    boxShadow: [
      "0 0 0 0 rgba(147, 51, 234, 0)",
      "0 0 0 4px rgba(147, 51, 234, 0.3)",
      "0 0 0 0 rgba(147, 51, 234, 0)",
    ],
    transition: {
      duration: 1.5,
      ease: "easeInOut" as const,
    },
  },
};

// Get unique ID for a place
function getPlaceId(place: TripPlace | PublicTripPlace): string {
  return (
    (place as TripPlace).poi_id ||
    (place as PublicTripPlace).poiId ||
    place.name ||
    Math.random().toString()
  );
}

export function AnimatedPlaceList({
  places,
  dayNumber,
  type,
  expandedIndex,
  onToggle,
  isMobile = false,
  onMobilePlaceClick,
  removingIds = new Set(),
  addingIds = new Set(),
}: AnimatedPlaceListProps) {
  // Filter out places that are being removed
  const visiblePlaces = places.filter((place) => {
    const placeId = getPlaceId(place);
    return !removingIds.has(placeId);
  });

  return (
    <AnimatePresence mode="popLayout" initial={false}>
      {visiblePlaces.map((place, index) => {
        const placeId = getPlaceId(place);
        const isNewlyAdded = addingIds.has(placeId);

        return (
          <motion.div
            key={placeId}
            layout
            variants={itemVariants}
            initial={isNewlyAdded ? "initial" : false}
            animate="animate"
            exit="exit"
            className="overflow-hidden"
          >
            {/* Highlight wrapper for new items */}
            <motion.div
              variants={highlightVariants}
              initial="initial"
              animate={isNewlyAdded ? "highlight" : "initial"}
              className="rounded-xl"
            >
              {type === "place" ? (
                <CompactPlaceCard
                  place={place}
                  dayNumber={dayNumber}
                  index={index}
                  isExpanded={!isMobile && expandedIndex === index}
                  onToggle={() => {
                    if (isMobile && onMobilePlaceClick) {
                      onMobilePlaceClick(place, "place", dayNumber, index);
                    } else {
                      onToggle(index);
                    }
                  }}
                />
              ) : (
                <CompactRestaurantCard
                  place={place}
                  dayNumber={dayNumber}
                  index={index}
                  isExpanded={!isMobile && expandedIndex === index}
                  onToggle={() => {
                    if (isMobile && onMobilePlaceClick) {
                      onMobilePlaceClick(place, "restaurant", dayNumber, index);
                    } else {
                      onToggle(index);
                    }
                  }}
                />
              )}
            </motion.div>
          </motion.div>
        );
      })}
    </AnimatePresence>
  );
}

// Skeleton placeholder for loading state during modifications
export function AnimatedPlaceSkeleton() {
  return (
    <motion.div
      initial={{ opacity: 0, height: 0 }}
      animate={{ opacity: 1, height: "auto" }}
      exit={{ opacity: 0, height: 0 }}
      className="overflow-hidden"
    >
      <div className="bg-white/5 rounded-xl p-3 animate-pulse">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-white/10" />
          <div className="w-12 h-12 rounded-lg bg-white/10" />
          <div className="flex-1 space-y-2">
            <div className="h-4 bg-white/10 rounded w-3/4" />
            <div className="h-3 bg-white/10 rounded w-1/2" />
          </div>
        </div>
      </div>
    </motion.div>
  );
}
