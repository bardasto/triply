/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Foursquare Places API Service
 * Restaurant details, tips, photos, trending venues
 * ═══════════════════════════════════════════════════════════════════════════
 */

import axios, { AxiosInstance } from 'axios';
import config from '../../../shared/config/env.js';
import logger from '../../../shared/utils/logger.js';
import retry from '../../../shared/utils/retry.js';
import rateLimiter from '../../../shared/utils/rate-limiter.js';

// ═══════════════════════════════════════════════════════════════════════════
// Type Definitions
// ═══════════════════════════════════════════════════════════════════════════

interface FoursquareCategory {
  id: number;
  name: string;
  short_name: string;
  icon: {
    prefix: string;
    suffix: string;
  };
}

interface FoursquareLocation {
  address?: string;
  locality?: string;
  region?: string;
  postcode?: string;
  country?: string;
  cross_street?: string;
  formatted_address: string;
}

interface FoursquareGeocode {
  main: {
    latitude: number;
    longitude: number;
  };
  roof?: {
    latitude: number;
    longitude: number;
  };
}

interface FoursquarePhoto {
  id: string;
  created_at: string;
  prefix: string;
  suffix: string;
  width: number;
  height: number;
  classifications?: string[];
}

interface FoursquareTip {
  id: string;
  created_at: string;
  text: string;
  agree_count: number;
  disagree_count: number;
  lang: string;
}

interface FoursquareHours {
  display: string;
  is_local_holiday: boolean;
  open_now: boolean;
  regular?: Array<{
    day: number;
    open: string;
    close: string;
  }>;
}

export interface FoursquareVenue {
  fsq_id: string;
  name: string;
  categories: FoursquareCategory[];
  location: FoursquareLocation;
  geocodes: FoursquareGeocode;
  distance?: number;

  // Optional enrichment fields
  rating?: number;
  price?: number; // 1-4 ($, $$, $$$, $$$$)
  popularity?: number;
  hours?: FoursquareHours;
  description?: string;
  tel?: string;
  website?: string;
  social_media?: {
    facebook_id?: string;
    twitter?: string;
    instagram?: string;
  };
  verified?: boolean;

  // Premium fields
  photos?: FoursquarePhoto[];
  tips?: FoursquareTip[];
  menu?: string;
  tastes?: string[];
  features?: {
    payment?: {
      credit_cards?: {
        accepts_credit_cards?: boolean;
      };
      digital_wallet?: {
        accepts_nfc?: boolean;
      };
    };
    food_and_drink?: {
      alcohol?: {
        bar_service?: boolean;
        beer?: boolean;
        wine?: boolean;
      };
      meals?: {
        breakfast?: boolean;
        lunch?: boolean;
        dinner?: boolean;
      };
    };
    services?: {
      delivery?: boolean;
      takeout?: boolean;
      dine_in?: {
        reservations?: boolean;
      };
    };
  };
}

export interface FoursquareSearchParams {
  query?: string;
  near?: string;
  ll?: string; // "latitude,longitude"
  radius?: number; // meters
  categories?: string; // comma-separated category IDs
  limit?: number;
  sort?: 'RELEVANCE' | 'DISTANCE' | 'RATING' | 'POPULARITY';
  fields?: string;
}

// ═══════════════════════════════════════════════════════════════════════════
// Foursquare Service Class
// ═══════════════════════════════════════════════════════════════════════════

class FoursquareService {
  private client: AxiosInstance;
  private apiKey: string;
  private baseUrl = 'https://api.foursquare.com/v3';

  constructor() {
    this.apiKey = config.FOURSQUARE_API_KEY;
    this.client = axios.create({
      baseURL: this.baseUrl,
      headers: {
        Authorization: this.apiKey,
        Accept: 'application/json',
      },
      timeout: 10000,
    });

    logger.info('✓ Foursquare service initialized');
  }

  /**
   * Build photo URL from Foursquare photo object
   */
  private buildPhotoUrl(
    photo: FoursquarePhoto,
    size: 'original' | 'small' = 'original'
  ): string {
    const sizeParam = size === 'original' ? 'original' : '300x300';
    return `${photo.prefix}${sizeParam}${photo.suffix}`;
  }

  /**
   * Format price level to currency symbol
   */
  private formatPrice(priceLevel?: number): string {
    if (!priceLevel) return '';
    return '$'.repeat(priceLevel);
  }

  /**
   * Validate and format coordinates
   */
  private formatLatLng(lat: number, lng: number): string {
    return `${lat.toFixed(6)},${lng.toFixed(6)}`;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Public API Methods
  // ═══════════════════════════════════════════════════════════════════════════

  /**
   * Health check - verify API key is working
   */
  async healthCheck(): Promise<boolean> {
    try {
      const response = await this.client.get('/places/search', {
        params: {
          near: 'Paris',
          limit: 1,
        },
      });

      logger.info('✓ Foursquare API health check passed');
      return response.status === 200;
    } catch (error) {
      logger.error('❌ Foursquare API health check failed:', error);
      return false;
    }
  }
}

export default new FoursquareService();
