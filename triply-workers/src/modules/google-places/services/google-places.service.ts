/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Google Places API Service
 * Работа с Google Places API: поиск POI, геокодинг, детали мест
 * ═══════════════════════════════════════════════════════════════════════════
 */

import axios, { AxiosInstance } from 'axios';
import config from '../../../shared/config/env.js';
import logger, { logApiCall } from '../../../shared/utils/logger.js';
import retry from '../../../shared/utils/retry.js';
import rateLimiter from '../../../shared/utils/rate-limiter.js';
import { circuitBreakers } from '../../../shared/utils/retry.js';

// ═══════════════════════════════════════════════════════════════════════════
// Types
// ═══════════════════════════════════════════════════════════════════════════

export interface PlaceResult {
  place_id: string;
  name: string;
  formatted_address?: string;
  geometry: {
    location: {
      lat: number;
      lng: number;
    };
  };
  types: string[];
  rating?: number;
  user_ratings_total?: number;
  photos?: Array<{ photo_reference: string }>;
  opening_hours?: {
    open_now?: boolean;
    weekday_text?: string[];
  };
  price_level?: number;
}

export interface PlaceDetails extends PlaceResult {
  formatted_phone_number?: string;
  website?: string;
  reviews?: Array<any>;
  opening_hours?: {
    open_now: boolean;
    periods: Array<any>;
    weekday_text: string[];
  };
}

export interface NearbySearchParams {
  location: { lat: number; lng: number };
  radius: number;
  type?: string;
  keyword?: string;
}

export interface TextSearchParams {
  query: string;
  location?: { lat: number; lng: number };
  radius?: number;
  type?: string;
}

// ═══════════════════════════════════════════════════════════════════════════
// Google Places Service Class
// ═══════════════════════════════════════════════════════════════════════════

class GooglePlacesService {
  private client: AxiosInstance;
  private apiKey: string;
  private baseUrl = 'https://maps.googleapis.com/maps/api';

