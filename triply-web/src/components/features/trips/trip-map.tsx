"use client";

import { useEffect, useState, useCallback, useMemo, useRef } from "react";
import {
  GoogleMap,
  useJsApiLoader,
  OverlayViewF,
} from "@react-google-maps/api";
import { Utensils, MapPin, Navigation, X, Loader2, Building2, Eye, Plus, Minus } from "lucide-react";
import { cn } from "@/lib/utils";
import type { TripItinerary, TripPlace } from "@/types/user-trip";
import type { TripDay, TripPlace as PublicTripPlace } from "@/types/trip";

const GOOGLE_MAPS_API_KEY = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY || "";

interface POIMarker {
  id: string;
  name: string;
  type: "place" | "restaurant";
  latitude: number;
  longitude: number;
  day: number;
  index: number;
  rating?: number;
  category?: string;
  address?: string;
  imageUrl?: string;
}

interface TripMapProps {
  itinerary: (TripItinerary | TripDay)[];
  selectedDay: number | null;
  onSelectDay: (day: number) => void;
  onSelectPOI?: (poi: POIMarker) => void;
  onViewDetails?: (poi: POIMarker) => void;
  city?: string;
  country?: string;
}

// Export POIMarker type for use in parent components
export type { POIMarker };

// Day colors for markers and routes
const DAY_COLORS = [
  "#8B5CF6", // purple
  "#F97316", // orange
  "#10B981", // green
  "#3B82F6", // blue
  "#EC4899", // pink
  "#F59E0B", // amber
  "#6366F1", // indigo
  "#14B8A6", // teal
];

function getDayColor(day: number): string {
  return DAY_COLORS[(day - 1) % DAY_COLORS.length];
}

// Dark map style
const darkMapStyle = [
  { elementType: "geometry", stylers: [{ color: "#212121" }] },
  { elementType: "labels.icon", stylers: [{ visibility: "off" }] },
  { elementType: "labels.text.fill", stylers: [{ color: "#757575" }] },
  { elementType: "labels.text.stroke", stylers: [{ color: "#212121" }] },
  {
    featureType: "administrative",
    elementType: "geometry",
    stylers: [{ color: "#757575" }],
  },
  {
    featureType: "administrative.country",
    elementType: "labels.text.fill",
    stylers: [{ color: "#9e9e9e" }],
  },
  {
    featureType: "administrative.locality",
    elementType: "labels.text.fill",
    stylers: [{ color: "#bdbdbd" }],
  },
  {
    featureType: "poi",
    elementType: "labels.text.fill",
    stylers: [{ color: "#757575" }],
  },
  {
    featureType: "poi.park",
    elementType: "geometry",
    stylers: [{ color: "#181818" }],
  },
  {
    featureType: "poi.park",
    elementType: "labels.text.fill",
    stylers: [{ color: "#616161" }],
  },
  {
    featureType: "road",
    elementType: "geometry.fill",
    stylers: [{ color: "#2c2c2c" }],
  },
  {
    featureType: "road",
    elementType: "labels.text.fill",
    stylers: [{ color: "#8a8a8a" }],
  },
  {
    featureType: "road.arterial",
    elementType: "geometry",
    stylers: [{ color: "#373737" }],
  },
  {
    featureType: "road.highway",
    elementType: "geometry",
    stylers: [{ color: "#3c3c3c" }],
  },
  {
    featureType: "road.highway.controlled_access",
    elementType: "geometry",
    stylers: [{ color: "#4e4e4e" }],
  },
  {
    featureType: "road.local",
    elementType: "labels.text.fill",
    stylers: [{ color: "#616161" }],
  },
  {
    featureType: "transit",
    elementType: "labels.text.fill",
    stylers: [{ color: "#757575" }],
  },
  {
    featureType: "water",
    elementType: "geometry",
    stylers: [{ color: "#000000" }],
  },
  {
    featureType: "water",
    elementType: "labels.text.fill",
    stylers: [{ color: "#3d3d3d" }],
  },
];

const mapContainerStyle = {
  width: "100%",
  height: "100%",
};

