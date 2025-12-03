"use client";

import { useState, useMemo } from "react";
import { Header } from "@/components/layout/header";
import { Footer } from "@/components/layout/footer";
import { FloatingDock } from "@/components/layout/floating-dock";
import { FloatingChat } from "@/components/features/chat/floating-chat";
import { MyTripsHeader } from "@/components/features/trips/my-trips-header";
import { MyTripCard, CompactTripCard, MyTripCardSkeleton, type Trip } from "@/components/features/trips/my-trip-card";
import { PlaceCard, CompactPlaceCard, PlaceCardSkeleton, type Place } from "@/components/features/trips/place-card";
import { TripsEmptyState } from "@/components/features/trips/trips-empty-state";
import { cn } from "@/lib/utils";

// Mock data for demonstration
const mockTrips: Trip[] = [
  {
    id: "1",
    title: "Weekend in Paris",
    city: "Paris",
    country: "France",
    price: 1200,
    currency: "EUR",
    duration_days: 3,
    rating: 4.8,
    is_favorite: true,
    images: [
      "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800",
      "https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=800",
    ],
    activity_type: "Cultural",
  },
  {
    id: "2",
    title: "Bali Adventure",
    city: "Bali",
    country: "Indonesia",
    price: 2500,
    currency: "USD",
    duration_days: 7,
    rating: 4.9,
    is_favorite: false,
    images: [
      "https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=800",
      "https://images.unsplash.com/photo-1552733407-5d5c46c3bb3b?w=800",
    ],
    activity_type: "Adventure",
  },
  {
    id: "3",
    title: "Tokyo Explorer",
    city: "Tokyo",
    country: "Japan",
    price: 3000,
    currency: "USD",
    duration_days: 5,
    rating: 4.7,
    is_favorite: true,
    images: [
      "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800",
      "https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=800",
    ],
    activity_type: "Cultural",
  },
  {
    id: "4",
    title: "Barcelona Beach Trip",
    city: "Barcelona",
    country: "Spain",
    price: 1500,
    currency: "EUR",
    duration_days: 4,
    rating: 4.6,
    is_favorite: false,
    images: [
      "https://images.unsplash.com/photo-1583422409516-2895a77efded?w=800",
    ],
    activity_type: "Beach",
  },
];

const mockPlaces: Place[] = [
  {
    id: "1",
    name: "Le Jules Verne",
    city: "Paris",
    country: "France",
    place_type: "restaurant",
    images: [
      "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800",
    ],
    rating: 4.9,
    is_favorite: true,
    estimated_price: "€150",
  },
  {
    id: "2",
    name: "Senso-ji Temple",
    city: "Tokyo",
    country: "Japan",
    place_type: "attraction",
    images: [
      "https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=800",
    ],
    rating: 4.8,
    is_favorite: false,
  },
  {
    id: "3",
    name: "Café de Flore",
    city: "Paris",
    country: "France",
    place_type: "cafe",
    images: [
      "https://images.unsplash.com/photo-1559925393-8be0ec4767c8?w=800",
    ],
    rating: 4.5,
    is_favorite: true,
    estimated_price: "€20",
  },
  {
    id: "4",
    name: "Nusa Dua Beach",
    city: "Bali",
    country: "Indonesia",
    place_type: "beach",
    images: [
      "https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?w=800",
    ],
    rating: 4.7,
    is_favorite: false,
  },
  {
    id: "5",
    name: "Park Hyatt Tokyo",
    city: "Tokyo",
    country: "Japan",
    place_type: "hotel",
    images: [
      "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800",
    ],
    rating: 4.9,
    is_favorite: true,
    price_range: "$400-600/night",
  },
];

