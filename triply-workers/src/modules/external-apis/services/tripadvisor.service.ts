/**
 * ═══════════════════════════════════════════════════════════════════════════
 * TripAdvisor Content API Service
 * Search for places, get details, ratings, and price levels
 * ═══════════════════════════════════════════════════════════════════════════
 */

import axios, { AxiosInstance } from 'axios';
import config from '../../../shared/config/env.js';
import logger from '../../../shared/utils/logger.js';

// ═══════════════════════════════════════════════════════════════════════════
// Type Definitions
// ═══════════════════════════════════════════════════════════════════════════

export interface TripAdvisorLocation {
  location_id: string;
  name: string;
  address_obj?: {
    street1?: string;
    street2?: string;
    city?: string;
    country?: string;
    postalcode?: string;
    address_string?: string;
  };
}

export interface TripAdvisorLocationDetails {
  location_id: string;
  name: string;
  description?: string;
  web_url?: string;
  address_obj?: {
    street1?: string;
    street2?: string;
    city?: string;
    country?: string;
    postalcode?: string;
    address_string?: string;
  };
  latitude?: string;
  longitude?: string;
  phone?: string;
  website?: string;
  email?: string;
  rating?: string;
  num_reviews?: string;
  price_level?: string; // $, $$, $$$, $$$$
  ranking_data?: {
    ranking_string?: string;
    ranking?: string;
    ranking_out_of?: string;
  };
  hours?: {
    weekday_text?: string[];
    periods?: Array<{
      open: { day: number; time: string };
      close: { day: number; time: string };
    }>;
  };
  cuisine?: Array<{
    name: string;
    localized_name: string;
  }>;
  features?: string[];
  category?: {
    name: string;
    localized_name: string;
  };
  awards?: Array<{
    award_type: string;
    year: string;
    display_name: string;
  }>;
}

// ═══════════════════════════════════════════════════════════════════════════
// TripAdvisor Service Class
// ═══════════════════════════════════════════════════════════════════════════

class TripAdvisorService {
  private client: AxiosInstance;
  private apiKey: string;
  private isEnabled: boolean;

  constructor() {
    this.apiKey = config.TRIPADVISOR_API_KEY || '';
    this.isEnabled = !!this.apiKey;

    this.client = axios.create({
      baseURL: 'https://api.content.tripadvisor.com/api/v1',
      timeout: 10000,
    });

    if (this.isEnabled) {
      logger.info('✅ TripAdvisor Service initialized');
    } else {
      logger.warn('⚠️ TripAdvisor Service disabled (no API key)');
    }
  }

  /**
   * Check if TripAdvisor service is available
   */
  isAvailable(): boolean {
    return this.isEnabled;
  }

  /**
   * Search for locations by query
   */
  async searchLocations(
    query: string,
    options: {
      category?: 'restaurants' | 'hotels' | 'attractions' | 'geos';
      language?: string;
    } = {}
  ): Promise<TripAdvisorLocation[]> {
    if (!this.isEnabled) {
      logger.debug('TripAdvisor disabled, skipping search');
      return [];
    }

    const { category, language = 'en' } = options;

    try {
      const params: Record<string, string> = {
        key: this.apiKey,
        searchQuery: query,
        language,
      };

      if (category) {
        params.category = category;
      }

      const response = await this.client.get('/location/search', { params });

      if (response.data?.data) {
        logger.debug(`TripAdvisor found ${response.data.data.length} locations for "${query}"`);
        return response.data.data;
      }

      return [];
    } catch (error: any) {
      logger.error('TripAdvisor search failed:', error.message);
      return [];
    }
  }

  /**
   * Get detailed information about a location
   */
  async getLocationDetails(
    locationId: string,
    options: {
      language?: string;
      currency?: string;
    } = {}
  ): Promise<TripAdvisorLocationDetails | null> {
    if (!this.isEnabled) {
      logger.debug('TripAdvisor disabled, skipping details fetch');
      return null;
    }

    const { language = 'en', currency = 'EUR' } = options;

    try {
      const params = {
        key: this.apiKey,
        language,
        currency,
      };

      const response = await this.client.get(`/location/${locationId}/details`, { params });

      if (response.data) {
        logger.debug(`TripAdvisor got details for location ${locationId}`);
        return response.data;
      }

      return null;
    } catch (error: any) {
      logger.error(`TripAdvisor details failed for ${locationId}:`, error.message);
      return null;
    }
  }

  /**
   * Search for a place by name and city, return details
   * This is the main method for enriching place data
   */
  async findPlaceDetails(
    placeName: string,
    city: string,
    placeType?: string
  ): Promise<TripAdvisorLocationDetails | null> {
    if (!this.isEnabled) {
      return null;
    }

    try {
      // Map place type to TripAdvisor category
      const category = this.mapPlaceTypeToCategory(placeType);

      // Search with place name and city
      const searchQuery = `${placeName} ${city}`;
      const locations = await this.searchLocations(searchQuery, { category });

      if (locations.length === 0) {
        logger.debug(`TripAdvisor: No results for "${placeName}" in ${city}`);
        return null;
      }

      // Get details for the first (best) match
      const bestMatch = locations[0];
      const details = await this.getLocationDetails(bestMatch.location_id);

      if (details) {
        logger.info(`TripAdvisor: Found "${details.name}" with rating ${details.rating}, price ${details.price_level}`);
      }

      return details;
    } catch (error: any) {
      logger.error(`TripAdvisor findPlaceDetails failed:`, error.message);
      return null;
    }
  }

  /**
   * Map our place types to TripAdvisor categories
   */
  private mapPlaceTypeToCategory(placeType?: string): 'restaurants' | 'hotels' | 'attractions' | undefined {
    if (!placeType) return undefined;

    const type = placeType.toLowerCase();

    if (['restaurant', 'cafe', 'bar', 'nightclub'].includes(type)) {
      return 'restaurants';
    }

    if (['hotel', 'hostel', 'resort', 'accommodation'].includes(type)) {
      return 'hotels';
    }

    if (['museum', 'park', 'attraction', 'viewpoint', 'beach', 'landmark'].includes(type)) {
      return 'attractions';
    }

    return undefined;
  }

  /**
   * Convert TripAdvisor price_level to estimated price range
   * Based on typical prices in major European cities
   */
  getPriceEstimate(
    priceLevel: string | undefined,
    placeType: string,
    city?: string
  ): string {
    if (!priceLevel) return '';

    const type = placeType.toLowerCase();

    // Restaurant/cafe/bar pricing (per person)
    if (['restaurant', 'cafe', 'bar'].includes(type)) {
      switch (priceLevel) {
        case '$':
          return '€8-15 per person';
        case '$$':
          return '€15-30 per person';
        case '$$$':
          return '€30-60 per person';
        case '$$$$':
          return '€60-150+ per person';
        default:
          return '';
      }
    }

    // Attractions/museums pricing
    if (['museum', 'attraction', 'park'].includes(type)) {
      switch (priceLevel) {
        case '$':
          return '€5-10';
        case '$$':
          return '€10-20';
        case '$$$':
          return '€20-40';
        case '$$$$':
          return '€40+';
        default:
          return '';
      }
    }

    return '';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Singleton Instance
// ═══════════════════════════════════════════════════════════════════════════

const tripAdvisorService = new TripAdvisorService();

export default tripAdvisorService;
