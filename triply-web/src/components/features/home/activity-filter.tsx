"use client";

import { useRef, useState, useEffect } from "react";
import { ChevronLeft, ChevronRight } from "lucide-react";
import {
  Bike,
  Palmtree,
  Mountain,
  Waves,
  Tent,
  Building2,
  Sparkles,
  Car,
  Snowflake,
  TreeDeciduous,
  Sailboat,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

const activities = [
  { id: "all", label: "All", icon: Sparkles },
  { id: "cycling", label: "Cycling", icon: Bike },
  { id: "beach", label: "Beach", icon: Palmtree },
  { id: "skiing", label: "Skiing", icon: Snowflake },
  { id: "mountains", label: "Mountains", icon: Mountain },
  { id: "hiking", label: "Hiking", icon: TreeDeciduous },
  { id: "sailing", label: "Sailing", icon: Sailboat },
  { id: "desert", label: "Desert", icon: Waves },
  { id: "camping", label: "Camping", icon: Tent },
  { id: "city", label: "City", icon: Building2 },
  { id: "road_trip", label: "Road Trip", icon: Car },
];

interface ActivityFilterProps {
  selected: string;
  onSelect: (id: string) => void;
  showBackground?: boolean;
}

export function ActivityFilter({ selected, onSelect, showBackground = false }: ActivityFilterProps) {
  const scrollRef = useRef<HTMLDivElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const [showLeftArrow, setShowLeftArrow] = useState(false);
  const [showRightArrow, setShowRightArrow] = useState(true);
  const [indicatorStyle, setIndicatorStyle] = useState({ left: 0, width: 0 });

  // Update indicator position when selected changes
  useEffect(() => {
    const updateIndicator = () => {
      const container = containerRef.current;
      if (!container) return;

      const selectedButton = container.querySelector(`[data-id="${selected}"]`) as HTMLElement;
      if (selectedButton) {
        setIndicatorStyle({
          left: selectedButton.offsetLeft,
          width: selectedButton.offsetWidth,
        });
      }
    };

    updateIndicator();
    // Small delay to ensure DOM is ready
    const timeout = setTimeout(updateIndicator, 50);
    return () => clearTimeout(timeout);
  }, [selected]);

  const handleScroll = () => {
    if (!scrollRef.current) return;
    const { scrollLeft, scrollWidth, clientWidth } = scrollRef.current;
    setShowLeftArrow(scrollLeft > 0);
    setShowRightArrow(scrollLeft < scrollWidth - clientWidth - 10);
  };

  const scroll = (direction: "left" | "right") => {
    if (!scrollRef.current) return;
    const scrollAmount = 200;
    scrollRef.current.scrollBy({
      left: direction === "left" ? -scrollAmount : scrollAmount,
      behavior: "smooth",
    });
  };

  return (
    <div className="relative">
      {/* Left Arrow */}
      <div
        className={cn(
          "absolute left-0 top-0 bottom-0 z-10 flex items-center pr-4",
          "transition-opacity duration-200",
          showLeftArrow ? "opacity-100" : "opacity-0 pointer-events-none"
        )}
      >
        <Button
          variant="outline"
          size="icon"
          className="h-8 w-8 rounded-full shadow-md"
          onClick={() => scroll("left")}
        >
          <ChevronLeft className="h-4 w-4" />
        </Button>
      </div>

      {/* Scrollable Container */}
      <div
        ref={scrollRef}
        onScroll={handleScroll}
        className="overflow-x-auto scrollbar-hide py-2 px-1"
      >
        <div
          ref={containerRef}
          className="relative flex gap-0 sm:gap-6 w-max"
        >
          {/* Sliding Indicator - only show when showBackground is true */}
          {showBackground && (
            <div
              className="absolute top-1 bottom-1 rounded-xl bg-primary/10 transition-all duration-300 ease-out"
              style={{
                left: indicatorStyle.left,
                width: indicatorStyle.width,
              }}
            />
          )}

          {activities.map((activity) => {
            const Icon = activity.icon;
            const isSelected = selected === activity.id;

            return (
              <button
                key={activity.id}
                data-id={activity.id}
                onClick={() => onSelect(activity.id)}
                className={cn(
                  "group relative flex flex-col items-center gap-1.5 sm:gap-2 px-3 sm:px-5 py-2 sm:py-3 rounded-xl whitespace-nowrap",
                  "transition-all duration-200 min-w-[60px] sm:min-w-[80px]",
                  "z-10",
                  isSelected
                    ? "text-primary"
                    : "text-muted-foreground hover:text-foreground"
                )}
              >
                <div className={cn(
                  "flex items-center justify-center p-2 transition-all duration-300 ease-out",
                  "group-hover:scale-125",
                  isSelected && "scale-110"
                )}>
                  <Icon
                    className={cn(
                      "h-6 w-6 transition-colors duration-200",
                      isSelected ? "text-primary" : "text-muted-foreground group-hover:text-primary"
                    )}
                  />
                </div>
                <span className={cn(
                  "text-xs font-medium transition-colors duration-200",
                  isSelected ? "text-primary" : "text-muted-foreground group-hover:text-foreground"
                )}>
                  {activity.label}
                </span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Right Arrow */}
      <div
        className={cn(
          "absolute right-0 top-0 bottom-0 z-10 flex items-center pl-4",
          "transition-opacity duration-200",
          showRightArrow ? "opacity-100" : "opacity-0 pointer-events-none"
        )}
      >
        <Button
          variant="outline"
          size="icon"
          className="h-8 w-8 rounded-full shadow-md"
          onClick={() => scroll("right")}
        >
          <ChevronRight className="h-4 w-4" />
        </Button>
      </div>
    </div>
  );
}