export default function MyTripsPage() {
  const [activeTab, setActiveTab] = useState(0);
  const [viewMode, setViewMode] = useState<"list" | "grid">("list");
  const [searchQuery, setSearchQuery] = useState("");
  const [trips, setTrips] = useState<Trip[]>(mockTrips);
  const [places, setPlaces] = useState<Place[]>(mockPlaces);
  const [isLoading, setIsLoading] = useState(false);

  // Filter trips based on search query
  const filteredTrips = useMemo(() => {
    if (!searchQuery.trim()) return trips;
    const query = searchQuery.toLowerCase();
    return trips.filter(
      (trip) =>
        trip.title.toLowerCase().includes(query) ||
        trip.city.toLowerCase().includes(query) ||
        trip.country.toLowerCase().includes(query) ||
        trip.activity_type?.toLowerCase().includes(query)
    );
  }, [trips, searchQuery]);

  // Filter places based on search query
  const filteredPlaces = useMemo(() => {
    if (!searchQuery.trim()) return places;
    const query = searchQuery.toLowerCase();
    return places.filter(
      (place) =>
        place.name.toLowerCase().includes(query) ||
        place.city.toLowerCase().includes(query) ||
        place.country.toLowerCase().includes(query) ||
        place.place_type.toLowerCase().includes(query)
    );
  }, [places, searchQuery]);

  const handleTripFavoriteToggle = (id: string) => {
    setTrips((prev) =>
      prev.map((trip) =>
        trip.id === id ? { ...trip, is_favorite: !trip.is_favorite } : trip
      )
    );
  };

  const handleTripDelete = (id: string) => {
    if (window.confirm("Are you sure you want to delete this trip?")) {
      setTrips((prev) => prev.filter((trip) => trip.id !== id));
    }
  };

  const handlePlaceFavoriteToggle = (id: string) => {
    setPlaces((prev) =>
      prev.map((place) =>
        place.id === id ? { ...place, is_favorite: !place.is_favorite } : place
      )
    );
  };

  const handlePlaceDelete = (id: string) => {
    if (window.confirm("Are you sure you want to delete this place?")) {
      setPlaces((prev) => prev.filter((place) => place.id !== id));
    }
  };

  const handleTripClick = (trip: Trip) => {
    console.log("Trip clicked:", trip);
    // TODO: Open trip details modal or navigate
  };

  const handlePlaceClick = (place: Place) => {
    console.log("Place clicked:", place);
    // TODO: Open place details modal
  };

  return (
    <div className="min-h-screen bg-background">
      <Header />

      <main className="pt-16">
        {/* Page Header with Search and Tabs */}
        <MyTripsHeader
          activeTab={activeTab}
          onTabChange={setActiveTab}
          tripsCount={filteredTrips.length}
          placesCount={filteredPlaces.length}
          viewMode={viewMode}
          onViewModeChange={setViewMode}
          searchQuery={searchQuery}
          onSearchChange={setSearchQuery}
        />

        {/* Content */}
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {/* Trips Tab */}
        {activeTab === 0 && (
          <>
            {isLoading ? (
              <div
                className={cn(
                  viewMode === "grid"
                    ? "grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4"
                    : "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
                )}
              >
                {Array.from({ length: 6 }).map((_, i) => (
                  <MyTripCardSkeleton key={i} />
                ))}
              </div>
            ) : filteredTrips.length === 0 ? (
              <TripsEmptyState type="trips" />
            ) : viewMode === "grid" ? (
              <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
                {filteredTrips.map((trip) => (
                  <CompactTripCard
                    key={trip.id}
                    trip={trip}
                    onFavoriteToggle={handleTripFavoriteToggle}
                    onClick={handleTripClick}
                  />
                ))}
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {filteredTrips.map((trip) => (
                  <MyTripCard
                    key={trip.id}
                    trip={trip}
                    onFavoriteToggle={handleTripFavoriteToggle}
                    onDelete={handleTripDelete}
                    onClick={handleTripClick}
                  />
                ))}
              </div>
            )}
          </>
        )}

        {/* Places Tab */}
        {activeTab === 1 && (
          <>
            {isLoading ? (
              <div
                className={cn(
                  viewMode === "grid"
                    ? "grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4"
                    : "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
                )}
              >
                {Array.from({ length: 6 }).map((_, i) => (
                  <PlaceCardSkeleton key={i} />
                ))}
              </div>
            ) : filteredPlaces.length === 0 ? (
              <TripsEmptyState type="places" />
            ) : viewMode === "grid" ? (
              <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
                {filteredPlaces.map((place) => (
                  <CompactPlaceCard
                    key={place.id}
                    place={place}
                    onFavoriteToggle={handlePlaceFavoriteToggle}
                    onClick={handlePlaceClick}
                  />
                ))}
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {filteredPlaces.map((place) => (
                  <PlaceCard
                    key={place.id}
                    place={place}
                    onFavoriteToggle={handlePlaceFavoriteToggle}
                    onDelete={handlePlaceDelete}
                    onClick={handlePlaceClick}
                  />
                ))}
              </div>
            )}
          </>
        )}
        </div>
      </main>

      <Footer />

      {/* Floating Elements */}
      <FloatingDock />
      <FloatingChat />
    </div>
  );
}
