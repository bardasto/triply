"use client";

import { useState } from "react";
import Image from "next/image";
import { Heart, Trash2, MapPin, Clock, Star, ChevronLeft, ChevronRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export interface Trip {
  id: string;
  title: string;
  city: string;
  country: string;
  price: number;
  currency: string;
  duration_days: number;
  rating: number;
  is_favorite: boolean;
  images: string[];
  activity_type?: string;
}

interface MyTripCardProps {
  trip: Trip;
  onFavoriteToggle?: (id: string) => void;
  onDelete?: (id: string) => void;
  onClick?: (trip: Trip) => void;
}

export function MyTripCard({ trip, onFavoriteToggle, onDelete, onClick }: MyTripCardProps) {
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [isHovered, setIsHovered] = useState(false);

  const images = trip.images.length > 0 ? trip.images.slice(0, 4) : ["/placeholder-trip.jpg"];

  const nextImage = (e: React.MouseEvent) => {
    e.stopPropagation();
    setCurrentImageIndex((prev) => (prev + 1) % images.length);
  };

  const prevImage = (e: React.MouseEvent) => {
    e.stopPropagation();
    setCurrentImageIndex((prev) => (prev - 1 + images.length) % images.length);
  };

  const formatPrice = (price: number, currency: string) => {
    const symbol = currency === "EUR" ? "€" : "$";
    return `${symbol}${price.toLocaleString()}`;
  };

  return (
    <article
      className={cn(
        "group relative rounded-2xl overflow-hidden bg-card",
        "transition-all duration-300",
        "hover:shadow-xl hover:shadow-primary/5 hover:-translate-y-1",
        "cursor-pointer"
      )}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      onClick={() => onClick?.(trip)}
    >
      {/* Image Carousel */}
      <div className="relative aspect-[4/3] overflow-hidden">
        <Image
          src={images[currentImageIndex]}
          alt={trip.title}
          fill
          className="object-cover transition-transform duration-500 group-hover:scale-105"
        />

        {/* Gradient overlay */}
        <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />

        {/* Navigation arrows */}
        {images.length > 1 && isHovered && (
          <>
            <Button
              variant="ghost"
              size="icon"
              className="absolute left-2 top-1/2 -translate-y-1/2 h-8 w-8 rounded-full bg-black/50 text-white hover:bg-black/70"
              onClick={prevImage}
            >
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <Button
              variant="ghost"
              size="icon"
              className="absolute right-2 top-1/2 -translate-y-1/2 h-8 w-8 rounded-full bg-black/50 text-white hover:bg-black/70"
              onClick={nextImage}
            >
              <ChevronRight className="h-4 w-4" />
            </Button>
          </>
        )}

        {/* Image indicators */}
        {images.length > 1 && (
          <div className="absolute bottom-3 left-1/2 -translate-x-1/2 flex gap-1.5">
            {images.map((_, index) => (
              <div
                key={index}
                className={cn(
                  "h-1 rounded-full transition-all duration-300",
                  index === currentImageIndex
                    ? "w-4 bg-white"
                    : "w-1 bg-white/50"
                )}
              />
            ))}
          </div>
        )}

        {/* Delete button */}
        <Button
          variant="ghost"
          size="icon"
          className={cn(
            "absolute top-3 left-3 h-9 w-9 rounded-full",
            "bg-black/50 text-white hover:bg-red-500 hover:text-white",
            "opacity-0 group-hover:opacity-100 transition-opacity"
          )}
          onClick={(e) => {
            e.stopPropagation();
            onDelete?.(trip.id);
          }}
        >
          <Trash2 className="h-4 w-4" />
        </Button>

        {/* Favorite button */}
        <Button
          variant="ghost"
          size="icon"
          className={cn(
            "absolute top-3 right-3 h-9 w-9 rounded-full",
            "bg-black/50 hover:bg-black/70",
            trip.is_favorite ? "text-red-500" : "text-white"
          )}
          onClick={(e) => {
            e.stopPropagation();
            onFavoriteToggle?.(trip.id);
          }}
        >
          <Heart className={cn("h-4 w-4", trip.is_favorite && "fill-current")} />
        </Button>

        {/* Activity type badge */}
        {trip.activity_type && (
          <div className="absolute top-3 left-3">
            <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-white/90 text-foreground backdrop-blur-sm">
              {trip.activity_type}
            </span>
          </div>
        )}

        {/* Rating badge */}
        {trip.rating > 0 && (
          <div className="absolute bottom-3 left-3 flex items-center gap-1 px-2 py-1 rounded-full bg-black/40 backdrop-blur-sm">
            <Star className="h-3.5 w-3.5 text-yellow-400 fill-yellow-400" />
            <span className="text-sm font-medium text-white">{trip.rating.toFixed(1)}</span>
          </div>
        )}
      </div>

      {/* Info section */}
      <div className="p-4">
        <h3 className="font-semibold text-foreground line-clamp-2 group-hover:text-primary transition-colors">
          {trip.title}
        </h3>

        {/* Location */}
        <div className="flex items-center gap-1 text-muted-foreground mb-1.5 mt-2">
          <MapPin className="h-3.5 w-3.5" />
          <span className="text-xs truncate">{trip.city}, {trip.country}</span>
        </div>

        {/* Meta */}
        <div className="mt-3 flex items-center justify-between">
          <div className="flex items-center gap-1 text-muted-foreground">
            <Clock className="h-3.5 w-3.5" />
            <span className="text-sm">{trip.duration_days} days</span>
          </div>
          <div className="text-right">
            <span className="text-lg font-bold text-foreground">
              {formatPrice(trip.price, trip.currency)}
            </span>
          </div>
        </div>
      </div>
    </article>
  );
}

// Compact version for grid view
export function CompactTripCard({ trip, onFavoriteToggle, onClick }: MyTripCardProps) {
  const image = trip.images[0] || "/placeholder-trip.jpg";

  const formatPrice = (price: number, currency: string) => {
    const symbol = currency === "EUR" ? "€" : "$";
    return `${symbol}${price.toLocaleString()}`;
  };

  return (
    <div
      className={cn(
        "group relative rounded-2xl overflow-hidden bg-card border border-border",
        "transition-all duration-300",
        "hover:border-primary/30 hover:shadow-lg hover:shadow-primary/5",
        "cursor-pointer"
      )}
      onClick={() => onClick?.(trip)}
    >
      {/* Image */}
      <div className="relative aspect-square overflow-hidden">
        <Image
          src={image}
          alt={trip.title}
          fill
          className="object-cover transition-transform duration-500 group-hover:scale-105"
        />

        {/* Gradient overlay */}
        <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />

        {/* Favorite button */}
        <Button
          variant="ghost"
          size="icon"
          className={cn(
            "absolute top-2 right-2 h-8 w-8 rounded-full",
            "bg-black/50 hover:bg-black/70",
            trip.is_favorite ? "text-red-500" : "text-white"
          )}
          onClick={(e) => {
            e.stopPropagation();
            onFavoriteToggle?.(trip.id);
          }}
        >
          <Heart className={cn("h-4 w-4", trip.is_favorite && "fill-current")} />
        </Button>

        {/* Price badge */}
        <div className="absolute bottom-2 right-2 px-2 py-1 rounded-lg bg-black/70 text-white text-xs font-medium">
          {formatPrice(trip.price, trip.currency)}
        </div>
      </div>

      {/* Info section */}
      <div className="p-3 space-y-1">
        <h3 className="font-medium text-foreground text-sm line-clamp-1">
          {trip.title}
        </h3>

        <div className="flex items-center justify-between text-xs text-muted-foreground">
          <span className="line-clamp-1">{trip.city}</span>
          <div className="flex items-center gap-2">
            <span>{trip.duration_days}d</span>
            {trip.rating > 0 && (
              <div className="flex items-center gap-0.5">
                <Star className="h-3 w-3 text-amber-500 fill-amber-500" />
                <span>{trip.rating.toFixed(1)}</span>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

// Skeleton for loading state
export function MyTripCardSkeleton() {
  return (
    <div className="rounded-3xl overflow-hidden bg-card border border-border">
      <div className="aspect-[4/3] bg-muted animate-pulse" />
      <div className="p-4 space-y-3">
        <div className="h-5 w-3/4 bg-muted rounded animate-pulse" />
        <div className="h-4 w-1/2 bg-muted rounded animate-pulse" />
        <div className="flex items-center justify-between pt-2">
          <div className="h-4 w-20 bg-muted rounded animate-pulse" />
          <div className="h-5 w-16 bg-muted rounded animate-pulse" />
        </div>
      </div>
    </div>
  );
}
