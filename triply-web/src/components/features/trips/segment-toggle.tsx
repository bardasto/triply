"use client";

import { cn } from "@/lib/utils";

interface SegmentToggleProps {
  segments: { label: string; count?: number }[];
  activeIndex: number;
  onChange: (index: number) => void;
}

export function SegmentToggle({ segments, activeIndex, onChange }: SegmentToggleProps) {
  return (
    <div className="relative flex p-1 bg-primary/10 rounded-full border border-primary/20">
      {/* Animated background indicator */}
      <div
        className={cn(
          "absolute top-1 bottom-1 rounded-full bg-primary shadow-sm",
          "transition-all duration-300 ease-out"
        )}
        style={{
          width: `calc(${100 / segments.length}% - 4px)`,
          left: `calc(${(activeIndex * 100) / segments.length}% + 2px)`,
        }}
      />

      {/* Segment buttons */}
      {segments.map((segment, index) => (
        <button
          key={segment.label}
          onClick={() => onChange(index)}
          className={cn(
            "relative flex-1 px-4 py-2 text-sm font-medium rounded-full",
            "transition-colors duration-200",
            "flex items-center justify-center gap-2",
            index === activeIndex
              ? "text-white"
              : "text-primary hover:text-primary/80"
          )}
        >
          <span>{segment.label}</span>
          {segment.count !== undefined && (
            <span
              className={cn(
                "text-xs px-1.5 py-0.5 rounded-full",
                index === activeIndex
                  ? "bg-white/20 text-white"
                  : "bg-primary/10 text-primary"
              )}
            >
              {segment.count}
            </span>
          )}
        </button>
      ))}
    </div>
  );
}
