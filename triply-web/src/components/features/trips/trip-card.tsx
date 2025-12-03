"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { Heart, Star, Clock, MapPin } from "lucide-react";
import { cn } from "@/lib/utils";
import type { Trip } from "@/types";

interface TripCardProps {
  trip: Trip;
  className?: string;
  priority?: boolean;
}

export function TripCard({ trip, className, priority = false }: TripCardProps) {
  const [isLiked, setIsLiked] = useState(false);
  const [imageLoaded, setImageLoaded] = useState(false);

  return (
    <article
      className={cn(
        "group relative bg-card rounded-2xl overflow-hidden transition-all duration-300",
        "hover:shadow-xl hover:shadow-primary/5 hover:-translate-y-1",
        className
      )}
    >
      <Link href={`/trips/${trip.id}`} className="block">
        {/* Image Container */}
        <div className="relative aspect-[4/3] overflow-hidden bg-muted">
          <Image
            src={trip.coverImage}
            alt={trip.title}
            fill
            priority={priority}
            className={cn(
              "object-cover transition-all duration-500",
              "group-hover:scale-105",
              imageLoaded ? "opacity-100" : "opacity-0"
            )}
            sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
            onLoad={() => setImageLoaded(true)}
          />

          {/* Skeleton while loading */}
          {!imageLoaded && (
            <div className="absolute inset-0 bg-muted animate-pulse" />
          )}

          {/* Gradient overlay */}
          <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-black/0 to-black/0" />

          {/* Category Badge */}
          <div className="absolute top-3 left-3">
            <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-white/90 text-foreground backdrop-blur-sm">
              {trip.category}
            </span>
          </div>

          {/* Rating */}
          <div className="absolute bottom-3 left-3 flex items-center gap-1.5">
            <div className="flex items-center gap-1 px-2 py-1 rounded-full bg-black/40 backdrop-blur-sm">
              <Star className="h-3.5 w-3.5 text-yellow-400 fill-yellow-400" />
              <span className="text-sm font-medium text-white">{trip.rating}</span>
            </div>
          </div>
        </div>

        {/* Content */}
        <div className="p-4">
          {/* Location */}
          <div className="flex items-center gap-1 text-muted-foreground mb-1.5">
            <MapPin className="h-3.5 w-3.5" />
            <span className="text-xs truncate">{trip.destination}, {trip.country}</span>
          </div>

          {/* Title */}
          <h3 className="font-semibold text-foreground line-clamp-2 group-hover:text-primary transition-colors">
            {trip.title}
          </h3>

          {/* Meta */}
          <div className="mt-3 flex items-center justify-between">
            <div className="flex items-center gap-1 text-muted-foreground">
              <Clock className="h-3.5 w-3.5" />
              <span className="text-sm">{trip.duration}</span>
            </div>

            <div className="text-right">
              <span className="text-lg font-bold text-foreground">{trip.price}</span>
            </div>
          </div>
        </div>
      </Link>

      {/* Like Button - positioned outside Link to prevent navigation */}
      <button
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          setIsLiked(!isLiked);
        }}
        className={cn(
          "absolute top-3 right-3 p-2 rounded-full transition-all duration-200",
          "bg-white/90 backdrop-blur-sm hover:bg-white hover:scale-110",
          isLiked && "bg-red-50"
        )}
        aria-label={isLiked ? "Remove from favorites" : "Add to favorites"}
      >
        <Heart
          className={cn(
            "h-5 w-5 transition-colors",
            isLiked ? "fill-red-500 text-red-500" : "text-gray-600"
          )}
        />
      </button>
    </article>
  );
}

// Skeleton component for loading state
export function TripCardSkeleton() {
  return (
    <div className="bg-card rounded-2xl overflow-hidden">
      <div className="aspect-[4/3] bg-muted animate-pulse" />
      <div className="p-4 space-y-3">
        <div className="h-3 w-24 bg-muted rounded animate-pulse" />
        <div className="h-5 w-full bg-muted rounded animate-pulse" />
        <div className="h-5 w-3/4 bg-muted rounded animate-pulse" />
        <div className="flex items-center justify-between pt-2">
          <div className="h-4 w-16 bg-muted rounded animate-pulse" />
          <div className="h-6 w-16 bg-muted rounded animate-pulse" />
        </div>
      </div>
    </div>
  );
}