// Custom Marker Component with preview - Dark theme, compact
function POIMarkerOverlay({
  poi,
  isSelected,
  onClick,
}: {
  poi: POIMarker;
  isSelected: boolean;
  onClick: () => void;
}) {
  const color = getDayColor(poi.day);
  const [imgError, setImgError] = useState(false);

  return (
    <OverlayViewF
      position={{ lat: poi.latitude, lng: poi.longitude }}
      mapPaneName="overlayMouseTarget"
      getPixelPositionOffset={(width, height) => ({
        x: -(width / 2),
        y: -height - 6,
      })}
    >
      <div
        onClick={(e) => {
          e.stopPropagation();
          onClick();
        }}
        className={cn(
          "cursor-pointer transform transition-all duration-200 hover:scale-110 hover:z-50",
          isSelected && "scale-110 z-50"
        )}
        style={{ position: "relative" }}
      >
        {/* Marker card with photo preview - Dark theme */}
        <div
          className="rounded-lg shadow-xl overflow-hidden"
          style={{
            borderWidth: 2,
            borderStyle: "solid",
            borderColor: isSelected ? color : "rgba(255,255,255,0.2)",
            background: "#1a1a1a",
            minWidth: 52,
          }}
        >
          {/* Photo */}
          <div
            className="relative overflow-hidden"
            style={{ width: 52, height: 36 }}
          >
            {poi.imageUrl && !imgError ? (
              <img
                src={poi.imageUrl}
                alt={poi.name}
                onError={() => setImgError(true)}
                style={{
                  width: "100%",
                  height: "100%",
                  objectFit: "cover",
                }}
              />
            ) : (
              <div
                className="w-full h-full flex items-center justify-center"
                style={{ background: `${color}30` }}
              >
                {poi.type === "restaurant" ? (
                  <Utensils style={{ width: 16, height: 16, color }} />
                ) : (
                  <Building2 style={{ width: 16, height: 16, color }} />
                )}
              </div>
            )}
            {/* Index badge */}
            <div
              className="absolute flex items-center justify-center text-white font-bold shadow-md"
              style={{
                top: 2,
                left: 2,
                width: 16,
                height: 16,
                borderRadius: 8,
                background: color,
                fontSize: 9,
              }}
            >
              {poi.type === "restaurant" ? "R" : poi.index}
            </div>
          </div>

          {/* Name */}
          <div
            className="font-medium truncate"
            style={{
              padding: "3px 5px",
              fontSize: 10,
              maxWidth: 52,
              color: "rgba(255,255,255,0.9)",
              background: "#1a1a1a",
            }}
          >
            {poi.name}
          </div>
        </div>

        {/* Pointer arrow - dark */}
        <div
          style={{
            width: 0,
            height: 0,
            borderLeft: "6px solid transparent",
            borderRight: "6px solid transparent",
            borderTop: "6px solid #1a1a1a",
            margin: "0 auto",
            marginTop: -1,
          }}
        />
      </div>
    </OverlayViewF>
  );
}

