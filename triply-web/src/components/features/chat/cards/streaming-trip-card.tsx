"use client";

import { useState, useEffect, useRef } from "react";
import { cn } from "@/lib/utils";
import { MapPin, Calendar, Euro, Loader2 } from "lucide-react";
import type { StreamingTripState } from "@/types/streaming";

// Hook for simulated progress when real progress is stuck
function useSimulatedProgress(realProgress: number, phase: string, isComplete: boolean) {
  const [simulatedProgress, setSimulatedProgress] = useState(realProgress);
  const lastRealProgressRef = useRef(realProgress);
  const lastUpdateTimeRef = useRef(Date.now());

  useEffect(() => {
    if (realProgress !== lastRealProgressRef.current) {
      lastRealProgressRef.current = realProgress;
      lastUpdateTimeRef.current = Date.now();
      setSimulatedProgress(realProgress);
      return;
    }

    if (isComplete) return;

    const interval = setInterval(() => {
      const timeSinceUpdate = Date.now() - lastUpdateTimeRef.current;
      if (timeSinceUpdate > 2000) {
        setSimulatedProgress(prev => {
          let maxProgress = realProgress + 0.15;
          if (phase === 'skeleton' || phase === 'generating_skeleton') {
            maxProgress = Math.min(maxProgress, 0.45);
          } else if (phase === 'days' || phase === 'places' || phase === 'assigning_places') {
            maxProgress = Math.min(maxProgress, 0.75);
          } else if (phase === 'images' || phase === 'loading_images') {
            maxProgress = Math.min(maxProgress, 0.95);
          }
          return Math.min(prev + 0.005, maxProgress);
        });
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [realProgress, phase, isComplete]);

  return simulatedProgress;
}

interface StreamingTripCardProps {
  state: StreamingTripState;
  onCancel?: () => void;
  className?: string;
}

/**
 * Live Streaming Trip Card - matches Flutter design
 * Text-based skeleton with typewriter effects
 * No image area - compact vertical layout
 */
export function StreamingTripCard({ state, onCancel, className }: StreamingTripCardProps) {
  // Animated text states
  const [animatedTitle, setAnimatedTitle] = useState("");
  const [animatedCity, setAnimatedCity] = useState("");
  const [animatedDuration, setAnimatedDuration] = useState("");
  const [animatedBudget, setAnimatedBudget] = useState("");

  // Track what we've already animated
  const animatedRef = useRef<Set<string>>(new Set());

  // Use simulated progress for smoother UX
  const displayProgress = useSimulatedProgress(state.progress, state.phase, state.isComplete);

  // Typewriter animation helper
  const animateText = (
    text: string,
    setter: (value: string) => void,
    key: string
  ) => {
    if (animatedRef.current.has(key) || !text) return;
    animatedRef.current.add(key);

    let index = 0;
    setter("");
    const interval = setInterval(() => {
      if (index <= text.length) {
        setter(text.substring(0, index));
        index++;
      } else {
        clearInterval(interval);
      }
    }, 25);

    return () => clearInterval(interval);
  };

  // Animate title when it arrives
  useEffect(() => {
    if (state.title) {
      animateText(state.title, setAnimatedTitle, "title");
    }
  }, [state.title]);

  // Animate city when it arrives
  useEffect(() => {
    if (state.city) {
      animateText(state.city, setAnimatedCity, "city");
    }
  }, [state.city]);

  // Animate duration when it arrives
  useEffect(() => {
    const durationText = state.durationDays
      ? `${state.durationDays} day${state.durationDays > 1 ? "s" : ""}`
      : "";
    if (durationText) {
      animateText(durationText, setAnimatedDuration, "duration");
    }
  }, [state.durationDays]);

  // Animate budget when it arrives
  useEffect(() => {
    const min = state.estimatedBudget?.min ?? state.prices?.min;
    const max = state.estimatedBudget?.max ?? state.prices?.max;
    if (min !== null && max !== null) {
      const budgetText = `€${min}-${max}`;
      animateText(budgetText, setAnimatedBudget, "budget");
    }
  }, [state.estimatedBudget, state.prices]);

  // Calculate days count
  const daysCount = state.durationDays || 0;
  const loadedDays = state.days.size;

  // Get places count per day
  const getPlacesCountForDay = (dayNum: number): number => {
    let count = 0;
    state.places.forEach((_, key) => {
      if (key.startsWith(`${dayNum}-`)) count++;
    });
    return count;
  };

  // Progress text based on phase for more accurate status
  const getProgressText = () => {
    const { phase } = state;
    if (phase === 'init' || phase === 'analyzing') return "Analyzing request...";
    if (phase === 'skeleton' || phase === 'generating_skeleton') return "Creating structure...";
    if (phase === 'days' || phase === 'places' || phase === 'assigning_places') return "Finding places...";
    if (phase === 'images' || phase === 'loading_images') return "Loading images...";
    if (phase === 'prices' || phase === 'finalizing') return "Finalizing...";
    if (phase === 'complete') return "Complete";
    // Fallback based on progress
    if (displayProgress < 0.15) return "Analyzing request...";
    if (displayProgress < 0.45) return "Creating structure...";
    if (displayProgress < 0.75) return "Finding places...";
    if (displayProgress < 0.95) return "Loading images...";
    return "Finalizing...";
  };

  return (
    <div className={cn("w-full max-w-[85%]", className)}>
      <div className="bg-white/10 rounded-[20px] overflow-hidden">
        <div className="p-4 space-y-3">
          {/* Title row with generating indicator */}
          <div className="flex items-center gap-3">
            {/* Purple glowing dot */}
            {!state.isComplete && (
              <div className="relative w-2.5 h-2.5 flex-shrink-0">
                <div className="absolute inset-0 bg-primary rounded-full" />
                <div className="absolute inset-0 bg-primary rounded-full animate-ping opacity-50" />
              </div>
            )}

            {/* Title */}
            <div className="flex-1 min-h-[24px]">
              {animatedTitle ? (
                <h3 className="font-semibold text-lg text-white leading-tight">
                  {animatedTitle}
                </h3>
              ) : (
                <Shimmer width={200} height={18} />
              )}
            </div>
          </div>

          {/* Divider */}
          <div className="h-px bg-white/10" />

          {/* Meta info - vertical stack like Flutter */}
          <div className="space-y-2">
            {/* Location */}
            <MetaItem
              icon={MapPin}
              text={animatedCity}
              placeholderWidth={100}
            />

            {/* Duration */}
            <MetaItem
              icon={Calendar}
              text={animatedDuration}
              placeholderWidth={70}
            />

            {/* Budget */}
            {(state.estimatedBudget?.max !== null || state.prices?.max) && (
              <MetaItem
                icon={Euro}
                text={animatedBudget}
                placeholderWidth={100}
              />
            )}
          </div>

          {/* Days progress - Itinerary section */}
          <div className="pt-2 space-y-3">
            {/* Header */}
            <div className="flex items-center justify-between">
              <span className="text-sm font-semibold text-white/60 tracking-wide">
                Itinerary
              </span>
              {daysCount > 0 && (
                <span className="text-[13px] font-medium text-white/50">
                  {loadedDays} / {daysCount} days
                </span>
              )}
            </div>

            {/* Day boxes */}
            {daysCount > 0 ? (
              <div className="flex gap-1.5">
                {Array.from({ length: daysCount }, (_, i) => i + 1).map((dayNum) => {
                  const isLoaded = state.days.has(dayNum);
                  const placesCount = getPlacesCountForDay(dayNum);
                  return (
                    <DayBox
                      key={dayNum}
                      dayNumber={dayNum}
                      isLoaded={isLoaded}
                      placesCount={placesCount}
                    />
                  );
                })}
              </div>
            ) : (
              // Shimmer placeholders for days
              <div className="flex gap-1.5">
                <Shimmer width={0} height={42} className="flex-1" />
                <Shimmer width={0} height={42} className="flex-1" />
                <Shimmer width={0} height={42} className="flex-1" />
              </div>
            )}
          </div>

          {/* Status row with spinner and percentage */}
          <div className="flex items-center justify-between pt-1">
            <div className="flex items-center gap-2.5">
              {!state.isComplete && (
                <Loader2 className="w-[18px] h-[18px] text-primary/70 animate-spin" />
              )}
              <span className="text-sm font-medium text-white/60">
                {getProgressText()}
              </span>
            </div>
            <span className="text-sm font-bold text-primary">
              {Math.round(displayProgress * 100)}%
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}

/**
 * Shimmer placeholder
 */
function Shimmer({ width, height, className }: { width: number; height: number; className?: string }) {
  return (
    <div
      className={cn("bg-white/[0.08] rounded", className)}
      style={{ width: width || undefined, height }}
    />
  );
}

/**
 * Meta info item with icon
 */
function MetaItem({
  icon: Icon,
  text,
  placeholderWidth,
}: {
  icon: typeof MapPin;
  text: string;
  placeholderWidth: number;
}) {
  return (
    <div className="flex items-center gap-2">
      <Icon
        className={cn(
          "w-4 h-4",
          text ? "text-primary" : "text-white/25"
        )}
      />
      {text ? (
        <span className="text-[15px] font-medium text-white/80">{text}</span>
      ) : (
        <Shimmer width={placeholderWidth} height={15} />
      )}
    </div>
  );
}

/**
 * Day progress box - matches Flutter _DayDot
 */
function DayBox({
  dayNumber,
  isLoaded,
  placesCount,
}: {
  dayNumber: number;
  isLoaded: boolean;
  placesCount: number;
}) {
  return (
    <div
      className={cn(
        "flex-1 h-[42px] rounded-[10px] flex flex-col items-center justify-center border transition-all duration-300",
        isLoaded
          ? "bg-primary/15 border-primary/40"
          : "bg-white/5 border-white/10"
      )}
    >
      <span
        className={cn(
          "text-xs font-semibold",
          isLoaded ? "text-primary" : "text-white/40"
        )}
      >
        Day {dayNumber}
      </span>
      {isLoaded && placesCount > 0 && (
        <span className="text-[10px] font-medium text-white/60">
          {placesCount} places
        </span>
      )}
    </div>
  );
}
