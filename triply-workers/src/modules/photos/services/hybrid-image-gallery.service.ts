/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Hybrid Image Gallery Service
 * 🔥 UPDATED: Несколько фотографий для каждого места (для details screen)
 * ═══════════════════════════════════════════════════════════════════════════
 */

import unsplashService from '../../external-apis/services/unsplash.service.js';
import googlePlacesPhotosService from '../../google-places/services/google-places-photos.service.js';
import googlePlacesService from '../../google-places/services/google-places.service.js';
import logger from '../../../shared/utils/logger.js';

interface ImageResult {
  url: string;
  source: string;
  alt_text: string;
  photographer?: string;
  photographer_url?: string;
  attribution?: string;
}

class HybridImageGalleryService {
  /**
   * 🖼️ Hero image - ТОЛЬКО Unsplash (для карточки трипа)
   */
  async getHeroImage(
    cityName: string,
    activityType: string
  ): Promise<ImageResult | null> {
    try {
      logger.info(`📸 Fetching hero image from Unsplash for ${cityName}...`);

      const photo = await unsplashService.getBestPhotoForTrip(
        cityName,
        activityType
      );

      if (!photo) {
        logger.warn('⚠️ No Unsplash photo found for hero');
        return null;
      }

      await unsplashService.trackDownload(photo.links.download_location);

      logger.info(`✓ Hero image from Unsplash: ${photo.user.name}`);
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
   * 🏙️ City gallery - ТОЛЬКО Google Places (landmarks)
   */
  async getCityGallery(
    cityName: string,
    count: number = 4
  ): Promise<ImageResult[]> {
    try {
      logger.info(
        `📸 Fetching ${count} city gallery images from Google Places...`
      );

      const queries = [
        `${cityName} landmark`,
        `${cityName} famous attraction`,
        `${cityName} architecture`,
        `${cityName} square`,
        `${cityName} monument`,
      ];

      const images: ImageResult[] = [];
      const seenPlaceIds = new Set<string>();

      for (const query of queries) {
        if (images.length >= count) break;

        try {
          const places = await googlePlacesService.searchPlaces(query, 2);

          for (const place of places) {
            if (images.length >= count) break;
            if (!place.place_id || seenPlaceIds.has(place.place_id)) continue;

            const photos = await googlePlacesPhotosService.getPOIPhotos(
              place.place_id,
              1
            );

            if (photos.length > 0) {
              images.push(photos[0]);
              seenPlaceIds.add(place.place_id);
              logger.info(`  ✓ City image ${images.length}: ${place.name}`);
            }
          }
        } catch (error) {
          logger.warn(`Failed query "${query}"`);
        }

        await this.sleep(400);
      }

      logger.info(
        `✓ Fetched ${images.length}/${count} city gallery images (100% Google Places)`
      );
      return images.slice(0, count);
    } catch (error) {
      logger.error('Failed to fetch city gallery:', error);
      return [];
    }
  }

  /**
   * 🗺️ Itinerary images - получаем НЕСКОЛЬКО фотографий для каждого места
   * Uses parallel batches for faster loading
   * @param photosPerPlace - количество фотографий на место (по умолчанию 7)
   */
  async getItineraryDayImages(
    dayTitle: string,
    cityName: string,
    places: Array<{
      place_id: string;
      name: string;
      google_place_id?: string;
    }>,
    photosPerPlace: number = 7
  ): Promise<Map<string, ImageResult[]>> {
    try {
      logger.info(
        `📸 Fetching ${photosPerPlace} photos for ${places.length} places in "${dayTitle}" (parallel batches)`
      );

      const placePhotosMap = new Map<string, ImageResult[]>();

      // Process in parallel batches of 5 to avoid rate limits
      const BATCH_SIZE = 5;
      for (let i = 0; i < places.length; i += BATCH_SIZE) {
        const batch = places.slice(i, i + BATCH_SIZE);

        const batchResults = await Promise.allSettled(
          batch.map(async (place) => {
            const placeId = place.google_place_id || place.place_id;

            if (!placeId) {
              return { name: place.name, photos: [] as ImageResult[] };
            }

            try {
              const photos = await googlePlacesPhotosService.getPOIPhotos(
                placeId,
                photosPerPlace
              );
              return { name: place.name, photos };
            } catch (error) {
              logger.warn(`  ⚠️ Failed to get photos for "${place.name}"`);
              return { name: place.name, photos: [] as ImageResult[] };
            }
          })
        );

        // Collect results
        for (const result of batchResults) {
          if (result.status === 'fulfilled') {
            const { name, photos } = result.value;
            placePhotosMap.set(name, photos);
            if (photos.length > 0) {
              logger.info(`  ✓ Got ${photos.length} photos: ${name}`);
            }
          }
        }

        // Small delay between batches
        if (i + BATCH_SIZE < places.length) {
          await this.sleep(200);
        }
      }

      const totalPhotos = Array.from(placePhotosMap.values()).reduce(
        (sum, photos) => sum + photos.length,
        0
      );

      logger.info(
        `✓ Fetched ${totalPhotos} total photos for ${places.length} places ` +
          `(avg ${(totalPhotos / places.length).toFixed(1)} per place)`
      );

      return placePhotosMap;
    } catch (error) {
      logger.error('Failed to fetch itinerary day images:', error);
      return new Map();
    }
  }

  /**
   * 📸 Complete trip gallery
   */
  async getCompleteTripGallery(
    cityName: string,
    activityType: string,
    itinerary: Array<{
      title: string;
      pois: Array<{
        place_id: string;
        name: string;
        google_place_id?: string;
      }>;
    }>
  ): Promise<{
    heroImage: ImageResult | null;
    cityGallery: ImageResult[];
    itineraryImages: Map<number, Map<string, ImageResult[]>>; // ✅ Nested Map!
  }> {
    logger.info('═══════════════════════════════════════════════════════');
    logger.info(`📸 Fetching COMPLETE gallery for ${cityName}`);
    logger.info('   Hero: Unsplash | POIs: Multiple Google Photos each');
    logger.info('═══════════════════════════════════════════════════════');

    // [1] Hero image - UNSPLASH
    logger.info('[1/3] Fetching hero image from Unsplash...');
    const heroImage = await this.getHeroImage(cityName, activityType);

    // [2] City gallery - GOOGLE PLACES
    logger.info('[2/3] Fetching city gallery (4 images) from Google Places...');
    const cityGallery = await this.getCityGallery(cityName, 4);

    // [3] Itinerary images - GOOGLE PLACES (MULTIPLE PER PLACE)
    logger.info('[3/3] Fetching itinerary images (7 photos per place)...');
    const itineraryImages = new Map<number, Map<string, ImageResult[]>>();

    for (let i = 0; i < itinerary.length; i++) {
      const day = itinerary[i];
      logger.info(`  Day ${i + 1}: ${day.title} (${day.pois.length} places)`);

      // ✅ Получаем 7 фотографий для КАЖДОГО места в дне
      const dayPlacePhotos = await this.getItineraryDayImages(
        day.title,
        cityName,
        day.pois,
        7 // 7 photos per place
      );

      itineraryImages.set(i + 1, dayPlacePhotos);
      await this.sleep(600);
    }

    const totalPlaces = itinerary.reduce(
      (sum, day) => sum + day.pois.length,
      0
    );
    const totalGooglePhotos =
      cityGallery.length +
      Array.from(itineraryImages.values())
        .flatMap(dayMap => Array.from(dayMap.values()))
        .flat().length;

    logger.info('═══════════════════════════════════════════════════════');
    logger.info('✅ COMPLETE GALLERY READY');
    logger.info(`   Hero (Unsplash): ${heroImage ? '✓' : '✗'}`);
    logger.info(`   City gallery (Google): ${cityGallery.length} photos`);
    logger.info(`   Itinerary days: ${itineraryImages.size}`);
    logger.info(`   Total places: ${totalPlaces}`);
    logger.info(`   Total Google Places photos: ${totalGooglePhotos}`);
    logger.info('═══════════════════════════════════════════════════════');

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
