/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Restaurant Cache Service
 * Specialized service for managing restaurant data with Google-compliant caching
 * ═══════════════════════════════════════════════════════════════════════════
 */

import logger from '../../../shared/utils/logger.js';
import googlePlacesService from './google-places.service.js';
import PlacesCacheService from './places-cache.service.js';
import {
  PlaceCatalogInput,
  CachedRestaurant,
  PlaceType,
} from '../../../shared/types/index.js';

// ═══════════════════════════════════════════════════════════════════════════
// Types
// ═══════════════════════════════════════════════════════════════════════════

export interface SeedRestaurantsParams {
  city: string;
  countryCode: string;
  query?: string;
  limit?: number;
  priority?: number;
}

export interface SeedResult {
  success: boolean;
  total: number;
  cached: number;
  failed: number;
  errors: string[];
}

// ═══════════════════════════════════════════════════════════════════════════
// Service Class
// ═══════════════════════════════════════════════════════════════════════════

class RestaurantCacheService {
  constructor() {
    logger.info('✅ RestaurantCacheService initialized');
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Seed Restaurants for a City
  // ═════════════════════════════════════════════════════════════════════════

  async seedRestaurants(params: SeedRestaurantsParams): Promise<SeedResult> {
    const {
      city,
      countryCode,
      query = `best restaurants in ${city}`,
      limit = 50,
      priority = 5,
    } = params;

    logger.info(
      `🍽️ Seeding restaurants for ${city}: "${query}" (limit: ${limit})`
    );

    const result: SeedResult = {
      success: true,
      total: 0,
      cached: 0,
      failed: 0,
      errors: [],
    };

    try {
      // Search for restaurants using Google Places Text Search
      const places = await googlePlacesService.textSearch({
        query,
        type: 'restaurant',
      });

      result.total = Math.min(places.length, limit);
      logger.info(`Found ${places.length} restaurants, processing ${result.total}...`);

      // Process each restaurant
      for (let i = 0; i < result.total; i++) {
        const place = places[i];

        try {
          // Create catalog entry
          const catalogInput: PlaceCatalogInput = {
            google_place_id: place.place_id,
            latitude: place.geometry.location.lat,
            longitude: place.geometry.location.lng,
            city,
            country_code: countryCode,
            place_type: 'restaurant' as PlaceType,
            category: this.extractCategory(place.types),
            tags: this.extractTags(place),
            priority,
          };

          const catalog = await PlacesCacheService.createCatalogEntry(catalogInput);

          // Get detailed information and cache it
          const details = await googlePlacesService.getPlaceDetails(place.place_id);

          if (!details) {
            throw new Error(`Failed to get details for ${place.place_id}`);
          }
          await PlacesCacheService.cachePlace(catalog.id, details);

          result.cached++;
          logger.info(
            `[${i + 1}/${result.total}] ✅ Cached: ${place.name} (${place.place_id})`
          );

          // Rate limiting: wait 500ms between requests
          await this.sleep(500);
        } catch (error: any) {
          result.failed++;
          const errorMsg = `Failed to cache ${place.name}: ${error.message}`;
          result.errors.push(errorMsg);
          logger.error(errorMsg);
        }
      }

      logger.info(
        `✅ Seed complete: ${result.cached} cached, ${result.failed} failed`
      );
    } catch (error: any) {
      result.success = false;
      result.errors.push(`Seed failed: ${error.message}`);
      logger.error('Seed failed:', error);
    }

    return result;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Get Restaurants for a City
  // ═════════════════════════════════════════════════════════════════════════

  async getRestaurantsByCity(
    city: string,
    filters?: {
      minRating?: number;
      priceLevel?: number[];
      cuisineTypes?: string[];
      limit?: number;
    }
  ): Promise<CachedRestaurant[]> {
    logger.info(`Getting restaurants for ${city}`, filters);

    let restaurants = await PlacesCacheService.getPlacesByCity(city, 'restaurant');

    // Apply filters
    if (filters) {
      if (filters.minRating !== undefined) {
        restaurants = restaurants.filter(
          (r) => r.rating && r.rating >= filters.minRating!
        );
      }

      if (filters.priceLevel && filters.priceLevel.length > 0) {
        restaurants = restaurants.filter(
          (r) => r.price_level && filters.priceLevel!.includes(r.price_level)
        );
      }

      if (filters.cuisineTypes && filters.cuisineTypes.length > 0) {
        restaurants = restaurants.filter((r) =>
          r.cuisine_types.some((ct) =>
            filters.cuisineTypes!.some((fct) =>
              ct.toLowerCase().includes(fct.toLowerCase())
            )
          )
        );
      }

      if (filters.limit) {
        restaurants = restaurants.slice(0, filters.limit);
      }
    }

    logger.info(`✅ Returning ${restaurants.length} restaurants`);
    return restaurants;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Get Single Restaurant by Place ID
  // ═════════════════════════════════════════════════════════════════════════

  async getRestaurantByPlaceId(
    placeId: string,
    forceRefresh = false
  ): Promise<CachedRestaurant> {
    logger.info(`Getting restaurant by place_id: ${placeId}`);

    // First, find the catalog entry
    const { data: catalog } = await PlacesCacheService['supabase']
      .from('places_catalog')
      .select('*')
      .eq('google_place_id', placeId)
      .single();

    if (!catalog) {
      throw new Error(`Restaurant not found with place_id: ${placeId}`);
    }

    return PlacesCacheService.getPlace(catalog.id, forceRefresh);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Get Restaurants by Tags
  // ═════════════════════════════════════════════════════════════════════════

  async getRestaurantsByTags(
    city: string,
    tags: string[]
  ): Promise<CachedRestaurant[]> {
    logger.info(`Getting restaurants with tags: ${tags.join(', ')}`);

    const restaurants = await PlacesCacheService.getPlacesByCity(city, 'restaurant');

    // Filter by tags
    const filtered = restaurants.filter((r) =>
      tags.some((tag) => r.tags.includes(tag))
    );

    logger.info(`✅ Found ${filtered.length} restaurants with specified tags`);
    return filtered;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Seed Multiple Cuisines
  // ═════════════════════════════════════════════════════════════════════════

  async seedMultipleCuisines(
    city: string,
    countryCode: string,
    cuisines: string[],
    perCuisineLimit = 20
  ): Promise<SeedResult> {
    logger.info(
      `🍽️ Seeding multiple cuisines for ${city}: ${cuisines.join(', ')}`
    );

    const totalResult: SeedResult = {
      success: true,
      total: 0,
      cached: 0,
      failed: 0,
      errors: [],
    };

    for (const cuisine of cuisines) {
      logger.info(`\n--- Seeding ${cuisine} restaurants ---`);

      const result = await this.seedRestaurants({
        city,
        countryCode,
        query: `best ${cuisine} restaurants in ${city}`,
        limit: perCuisineLimit,
        priority: 5,
      });

      totalResult.total += result.total;
      totalResult.cached += result.cached;
      totalResult.failed += result.failed;
      totalResult.errors.push(...result.errors);

      if (!result.success) {
        totalResult.success = false;
      }

      // Wait between cuisines to avoid rate limiting
      await this.sleep(2000);
    }

    logger.info(
      `\n✅ All cuisines seeded: ${totalResult.cached} cached, ${totalResult.failed} failed`
    );
    return totalResult;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Helper Methods
  // ═════════════════════════════════════════════════════════════════════════

  private extractCategory(types: string[]): string {
    const restaurantTypes = [
      'fine_dining_restaurant',
      'french_restaurant',
      'italian_restaurant',
      'japanese_restaurant',
      'chinese_restaurant',
      'indian_restaurant',
      'mexican_restaurant',
      'thai_restaurant',
      'mediterranean_restaurant',
      'seafood_restaurant',
      'steakhouse',
      'vegetarian_restaurant',
      'vegan_restaurant',
      'fast_food_restaurant',
      'pizza_restaurant',
      'sushi_restaurant',
      'ramen_restaurant',
      'american_restaurant',
      'bar_and_grill',
    ];

    const found = types.find((t) => restaurantTypes.includes(t));
    return found || 'restaurant';
  }

  private extractTags(place: any): string[] {
    const tags: string[] = [];

    // Add rating-based tags
    if (place.rating >= 4.5) tags.push('highly_rated');
    if (place.rating >= 4.0) tags.push('popular');

    // Add price level tags
    if (place.price_level === 4) tags.push('fine_dining', 'expensive');
    if (place.price_level === 3) tags.push('upscale');
    if (place.price_level === 2) tags.push('mid_range');
    if (place.price_level === 1) tags.push('budget');

    // Add type-based tags
    if (place.types.includes('meal_delivery')) tags.push('delivery');
    if (place.types.includes('meal_takeaway')) tags.push('takeaway');
    if (place.types.some((t: string) => t.includes('vegetarian'))) {
      tags.push('vegetarian');
    }

    return tags;
  }

  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Export singleton instance
// ═══════════════════════════════════════════════════════════════════════════

export default new RestaurantCacheService();
