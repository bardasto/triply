/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Unsplash Service - Production Ready
 * Поиск высококачественных изображений для трипов
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

export interface UnsplashPhoto {
  id: string;
  created_at: string;
  width: number;
  height: number;
  color: string;
  description: string | null;
  alt_description: string | null;
  urls: {
    raw: string;
    full: string;
    regular: string;
    small: string;
    thumb: string;
  };
  links: {
    self: string;
    html: string;
    download: string;
    download_location: string;
  };
  user: {
    id: string;
    username: string;
    name: string;
    portfolio_url: string | null;
    links: {
      html: string;
    };
  };
  likes?: number;
}

export interface SearchParams {
  query: string;
  page?: number;
  perPage?: number;
  orientation?: 'landscape' | 'portrait' | 'squarish';
  color?: string;
  orderBy?: 'relevant' | 'latest';
}

// ═══════════════════════════════════════════════════════════════════════════
// Unsplash Service Class
// ═══════════════════════════════════════════════════════════════════════════

class UnsplashService {
  private client: AxiosInstance;
  private accessKey: string;
  private baseUrl: string = 'https://api.unsplash.com';

  constructor() {
    this.accessKey = config.UNSPLASH_ACCESS_KEY;

    if (!this.accessKey) {
      throw new Error('UNSPLASH_ACCESS_KEY is not configured');
    }

    this.client = axios.create({
      baseURL: this.baseUrl,
      timeout: 15000,
      headers: {
        Authorization: `Client-ID ${this.accessKey}`,
        'Accept-Version': 'v1',
      },
    });

    logger.info('✅ Unsplash Service initialized');
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Search Photos (Primary Method)
  // ═════════════════════════════════════════════════════════════════════════

  async searchPhotos(
    query: string,
    perPage: number = 10,
    options?: Partial<SearchParams>
  ): Promise<UnsplashPhoto[]> {
    const startTime = Date.now();

    try {
      return await rateLimiter.execute('unsplash', async () => {
        return await circuitBreakers.unsplash.execute(async () => {
          return await retry(async () => {
            const response = await this.client.get('/search/photos', {
              params: {
                query,
                page: options?.page || 1,
                per_page: perPage,
                orientation: options?.orientation || 'landscape',
                color: options?.color,
                order_by: options?.orderBy || 'relevant',
                content_filter: 'high',
              },
            });

            const duration = Date.now() - startTime;
            logApiCall(
              'unsplash',
              'GET',
              '/search/photos',
              response.status,
              duration
            );

            // Track rate limits
            const remaining = response.headers['x-ratelimit-remaining'];
            if (remaining && parseInt(remaining) < 10) {
              logger.warn(`⚠️ Unsplash rate limit low: ${remaining} remaining`);
            }

            const photos = response.data.results as UnsplashPhoto[];

            logger.debug(`Found ${photos.length} photos for query: "${query}"`);

            return photos;
          });
        });
      });
    } catch (error) {
      logger.error(`Failed to search photos for query "${query}":`, error);
      return [];
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Search Photos (Legacy compatibility - with SearchParams object)
  // ═════════════════════════════════════════════════════════════════════════

  async searchPhotosWithParams(params: SearchParams): Promise<UnsplashPhoto[]> {
    return this.searchPhotos(params.query, params.perPage, params);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Get Random Photo
  // ═════════════════════════════════════════════════════════════════════════

  async getRandomPhoto(
    query?: string,
    count: number = 1
  ): Promise<UnsplashPhoto | UnsplashPhoto[] | null> {
    const startTime = Date.now();

    try {
      return await rateLimiter.execute('unsplash', async () => {
        return await retry(async () => {
          const response = await this.client.get('/photos/random', {
            params: {
              query,
              count: count > 1 ? count : undefined,
              orientation: 'landscape',
              content_filter: 'high',
            },
          });

          const duration = Date.now() - startTime;
          logApiCall(
            'unsplash',
            'GET',
            '/photos/random',
            response.status,
            duration
          );

          if (count > 1) {
            return response.data as UnsplashPhoto[];
          }
          return response.data as UnsplashPhoto;
        });
      });
    } catch (error) {
      logger.error('Failed to get random photo:', error);
      return null;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Track Download (Required by Unsplash API Guidelines)
  // ═════════════════════════════════════════════════════════════════════════

  async trackDownload(downloadLocation: string): Promise<void> {
    try {
      // Use download_location from photo object, not the download link
      await this.client.get(downloadLocation);
      logger.debug('✓ Tracked Unsplash download');
    } catch (error) {
      logger.warn('⚠️ Failed to track Unsplash download:', error);
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Get Best Photo for Trip (Smart Selection)
  // ═════════════════════════════════════════════════════════════════════════

  async getBestPhotoForTrip(
    city: string,
    activity: string,
    fallbackQuery?: string
  ): Promise<UnsplashPhoto | null> {
    logger.info(`Searching best photo for: ${city} + ${activity}`);

    // Strategy 1: Primary query (city + activity)
    const primaryQuery = `${city} ${activity} travel`;
    let photos = await this.searchPhotos(primaryQuery, 5);

    if (photos.length > 0) {
      const bestPhoto = this.selectBestPhoto(photos);
      logger.info(`✓ Found photo with primary query: "${primaryQuery}"`);
      return bestPhoto;
    }

    // Strategy 2: Fallback query if provided
    if (fallbackQuery) {
      logger.info(`Trying fallback query: "${fallbackQuery}"`);
      photos = await this.searchPhotos(fallbackQuery, 5);

      if (photos.length > 0) {
        const bestPhoto = this.selectBestPhoto(photos);
        logger.info(`✓ Found photo with fallback query`);
        return bestPhoto;
      }
    }

    // Strategy 3: City only
    logger.info(`Trying city-only query: "${city}"`);
    photos = await this.searchPhotos(`${city} landmark`, 5);

    if (photos.length > 0) {
      const bestPhoto = this.selectBestPhoto(photos);
      logger.info(`✓ Found photo with city-only query`);
      return bestPhoto;
    }

    // Strategy 4: Generic city
    photos = await this.searchPhotos(city, 5);

    if (photos.length > 0) {
      const bestPhoto = this.selectBestPhoto(photos);
      logger.info(`✓ Found photo with generic city query`);
      return bestPhoto;
    }

    logger.warn(`❌ No photos found for ${city}`);
    return null;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Batch Search for Multiple Queries
  // ═════════════════════════════════════════════════════════════════════════

  async batchSearchPhotos(
    queries: string[],
    perQueryLimit: number = 1
  ): Promise<Map<string, UnsplashPhoto[]>> {
    logger.info(`Batch searching ${queries.length} queries...`);

    const results = new Map<string, UnsplashPhoto[]>();

    for (const query of queries) {
      try {
        const photos = await this.searchPhotos(query, perQueryLimit);
        results.set(query, photos);

        // Rate limiting between queries
        await this.sleep(500);
      } catch (error) {
        logger.error(`Failed batch query "${query}":`, error);
        results.set(query, []);
      }
    }

    logger.info(`✓ Batch search complete: ${results.size} queries processed`);
    return results;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Helper: Select Best Photo (Quality-based Selection)
  // ═════════════════════════════════════════════════════════════════════════

  private selectBestPhoto(photos: UnsplashPhoto[]): UnsplashPhoto {
    if (photos.length === 0) {
      throw new Error('No photos to select from');
    }

    // Score each photo based on multiple criteria
    const scoredPhotos = photos.map(photo => {
      let score = 0;

      // Resolution score (higher is better)
      const totalPixels = photo.width * photo.height;
      if (totalPixels > 3000000) score += 3; // 3MP+
      else if (totalPixels > 2000000) score += 2; // 2MP+
      else if (totalPixels > 1000000) score += 1; // 1MP+

      // Aspect ratio score (prefer landscape ~16:9)
      const aspectRatio = photo.width / photo.height;
      if (aspectRatio >= 1.5 && aspectRatio <= 1.8) score += 2; // Near 16:9
      else if (aspectRatio >= 1.3 && aspectRatio <= 2.0) score += 1; // Reasonable

      // Likes score (popularity indicator)
      if (photo.likes) {
        if (photo.likes > 1000) score += 3;
        else if (photo.likes > 500) score += 2;
        else if (photo.likes > 100) score += 1;
      }

      // Description score (better metadata)
      if (photo.description || photo.alt_description) {
        score += 1;
      }

      return { photo, score };
    });

    // Sort by score (descending) and return the best
    scoredPhotos.sort((a, b) => b.score - a.score);

    const bestPhoto = scoredPhotos[0].photo;

    logger.debug(
      `Selected photo ${bestPhoto.id} with score ${scoredPhotos[0].score}`
    );

    return bestPhoto;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Helper: Format Photo Metadata for Database
  // ═════════════════════════════════════════════════════════════════════════

  formatPhotoMetadata(photo: UnsplashPhoto) {
    return {
      url: photo.urls.regular,
      source: 'unsplash',
      external_id: photo.id,
      photographer_name: photo.user.name,
      photographer_url: photo.user.links.html,
      license: 'Unsplash License',
      width: photo.width,
      height: photo.height,
      aspect_ratio: photo.width / photo.height,
      alt_text: photo.alt_description || photo.description || '',
      color: photo.color,
      likes: photo.likes || 0,
    };
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Helper: Sleep (Rate Limiting)
  // ═════════════════════════════════════════════════════════════════════════

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Health Check
  // ═════════════════════════════════════════════════════════════════════════

  async healthCheck(): Promise<boolean> {
    try {
      const response = await this.client.get('/');
      return response.status === 200;
    } catch (error) {
      logger.error('Unsplash health check failed:', error);
      return false;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Singleton Instance
// ═══════════════════════════════════════════════════════════════════════════

const unsplashService = new UnsplashService();

export default unsplashService;
