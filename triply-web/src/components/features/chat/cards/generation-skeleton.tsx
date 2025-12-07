"use client";

import { cn } from "@/lib/utils";
import { Sparkles } from "lucide-react";

interface GenerationSkeletonProps {
  type?: 'trip' | 'place' | 'unknown';
  className?: string;
}

const THEME = {
  cardBorderRadius: 20,
};

/**
 * Generation Skeleton
 * Animated skeleton displayed while AI is generating a response
 * Matches the Flutter app's shimmer/pulse animation style
 */
export function GenerationSkeleton({ type = 'unknown', className }: GenerationSkeletonProps) {
  return (
    <div className={cn("space-y-3", className)}>
      {/* AI indicator */}
      <div className="flex items-center gap-2">
        <div className="w-8 h-8 rounded-full bg-gradient-to-br from-primary to-accent flex items-center justify-center">
          <Sparkles className="h-4 w-4 text-white animate-pulse" />
        </div>
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium text-white/90">Toogo AI</span>
          <span className="text-xs text-white/50">is thinking...</span>
        </div>
      </div>

      {/* Card skeleton */}
      <div
        className="bg-white/5 border border-white/10 overflow-hidden"
        style={{ borderRadius: THEME.cardBorderRadius }}
      >
        {/* Image skeleton with shimmer effect */}
        <div className="relative h-[200px] bg-white/5 overflow-hidden">
          <div className="absolute inset-0 shimmer-effect" />

          {/* Placeholder icon */}
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="w-16 h-16 rounded-full bg-white/10 flex items-center justify-center animate-pulse">
              <Sparkles className="h-8 w-8 text-white/20" />
            </div>
          </div>

          {/* Activity badge skeleton */}
          <div className="absolute top-3 left-3">
            <div className="h-6 w-20 bg-white/10 rounded-full animate-pulse" />
          </div>

          {/* Save button skeleton */}
          <div className="absolute top-3 right-3">
            <div className="h-8 w-8 bg-white/10 rounded-full animate-pulse" />
          </div>

          {/* Image indicators skeleton */}
          <div className="absolute bottom-3 left-3 right-3 flex gap-1">
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className="flex-1 h-0.5 bg-white/10 rounded animate-pulse" />
            ))}
          </div>
        </div>

        {/* Content skeleton */}
        <div className="p-4 space-y-3">
          {/* Title skeleton */}
          <div className="space-y-2">
            <div className="h-5 w-3/4 bg-white/10 rounded animate-pulse" />
            <div className="h-5 w-1/2 bg-white/10 rounded animate-pulse" />
          </div>

          {/* Location skeleton */}
          <div className="flex items-center gap-2">
            <div className="h-4 w-4 bg-white/10 rounded animate-pulse" />
            <div className="h-4 w-32 bg-white/10 rounded animate-pulse" />
          </div>

          {/* Stats row skeleton */}
          <div className="flex items-center gap-3">
            <div className="h-4 w-12 bg-white/10 rounded animate-pulse" />
            <div className="h-4 w-16 bg-white/10 rounded animate-pulse" />
            <div className="h-4 w-20 bg-white/10 rounded animate-pulse" />
          </div>

          {/* Price + Button row skeleton */}
          <div className="flex items-center justify-between pt-2">
            <div className="h-6 w-16 bg-white/10 rounded animate-pulse" />
            <div className="h-8 w-28 bg-white/10 rounded-lg animate-pulse" />
          </div>

          {/* Highlights skeleton */}
          <div className="flex flex-wrap gap-1.5 pt-1">
            {[1, 2, 3].map((i) => (
              <div
                key={i}
                className="h-5 bg-white/10 rounded-full animate-pulse"
                style={{ width: `${60 + i * 20}px` }}
              />
            ))}
          </div>
        </div>
      </div>

      {/* Shimmer effect styles */}
      <style jsx>{`
        .shimmer-effect {
          background: linear-gradient(
            90deg,
            transparent 0%,
            rgba(255, 255, 255, 0.05) 50%,
            transparent 100%
          );
          animation: shimmer 1.5s infinite;
        }

        @keyframes shimmer {
          0% {
            transform: translateX(-100%);
          }
          100% {
            transform: translateX(100%);
          }
        }
      `}</style>
    </div>
  );
}

/**
 * Place Generation Skeleton
 * Compact skeleton for single place recommendations
 */
export function PlaceGenerationSkeleton({ className }: { className?: string }) {
  return (
    <div className={cn("space-y-3", className)}>
      {/* AI indicator */}
      <div className="flex items-center gap-2">
        <div className="w-8 h-8 rounded-full bg-gradient-to-br from-primary to-accent flex items-center justify-center">
          <Sparkles className="h-4 w-4 text-white animate-pulse" />
        </div>
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium text-white/90">Toogo AI</span>
          <span className="text-xs text-white/50">finding the perfect spot...</span>
        </div>
      </div>

      {/* Main place skeleton */}
      <div
        className="bg-white/5 border border-white/10 overflow-hidden"
        style={{ borderRadius: THEME.cardBorderRadius }}
      >
        <div className="relative h-[160px] bg-white/5 overflow-hidden">
          <div className="absolute inset-0 shimmer-effect" />
          <div className="absolute top-3 left-3">
            <div className="h-6 w-20 bg-white/10 rounded-full animate-pulse" />
          </div>
        </div>

        <div className="p-3 space-y-2">
          <div className="h-5 w-2/3 bg-white/10 rounded animate-pulse" />
          <div className="h-4 w-1/2 bg-white/10 rounded animate-pulse" />
          <div className="flex items-center gap-2">
            <div className="h-4 w-10 bg-white/10 rounded animate-pulse" />
            <div className="h-4 w-8 bg-white/10 rounded animate-pulse" />
          </div>
        </div>
      </div>

      {/* Alternatives skeleton */}
      <div className="space-y-2">
        <div className="h-3 w-24 bg-white/10 rounded animate-pulse" />
        <div className="grid grid-cols-2 gap-2">
          {[1, 2].map((i) => (
            <div
              key={i}
              className="bg-white/5 border border-white/10 overflow-hidden"
              style={{ borderRadius: 16 }}
            >
              <div className="h-[100px] bg-white/5 relative overflow-hidden">
                <div className="absolute inset-0 shimmer-effect" />
              </div>
              <div className="p-2.5 space-y-1.5">
                <div className="h-4 w-full bg-white/10 rounded animate-pulse" />
                <div className="h-3 w-2/3 bg-white/10 rounded animate-pulse" />
              </div>
            </div>
          ))}
        </div>
      </div>

      <style jsx>{`
        .shimmer-effect {
          background: linear-gradient(
            90deg,
            transparent 0%,
            rgba(255, 255, 255, 0.05) 50%,
            transparent 100%
          );
          animation: shimmer 1.5s infinite;
        }

        @keyframes shimmer {
          0% {
            transform: translateX(-100%);
          }
          100% {
            transform: translateX(100%);
          }
        }
      `}</style>
    </div>
  );
}

/**
 * Inline text skeleton for when AI is typing
 */
export function TypingSkeleton({ className }: { className?: string }) {
  return (
    <div className={cn("flex items-center gap-1", className)}>
      <div className="w-2 h-2 rounded-full bg-white/40 animate-bounce" style={{ animationDelay: '0ms' }} />
      <div className="w-2 h-2 rounded-full bg-white/40 animate-bounce" style={{ animationDelay: '150ms' }} />
      <div className="w-2 h-2 rounded-full bg-white/40 animate-bounce" style={{ animationDelay: '300ms' }} />
    </div>
  );
}
