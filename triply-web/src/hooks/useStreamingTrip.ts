"use client";

import { useState, useCallback, useRef } from "react";
import type {
  StreamingTripState,
  TripStreamEvent,
  SkeletonEventData,
  DayEventData,
  PlaceEventData,
  RestaurantEventData,
  ImageEventData,
  PricesEventData,
  PriceUpdateEventData,
  CompleteEventData,
} from "@/types/streaming";
import { createInitialStreamingState, streamingStateToTripData } from "@/types/streaming";
import type { ConversationMessage } from "@/types/ai-response";

const API_BASE_URL = process.env.NEXT_PUBLIC_AI_API_URL || "http://localhost:3000";

interface UseStreamingTripOptions {
  onComplete?: (tripData: unknown, message: string) => void;
  onError?: (error: string) => void;
}

export function useStreamingTrip(options: UseStreamingTripOptions = {}) {
  const [state, setState] = useState<StreamingTripState>(createInitialStreamingState());
  const [isStreaming, setIsStreaming] = useState(false);
  const abortControllerRef = useRef<AbortController | null>(null);
  const stateRef = useRef<StreamingTripState>(state);

  /**
   * Update state immutably with partial updates
   * Also updates stateRef synchronously for use in callbacks
   */
  const updateState = useCallback((updates: Partial<StreamingTripState> | ((prev: StreamingTripState) => Partial<StreamingTripState>)) => {
    setState((prev) => {
      const newUpdates = typeof updates === "function" ? updates(prev) : updates;
      const newState = { ...prev, ...newUpdates };
      // Update ref synchronously inside setState to keep it current
      stateRef.current = newState;
      return newState;
    });
  }, []);

  /**
   * Process incoming SSE event
   */
  const processEvent = useCallback(
    (event: TripStreamEvent) => {
      switch (event.type) {
        case "init":
          updateState({
            isConnected: true,
            progress: event.progress || 0.05,
            phase: event.phase || "init",
          });
          break;

        case "skeleton": {
          const data = event.data as SkeletonEventData;
          updateState({
            progress: event.progress || 0.15,
            phase: event.phase || "skeleton",
            title: data.title || null,
            description: data.description || null,
            city: data.city || null,
            country: data.country || null,
            duration: data.duration || null,
            durationDays: data.durationDays || null,
            theme: data.theme || null,
            thematicKeywords: data.thematicKeywords || [],
            vibe: data.vibe || [],
            estimatedBudget: {
              min: data.estimatedBudget?.min || null,
              max: data.estimatedBudget?.max || null,
              currency: data.estimatedBudget?.currency || "EUR",
            },
          });
          break;
        }

        case "day": {
          const data = event.data as DayEventData;
          // Backend sends 'day' but our type expects 'dayNumber' - handle both
          const dayNumber = data.dayNumber || (data as unknown as { day: number }).day;
          console.log("[Streaming] Day event:", data, "dayNumber:", dayNumber);
          updateState((prev) => {
            const newDays = new Map(prev.days);
            newDays.set(dayNumber, {
              title: data.title || `Day ${dayNumber}`,
              description: data.description || "",
              slotsCount: data.slotsCount || 0,
              restaurantsCount: data.restaurantsCount || 0,
            });
            console.log("[Streaming] Days map size:", newDays.size);
            return {
              days: newDays,
              progress: event.progress || Math.min(0.25 + newDays.size * 0.05, 0.5),
              phase: event.phase || "days",
            };
          });
          break;
        }

        case "place": {
          const data = event.data as PlaceEventData;
          // Backend sends 'day' and 'index' but our type expects 'dayNumber' and 'slotIndex' - handle both
          const dayNumber = data.dayNumber || (data as unknown as { day: number }).day;
          const slotIndex = data.slotIndex ?? (data as unknown as { index: number }).index;
          const key = `${dayNumber}-${slotIndex}`;
          console.log("[Streaming] Place event:", key, data.place?.name);
          updateState((prev) => {
            const newPlaces = new Map(prev.places);
            newPlaces.set(key, data.place);
            console.log("[Streaming] Places map size:", newPlaces.size);
            return {
              places: newPlaces,
              progress: event.progress || Math.min(0.5 + newPlaces.size * 0.02, 0.75),
              phase: event.phase || "places",
            };
          });
          break;
        }

        case "restaurant": {
          const data = event.data as RestaurantEventData;
          const dayNumber = data.dayNumber || (data as unknown as { day: number }).day;
          const slotIndex = data.slotIndex ?? (data as unknown as { index: number }).index;
          const key = `${dayNumber}-${slotIndex}`;
          console.log("[Streaming] Restaurant event:", key, data.restaurant?.name);
          updateState((prev) => {
            const newRestaurants = new Map(prev.restaurants);
            newRestaurants.set(key, data.restaurant);
            console.log("[Streaming] Restaurants map size:", newRestaurants.size);
            return {
              restaurants: newRestaurants,
              progress: event.progress || Math.min(0.75 + newRestaurants.size * 0.02, 0.9),
              phase: event.phase || "restaurants",
            };
          });
          break;
        }

        case "image": {
          const data = event.data as ImageEventData;
          if (data.type === "hero") {
            updateState({
              heroImageUrl: data.url,
              progress: event.progress || 0.8,
              phase: event.phase || "images",
            });
          } else if (data.placeId) {
            updateState((prev) => {
              const newPlaceImages = new Map(prev.placeImages);
              const existing = newPlaceImages.get(data.placeId!) || [];
              newPlaceImages.set(data.placeId!, [...existing, data.url]);
              return {
                placeImages: newPlaceImages,
                progress: event.progress || 0.85,
                phase: event.phase || "images",
              };
            });
          }
          break;
        }

        case "prices": {
          const data = event.data as PricesEventData;
          updateState({
            prices: data,
            progress: event.progress || 0.95,
            phase: event.phase || "prices",
          });
          break;
        }

        case "price_update": {
          const data = event.data as PriceUpdateEventData;
          const key = `${data.dayNumber}-${data.slotIndex}`;
          console.log("[Streaming] Price update:", key, data.price);
          updateState((prev) => {
            const newPlaces = new Map(prev.places);
            const place = newPlaces.get(key);
            if (place) {
              // Update the place with the new price
              newPlaces.set(key, {
                ...place,
                price: data.price,
              });
              console.log("[Streaming] Updated place price:", place.name, data.price);
            }
            return {
              places: newPlaces,
              phase: "price_update",
            };
          });
          break;
        }

        case "prices_complete": {
          console.log("[Streaming] Prices complete");
          updateState({
            phase: "prices_complete",
          });
          break;
        }

        case "complete": {
          const data = event.data as CompleteEventData;
          console.log("[Streaming] Complete event received:", data);
          console.log("[Streaming] Current stateRef.current.days.size:", stateRef.current.days.size);
          console.log("[Streaming] Current stateRef.current.places.size:", stateRef.current.places.size);
          console.log("[Streaming] Current stateRef.current.durationDays:", stateRef.current.durationDays);

          // Build trip data from accumulated streaming state
          // Use setTimeout to ensure state is fully updated before building
          setTimeout(() => {
            console.log("[Streaming] After timeout - stateRef.current.days.size:", stateRef.current.days.size);
            console.log("[Streaming] After timeout - stateRef.current.places.size:", stateRef.current.places.size);

            const tripData = streamingStateToTripData(stateRef.current);
            console.log("[Streaming] Built tripData:", tripData);
            console.log("[Streaming] tripData.itinerary length:", (tripData as Record<string, unknown>).itinerary ? ((tripData as Record<string, unknown>).itinerary as unknown[]).length : 0);

            updateState({
              isComplete: true,
              progress: 1,
              phase: "complete",
              tripId: data.tripId,
              finalTripData: tripData,
            });
            setIsStreaming(false);
            // Call onComplete to update the message state in chat page
            console.log("[Streaming] Calling onComplete");
            options.onComplete?.(tripData, data.message || "Trip generated successfully!");
          }, 100);
          break;
        }

        case "error": {
          const errorMsg = event.error || event.message || "Unknown error";
          updateState({
            error: errorMsg,
            isComplete: true,
          });
          setIsStreaming(false);
          options.onError?.(errorMsg);
          break;
        }
      }
    },
    [updateState, options]
  );

  /**
   * Parse SSE message
   */
  const parseSSEMessage = useCallback((message: string): TripStreamEvent | null => {
    let eventType: string | null = null;
    let data: string | null = null;

    for (const line of message.split("\n")) {
      if (line.startsWith("event:")) {
        eventType = line.substring(6).trim();
      } else if (line.startsWith("data:")) {
        data = line.substring(5).trim();
      }
    }

    if (!data) return null;

    try {
      const json = JSON.parse(data);
      return {
        type: (eventType || json.type || "unknown") as TripStreamEvent["type"],
        ...json,
      };
    } catch {
      console.error("[SSE] Failed to parse message:", data);
      return null;
    }
  }, []);

  /**
   * Start streaming trip generation
   */
  const startStreaming = useCallback(
    async (query: string, conversationContext?: ConversationMessage[]) => {
      // Reset state
      setState(createInitialStreamingState());
      setIsStreaming(true);

      // Create abort controller
      abortControllerRef.current = new AbortController();

      try {
        // Step 1: Start generation and get stream URL
        const startResponse = await fetch(`${API_BASE_URL}/api/trips/generate/stream`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            query,
            conversationContext,
          }),
          signal: abortControllerRef.current.signal,
        });

        if (!startResponse.ok) {
          const errorData = await startResponse.json().catch(() => ({}));
          throw new Error(errorData.error?.message || `HTTP error ${startResponse.status}`);
        }

        const startData = await startResponse.json();
        const tripId = startData.data?.tripId;
        const streamUrl = startData.data?.streamUrl;

        if (!tripId || !streamUrl) {
          throw new Error("Invalid response: missing tripId or streamUrl");
        }

        updateState({ tripId });

        // Step 2: Connect to SSE stream
        const eventSource = new EventSource(`${API_BASE_URL}${streamUrl}`);

        eventSource.onopen = () => {
          updateState({ isConnected: true });
        };

        eventSource.onmessage = (event) => {
          const parsed = parseSSEMessage(`data:${event.data}`);
          if (parsed) {
            processEvent(parsed);
          }
        };

        // Track if we've completed successfully to avoid error handler overwriting state
        let hasCompleted = false;

        // Handle named events
        const eventTypes = ["init", "skeleton", "day", "place", "restaurant", "image", "prices", "price_update", "prices_complete", "complete", "error"];
        eventTypes.forEach((type) => {
          eventSource.addEventListener(type, (event: MessageEvent) => {
            console.log(`[SSE] Received event: ${type}`, event.data);
            // Skip if no data
            if (!event.data || event.data === "undefined") {
              console.log(`[SSE] Skipping event with no data: ${type}`);
              return;
            }
            try {
              const parsed: TripStreamEvent = {
                type: type as TripStreamEvent["type"],
                ...JSON.parse(event.data),
              };
              processEvent(parsed);
            } catch (e) {
              console.error(`[SSE] Failed to parse event ${type}:`, e, event.data);
            }

            // Close on complete or error
            if (type === "complete") {
              hasCompleted = true;
              // Delay closing to ensure processEvent completes
              setTimeout(() => {
                eventSource.close();
              }, 200);
            } else if (type === "error") {
              eventSource.close();
            }
          });
        });

        eventSource.onerror = (error) => {
          // Don't treat as error if we've already completed successfully
          if (hasCompleted) {
            console.log("[SSE] Connection closed after completion (expected)");
            return;
          }
          console.error("[SSE] Connection error:", error);
          eventSource.close();
          updateState({
            error: "Connection lost. Please try again.",
            isComplete: true,
          });
          setIsStreaming(false);
          options.onError?.("Connection lost. Please try again.");
        };

        // Store eventSource for cleanup
        const cleanup = () => {
          eventSource.close();
        };

        // Handle abort
        abortControllerRef.current.signal.addEventListener("abort", cleanup);

        return cleanup;
      } catch (error) {
        if ((error as Error).name === "AbortError") {
          return;
        }

        const errorMsg = error instanceof Error ? error.message : "Unknown error occurred";
        updateState({
          error: errorMsg,
          isComplete: true,
        });
        setIsStreaming(false);
        options.onError?.(errorMsg);
      }
    },
    [parseSSEMessage, processEvent, updateState, options]
  );

  /**
   * Cancel streaming
   */
  const cancelStreaming = useCallback(() => {
    abortControllerRef.current?.abort();
    setIsStreaming(false);
    updateState({
      error: "Generation cancelled",
      isComplete: true,
    });
  }, [updateState]);

  /**
   * Reset state
   */
  const reset = useCallback(() => {
    setState(createInitialStreamingState());
    setIsStreaming(false);
  }, []);

  return {
    state,
    isStreaming,
    startStreaming,
    cancelStreaming,
    reset,
  };
}
