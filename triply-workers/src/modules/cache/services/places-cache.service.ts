/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Places Cache Service
 * Google Places API compliant caching (30-day cache, 15-day refresh)
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js';
import config from '../../../shared/config/env.js';
import logger from '../../../shared/utils/logger.js';
import googlePlacesService from './google-places.service.js';
import type { PlaceDetails } from './google-places.service.js';
import {
  PlaceCatalog,
  PlaceCache,
  PlaceCatalogInput,
  PlaceCacheInput,
  CachedRestaurant,
  CacheStatus,
  CacheRefreshLog,
  RefreshStatus,
  RefreshType,
} from '../../../shared/types/index.js';

// ═══════════════════════════════════════════════════════════════════════════
// Types
// ═══════════════════════════════════════════════════════════════════════════

interface CacheCheckResult {
  exists: boolean;
  status: CacheStatus;
  cache?: PlaceCache;
  catalog?: PlaceCatalog;
}

interface RefreshResult {
  success: boolean;
  cache?: PlaceCache;
  error?: string;
  latency_ms?: number;
}

// ═══════════════════════════════════════════════════════════════════════════
// Service Class
// ═══════════════════════════════════════════════════════════════════════════

class PlacesCacheService {
  private supabase: SupabaseClient;

  // Cache settings (Google Policy compliant)
  private readonly CACHE_EXPIRY_DAYS = 30; // Max allowed by Google
  private readonly REFRESH_INTERVAL_DAYS = 15; // Refresh every 15 days to stay fresh

