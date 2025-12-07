/**
 * React Hooks for Trip Data Fetching
 * Uses SWR for efficient data fetching with caching and revalidation
 */

'use client';

import useSWR from 'swr';
import useSWRInfinite from 'swr/infinite';
import type { Trip, TripsByCity, City, TripFilters, TripSortOptions } from '@/types/trip';
import {
  getPublicTrips,
  getTripsByCity,
  getTripById,
  getTripsByActivityType,
  getFeaturedTrips,
  searchTrips,
  getCitiesWithTrips,
  incrementTripViews,
} from '@/services/trips.service';

// SWR configuration
const swrConfig = {
  revalidateOnFocus: false,
  revalidateIfStale: true,
  dedupingInterval: 60000, // 1 minute
};

/**
 * Hook for fetching trips grouped by city
 */
export function useTripsByCity(options?: { limit?: number; citiesLimit?: number }) {
  const { data, error, isLoading, mutate } = useSWR(
    ['trips-by-city', options?.limit, options?.citiesLimit],
    () => getTripsByCity(options),
    swrConfig
  );

  return {
    tripsByCity: data?.data || [],
    error: data?.error || error?.message,
    isLoading,
    mutate,
  };
}

/**
 * Hook for fetching public trips with filters and pagination
 */
export function usePublicTrips(options?: {
  filters?: TripFilters;
  sort?: TripSortOptions;
  limit?: number;
  offset?: number;
}) {
  const { data, error, isLoading, mutate } = useSWR(
    ['public-trips', JSON.stringify(options)],
    () => getPublicTrips(options),
    swrConfig
  );

  return {
    trips: data?.data || [],
    count: data?.count || 0,
    error: data?.error || error?.message,
    isLoading,
    mutate,
  };
}

/**
 * Hook for infinite scroll trips loading
 */
export function useInfiniteTrips(options?: {
  filters?: TripFilters;
  sort?: TripSortOptions;
  limit?: number;
}) {
  const limit = options?.limit || 20;

  const getKey = (pageIndex: number, previousPageData: { data: Trip[] } | null) => {
    if (previousPageData && previousPageData.data.length === 0) return null;
    return ['infinite-trips', JSON.stringify(options), pageIndex];
  };

  const { data, error, size, setSize, isLoading, isValidating, mutate } = useSWRInfinite(
    getKey,
    ([, , pageIndex]) =>
      getPublicTrips({
        ...options,
        offset: (pageIndex as number) * limit,
        limit,
      }),
    swrConfig
  );

  const trips = data ? data.flatMap((page) => page.data) : [];
  const totalCount = data?.[0]?.count || 0;
  const isLoadingMore = isLoading || (size > 0 && data && typeof data[size - 1] === 'undefined');
  const isEmpty = data?.[0]?.data.length === 0;
  const isReachingEnd = isEmpty || (data && data[data.length - 1]?.data.length < limit);

  return {
    trips,
    totalCount,
    error: error?.message,
    isLoading,
    isLoadingMore,
    isValidating,
    isEmpty,
    isReachingEnd,
    size,
    setSize,
    loadMore: () => setSize(size + 1),
    mutate,
  };
}

/**
 * Hook for fetching a single trip by ID
 */
export function useTrip(id: string | null) {
  const { data, error, isLoading, mutate } = useSWR(
    id ? ['trip', id] : null,
    () => (id ? getTripById(id) : Promise.resolve({ data: null })),
    {
      ...swrConfig,
      onSuccess: (data) => {
        // Increment view count when trip is loaded
        if (data?.data?.id) {
          incrementTripViews(data.data.id);
        }
      },
    }
  );

  return {
    trip: data?.data || null,
    error: data?.error || error?.message,
    isLoading,
    mutate,
  };
}

/**
 * Hook for fetching trips by activity type
 */
export function useTripsByActivityType(activityType: string | null, limit = 10) {
  const { data, error, isLoading, mutate } = useSWR(
    activityType ? ['trips-by-activity', activityType, limit] : null,
    () => (activityType ? getTripsByActivityType(activityType, limit) : Promise.resolve({ data: [] })),
    swrConfig
  );

  return {
    trips: data?.data || [],
    error: data?.error || error?.message,
    isLoading,
    mutate,
  };
}

/**
 * Hook for fetching featured trips
 */
export function useFeaturedTrips(limit = 8) {
  const { data, error, isLoading, mutate } = useSWR(
    ['featured-trips', limit],
    () => getFeaturedTrips(limit),
    swrConfig
  );

  return {
    trips: data?.data || [],
    error: data?.error || error?.message,
    isLoading,
    mutate,
  };
}

/**
 * Hook for searching trips
 */
export function useSearchTrips(query: string | null, limit = 20) {
  const { data, error, isLoading, mutate } = useSWR(
    query && query.length >= 2 ? ['search-trips', query, limit] : null,
    () => (query ? searchTrips(query, limit) : Promise.resolve({ data: [] })),
    {
      ...swrConfig,
      dedupingInterval: 500, // Faster deduping for search
    }
  );

  return {
    trips: data?.data || [],
    error: data?.error || error?.message,
    isLoading,
    mutate,
  };
}

/**
 * Hook for fetching cities with trip counts
 */
export function useCitiesWithTrips() {
  const { data, error, isLoading, mutate } = useSWR(
    'cities-with-trips',
    () => getCitiesWithTrips(),
    swrConfig
  );

  return {
    cities: data?.data || [],
    error: data?.error || error?.message,
    isLoading,
    mutate,
  };
}
