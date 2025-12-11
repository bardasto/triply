"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import { createPortal } from "react-dom";
import Image from "next/image";
import { MapPin, Clock, TrendingUp } from "lucide-react";
import { Input } from "@/components/ui/input";
import { LottieIcon } from "@/components/ui/lottie-icon";
import { cn } from "@/lib/utils";

interface Destination {
  id: string;
  name: string;
  country: string;
  image: string;
  trending?: boolean;
}

const popularDestinations: Destination[] = [
  { id: "1", name: "Paris", country: "France", image: "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=200&h=200&fit=crop", trending: true },
  { id: "2", name: "Tokyo", country: "Japan", image: "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=200&h=200&fit=crop", trending: true },
  { id: "3", name: "New York", country: "USA", image: "https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=200&h=200&fit=crop" },
  { id: "4", name: "Barcelona", country: "Spain", image: "https://images.unsplash.com/photo-1583422409516-2895a77efded?w=200&h=200&fit=crop", trending: true },
  { id: "5", name: "Bali", country: "Indonesia", image: "https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=200&h=200&fit=crop" },
  { id: "6", name: "Rome", country: "Italy", image: "https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=200&h=200&fit=crop" },
];

const recentSearches = ["London, UK", "Amsterdam, Netherlands"];

interface DestinationPickerProps {
  value: string;
  onChange: (value: string) => void;
  isOpen: boolean;
  onOpenChange: (open: boolean) => void;
  compact?: boolean;
}

