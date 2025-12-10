"use client";

import { useTripsByCity } from "@/hooks/useTrips";
import { DBTripCard, DBTripCardSkeleton } from "@/components/features/trips/db-trip-card";
import { Button } from "@/components/ui/button";
import { ArrowRight, MapPin, AlertCircle } from "lucide-react";
import Link from "next/link";
import type { TripsByCity } from "@/types/trip";

interface TripsByCitySectionProps {
  tripsLimit?: number;
  citiesLimit?: number;
  activityType?: string | null;
}

function CitySection({ cityData }: { cityData: TripsByCity }) {
  const { city, trips } = cityData;

  return (
    <section className="py-4 sm:py-6 first:pt-2 sm:first:pt-4">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        {/* City Header */}
        <div className="flex items-center justify-between mb-6">
          <div>
            <h2 className="text-xl sm:text-2xl font-bold text-foreground">
              Trips in {city.name}
            </h2>
            <p className="text-muted-foreground text-sm mt-0.5">
              {city.country} • {city.tripsCount} {city.tripsCount === 1 ? "trip" : "trips"} available
            </p>
          </div>
          <Link href={`/explore?city=${encodeURIComponent(city.name)}`}>
            <Button variant="ghost" className="gap-2 hidden sm:flex">
              View all
              <ArrowRight className="h-4 w-4" />
            </Button>
          </Link>
        </div>

        {/* Trips Grid */}
        <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3 sm:gap-6">
          {trips.map((trip, index) => (
            <DBTripCard
              key={trip.id}
              trip={trip}
              priority={index < 2}
            />
          ))}
        </div>

        {/* Mobile View All Button */}
        {city.tripsCount > trips.length && (
          <div className="mt-6 flex justify-center sm:hidden">
            <Link href={`/explore?city=${encodeURIComponent(city.name)}`}>
              <Button variant="outline" className="gap-2">
                View all {city.tripsCount} trips
                <ArrowRight className="h-4 w-4" />
              </Button>
            </Link>
          </div>
        )}
      </div>
    </section>
  );
}

function LoadingSkeleton({ count = 3 }: { count?: number }) {
  return (
    <>
      {Array.from({ length: count }).map((_, cityIndex) => (
        <section key={cityIndex} className="py-8 sm:py-12">
          <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            {/* Header Skeleton */}
            <div className="mb-6">
              <div className="h-7 w-48 bg-muted rounded animate-pulse" />
              <div className="h-4 w-32 bg-muted rounded animate-pulse mt-2" />
            </div>
            {/* Cards Skeleton */}
            <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3 sm:gap-6">
              {Array.from({ length: 4 }).map((_, i) => (
                <DBTripCardSkeleton key={i} />
              ))}
            </div>
          </div>
        </section>
      ))}
    </>
  );
}

function ErrorState({ error }: { error: string }) {
  return (
    <section className="py-12">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="text-center py-12 bg-muted/30 rounded-2xl">
          <AlertCircle className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-foreground mb-2">
            Unable to load trips
          </h3>
          <p className="text-muted-foreground max-w-md mx-auto">
            {error || "Something went wrong while loading trips. Please try again later."}
          </p>
        </div>
      </div>
    </section>
  );
}

function EmptyState() {
  return (
    <section className="py-12">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="text-center py-12 bg-muted/30 rounded-2xl">
          <MapPin className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-foreground mb-2">
            No trips available yet
          </h3>
          <p className="text-muted-foreground max-w-md mx-auto mb-6">
            Be the first to create an AI-generated trip! Start a conversation with our travel AI assistant.
          </p>
          <Link href="/chat">
            <Button>Start Planning</Button>
          </Link>
        </div>
      </div>
    </section>
  );
}

export function TripsByCitySection({
  tripsLimit = 4,
  citiesLimit = 6,
  activityType,
}: TripsByCitySectionProps) {
  const { tripsByCity, error, isLoading } = useTripsByCity({
    limit: tripsLimit,
    citiesLimit,
  });

  if (isLoading) {
    return <LoadingSkeleton count={3} />;
  }

  if (error) {
    return <ErrorState error={error} />;
  }

  if (!tripsByCity.length) {
    return <EmptyState />;
  }

  // Filter by activity type if selected
  const filteredTripsByCity = activityType
    ? tripsByCity
        .map((cityData) => ({
          ...cityData,
          trips: cityData.trips.filter(
            (trip) => trip.activityType === activityType
          ),
        }))
        .filter((cityData) => cityData.trips.length > 0)
    : tripsByCity;

  if (activityType && filteredTripsByCity.length === 0) {
    return (
      <section className="py-12">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center py-12 bg-muted/30 rounded-2xl">
            <MapPin className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
            <h3 className="text-lg font-semibold text-foreground mb-2">
              No {activityType.replace("_", " ")} trips found
            </h3>
            <p className="text-muted-foreground max-w-md mx-auto">
              Try selecting a different activity type or explore all trips.
            </p>
          </div>
        </div>
      </section>
    );
  }

  return (
    <div className="divide-y divide-border/50">
      {filteredTripsByCity.map((cityData) => (
        <CitySection key={cityData.city.id} cityData={cityData} />
      ))}
    </div>
  );
}
