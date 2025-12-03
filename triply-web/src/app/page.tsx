"use client";

import { useState, useMemo } from "react";
import { Header } from "@/components/layout/header";
import { Footer } from "@/components/layout/footer";
import { FloatingDock } from "@/components/layout/floating-dock";
import { HeroSearch } from "@/components/features/home/hero-search";
import { FloatingChat } from "@/components/features/chat/floating-chat";
import { ActivityFilter } from "@/components/features/home/activity-filter";
import { TripCard } from "@/components/features/trips/trip-card";
import { mockTrips, featuredDestinations } from "@/data/mock-trips";
import { ArrowRight, MapPin, TrendingUp } from "lucide-react";
import { Button } from "@/components/ui/button";
import Link from "next/link";
import Image from "next/image";

export default function HomePage() {
  const [selectedActivity, setSelectedActivity] = useState("all");

  const filteredTrips = useMemo(() => {
    if (selectedActivity === "all") return mockTrips;
    return mockTrips.filter((trip) =>
      trip.activities.includes(selectedActivity)
    );
  }, [selectedActivity]);

  return (
    <div className="min-h-screen bg-background">
      <Header />

      <main>
        {/* Hero Section */}
        <HeroSearch />

        {/* Activity Filter */}
        <section className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-2 sm:py-6">
          <ActivityFilter
            selected={selectedActivity}
            onSelect={setSelectedActivity}
          />
        </section>

        {/* Trips Grid */}
        <section className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 pb-12">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h2 className="text-2xl sm:text-3xl font-bold text-foreground">
                {selectedActivity === "all"
                  ? "Popular Trips"
                  : `${selectedActivity.charAt(0).toUpperCase() + selectedActivity.slice(1).replace("_", " ")} Trips`}
              </h2>
              <p className="text-muted-foreground mt-1">
                {filteredTrips.length} trips found
              </p>
            </div>
            <Link href="/explore">
              <Button variant="ghost" className="gap-2 hidden sm:flex">
                View all
                <ArrowRight className="h-4 w-4" />
              </Button>
            </Link>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {filteredTrips.map((trip, index) => (
              <TripCard
                key={trip.id}
                trip={trip}
                priority={index < 4}
              />
            ))}
          </div>

          {filteredTrips.length === 0 && (
            <div className="text-center py-12">
              <p className="text-muted-foreground text-lg">
                No trips found for this activity. Try another filter!
              </p>
            </div>
          )}

          {/* Mobile View All Button */}
          <div className="mt-8 flex justify-center sm:hidden">
            <Link href="/explore">
              <Button className="gap-2">
                View all trips
                <ArrowRight className="h-4 w-4" />
              </Button>
            </Link>
          </div>
        </section>

        {/* Featured Destinations */}
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
              {featuredDestinations.map((destination, index) => (
                <Link
                  key={destination.id}
                  href={`/destinations/${destination.id}`}
                  className="group relative aspect-[4/5] rounded-2xl overflow-hidden"
                >
                  <Image
                    src={destination.image}
                    alt={destination.name}
                    fill
                    className="object-cover transition-transform duration-500 group-hover:scale-110"
                    sizes="(max-width: 640px) 50vw, (max-width: 1024px) 50vw, 25vw"
                    priority={index < 2}
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-transparent" />
                  <div className="absolute bottom-0 left-0 right-0 p-4 sm:p-5">
                    <h3 className="text-lg sm:text-xl font-bold text-white">
                      {destination.name}
                    </h3>
                    <p className="text-white/80 text-sm flex items-center gap-1 mt-1">
                      <MapPin className="h-3.5 w-3.5" />
                      {destination.country}
                    </p>
                    <p className="text-white/60 text-xs mt-2">
                      {destination.tripCount} trips
                    </p>
                  </div>
                </Link>
              ))}
            </div>
          </div>
        </section>

      </main>

      <Footer />

      {/* Floating Elements */}
      <FloatingDock />
      <FloatingChat />
    </div>
  );
}
