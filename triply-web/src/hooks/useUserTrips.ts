"use client";

import useSWR from "swr";
import useSWRInfinite from "swr/infinite";
import { useCallback, useMemo } from "react";
import { useAuth } from "@/contexts/auth-context";
import { getSupabaseBrowserClient } from "@/lib/supabase/client";
import type { UserTrip, UserTripFilters, UserTripCard } from "@/types/user-trip";
import { toUserTripCard } from "@/types/user-trip";

// Default page size for pagination
const DEFAULT_PAGE_SIZE = 8;

// Paginated response type
interface PaginatedTripsResponse {
  trips: UserTrip[];
  totalCount: number;
  hasMore: boolean;
}

// Fetcher for user trips (all at once - legacy)
async function fetchUserTrips(
  userId: string,
  filters?: UserTripFilters
): Promise<UserTrip[]> {
  const supabase = getSupabaseBrowserClient();
  let query = supabase
    .from("ai_generated_trips")
    .select("*")
    .eq("user_id", userId)
    .order("created_at", { ascending: false });

  if (filters?.city) {
    query = query.ilike("city", `%${filters.city}%`);
  }

  if (filters?.country) {
    query = query.ilike("country", `%${filters.country}%`);
  }

  if (filters?.activityType) {
    query = query.eq("activity_type", filters.activityType);
  }

  if (filters?.isFavorite !== undefined) {
    query = query.eq("is_favorite", filters.isFavorite);
  }

  if (filters?.search) {
    query = query.or(
      `title.ilike.%${filters.search}%,city.ilike.%${filters.search}%,country.ilike.%${filters.search}%`
    );
  }

  const { data, error } = await query;

  if (error) {
    throw new Error(error.message);
  }

  return data as UserTrip[];
}

// Fetcher for paginated user trips
async function fetchUserTripsPaginated(
  userId: string,
  page: number,
  pageSize: number,
  filters?: UserTripFilters
): Promise<PaginatedTripsResponse> {
  const supabase = getSupabaseBrowserClient();

  const from = page * pageSize;
  const to = from + pageSize - 1;

  // Build query for data
  let query = supabase
    .from("ai_generated_trips")
    .select("*", { count: "exact" })
    .eq("user_id", userId)
    .order("created_at", { ascending: false })
    .range(from, to);

  if (filters?.city) {
    query = query.ilike("city", `%${filters.city}%`);
  }

  if (filters?.country) {
    query = query.ilike("country", `%${filters.country}%`);
  }

  if (filters?.activityType) {
    query = query.eq("activity_type", filters.activityType);
  }

  if (filters?.isFavorite !== undefined) {
    query = query.eq("is_favorite", filters.isFavorite);
  }

  if (filters?.search) {
    query = query.or(
      `title.ilike.%${filters.search}%,city.ilike.%${filters.search}%,country.ilike.%${filters.search}%`
    );
  }

  const { data, error, count } = await query;

  if (error) {
    throw new Error(error.message);
  }

  const totalCount = count || 0;
  const trips = (data || []) as UserTrip[];
  const hasMore = from + trips.length < totalCount;

  return { trips, totalCount, hasMore };
}

// Fetcher for single trip
async function fetchUserTrip(userId: string, tripId: string): Promise<UserTrip | null> {
  const supabase = getSupabaseBrowserClient();
  const { data, error } = await supabase
    .from("ai_generated_trips")
    .select("*")
    .eq("id", tripId)
    .eq("user_id", userId)
    .single();

  if (error) {
    if (error.code === "PGRST116") {
      return null; // Not found
    }
    throw new Error(error.message);
  }

  return data as UserTrip;
}

/**
 * Hook to fetch all trips for the current user
 */
export function useUserTrips(filters?: UserTripFilters) {
  const { user } = useAuth();

  const { data, error, isLoading, mutate } = useSWR(
    user ? ["user-trips", user.id, filters] : null,
    () => fetchUserTrips(user!.id, filters),
    {
      revalidateOnFocus: false,
      revalidateIfStale: true,
      dedupingInterval: 30000,
    }
  );

  const trips = data || [];
  const tripCards: UserTripCard[] = trips.map(toUserTripCard);

  return {
    trips,
    tripCards,
    isLoading,
    error: error?.message || null,
    mutate,
  };
}

/**
 * Hook to fetch trips with server-side pagination (infinite scroll / load more)
 */
