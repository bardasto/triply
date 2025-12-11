"use client";

import { useState, useMemo, useEffect, useRef, useCallback } from "react";
import { useRouter } from "next/navigation";
import { Header } from "@/components/layout/header";
import { Footer } from "@/components/layout/footer";
import { FloatingDock } from "@/components/layout/floating-dock";
import { MyTripsHeader } from "@/components/features/trips/my-trips-header";
import { MyTripCard, CompactTripCard, MyTripCardSkeleton } from "@/components/features/trips/my-trip-card";
import { PlaceCard, CompactPlaceCard, PlaceCardSkeleton, type Place } from "@/components/features/trips/place-card";
import { TripsEmptyState } from "@/components/features/trips/trips-empty-state";
import { AuthModal } from "@/components/features/auth/auth-modal";
import { useAuth } from "@/contexts/auth-context";
import { useUserTripsPaginated, useUserTripActions, useUserTripsRealtime } from "@/hooks/useUserTrips";
import type { UserTripCard } from "@/types/user-trip";

// Mock places data (will be replaced when places table is ready)
const mockPlaces: Place[] = [];

// View More button component
function ViewMoreButton({
  remainingCount,
  onClick,
  isLoading = false,
}: {
  remainingCount: number;
  onClick: () => void;
  isLoading?: boolean;
}) {
  return (
    <button
      onClick={onClick}
      disabled={isLoading}
      className="group relative w-full py-4 px-6 rounded-2xl border border-white/10 bg-white/5 backdrop-blur-sm hover:bg-white/10 hover:border-primary/30 transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed"
    >
      <div className="flex items-center justify-center gap-3">
        {isLoading ? (
          <div className="w-5 h-5 border-2 border-primary/30 border-t-primary rounded-full animate-spin" />
        ) : (
          <>
            <span className="text-sm font-medium text-foreground/80 group-hover:text-foreground transition-colors">
              View more
            </span>
            <span className="px-2 py-0.5 rounded-full bg-primary/20 text-primary text-xs font-semibold">
              +{remainingCount}
            </span>
          </>
        )}
      </div>
    </button>
  );
}