export function DestinationPicker({ value, onChange, isOpen, onOpenChange, compact = false }: DestinationPickerProps) {
  const [searchQuery, setSearchQuery] = useState(value);
  const [mounted, setMounted] = useState(false);
  const [dropdownPosition, setDropdownPosition] = useState<{ top: number; left: number } | null>(null);
  const triggerRef = useRef<HTMLDivElement>(null);
  const dropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    setSearchQuery(value);
  }, [value]);

  // Update position on scroll and when open
  useEffect(() => {
    const updatePosition = () => {
      if (isOpen && triggerRef.current) {
        const rect = triggerRef.current.getBoundingClientRect();
        setDropdownPosition({
          top: rect.bottom + 8,
          left: rect.left,
        });
      }
    };

    if (isOpen) {
      updatePosition();
      window.addEventListener("scroll", updatePosition, { passive: true });
      window.addEventListener("resize", updatePosition, { passive: true });
      return () => {
        window.removeEventListener("scroll", updatePosition);
        window.removeEventListener("resize", updatePosition);
      };
    } else {
      setDropdownPosition(null);
    }
  }, [isOpen]);

  const handleClickOutside = useCallback((event: MouseEvent) => {
    const target = event.target as Element;

    // Check if click was on trigger
    if (triggerRef.current?.contains(target)) {
      return;
    }

    // Check if click was inside dropdown using data attribute
    if (target.closest('[data-dropdown-content="destination"]')) {
      return;
    }

    onOpenChange(false);
  }, [onOpenChange]);

  useEffect(() => {
    if (isOpen) {
      // Small delay to ensure Portal has rendered
      const timeoutId = setTimeout(() => {
        document.addEventListener("mousedown", handleClickOutside);
      }, 10);
      return () => {
        clearTimeout(timeoutId);
        document.removeEventListener("mousedown", handleClickOutside);
      };
    }
  }, [isOpen, handleClickOutside]);

  const filteredDestinations = searchQuery
    ? popularDestinations.filter(
        (d) =>
          d.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
          d.country.toLowerCase().includes(searchQuery.toLowerCase())
      )
    : popularDestinations;

  const handleSelect = (destination: string) => {
    onChange(destination);
    setSearchQuery(destination);
    onOpenChange(false);
  };

  const dropdown = isOpen && mounted && dropdownPosition ? createPortal(
    <div
      ref={dropdownRef}
      data-dropdown-content="destination"
      className="fixed w-[360px] bg-background rounded-3xl shadow-2xl border border-border overflow-hidden z-[9999]"
      style={{ top: dropdownPosition.top, left: dropdownPosition.left }}
      onMouseDown={(e) => e.stopPropagation()}
    >
      <div className="p-4 h-[340px] flex flex-col">
        {/* Recent Searches */}
        {recentSearches.length > 0 && !searchQuery && (
          <div className="mb-3 flex-shrink-0">
            <div className="flex items-center gap-2 text-xs font-medium text-muted-foreground mb-2 px-2">
              <Clock className="h-3.5 w-3.5" />
              Recent searches
            </div>
            <div className="space-y-1">
              {recentSearches.map((search, index) => (
                <button
                  key={index}
                  type="button"
                  onClick={() => handleSelect(search)}
                  className="w-full flex items-center gap-3 px-3 py-2 rounded-xl hover:bg-muted transition-colors text-left"
                >
                  <div className="h-8 w-8 rounded-lg bg-muted flex items-center justify-center">
                    <MapPin className="h-4 w-4 text-muted-foreground" />
                  </div>
                  <span className="text-sm text-foreground">{search}</span>
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Popular Destinations */}
        <div className="flex-1 overflow-hidden flex flex-col">
          <div className="flex items-center gap-2 text-xs font-medium text-muted-foreground mb-2 px-2 flex-shrink-0">
            <TrendingUp className="h-3.5 w-3.5" />
            {searchQuery ? "Search results" : "Popular destinations"}
          </div>
          <div className="flex-1 overflow-y-auto pr-1">
            <div className="grid grid-cols-3 gap-2">
              {filteredDestinations.map((destination) => (
                <button
                  key={destination.id}
                  type="button"
                  onClick={() => handleSelect(`${destination.name}, ${destination.country}`)}
                  className="group relative flex flex-col items-center p-2 rounded-xl hover:bg-muted transition-colors"
                >
                  <div className="relative h-14 w-14 rounded-xl overflow-hidden mb-1.5">
                    <Image
                      src={destination.image}
                      alt={destination.name}
                      fill
                      className="object-cover group-hover:scale-110 transition-transform duration-300"
                    />
                    {destination.trending && (
                      <div className="absolute top-0.5 right-0.5 h-3.5 w-3.5 rounded-full bg-primary flex items-center justify-center">
                        <TrendingUp className="h-2 w-2 text-white" />
                      </div>
                    )}
                  </div>
                  <span className="text-xs font-medium text-foreground">{destination.name}</span>
                  <span className="text-[10px] text-muted-foreground">{destination.country}</span>
                </button>
              ))}
            </div>

            {filteredDestinations.length === 0 && (
              <div className="text-center py-8 text-muted-foreground">
                <LottieIcon name="search" size={32} className="mx-auto mb-2 opacity-50" />
                <p className="text-sm">No destinations found</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>,
    document.body
  ) : null;

  return (
    <div className="relative">
      {/* Input trigger */}
      <div
        ref={triggerRef}
        className={cn(
          "flex items-center gap-2 cursor-pointer rounded-full transition-colors",
          compact ? "px-2 py-1" : "px-6 py-3",
          isOpen && "bg-muted/50"
        )}
        onClick={() => onOpenChange(!isOpen)}
      >
        <LottieIcon name="map" size={compact ? 16 : 20} playOnHover isActive={isOpen} />
        <div className="flex-1 min-w-0">
          <div className={cn("font-medium text-foreground", compact ? "text-[10px]" : "text-xs")}>Where</div>
          <Input
            type="text"
            placeholder="Search destinations"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            onClick={(e) => {
              e.stopPropagation();
              if (!isOpen) onOpenChange(true);
            }}
            className="border-0 p-0 h-auto text-sm focus-visible:ring-0 placeholder:text-muted-foreground bg-transparent dark:bg-transparent shadow-none rounded-none"
          />
        </div>
      </div>

      {dropdown}
    </div>
  );
}
