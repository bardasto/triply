"use client";

import Link from "next/link";
import { Map, MapPin, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

interface TripsEmptyStateProps {
  type: "trips" | "places";
}

export function TripsEmptyState({ type }: TripsEmptyStateProps) {
  const isTrips = type === "trips";

  return (
    <div className="flex flex-col items-center justify-center py-16 px-4 text-center">
      {/* Icon */}
      <div className="relative mb-6">
        <div className="absolute inset-0 bg-primary/20 rounded-full blur-2xl scale-150" />
        <div className={cn(
          "relative h-20 w-20 rounded-2xl flex items-center justify-center",
          "bg-gradient-to-br from-primary to-accent"
        )}>
          {isTrips ? (
            <Map className="h-10 w-10 text-white" />
          ) : (
            <MapPin className="h-10 w-10 text-white" />
          )}
        </div>
      </div>

      {/* Text */}
      <h2 className="text-xl font-semibold text-foreground mb-2">
        {isTrips ? "No trips yet" : "No places saved"}
      </h2>
      <p className="text-muted-foreground max-w-sm mb-6">
        {isTrips
          ? "Start planning your next adventure! Chat with AI to create your perfect trip."
          : "Save your favorite places from trips to access them quickly here."
        }
      </p>

      {/* CTA */}
      {isTrips && (
        <Link href="/chat">
          <Button className="gap-2 rounded-xl">
            <Sparkles className="h-4 w-4" />
            Plan with AI
          </Button>
        </Link>
      )}
    </div>
  );
}
