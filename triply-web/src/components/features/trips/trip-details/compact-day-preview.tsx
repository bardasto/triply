"use client";

import Image from "next/image";
import { Building2 } from "lucide-react";
import { cn } from "@/lib/utils";
import type { TripItinerary, TripPlace } from "@/types/user-trip";
import type { TripDay, TripPlace as PublicTripPlace } from "@/types/trip";

interface CompactDayPreviewProps {
  day: TripItinerary | TripDay;
  isSelected: boolean;
  onClick: () => void;
}

export function CompactDayPreview({ day, isSelected, onClick }: CompactDayPreviewProps) {
  const places = day.places || [];
  const restaurants = day.restaurants || [];
  const allItems = [...places, ...restaurants];
  const previewItems = allItems.slice(0, 4);

  return (
    <button
      onClick={onClick}
      className={cn(
        "w-full text-left p-2 rounded-xl transition-all duration-300",
        isSelected
          ? "bg-primary/20 border border-primary/50"
          : "bg-white/5 border border-transparent hover:bg-white/10"
      )}
    >
      {/* Day label */}
      <div className={cn(
        "text-[10px] font-semibold mb-1.5 text-center",
        isSelected ? "text-primary" : "text-white/60"
      )}>
        Day {day.day}
      </div>

      {/* Photo grid 2x2 */}
      <div className="grid grid-cols-2 gap-1">
        {previewItems.map((item, idx) => {
          const imageUrl = (item as TripPlace).image_url ||
                          ((item as TripPlace).images?.[0] as { url?: string })?.url ||
                          (item as PublicTripPlace).imageUrl;
          return (
            <div
              key={idx}
              className="aspect-square rounded-md overflow-hidden bg-white/10"
            >
              {imageUrl ? (
                <Image
                  src={imageUrl}
                  alt={item.name}
                  width={40}
                  height={40}
                  className="w-full h-full object-cover"
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center">
                  <Building2 className="h-3 w-3 text-white/30" />
                </div>
              )}
            </div>
          );
        })}
        {/* Fill empty slots */}
        {previewItems.length < 4 && Array.from({ length: 4 - previewItems.length }).map((_, idx) => (
          <div key={`empty-${idx}`} className="aspect-square rounded-md bg-white/5" />
        ))}
      </div>

      {/* More indicator */}
      {allItems.length > 4 && (
        <div className="text-[9px] text-white/40 text-center mt-1">
          +{allItems.length - 4}
        </div>
      )}
    </button>
  );
}