export function useUserTripsPaginated(
  filters?: UserTripFilters,
  pageSize: number = DEFAULT_PAGE_SIZE
) {
  const { user } = useAuth();

  // Key generator for SWR infinite
  const getKey = useCallback(
    (pageIndex: number, previousPageData: PaginatedTripsResponse | null) => {
      // No user - don't fetch
      if (!user) return null;

      // Reached the end
      if (previousPageData && !previousPageData.hasMore) return null;

      // Return the key for this page
      return ["user-trips-paginated", user.id, pageIndex, pageSize, filters];
    },
    [user, pageSize, filters]
  );

  const {
    data,
    error,
    isLoading,
    isValidating,
    size,
    setSize,
    mutate,
  } = useSWRInfinite<PaginatedTripsResponse>(
    getKey,
    ([, userId, pageIndex, pageSizeParam, filtersParam]) =>
      fetchUserTripsPaginated(
        userId as string,
        pageIndex as number,
        pageSizeParam as number,
        filtersParam as UserTripFilters | undefined
      ),
    {
      revalidateOnFocus: false,
      revalidateFirstPage: false,
      revalidateIfStale: true,
      dedupingInterval: 30000,
      parallel: false,
    }
  );

  // Flatten all pages into single arrays
  const allTrips = useMemo(() => {
    if (!data) return [];
    return data.flatMap((page) => page.trips);
  }, [data]);

  const tripCards = useMemo(() => {
    return allTrips.map(toUserTripCard);
  }, [allTrips]);

  // Get total count from first page
  const totalCount = data?.[0]?.totalCount ?? 0;

  // Check if there are more items to load
  const hasMore = data ? data[data.length - 1]?.hasMore ?? false : false;

  // Calculate remaining count
  const remainingCount = Math.max(0, totalCount - allTrips.length);

  // Is loading more pages (not initial load)
  const isLoadingMore = isValidating && size > 1;

  // Load next page
  const loadMore = useCallback(() => {
    if (!isValidating && hasMore) {
      setSize(size + 1);
    }
  }, [isValidating, hasMore, setSize, size]);

  // Reset to first page (useful when filters change)
  const reset = useCallback(() => {
    setSize(1);
  }, [setSize]);

  return {
    trips: allTrips,
    tripCards,
    totalCount,
    isLoading,
    isLoadingMore,
    hasMore,
    remainingCount,
    error: error?.message || null,
    loadMore,
    reset,
    mutate,
  };
}

/**
 * Hook to fetch a single trip by ID
 */
export function useUserTrip(tripId: string | null) {
  const { user } = useAuth();

  const { data, error, isLoading, mutate } = useSWR(
    user && tripId ? ["user-trip", user.id, tripId] : null,
    () => fetchUserTrip(user!.id, tripId!),
    {
      revalidateOnFocus: false,
    }
  );

  return {
    trip: data || null,
    isLoading,
    error: error?.message || null,
    mutate,
  };
}

/**
 * Hook to fetch favorite trips
 */
export function useFavoriteTrips() {
  return useUserTrips({ isFavorite: true });
}

/**
 * Hook for trip actions (toggle favorite, delete)
 */
export function useUserTripActions() {
  const { user } = useAuth();

  const toggleFavorite = useCallback(
    async (tripId: string, isFavorite: boolean) => {
      if (!user) {
        return { success: false, error: "Not authenticated" };
      }

      const supabase = getSupabaseBrowserClient();
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const { error } = await (supabase as any)
        .from("ai_generated_trips")
        .update({
          is_favorite: isFavorite,
          updated_at: new Date().toISOString()
        })
        .eq("id", tripId)
        .eq("user_id", user.id);

      if (error) {
        return { success: false, error: error.message };
      }

      return { success: true, error: null };
    },
    [user]
  );

  const deleteTrip = useCallback(
    async (tripId: string) => {
      if (!user) {
        return { success: false, error: "Not authenticated" };
      }

      const supabase = getSupabaseBrowserClient();
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const { error } = await (supabase as any)
        .from("ai_generated_trips")
        .delete()
        .eq("id", tripId)
        .eq("user_id", user.id);

      if (error) {
        return { success: false, error: error.message };
      }

      return { success: true, error: null };
    },
    [user]
  );

  return {
    toggleFavorite,
    deleteTrip,
  };
}

/**
 * Hook to get trips grouped by city
 */
export function useUserTripsByCity() {
  const { trips, isLoading, error, mutate } = useUserTrips();

  // Group trips by city
  const cities = trips.reduce(
    (acc, trip) => {
      const key = `${trip.city}-${trip.country}`;
      if (!acc[key]) {
        acc[key] = {
          city: trip.city,
          country: trip.country,
          trips: [],
        };
      }
      acc[key].trips.push(trip);
      return acc;
    },
    {} as Record<string, { city: string; country: string; trips: UserTrip[] }>
  );

  const citiesArray = Object.values(cities)
    .map((item) => ({
      ...item,
      count: item.trips.length,
    }))
    .sort((a, b) => b.count - a.count);

  return {
    cities: citiesArray,
    isLoading,
    error,
    mutate,
  };
}

/**
 * Hook for real-time trip updates
 */
export function useUserTripsRealtime() {
  const { user } = useAuth();
  const { mutate } = useUserTrips();

  const subscribe = useCallback(() => {
    if (!user) return () => {};

    const supabase = getSupabaseBrowserClient();
    const channel = supabase
      .channel(`user_trips_${user.id}`)
      .on(
        "postgres_changes",
        {
          event: "*",
          schema: "public",
          table: "ai_generated_trips",
          filter: `user_id=eq.${user.id}`,
        },
        () => {
          // Revalidate the trips data
          mutate();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user, mutate]);

  return { subscribe };
}
