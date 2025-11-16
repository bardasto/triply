/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Hybrid Image Gallery Service
 * Google Places для POI + Unsplash для generic фото
 * ═══════════════════════════════════════════════════════════════════════════
 */

import unsplashService from './unsplash.service.js';
import googlePlacesPhotosService from './google-places-photos.service.js';
import logger from '../utils/logger.js';

interface ImageResult {
  url: string;
  source: string; // 'google_places' | 'unsplash'
  alt_text: string;
  photographer?: string;
  photographer_url?: string;
  attribution?: string;
}

class HybridImageGalleryService {
  /**
   * Получить hero image (Unsplash)
   */
  async getHeroImage(
    cityName: string,
    activityType: string
  ): Promise<ImageResult | null> {
    try {
      const photo = await unsplashService.getBestPhotoForTrip(
        cityName,
        activityType
      );

      if (!photo) return null;

      await unsplashService.trackDownload(photo.links.download_location);

      return {
        url: photo.urls.regular,
        source: 'unsplash',
        alt_text: `${cityName} ${activityType} hero image`,
        photographer: photo.user.name,
        photographer_url: photo.user.links.html,
      };
    } catch (error) {
      logger.error('Failed to fetch hero image:', error);
      return null;
    }
  }

  /**
   * Получить галерею города (Unsplash)
   */
  async getCityGallery(
    cityName: string,
    count: number = 4
  ): Promise<ImageResult[]> {
    try {
      logger.info(`Fetching ${count} city gallery images for ${cityName}...`);

      const queries = [
        `${cityName} cityscape`,
        `${cityName} architecture`,
        `${cityName} street`,
        `${cityName} landmark`,
      ];

      const images: ImageResult[] = [];

      for (let i = 0; i < Math.min(count, queries.length); i++) {
        try {
          const photos = await unsplashService.searchPhotos(queries[i], 1);

          if (photos && photos.length > 0) {
            const photo = photos[0];
            await unsplashService.trackDownload(photo.links.download_location);

            images.push({
              url: photo.urls.regular,
              source: 'unsplash',
              alt_text: `${cityName} - ${queries[i]}`,
              photographer: photo.user.name,
              photographer_url: photo.user.links.html,
            });
          }
        } catch (error) {
          logger.warn(`Failed to fetch image for query "${queries[i]}"`);
        }

        await this.sleep(1200); // Rate limiting for Unsplash
      }

      logger.info(`✓ Fetched ${images.length} city gallery images`);
      return images;
    } catch (error) {
      logger.error('Failed to fetch city gallery:', error);
      return [];
    }
  }

  /**
   * 🎯 КЛЮЧЕВОЕ ИЗМЕНЕНИЕ: Получить фото для дня itinerary
   * Приоритет: Google Places (POI) → Unsplash (fallback)
   */
  async getItineraryDayImages(
    dayTitle: string,
    cityName: string,
    pois: Array<{ place_id: string; name: string }>,
    count: number = 2
  ): Promise<ImageResult[]> {
    try {
      logger.info(`Fetching ${count} images for itinerary day: ${dayTitle}`);

      const images: ImageResult[] = [];

      // Strategy 1: Try Google Places Photos for POIs
      for (const poi of pois.slice(0, count)) {
        if (images.length >= count) break;

        try {
          const poiPhotos = await googlePlacesPhotosService.getPOIPhotos(
            poi.place_id,
            1
          );

          if (poiPhotos.length > 0) {
            images.push(poiPhotos[0]);
            logger.info(`  ✓ Got POI photo from Google Places: ${poi.name}`);
          }
        } catch (error) {
          logger.warn(`  Failed to get Google Places photo for ${poi.name}`);
        }

        await this.sleep(200);
      }

      // Strategy 2: Fallback to Unsplash if not enough POI photos
      if (images.length < count) {
        const remainingCount = count - images.length;
        logger.info(
          `  Fetching ${remainingCount} fallback images from Unsplash...`
        );

        for (const poi of pois.slice(0, remainingCount)) {
          try {
            const query = `${poi.name} ${cityName}`;
            const photos = await unsplashService.searchPhotos(query, 1);

            if (photos && photos.length > 0) {
              const photo = photos[0];
              await unsplashService.trackDownload(
                photo.links.download_location
              );

              images.push({
                url: photo.urls.regular,
                source: 'unsplash',
                alt_text: `${poi.name} in ${cityName}`,
                photographer: photo.user.name,
                photographer_url: photo.user.links.html,
              });

              logger.info(`  ✓ Got fallback photo from Unsplash: ${poi.name}`);
            }
          } catch (error) {
            logger.warn(`  Failed Unsplash fallback for ${poi.name}`);
          }

          await this.sleep(1200);
        }
      }

      logger.info(
        `✓ Fetched ${images.length} itinerary day images (${
          images.filter(i => i.source === 'google_places').length
        } from Google, ${
          images.filter(i => i.source === 'unsplash').length
        } from Unsplash)`
      );
      return images;
    } catch (error) {
      logger.error('Failed to fetch itinerary day images:', error);
      return [];
    }
  }

  /**
   * Получить полный набор фото для трипа (HYBRID)
   */
  async getCompleteTripGallery(
    cityName: string,
    activityType: string,
    itinerary: Array<{
      title: string;
      pois: Array<{ place_id: string; name: string }>;
    }>
  ): Promise<{
    heroImage: ImageResult | null;
    cityGallery: ImageResult[];
    itineraryImages: Map<number, ImageResult[]>;
  }> {
    logger.info('═══════════════════════════════════════════════════════');
    logger.info(`📸 Fetching HYBRID gallery for ${cityName}`);
    logger.info('═══════════════════════════════════════════════════════');

    // 1. Hero Image (Unsplash)
    logger.info('[1/3] Fetching hero image from Unsplash...');
    const heroImage = await this.getHeroImage(cityName, activityType);

    // 2. City Gallery (Unsplash)
    logger.info('[2/3] Fetching city gallery from Unsplash (4 images)...');
    const cityGallery = await this.getCityGallery(cityName, 4);

    // 3. Itinerary Images (Google Places + Unsplash fallback)
    logger.info(
      '[3/3] Fetching itinerary images (Google Places + Unsplash)...'
    );
    const itineraryImages = new Map<number, ImageResult[]>();

    for (let i = 0; i < itinerary.length; i++) {
      const day = itinerary[i];
      logger.info(`  Day ${i + 1}: ${day.title}`);

      const dayImages = await this.getItineraryDayImages(
        day.title,
        cityName,
        day.pois,
        2 // 2 images per day
      );

      itineraryImages.set(i + 1, dayImages);

      await this.sleep(500);
    }

    const totalGooglePhotos = Array.from(itineraryImages.values())
      .flat()
      .filter(img => img.source === 'google_places').length;

    const totalUnsplashPhotos = Array.from(itineraryImages.values())
      .flat()
      .filter(img => img.source === 'unsplash').length;

    logger.info('✅ HYBRID gallery complete');
    logger.info(`  Hero: ${heroImage ? '✓' : '✗'} (Unsplash)`);
    logger.info(`  City gallery: ${cityGallery.length} images (Unsplash)`);
    logger.info(`  Itinerary: ${itineraryImages.size} days`);
    logger.info(`    ├─ Google Places: ${totalGooglePhotos} photos`);
    logger.info(`    └─ Unsplash: ${totalUnsplashPhotos} photos`);

    return {
      heroImage,
      cityGallery,
      itineraryImages,
    };
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

export default new HybridImageGalleryService();
