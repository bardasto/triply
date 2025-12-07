"use client";

export function TripDetailsSkeleton() {
  return (
    <div className="min-h-screen bg-background pb-32">
      {/* Header skeleton */}
      <div className="fixed top-0 left-0 right-0 z-50 bg-background/80 backdrop-blur-md border-b border-white/10">
        <div className="px-4 h-14 flex items-center">
          <div className="h-5 w-16 bg-white/5 rounded animate-pulse" />
        </div>
      </div>

      {/* Content */}
      <div className="pt-14">
        {/* Image skeleton */}
        <div className="pt-4">
          {/* Desktop: Airbnb-style grid */}
          <div className="hidden md:grid md:grid-cols-4 md:grid-rows-2 gap-2 h-[400px] max-w-4xl mx-auto px-4 sm:px-6">
            <div className="col-span-2 row-span-2 bg-white/5 rounded-xl animate-pulse" />
            <div className="bg-white/5 rounded-xl animate-pulse" />
            <div className="bg-white/5 rounded-xl animate-pulse" />
            <div className="bg-white/5 rounded-xl animate-pulse" />
            <div className="bg-white/5 rounded-xl animate-pulse" />
          </div>

          {/* Mobile: Single image */}
          <div className="md:hidden max-w-4xl mx-auto px-4 sm:px-6">
            <div className="w-full h-[280px] bg-white/5 rounded-xl animate-pulse" />
          </div>
        </div>

        <div className="max-w-4xl mx-auto px-4 sm:px-6 py-6 space-y-6">
          {/* Title skeleton */}
          <div className="space-y-3">
            <div className="h-8 w-3/4 bg-white/5 rounded animate-pulse" />
            <div className="h-5 w-1/2 bg-white/5 rounded animate-pulse" />
          </div>

          {/* Itinerary skeleton */}
          <div className="space-y-3">
            {[1, 2, 3].map((i) => (
              <div key={i} className="h-16 bg-white/5 rounded-2xl animate-pulse" />
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
