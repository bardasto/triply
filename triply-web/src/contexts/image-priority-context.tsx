"use client";

import { createContext, useContext, useRef, useCallback, type ReactNode } from "react";

/**
 * Image Priority Context
 *
 * Tracks global image rendering order to determine which images should be
 * loaded with high priority (LCP candidates). Only the first N images
 * rendered on the page get priority loading.
 *
 * This solves the problem where multiple components independently mark their
 * first images as priority, resulting in too many priority images which
 * defeats the purpose of prioritization.
 *
 * Usage:
 * 1. Wrap your app/page with <ImagePriorityProvider>
 * 2. In image components, call useImagePriority() to get { shouldPrioritize, registerImage }
 * 3. Call registerImage() when rendering to claim a priority slot
 * 4. Use shouldPrioritize to determine if this image should have priority/fetchPriority
 */

// Number of images to prioritize (above the fold on most viewports)
// Desktop: typically 4-8 cards visible
// Mobile: typically 2-4 cards visible
// We use 4 as a safe default that covers most cases
const MAX_PRIORITY_IMAGES = 4;

interface ImagePriorityContextValue {
  /**
   * Register an image and get whether it should be prioritized
   * @returns true if this image should have priority loading
   */
  claimPrioritySlot: () => boolean;

  /**
   * Get current count of priority images claimed
   */
  getPriorityCount: () => number;

  /**
   * Reset priority counter (useful for route changes)
   */
  reset: () => void;
}

const ImagePriorityContext = createContext<ImagePriorityContextValue | null>(null);

export function ImagePriorityProvider({
  children,
  maxPriorityImages = MAX_PRIORITY_IMAGES
}: {
  children: ReactNode;
  maxPriorityImages?: number;
}) {
  const priorityCountRef = useRef(0);

  const claimPrioritySlot = useCallback(() => {
    const currentCount = priorityCountRef.current;
    if (currentCount < maxPriorityImages) {
      priorityCountRef.current = currentCount + 1;
      return true;
    }
    return false;
  }, [maxPriorityImages]);

  const getPriorityCount = useCallback(() => {
    return priorityCountRef.current;
  }, []);

  const reset = useCallback(() => {
    priorityCountRef.current = 0;
  }, []);

  return (
    <ImagePriorityContext.Provider value={{ claimPrioritySlot, getPriorityCount, reset }}>
      {children}
    </ImagePriorityContext.Provider>
  );
}

/**
 * Hook to manage image priority within the global context
 *
 * @example
 * ```tsx
 * function TripCard({ trip, index }) {
 *   const { shouldPrioritize } = useImagePriority();
 *   const isPriority = shouldPrioritize();
 *
 *   return (
 *     <Image
 *       src={trip.image}
 *       priority={isPriority}
 *       fetchPriority={isPriority ? "high" : "auto"}
 *     />
 *   );
 * }
 * ```
 */
export function useImagePriority() {
  const context = useContext(ImagePriorityContext);

  // If no provider, fall back to allowing priority (for backwards compatibility)
  if (!context) {
    return {
      claimPrioritySlot: () => false,
      getPriorityCount: () => 0,
      reset: () => {},
    };
  }

  return context;
}

/**
 * Utility to determine if an image at a given index should be prioritized
 * without using the context (for simple cases)
 *
 * @param index - The index of the image in its list
 * @param isFirstSection - Whether this is the first section on the page
 * @param maxPriority - Maximum number of priority images (default: 4)
 */
export function shouldImageHavePriority(
  index: number,
  isFirstSection: boolean = false,
  maxPriority: number = MAX_PRIORITY_IMAGES
): boolean {
  // Only prioritize images in the first section
  if (!isFirstSection) return false;

  // Only prioritize the first N images
  return index < maxPriority;
}
