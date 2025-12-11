/**
 * Image Preloading Utilities
 *
 * Provides utilities for preloading critical images to improve LCP.
 * Used in conjunction with ImagePriorityContext for optimal performance.
 */

/**
 * Preload an image programmatically
 * Creates a link element with rel="preload" or uses the browser's preload API
 *
 * @param src - Image source URL
 * @param options - Additional options for the preload
 */
export function preloadImage(
  src: string,
  options?: {
    fetchPriority?: "high" | "low" | "auto";
    as?: "image";
  }
): void {
  if (typeof window === "undefined") return;

  // Check if already preloaded
  const existingPreload = document.querySelector(`link[rel="preload"][href="${src}"]`);
  if (existingPreload) return;

  const link = document.createElement("link");
  link.rel = "preload";
  link.as = options?.as || "image";
  link.href = src;

  if (options?.fetchPriority) {
    link.fetchPriority = options.fetchPriority;
  }

  document.head.appendChild(link);
}

/**
 * Preload multiple images
 *
 * @param srcs - Array of image source URLs
 * @param maxCount - Maximum number of images to preload (default: 4)
 */
export function preloadImages(srcs: string[], maxCount = 4): void {
  const toPreload = srcs.slice(0, maxCount);
  toPreload.forEach((src, index) => {
    preloadImage(src, {
      fetchPriority: index === 0 ? "high" : "auto",
    });
  });
}

/**
 * Extract image URL from various image formats
 */
export function extractImageUrl(image: string | { url: string } | null | undefined): string | null {
  if (!image) return null;
  if (typeof image === "string") return image;
  if (typeof image === "object" && "url" in image) return image.url;
  return null;
}