// Ripple text button component
function RippleTextButton({
  children,
  onClick,
  className = ""
}: {
  children: React.ReactNode;
  onClick: () => void;
  className?: string;
}) {
  const buttonRef = useRef<HTMLButtonElement>(null);
  const overlayRef = useRef<HTMLSpanElement>(null);
  const [clipPath, setClipPath] = useState('circle(0% at 50% 50%)');

  const handleMouseEnter = useCallback((event: React.MouseEvent<HTMLButtonElement>) => {
    if (!buttonRef.current) return;
    const rect = buttonRef.current.getBoundingClientRect();
    const x = ((event.clientX - rect.left) / rect.width) * 100;
    const y = ((event.clientY - rect.top) / rect.height) * 100;
    setClipPath(`circle(0% at ${x}% ${y}%)`);

    requestAnimationFrame(() => {
      setClipPath(`circle(150% at ${x}% ${y}%)`);
    });
  }, []);

  const handleMouseLeave = useCallback((event: React.MouseEvent<HTMLButtonElement>) => {
    if (!buttonRef.current) return;
    const rect = buttonRef.current.getBoundingClientRect();
    const x = ((event.clientX - rect.left) / rect.width) * 100;
    const y = ((event.clientY - rect.top) / rect.height) * 100;
    setClipPath(`circle(0% at ${x}% ${y}%)`);
  }, []);

  const handleMouseMove = useCallback((event: React.MouseEvent<HTMLButtonElement>) => {
    if (!buttonRef.current || !overlayRef.current) return;
    const rect = buttonRef.current.getBoundingClientRect();
    const x = ((event.clientX - rect.left) / rect.width) * 100;
    const y = ((event.clientY - rect.top) / rect.height) * 100;

    // Update clip-path center position while keeping the size
    const currentClip = overlayRef.current.style.clipPath;
    const sizeMatch = currentClip.match(/circle\(([^%]+%)/);
    const size = sizeMatch ? sizeMatch[1] : '150%';
    setClipPath(`circle(${size} at ${x}% ${y}%)`);
  }, []);

  return (
    <button
      ref={buttonRef}
      className={`relative inline-block cursor-pointer ${className}`}
      onClick={onClick}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      onMouseMove={handleMouseMove}
    >
      {/* Base text - purple */}
      <span className="text-primary">{children}</span>

      {/* Overlay text - orange, revealed by clip-path */}
      <span
        ref={overlayRef}
        className="absolute inset-0 text-accent"
        style={{
          clipPath,
          transition: 'clip-path 300ms ease-out'
        }}
      >
        {children}
      </span>
    </button>
  );
}

export default function MyTripsPage() {
  const router = useRouter();
  const { user, isLoading: authLoading } = useAuth();
  const [searchQuery, setSearchQuery] = useState("");

  // Use server-side paginated hook with search filter
  const searchFilter = useMemo(() => {
    return searchQuery.trim() ? { search: searchQuery.trim() } : undefined;
  }, [searchQuery]);

  const {
    tripCards,
    totalCount,
    isLoading: tripsLoading,
    isLoadingMore,
    hasMore: hasMoreTrips,
    remainingCount: remainingTripsCount,
    loadMore: loadMoreTrips,
    mutate,
  } = useUserTripsPaginated(searchFilter);

  const { toggleFavorite, deleteTrip } = useUserTripActions();
  const { subscribe } = useUserTripsRealtime();

  const [activeTab, setActiveTab] = useState(0);
  const [viewMode, setViewMode] = useState<"list" | "grid">("list");
  const [places] = useState<Place[]>(mockPlaces);
  const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);

  // Places pagination (client-side for now since places aren't from server yet)
  const PLACES_PAGE_SIZE = 8;
  const [placesVisibleCount, setPlacesVisibleCount] = useState(PLACES_PAGE_SIZE);

  // Reset places pagination when search query changes
  useEffect(() => {
    setPlacesVisibleCount(PLACES_PAGE_SIZE);
  }, [searchQuery]);

  // Subscribe to real-time updates
  useEffect(() => {
    const unsubscribe = subscribe();
    return unsubscribe;
  }, [subscribe]);

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

  // Visible places (client-side pagination)
  const visiblePlaces = useMemo(() => {
    return filteredPlaces.slice(0, placesVisibleCount);
  }, [filteredPlaces, placesVisibleCount]);

  const remainingPlacesCount = filteredPlaces.length - placesVisibleCount;
  const hasMorePlaces = remainingPlacesCount > 0;

  // Load more handler for places
  const handleLoadMorePlaces = useCallback(() => {
    setPlacesVisibleCount((prev) => prev + PLACES_PAGE_SIZE);
  }, []);

  const handleTripFavoriteToggle = async (id: string) => {
    const trip = tripCards.find((t) => t.id === id);
    if (!trip) return;

    const { success } = await toggleFavorite(id, !trip.is_favorite);
    if (success) {
      // Revalidate data from server
      mutate();
    }
  };

  const handleTripDelete = async (id: string) => {
    if (!window.confirm("Are you sure you want to delete this trip?")) {
      return;
    }

    const { success } = await deleteTrip(id);
    if (success) {
      // Revalidate data from server
      mutate();
    }
  };

  const handlePlaceFavoriteToggle = (id: string) => {
    // TODO: Implement when places table is ready
    console.log("Toggle place favorite:", id);
  };

  const handlePlaceDelete = (id: string) => {
    // TODO: Implement when places table is ready
    console.log("Delete place:", id);
  };

  const handleTripClick = (trip: UserTripCard) => {
    router.push(`/trips/${trip.id}`);
  };

  const handlePlaceClick = (place: Place) => {
    console.log("Place clicked:", place);
    // TODO: Open place details modal
  };

  const isLoading = authLoading || tripsLoading;

  // Show login prompt if not authenticated
  if (!authLoading && !user) {
    return (
      <div className="min-h-screen bg-background">
        <Header />
        <main className="pt-16 relative overflow-hidden">
          {/* Background gradient */}
          <div className="absolute inset-0 bg-gradient-to-b from-primary/5 via-background to-background pointer-events-none" />

          {/* Decorative elements */}
          <div className="absolute top-10 left-0 w-[400px] h-[400px] bg-primary/10 rounded-full blur-3xl animate-pulse pointer-events-none" />
          <div className="absolute top-20 right-0 w-[500px] h-[500px] bg-accent/10 rounded-full blur-3xl animate-pulse delay-1000 pointer-events-none" />

          <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
            <div className="text-center py-20">
              <h1 className="text-2xl font-bold text-foreground mb-4">
                <RippleTextButton
                  onClick={() => setIsAuthModalOpen(true)}
                  className="text-primary"
                >
                  Sign in
                </RippleTextButton>
                {" "}to view your trips
              </h1>
              <p className="text-muted-foreground mb-8">
                Your saved trips and favorite places will appear here once you sign in.
              </p>
            </div>
          </div>
        </main>
        <Footer />
        <FloatingDock />

        {/* Auth Modal */}
        <AuthModal
          isOpen={isAuthModalOpen}
          onClose={() => setIsAuthModalOpen(false)}
        />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <Header />

      <main className="pt-16 relative overflow-hidden">
        {/* Background gradient */}
        <div className="absolute inset-0 bg-gradient-to-b from-primary/5 via-background to-background pointer-events-none" />

        {/* Decorative elements */}
        <div className="absolute top-10 left-0 w-[400px] h-[400px] bg-primary/10 rounded-full blur-3xl animate-pulse pointer-events-none" />
        <div className="absolute top-20 right-0 w-[500px] h-[500px] bg-accent/10 rounded-full blur-3xl animate-pulse delay-1000 pointer-events-none" />

        {/* Page Header with Search and Tabs */}
        <MyTripsHeader
          activeTab={activeTab}
          onTabChange={setActiveTab}
          tripsCount={totalCount}
          placesCount={filteredPlaces.length}
          viewMode={viewMode}
          onViewModeChange={setViewMode}
          searchQuery={searchQuery}
          onSearchChange={setSearchQuery}
        />

        {/* Content */}
        <div className="relative max-w-7xl mx-auto px-5 sm:px-6 lg:px-8 py-6 pb-32">
          {/* Trips Tab */}
          {activeTab === 0 && (
            <>
              {isLoading ? (
                <div className="grid grid-cols-2 gap-3 md:grid-cols-3 lg:grid-cols-4 md:gap-5 lg:gap-6">
                  {Array.from({ length: 6 }).map((_, i) => (
                    <MyTripCardSkeleton key={i} />
                  ))}
                </div>
              ) : tripCards.length === 0 ? (
                <TripsEmptyState type="trips" />
              ) : (
                <div className="space-y-6">
                  {/* Mobile: list or grid based on viewMode */}
                  {viewMode === "list" ? (
                    <div className="md:hidden space-y-0">
                      {tripCards.map((trip, index) => (
                        <div key={trip.id}>
                          <div className="py-4 first:pt-0">
                            <MyTripCard
                              trip={trip}
                              onFavoriteToggle={handleTripFavoriteToggle}
                              onDelete={handleTripDelete}
                              onClick={handleTripClick}
                            />
                          </div>
                          {index < tripCards.length - 1 && (
                            <div className="h-px bg-white/10" />
                          )}
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="md:hidden grid grid-cols-2 gap-3">
                      {tripCards.map((trip) => (
                        <CompactTripCard
                          key={trip.id}
                          trip={trip}
                          onFavoriteToggle={handleTripFavoriteToggle}
                          onDelete={handleTripDelete}
                          onClick={handleTripClick}
                        />
                      ))}
                    </div>
                  )}

                  {/* Desktop: always grid with larger cards */}
                  <div className="hidden md:grid md:grid-cols-3 lg:grid-cols-4 gap-5 lg:gap-6">
                    {tripCards.map((trip) => (
                      <CompactTripCard
                        key={trip.id}
                        trip={trip}
                        onFavoriteToggle={handleTripFavoriteToggle}
                        onDelete={handleTripDelete}
                        onClick={handleTripClick}
                      />
                    ))}
                  </div>

                  {/* View More button */}
                  {hasMoreTrips && (
                    <ViewMoreButton
                      remainingCount={remainingTripsCount}
                      onClick={loadMoreTrips}
                      isLoading={isLoadingMore}
                    />
                  )}
                </div>
              )}
            </>
          )}

          {/* Places Tab */}
          {activeTab === 1 && (
            <>
              {isLoading ? (
                <div className="grid grid-cols-2 gap-3 md:grid-cols-3 lg:grid-cols-4 md:gap-5 lg:gap-6">
                  {Array.from({ length: 6 }).map((_, i) => (
                    <PlaceCardSkeleton key={i} />
                  ))}
                </div>
              ) : filteredPlaces.length === 0 ? (
                <TripsEmptyState type="places" />
              ) : (
                <div className="space-y-6">
                  {/* Mobile: list or grid based on viewMode */}
                  {viewMode === "list" ? (
                    <div className="md:hidden space-y-0">
                      {visiblePlaces.map((place, index) => (
                        <div key={place.id}>
                          <div className="py-4 first:pt-0">
                            <PlaceCard
                              place={place}
                              onFavoriteToggle={handlePlaceFavoriteToggle}
                              onDelete={handlePlaceDelete}
                              onClick={handlePlaceClick}
                            />
                          </div>
                          {index < visiblePlaces.length - 1 && (
                            <div className="h-px bg-white/10" />
                          )}
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="md:hidden grid grid-cols-2 gap-3">
                      {visiblePlaces.map((place) => (
                        <CompactPlaceCard
                          key={place.id}
                          place={place}
                          onFavoriteToggle={handlePlaceFavoriteToggle}
                          onDelete={handlePlaceDelete}
                          onClick={handlePlaceClick}
                        />
                      ))}
                    </div>
                  )}

                  {/* Desktop: always grid */}
                  <div className="hidden md:grid md:grid-cols-3 lg:grid-cols-4 gap-5 lg:gap-6">
                    {visiblePlaces.map((place) => (
                      <CompactPlaceCard
                        key={place.id}
                        place={place}
                        onFavoriteToggle={handlePlaceFavoriteToggle}
                        onDelete={handlePlaceDelete}
                        onClick={handlePlaceClick}
                      />
                    ))}
                  </div>

                  {/* View More button */}
                  {hasMorePlaces && (
                    <ViewMoreButton
                      remainingCount={remainingPlacesCount}
                      onClick={handleLoadMorePlaces}
                    />
                  )}
                </div>
              )}
            </>
          )}
        </div>
      </main>

      <Footer />

      {/* Floating Elements */}
      <FloatingDock />
    </div>
  );
}