  constructor() {
    this.supabase = createClient(config.SUPABASE_URL, config.SUPABASE_SERVICE_ROLE_KEY);
    logger.info('✅ PlacesCacheService initialized');
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Create or Update Catalog Entry
  // ═════════════════════════════════════════════════════════════════════════

  async createCatalogEntry(input: PlaceCatalogInput): Promise<PlaceCatalog> {
    logger.info(`Creating catalog entry for place_id: ${input.google_place_id}`);

    const { data, error } = await this.supabase
      .from('places_catalog')
      .upsert(
        {
          google_place_id: input.google_place_id,
          latitude: input.latitude,
          longitude: input.longitude,
          coordinates_cached_at: input.latitude ? new Date().toISOString() : null,
          city: input.city,
          country_code: input.country_code,
          place_type: input.place_type,
          category: input.category,
          tags: input.tags || [],
          poi_id: input.poi_id,
          priority: input.priority || 0,
          is_active: true,
        },
        { onConflict: 'google_place_id' }
      )
      .select()
      .single();

    if (error) {
      logger.error('Failed to create catalog entry:', error);
      throw new Error(`Failed to create catalog entry: ${error.message}`);
    }

    logger.info(`✅ Catalog entry created: ${data.id}`);
    return data as PlaceCatalog;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Cache Place Data from Google Places API
  // ═════════════════════════════════════════════════════════════════════════

  async cachePlace(catalogId: string, placeDetails: PlaceDetails): Promise<PlaceCache> {
    logger.info(`Caching place data for catalog_id: ${catalogId}`);

    const now = new Date();
    const expiresAt = new Date(now.getTime() + this.CACHE_EXPIRY_DAYS * 24 * 60 * 60 * 1000);
    const nextRefreshAt = new Date(now.getTime() + this.REFRESH_INTERVAL_DAYS * 24 * 60 * 60 * 1000);

    const cacheInput: PlaceCacheInput = {
      place_catalog_id: catalogId,
      name: placeDetails.name,
      formatted_address: placeDetails.formatted_address,
      international_phone_number: placeDetails.formatted_phone_number,
      website: placeDetails.website,
      rating: placeDetails.rating,
      user_ratings_total: placeDetails.user_ratings_total,
      price_level: placeDetails.price_level,
      cuisine_types: this.extractCuisineTypes(placeDetails.types),
      opening_hours: placeDetails.opening_hours,
      is_open_now: placeDetails.opening_hours?.open_now,
      photos: placeDetails.photos?.map((p) => ({
        photo_reference: p.photo_reference,
        width: (p as any).width || 400,
        height: (p as any).height || 300,
      })),
      reviews: placeDetails.reviews?.slice(0, 5).map((r) => ({
        author_name: (r as any).author_name,
        rating: (r as any).rating,
        text: (r as any).text,
        time: (r as any).time,
      })),
      business_status: (placeDetails as any).business_status,
      types: placeDetails.types,
      editorial_summary: (placeDetails as any).editorial_summary?.overview,
      raw_data: placeDetails,
    };

    const { data, error } = await this.supabase
      .from('places_cache')
      .upsert(
        {
          ...cacheInput,
          cached_at: now.toISOString(),
          expires_at: expiresAt.toISOString(),
          next_refresh_at: nextRefreshAt.toISOString(),
          last_api_call_at: now.toISOString(),
        },
        { onConflict: 'place_catalog_id' }
      )
      .select()
      .single();

    if (error) {
      logger.error('Failed to cache place data:', error);
      throw new Error(`Failed to cache place data: ${error.message}`);
    }

    logger.info(`✅ Place cached: ${data.name} (expires: ${expiresAt.toISOString()})`);
    return data as PlaceCache;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Check Cache Status
  // ═════════════════════════════════════════════════════════════════════════

  async checkCacheStatus(catalogId: string): Promise<CacheCheckResult> {
    const { data: catalog } = await this.supabase
      .from('places_catalog')
      .select('*')
      .eq('id', catalogId)
      .single();

    if (!catalog) {
      return { exists: false, status: 'missing' };
    }

    const { data: cache } = await this.supabase
      .from('places_cache')
      .select('*')
      .eq('place_catalog_id', catalogId)
      .single();

    if (!cache) {
      return { exists: false, status: 'missing', catalog: catalog as PlaceCatalog };
    }

    const now = new Date();
    const expiresAt = new Date(cache.expires_at);
    const nextRefreshAt = new Date(cache.next_refresh_at);

    let status: CacheStatus;
    if (expiresAt <= now) {
      status = 'expired';
    } else if (nextRefreshAt <= now) {
      status = 'needs_refresh';
    } else {
      status = 'fresh';
    }

    return {
      exists: true,
      status,
      cache: cache as PlaceCache,
      catalog: catalog as PlaceCatalog,
    };
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Get Place (with automatic refresh if needed)
  // ═════════════════════════════════════════════════════════════════════════

  async getPlace(catalogId: string, forceRefresh = false): Promise<CachedRestaurant> {
    const cacheCheck = await this.checkCacheStatus(catalogId);

    if (!cacheCheck.catalog) {
      throw new Error(`Catalog entry not found: ${catalogId}`);
    }

    // Return cached data if fresh and not forcing refresh
    if (
      cacheCheck.status === 'fresh' &&
      !forceRefresh &&
      cacheCheck.cache
    ) {
      logger.info(`✅ Cache hit (fresh): ${cacheCheck.cache.name}`);
      return this.buildCachedRestaurant(cacheCheck.catalog, cacheCheck.cache);
    }

    // Refresh cache if needed
    logger.info(`🔄 Cache ${cacheCheck.status}, fetching fresh data from Google...`);
    const refreshResult = await this.refreshCache(catalogId);

    if (!refreshResult.success || !refreshResult.cache) {
      // If refresh failed but we have stale cache, return it with warning
      if (cacheCheck.cache && cacheCheck.status !== 'expired') {
        logger.warn(`⚠️ Using stale cache due to refresh failure`);
        return this.buildCachedRestaurant(cacheCheck.catalog, cacheCheck.cache);
      }
      throw new Error(`Failed to get place data: ${refreshResult.error}`);
    }

    return this.buildCachedRestaurant(cacheCheck.catalog, refreshResult.cache);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Refresh Cache from Google Places API
  // ═════════════════════════════════════════════════════════════════════════

  async refreshCache(
    catalogId: string,
    refreshType: RefreshType = 'on_demand'
  ): Promise<RefreshResult> {
    const startTime = Date.now();

    try {
      const { data: catalog } = await this.supabase
        .from('places_catalog')
        .select('*')
        .eq('id', catalogId)
        .single();

      if (!catalog) {
        throw new Error(`Catalog entry not found: ${catalogId}`);
      }

      // Fetch fresh data from Google Places API
      const placeDetails = await googlePlacesService.getPlaceDetails(catalog.google_place_id);

      if (!placeDetails) {
        throw new Error(`Failed to get place details for ${catalog.google_place_id}`);
      }

      // Update coordinates if needed (30-day refresh for coordinates)
      if (catalog.latitude && catalog.coordinates_cached_at) {
        const coordsCachedAt = new Date(catalog.coordinates_cached_at);
        const daysSinceCoordsCached =
          (Date.now() - coordsCachedAt.getTime()) / (24 * 60 * 60 * 1000);

        if (daysSinceCoordsCached > 30) {
          await this.supabase
            .from('places_catalog')
            .update({
              latitude: placeDetails.geometry.location.lat,
              longitude: placeDetails.geometry.location.lng,
              coordinates_cached_at: new Date().toISOString(),
            })
            .eq('id', catalogId);

          logger.info(`✅ Updated coordinates for ${catalog.google_place_id}`);
        }
      }

      // Cache the place data
      const cache = await this.cachePlace(catalogId, placeDetails);

      const latencyMs = Date.now() - startTime;

      // Log refresh
      await this.logRefresh(catalogId, refreshType, 'success', latencyMs);

      return { success: true, cache, latency_ms: latencyMs };
    } catch (error: any) {
      const latencyMs = Date.now() - startTime;
      logger.error(`Failed to refresh cache for ${catalogId}:`, error);

      // Log failure
      await this.logRefresh(
        catalogId,
        refreshType,
        'failed',
        latencyMs,
        error.message
      );

      return {
        success: false,
        error: error.message,
        latency_ms: latencyMs,
      };
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Get Multiple Places
  // ═════════════════════════════════════════════════════════════════════════

  async getPlacesByCity(
    city: string,
    placeType?: string
  ): Promise<CachedRestaurant[]> {
    logger.info(`Getting places for city: ${city}, type: ${placeType || 'all'}`);

    const query = this.supabase
      .from('places_catalog')
      .select('*, places_cache(*)')
      .eq('city', city)
      .eq('is_active', true);

    if (placeType) {
      query.eq('place_type', placeType);
    }

    const { data, error } = await query;

    if (error) {
      throw new Error(`Failed to get places: ${error.message}`);
    }

    const results: CachedRestaurant[] = [];

    for (const entry of data || []) {
      const cache = entry.places_cache?.[0];

      if (cache) {
        const cacheStatus = this.determineCacheStatus(cache);

        // Refresh if needed (but don't block the response)
        if (cacheStatus === 'needs_refresh' || cacheStatus === 'expired') {
          this.refreshCache(entry.id, 'scheduled').catch((err) =>
            logger.warn(`Background refresh failed for ${entry.id}:`, err)
          );
        }

        results.push(this.buildCachedRestaurant(entry, cache));
      }
    }

    logger.info(`✅ Retrieved ${results.length} places for ${city}`);
    return results;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Delete Expired Cache
  // ═════════════════════════════════════════════════════════════════════════

  async deleteExpiredCache(): Promise<number> {
    logger.info('🧹 Deleting expired cache entries...');

    const { data, error } = await this.supabase
      .from('places_cache')
      .delete()
      .lt('expires_at', new Date().toISOString())
      .select();

    if (error) {
      logger.error('Failed to delete expired cache:', error);
      throw new Error(`Failed to delete expired cache: ${error.message}`);
    }

    const deletedCount = data?.length || 0;
    logger.info(`✅ Deleted ${deletedCount} expired cache entries`);
    return deletedCount;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Helper Methods
  // ═════════════════════════════════════════════════════════════════════════

  private extractCuisineTypes(types: string[]): string[] {
    const cuisineTypes = types.filter(
      (t) =>
        t.includes('restaurant') ||
        t.includes('food') ||
        t.includes('cafe') ||
        t.includes('bar')
    );
    return cuisineTypes.length > 0 ? cuisineTypes : [];
  }

  private determineCacheStatus(cache: PlaceCache): CacheStatus {
    const now = new Date();
    const expiresAt = new Date(cache.expires_at);
    const nextRefreshAt = new Date(cache.next_refresh_at);

    if (expiresAt <= now) return 'expired';
    if (nextRefreshAt <= now) return 'needs_refresh';
    return 'fresh';
  }

  private buildCachedRestaurant(
    catalog: PlaceCatalog,
    cache: PlaceCache
  ): CachedRestaurant {
    return {
      catalog_id: catalog.id,
      google_place_id: catalog.google_place_id,
      latitude: catalog.latitude,
      longitude: catalog.longitude,
      category: catalog.category,
      tags: catalog.tags,
      name: cache.name,
      formatted_address: cache.formatted_address,
      phone: cache.international_phone_number,
      website: cache.website,
      rating: cache.rating,
      user_ratings_total: cache.user_ratings_total,
      price_level: cache.price_level,
      cuisine_types: cache.cuisine_types,
      opening_hours: cache.opening_hours,
      is_open_now: cache.is_open_now,
      photos: cache.photos,
      reviews: cache.reviews,
      cached_at: cache.cached_at,
      expires_at: cache.expires_at,
      cache_status: this.determineCacheStatus(cache),
    };
  }

  private async logRefresh(
    catalogId: string,
    refreshType: RefreshType,
    status: RefreshStatus,
    latencyMs: number,
    errorMessage?: string
  ): Promise<void> {
    await this.supabase.from('cache_refresh_log').insert({
      place_catalog_id: catalogId,
      refresh_type: refreshType,
      status,
      error_message: errorMessage,
      api_latency_ms: latencyMs,
      refreshed_at: new Date().toISOString(),
    });
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Get Cache Statistics
  // ═════════════════════════════════════════════════════════════════════════

  async getCacheStatistics() {
    const { data, error } = await this.supabase.rpc('get_cache_statistics');

    if (error) {
      logger.error('Failed to get cache statistics:', error);
      throw new Error(`Failed to get cache statistics: ${error.message}`);
    }

    return data;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Export singleton instance
// ═══════════════════════════════════════════════════════════════════════════

export default new PlacesCacheService();
