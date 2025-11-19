/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Google Places Photos Service
 * 🔥 UPDATED: Получение НЕСКОЛЬКИХ фотографий для каждого POI
 * ═══════════════════════════════════════════════════════════════════════════
 */

import axios, { AxiosInstance } from 'axios';
import config from '../../../shared/config/env.js';
import logger from '../../../shared/utils/logger.js';
import retry from '../../../shared/utils/retry.js';
import rateLimiter from '../../../shared/utils/rate-limiter.js';

interface PlacePhoto {
  photo_reference: string;
  height: number;
  width: number;
  html_attributions: string[];
}

interface PlaceDetailsResponse {
  result: {
    name: string;
    photos?: PlacePhoto[];
    place_id: string;
  };
  status: string;
}

interface PhotoResult {
  url: string;
  source: string;
  alt_text: string;
  photo_reference: string;
  attribution?: string;
}

class GooglePlacesPhotosService {
  private client: AxiosInstance;
  private apiKey: string;
  private baseUrl = 'https://maps.googleapis.com/maps/api';

  constructor() {
    this.apiKey = config.GOOGLE_PLACES_API_KEY;
    this.client = axios.create({
      baseURL: this.baseUrl,
      timeout: 10000,
    });
  }

  /**
   * 🔥 Получить НЕСКОЛЬКО фотографий POI (до maxPhotos)
   * @param placeId - Google Place ID
   * @param maxPhotos - Максимальное количество фотографий (по умолчанию 3)
   */
  async getPOIPhotos(
    placeId: string,
    maxPhotos: number = 3
  ): Promise<PhotoResult[]> {
    if (!placeId) {
      logger.warn('No place_id provided for photos');
      return [];
    }

    try {
      return await rateLimiter.execute('google_places', async () => {
        return await retry(async () => {
          // 1. Получаем детали места с фотографиями
          const detailsResponse = await this.client.get<PlaceDetailsResponse>(
            '/place/details/json',
            {
              params: {
                place_id: placeId,
                fields: 'name,photos',
                key: this.apiKey,
              },
            }
          );

          if (detailsResponse.data.status !== 'OK') {
            logger.warn(
              `Google Places API error for ${placeId}: ${detailsResponse.data.status}`
            );
            return [];
          }

          const photos = detailsResponse.data.result.photos || [];

          if (photos.length === 0) {
            logger.warn(`No photos found for place_id: ${placeId}`);
            return [];
          }

          // 2. Берем первые N фотографий
          const selectedPhotos = photos.slice(0, maxPhotos);

          logger.info(
            `✓ Found ${photos.length} photos for ${detailsResponse.data.result.name}, ` +
              `using ${selectedPhotos.length}`
          );

          // 3. Генерируем URL для каждой фотографии
          const photoResults: PhotoResult[] = selectedPhotos.map(
            (photo, index) => {
              const photoUrl = this.getPhotoUrl(photo.photo_reference, 800);

              return {
                url: photoUrl,
                source: 'google_places',
                alt_text: `${detailsResponse.data.result.name} - Photo ${
                  index + 1
                }`,
                photo_reference: photo.photo_reference,
                attribution: photo.html_attributions.join(', '),
              };
            }
          );

          return photoResults;
        });
      });
    } catch (error) {
      logger.error(`Failed to get photos for place_id ${placeId}:`, error);
      return [];
    }
  }

  /**
   * Генерирует URL для фото по photo_reference
   */
  private getPhotoUrl(photoReference: string, maxWidth: number = 800): string {
    return `${this.baseUrl}/place/photo?maxwidth=${maxWidth}&photo_reference=${photoReference}&key=${this.apiKey}`;
  }

  /**
   * 🔥 Получить ОДНУ главную фотографию (для preview)
   */
  async getPrimaryPhoto(placeId: string): Promise<PhotoResult | null> {
    const photos = await this.getPOIPhotos(placeId, 1);
    return photos.length > 0 ? photos[0] : null;
  }
}

export default new GooglePlacesPhotosService();