  constructor() {
    this.apiKey = config.GOOGLE_PLACES_API_KEY;

    this.client = axios.create({
      baseURL: this.baseUrl,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    logger.info('✅ Google Places Service initialized');
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Nearby Search - поиск мест в радиусе
  // ═════════════════════════════════════════════════════════════════════════

  async nearbySearch(params: NearbySearchParams): Promise<PlaceResult[]> {
    const startTime = Date.now();

    return rateLimiter.execute('google_places', async () => {
      return circuitBreakers.googlePlaces.execute(async () => {
        return retry(async () => {
          const response = await this.client.get('/place/nearbysearch/json', {
            params: {
              location: `${params.location.lat},${params.location.lng}`,
              radius: params.radius,
              type: params.type,
              keyword: params.keyword,
              key: this.apiKey,
            },
          });

          const duration = Date.now() - startTime;

          if (
            response.data.status !== 'OK' &&
            response.data.status !== 'ZERO_RESULTS'
          ) {
            logApiCall(
              'google_places',
              'GET',
              '/place/nearbysearch',
              response.status,
              duration,
              new Error(response.data.status)
            );
            throw new Error(`Google Places API error: ${response.data.status}`);
          }

          logApiCall(
            'google_places',
            'GET',
            '/place/nearbysearch',
            response.status,
            duration
          );

          return response.data.results as PlaceResult[];
        });
      });
    });
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Text Search - поиск по тексту
  // ═════════════════════════════════════════════════════════════════════════

  async textSearch(params: TextSearchParams): Promise<PlaceResult[]> {
    const startTime = Date.now();

    return rateLimiter.execute('google_places', async () => {
      return circuitBreakers.googlePlaces.execute(async () => {
        return retry(async () => {
          const requestParams: any = {
            query: params.query,
            key: this.apiKey,
          };

          if (params.location) {
            requestParams.location = `${params.location.lat},${params.location.lng}`;
          }
          if (params.radius) {
            requestParams.radius = params.radius;
          }
          if (params.type) {
            requestParams.type = params.type;
          }

          logger.info('Making Text Search request:', requestParams);

          const response = await this.client.get('/place/textsearch/json', {
            params: requestParams,
          });

          const duration = Date.now() - startTime;

          if (
            response.data.status !== 'OK' &&
            response.data.status !== 'ZERO_RESULTS'
          ) {
            logApiCall(
              'google_places',
              'GET',
              '/place/textsearch',
              response.status,
              duration,
              new Error(response.data.status)
            );
            throw new Error(`Google Places API error: ${response.data.status}`);
          }

          logApiCall(
            'google_places',
            'GET',
            '/place/textsearch',
            response.status,
            duration
          );

          return response.data.results as PlaceResult[];
        });
      });
    });
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Place Details - детальная информация о месте
  // ═════════════════════════════════════════════════════════════════════════

  async getPlaceDetails(placeId: string): Promise<PlaceDetails | null> {
    const startTime = Date.now();

    return rateLimiter.execute('google_places', async () => {
      return circuitBreakers.googlePlaces.execute(async () => {
        return retry(async () => {
          const response = await this.client.get('/place/details/json', {
            params: {
              place_id: placeId,
              fields:
                'place_id,name,formatted_address,geometry,types,rating,user_ratings_total,photos,opening_hours,price_level,formatted_phone_number,website,reviews',
              key: this.apiKey,
            },
          });

          const duration = Date.now() - startTime;

          if (response.data.status !== 'OK') {
            logApiCall(
              'google_places',
              'GET',
              '/place/details',
              response.status,
              duration,
              new Error(response.data.status)
            );
            return null;
          }

          logApiCall(
            'google_places',
            'GET',
            '/place/details',
            response.status,
            duration
          );

          return response.data.result as PlaceDetails;
        });
      });
    });
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Geocoding - получить координаты по адресу
  // ═════════════════════════════════════════════════════════════════════════

  async geocode(address: string): Promise<{ lat: number; lng: number } | null> {
    const startTime = Date.now();

    return rateLimiter.execute('google_places', async () => {
      return retry(async () => {
        const response = await this.client.get('/geocode/json', {
          params: {
            address,
            key: this.apiKey,
          },
        });

        const duration = Date.now() - startTime;

        if (response.data.status !== 'OK') {
          logApiCall(
            'google_places',
            'GET',
            '/geocode',
            response.status,
            duration,
            new Error(response.data.status)
          );
          return null;
        }

        logApiCall(
          'google_places',
          'GET',
          '/geocode',
          response.status,
          duration
        );

        return response.data.results[0]?.geometry.location || null;
      });
    });
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Helper: Map Place Type to Category
  // ═════════════════════════════════════════════════════════════════════════

  mapTypeToCategory(types: string[]): string {
    const categoryMap: Record<string, string> = {
      museum: 'museum',
      art_gallery: 'museum',
      tourist_attraction: 'landmark',
      park: 'park',
      natural_feature: 'nature',
      beach: 'beach',
      restaurant: 'restaurant',
      cafe: 'cafe',
      bar: 'nightlife',
      night_club: 'nightlife',
      shopping_mall: 'shopping',
      store: 'shopping',
      church: 'religious',
      mosque: 'religious',
      temple: 'religious',
      amusement_park: 'entertainment',
      zoo: 'entertainment',
      aquarium: 'entertainment',
    };

    for (const type of types) {
      if (categoryMap[type]) {
        return categoryMap[type];
      }
    }

    return 'other';
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Helper: Get Photo URL
  // ═════════════════════════════════════════════════════════════════════════

  getPhotoUrl(photoReference: string, maxWidth: number = 800): string {
    return `${this.baseUrl}/place/photo?photo_reference=${photoReference}&maxwidth=${maxWidth}&key=${this.apiKey}`;
  }
  /**
   * Search places by text query
   */
  /**
   * 🔍 Search places by text query (для city gallery)
   */
  async searchPlaces(
    query: string,
    maxResults: number = 5
  ): Promise<PlaceResult[]> {
    try {
      return await rateLimiter.execute('google_places', async () => {
        return await retry(async () => {
          const response = await this.client.get('/place/textsearch/json', {
            params: {
              query,
              key: this.apiKey,
            },
          });

          if (response.data.status === 'ZERO_RESULTS') {
            logger.warn(`No results for query: "${query}"`);
            return [];
          }

          if (response.data.status !== 'OK') {
            throw new Error(`Google Places API error: ${response.data.status}`);
          }

          return response.data.results.slice(0, maxResults);
        });
      });
    } catch (error) {
      logger.error(`Failed to search places for "${query}":`, error);
      return [];
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Find Place - поиск place_id по названию и городу
  // ═════════════════════════════════════════════════════════════════════════

  async findPlaceByName(
    placeName: string,
    cityName: string,
    location?: { lat: number; lng: number }
  ): Promise<{ place_id: string; name: string; address?: string } | null> {
    const startTime = Date.now();

    try {
      return await rateLimiter.execute('google_places', async () => {
        return circuitBreakers.googlePlaces.execute(async () => {
          return retry(async () => {
            const query = `${placeName}, ${cityName}`;

            // Используем Text Search вместо Find Place from Text
            // Text Search работает с тем же API key и делает то же самое
            const params: any = {
              query: query,
              key: this.apiKey,
            };

            // Добавляем location только если он передан
            if (location) {
              params.location = `${location.lat},${location.lng}`;
              params.radius = 2000;
            }

            const response = await this.client.get('/place/textsearch/json', {
              params,
            });

            const duration = Date.now() - startTime;

            if (
              response.data.status !== 'OK' &&
              response.data.status !== 'ZERO_RESULTS'
            ) {
              logApiCall(
                'google_places',
                'GET',
                '/place/textsearch',
                response.status,
                duration,
                new Error(response.data.status)
              );
              return null;
            }

            logApiCall(
              'google_places',
              'GET',
              '/place/textsearch',
              response.status,
              duration
            );

            // Text Search возвращает массив results вместо candidates
            if (response.data.results && response.data.results.length > 0) {
              const place = response.data.results[0];
              return {
                place_id: place.place_id,
                name: place.name,
                address: place.formatted_address,
              };
            }

            return null;
          });
        });
      });
    } catch (error) {
      logger.error(`Failed to find place: ${placeName} in ${cityName}`, error);
      return null;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Singleton Instance
// ═══════════════════════════════════════════════════════════════════════════

const googlePlacesService = new GooglePlacesService();

export default googlePlacesService;

