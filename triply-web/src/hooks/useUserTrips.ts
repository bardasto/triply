"use client";

import useSWR from "swr";
import { useCallback, useMemo } from "react";
import { useAuth } from "@/contexts/auth-context";
import { getSupabaseBrowserClient } from "@/lib/supabase/client";
import type { UserTrip, UserTripFilters, UserTripCard } from "@/types/user-trip";
import { toUserTripCard } from "@/types/user-trip";

// Fetcher for user trips
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
