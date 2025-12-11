"use client";

import { useState } from "react";
import dynamic from "next/dynamic";
import { Header } from "@/components/layout/header";
import { Footer } from "@/components/layout/footer";
import { FloatingDock } from "@/components/layout/floating-dock";
import { HeroSearch } from "@/components/features/home/hero-search";
import { useCitiesWithTrips } from "@/hooks/useTrips";
import { useAuth } from "@/contexts/auth-context";
import { MapPin, TrendingUp } from "lucide-react";
import Link from "next/link";
import Image from "next/image";
import { cn } from "@/lib/utils";

// Dynamic imports for below-the-fold components to reduce initial JS bundle
const TripsByCitySection = dynamic(
  () => import("@/components/features/home/trips-by-city-section").then(m => ({ default: m.TripsByCitySection })),
  {
    ssr: true,
    loading: () => <TripsByCitySkeleton />
  }
);

const ActivityFilter = dynamic(
  () => import("@/components/features/home/activity-filter").then(m => ({ default: m.ActivityFilter })),
  { ssr: true }
);

// Skeleton for TripsByCitySection
function TripsByCitySkeleton() {
  return (
    <div className="py-8 sm:py-12">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="mb-6">
          <div className="h-7 w-48 bg-muted rounded animate-pulse" />
          <div className="h-4 w-32 bg-muted rounded animate-pulse mt-2" />
        </div>
        <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3 sm:gap-6">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="aspect-[4/5] rounded-2xl bg-muted animate-pulse" />
          ))}
        </div>
      </div>
    </div>
  );
}

export default function HomePage() {
  const { cities, isLoading: citiesLoading } = useCitiesWithTrips();
  const { user } = useAuth();
  const isLoggedIn = !!user;
  const [selectedActivity, setSelectedActivity] = useState<string>("all");

  // Get top 4 cities for trending section
  const trendingCities = cities.slice(0, 4);

  return (
    <div className="min-h-screen bg-background">
      <Header />

      <main>
        {/* Hero Section */}
        <HeroSearch />

        {/* Activity Filter */}
        <div className={cn(
          "mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 pb-0 sm:pb-4",
          isLoggedIn ? "pt-0" : "pt-4"
        )}>
          <ActivityFilter
            selected={selectedActivity}
            onSelect={setSelectedActivity}
          />
        </div>

        {/* Trips by City Sections */}
        <TripsByCitySection
          tripsLimit={4}
          citiesLimit={6}
          activityType={selectedActivity === "all" ? null : selectedActivity}
        />

        {/* Trending Destinations */}
        {trendingCities.length > 0 && (
          <section className="bg-muted/30 py-12 sm:py-16">
            <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
              <div className="flex items-center justify-between mb-8">
                <div>
                  <h2 className="text-2xl sm:text-3xl font-bold text-foreground">
                    Trending Destinations
                  </h2>
                  <p className="text-muted-foreground mt-1 flex items-center gap-2">
                    <TrendingUp className="h-4 w-4" />
                    Most popular this month
                  </p>
                </div>
              </div>

              <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
                {trendingCities.map((city, index) => (
                  <Link
                    key={city.id}
                    href={`/explore?city=${encodeURIComponent(city.name)}`}
                    className="group relative aspect-[4/5] rounded-2xl overflow-hidden bg-muted"
                  >
                    {city.imageUrl ? (
                      <Image
                        src={city.imageUrl}
                        alt={city.name}
                        fill
                        className="object-cover transition-transform duration-500 group-hover:scale-110"
                        sizes="(max-width: 640px) 50vw, (max-width: 1024px) 50vw, 25vw"
                        priority={index < 2}
                      />
                    ) : (
                      <div className="absolute inset-0 bg-gradient-to-br from-primary/20 to-primary/5 flex items-center justify-center">
                        <MapPin className="h-16 w-16 text-muted-foreground/30" />
                      </div>
                    )}
                    <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-transparent" />
                    <div className="absolute bottom-0 left-0 right-0 p-4 sm:p-5">
                      <h3 className="text-lg sm:text-xl font-bold text-white">
                        {city.name}
                      </h3>
                      <p className="text-white/80 text-sm flex items-center gap-1 mt-1">
                        <MapPin className="h-3.5 w-3.5" />
                        {city.country}
                      </p>
                      <p className="text-white/60 text-xs mt-2">
                        {city.tripsCount} {city.tripsCount === 1 ? "trip" : "trips"}
                      </p>
                    </div>
                  </Link>
                ))}
              </div>
            </div>
          </section>
        )}

        {/* Loading skeleton for trending cities */}
        {citiesLoading && (
          <section className="bg-muted/30 py-12 sm:py-16">
            <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
              <div className="space-y-2 mb-8">
                <div className="h-8 w-64 bg-muted rounded animate-pulse" />
                <div className="h-5 w-48 bg-muted rounded animate-pulse" />
              </div>
              <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
                {Array.from({ length: 4 }).map((_, i) => (
                  <div key={i} className="aspect-[4/5] rounded-2xl bg-muted animate-pulse" />
                ))}
              </div>
            </div>
          </section>
        )}
      </main>

      <Footer />

      {/* Floating Elements */}
      <FloatingDock />
    </div>
  );
}