export function TripMap({
  itinerary,
  selectedDay,
  onSelectDay,
  onSelectPOI,
  onViewDetails,
}: TripMapProps) {
  const [map, setMap] = useState<google.maps.Map | null>(null);
  const [selectedPOI, setSelectedPOI] = useState<POIMarker | null>(null);
  const boundsTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  const { isLoaded, loadError } = useJsApiLoader({
    googleMapsApiKey: GOOGLE_MAPS_API_KEY,
  });

  // Extract all POIs from itinerary
  const getAllPOIs = useCallback((): POIMarker[] => {
    const pois: POIMarker[] = [];

    itinerary.forEach((day) => {
      const dayNumber = day.day || 1;
      const places = day.places || [];
      const restaurants = day.restaurants || [];

      places.forEach((place, index) => {
        const lat = place.latitude;
        const lng = place.longitude;
        if (lat && lng) {
          const imageUrl =
            (place as TripPlace).image_url ||
            ((place as TripPlace).images?.[0] as { url?: string })?.url ||
            (place as PublicTripPlace).imageUrl;

          pois.push({
            id: `place-${dayNumber}-${index}`,
            name: place.name,
            type: "place",
            latitude: lat,
            longitude: lng,
            day: dayNumber,
            index: index + 1,
            rating: place.rating,
            category: place.category,
            address: place.address,
            imageUrl,
          });
        }
      });

      restaurants.forEach((restaurant, index) => {
        const lat = restaurant.latitude;
        const lng = restaurant.longitude;
        if (lat && lng) {
          const imageUrl =
            (restaurant as TripPlace).image_url ||
            ((restaurant as TripPlace).images?.[0] as { url?: string })?.url ||
            (restaurant as PublicTripPlace).imageUrl;

          pois.push({
            id: `restaurant-${dayNumber}-${index}`,
            name: restaurant.name,
            type: "restaurant",
            latitude: lat,
            longitude: lng,
            day: dayNumber,
            index: index + 1,
            rating: restaurant.rating,
            category: restaurant.cuisine || restaurant.category,
            address: restaurant.address,
            imageUrl,
          });
        }
      });
    });

    return pois;
  }, [itinerary]);

  const allPOIs = useMemo(() => getAllPOIs(), [getAllPOIs]);

  const filteredPOIs = useMemo(() => {
    return selectedDay ? allPOIs.filter((p) => p.day === selectedDay) : allPOIs;
  }, [allPOIs, selectedDay]);

  // Calculate center
  const center = useMemo(() => {
    if (filteredPOIs.length === 0) {
      return { lat: 48.8566, lng: 2.3522 }; // Default to Paris
    }
    const lats = filteredPOIs.map((p) => p.latitude);
    const lngs = filteredPOIs.map((p) => p.longitude);
    return {
      lat: (Math.min(...lats) + Math.max(...lats)) / 2,
      lng: (Math.min(...lngs) + Math.max(...lngs)) / 2,
    };
  }, [filteredPOIs]);

  // Fit bounds when POIs change
  useEffect(() => {
    if (!map || filteredPOIs.length === 0) return;

    // Debounce bounds fitting
    if (boundsTimeoutRef.current) {
      clearTimeout(boundsTimeoutRef.current);
    }

    boundsTimeoutRef.current = setTimeout(() => {
      const bounds = new google.maps.LatLngBounds();
      filteredPOIs.forEach((poi) => {
        bounds.extend({ lat: poi.latitude, lng: poi.longitude });
      });

      map.fitBounds(bounds, { top: 80, bottom: 120, left: 50, right: 50 });
    }, 100);

    return () => {
      if (boundsTimeoutRef.current) {
        clearTimeout(boundsTimeoutRef.current);
      }
    };
  }, [map, filteredPOIs]);

  const onLoad = useCallback((map: google.maps.Map) => {
    setMap(map);
  }, []);

  const onUnmount = useCallback(() => {
    setMap(null);
  }, []);

  const handleMarkerClick = (poi: POIMarker) => {
    setSelectedPOI(poi);
    onSelectPOI?.(poi);

    if (map) {
      map.panTo({ lat: poi.latitude, lng: poi.longitude });
    }
  };

  const openInMaps = (poi: POIMarker) => {
    window.open(
      `https://www.google.com/maps/search/?api=1&query=${poi.latitude},${poi.longitude}`,
      "_blank"
    );
  };

  if (loadError) {
    return (
      <div className="w-full h-full rounded-2xl bg-black/50 flex items-center justify-center">
        <div className="text-center px-4">
          <MapPin className="h-12 w-12 text-white/30 mx-auto mb-3" />
          <p className="text-white/70 text-sm">Failed to load Google Maps</p>
        </div>
      </div>
    );
  }

  if (!isLoaded) {
    return (
      <div className="w-full h-full rounded-2xl bg-black/50 flex items-center justify-center">
        <Loader2 className="h-8 w-8 text-primary animate-spin" />
      </div>
    );
  }

  if (!GOOGLE_MAPS_API_KEY) {
    return (
      <div className="w-full h-full rounded-2xl bg-black/50 flex items-center justify-center">
        <div className="text-center px-4">
          <MapPin className="h-12 w-12 text-white/30 mx-auto mb-3" />
          <p className="text-white/70 text-sm">
            Map unavailable. Add NEXT_PUBLIC_GOOGLE_MAPS_API_KEY to enable maps.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="relative w-full h-full rounded-2xl overflow-hidden">
      <GoogleMap
        mapContainerStyle={mapContainerStyle}
        center={center}
        zoom={13}
        onLoad={onLoad}
        onUnmount={onUnmount}
        options={{
          styles: darkMapStyle,
          disableDefaultUI: true,
          zoomControl: false,
          mapTypeControl: false,
          streetViewControl: false,
          fullscreenControl: false,
        }}
      >
        {/* POI Markers with preview */}
        {filteredPOIs.map((poi) => (
          <POIMarkerOverlay
            key={poi.id}
            poi={poi}
            isSelected={selectedPOI?.id === poi.id}
            onClick={() => handleMarkerClick(poi)}
          />
        ))}
      </GoogleMap>

      {/* Custom Zoom Controls - Desktop only, top right */}
      <div className="absolute top-4 right-4 z-10 hidden md:flex flex-col gap-0 rounded-xl overflow-hidden shadow-lg">
        <button
          onClick={() => map?.setZoom((map.getZoom() || 13) + 1)}
          className="p-3 bg-black/50 backdrop-blur-md text-white hover:bg-black/70 transition-colors border-b border-white/10"
        >
          <Plus className="h-5 w-5" />
        </button>
        <button
          onClick={() => map?.setZoom((map.getZoom() || 13) - 1)}
          className="p-3 bg-black/50 backdrop-blur-md text-white hover:bg-black/70 transition-colors"
        >
          <Minus className="h-5 w-5" />
        </button>
      </div>

      {/* Day indicator (only show when a day is selected) */}
      {selectedDay && (
        <div className="absolute top-4 left-4 z-10">
          <div
            className="px-4 py-2 rounded-full text-white text-sm font-semibold shadow-lg flex items-center gap-2"
            style={{ background: getDayColor(selectedDay) }}
          >
            <span>Day {selectedDay}</span>
            <span className="opacity-70">•</span>
            <span className="opacity-70">{filteredPOIs.length} places</span>
          </div>
        </div>
      )}

      {/* Selected POI card */}
      {selectedPOI && (
        <div className="absolute bottom-4 left-4 right-4 z-10">
          <div className="bg-black/90 backdrop-blur-md rounded-2xl p-4 shadow-xl border border-white/10">
            <div className="flex items-start gap-3">
              {/* POI image */}
              <div
                className="rounded-xl overflow-hidden flex-shrink-0"
                style={{ width: 64, height: 64 }}
              >
                {selectedPOI.imageUrl ? (
                  <img
                    src={selectedPOI.imageUrl}
                    alt={selectedPOI.name}
                    style={{
                      width: "100%",
                      height: "100%",
                      objectFit: "cover",
                    }}
                  />
                ) : (
                  <div
                    className="w-full h-full flex items-center justify-center"
                    style={{ background: getDayColor(selectedPOI.day) }}
                  >
                    {selectedPOI.type === "restaurant" ? (
                      <Utensils className="h-6 w-6 text-white" />
                    ) : (
                      <Building2 className="h-6 w-6 text-white" />
                    )}
                  </div>
                )}
              </div>

              {/* Info */}
              <div className="flex-1 min-w-0">
                <h3 className="font-semibold text-white truncate">
                  {selectedPOI.name}
                </h3>
                <p className="text-sm text-white/60 mt-0.5">
                  {selectedPOI.type === "restaurant" ? "Restaurant" : "Place"}
                  {selectedPOI.category && ` • ${selectedPOI.category}`}
                </p>
                {selectedPOI.address && (
                  <p className="text-xs text-white/40 mt-1 truncate">
                    {selectedPOI.address}
                  </p>
                )}
              </div>

              {/* Close button */}
              <button
                onClick={() => setSelectedPOI(null)}
                className="p-1.5 rounded-full hover:bg-white/10 transition-colors"
              >
                <X className="h-4 w-4 text-white/70" />
              </button>
            </div>

            {/* Action buttons */}
            <div className="flex gap-2 mt-3">
              <button
                onClick={() => openInMaps(selectedPOI)}
                className="flex-1 flex items-center justify-center gap-2 bg-white/10 text-white py-2.5 px-3 rounded-xl text-sm font-medium hover:bg-white/20 transition-colors"
              >
                <Navigation className="h-4 w-4" />
                Directions
              </button>
              <button
                onClick={() => {
                  onViewDetails?.(selectedPOI);
                  setSelectedPOI(null);
                }}
                className="flex-1 flex items-center justify-center gap-2 bg-primary text-white py-2.5 px-3 rounded-xl text-sm font-medium hover:bg-primary/90 transition-colors"
              >
                <Eye className="h-4 w-4" />
                View Details
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
