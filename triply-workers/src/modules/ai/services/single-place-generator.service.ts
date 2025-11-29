/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Single Place Generator Service
 * Generates recommendations for single places (restaurants, hotels, etc.)
 * ═══════════════════════════════════════════════════════════════════════════
 */

import OpenAI from 'openai';
import { v4 as uuidv4 } from 'uuid';
import config from '../../../shared/config/env.js';
import logger from '../../../shared/utils/logger.js';
import retry from '../../../shared/utils/retry.js';
import rateLimiter from '../../../shared/utils/rate-limiter.js';
import googlePlacesService from '../../google-places/services/google-places.service.js';
import { SinglePlaceIntent } from './query-analyzer.service.js';

// ═══════════════════════════════════════════════════════════════════════════
// Types
// ═══════════════════════════════════════════════════════════════════════════

export interface SinglePlaceResult {
  id: string;
  type: 'single_place';
  place: {
    id: string;
    name: string;
    description: string;
    placeType: string;
    category: string;
    address: string;
    city: string;
    country: string;
    latitude: number;
    longitude: number;
    rating: number;
    reviewCount: number;
    priceLevel: string;
    priceRange: string;
    phone?: string;
    website?: string;
    openingHours?: {
      open_now?: boolean;
      weekday_text?: string[];
    };
    isOpenNow?: boolean;
    cuisineTypes?: string[];
    features?: string[];
    whyRecommended: string;
    imageUrl?: string;
    images?: string[];
    googlePlaceId?: string;
  };
  alternatives?: Array<{
    id: string;
    name: string;
    description: string;
    rating: number;
    priceLevel: string;
    whyAlternative: string;
    googlePlaceId?: string;
    imageUrl?: string;
    address?: string;
  }>;
  _meta: {
    originalQuery: string;
    intent: SinglePlaceIntent;
    generatedAt: string;
  };
}

interface GooglePlace {
  place_id: string;
  name: string;
  formatted_address?: string;
  geometry?: {
    location: {
      lat: number;
      lng: number;
    };
  };
  rating?: number;
  user_ratings_total?: number;
  price_level?: number;
  opening_hours?: {
    open_now?: boolean;
    weekday_text?: string[];
  };
  types?: string[];
  photos?: Array<{
    photo_reference: string;
  }>;
  website?: string;
  formatted_phone_number?: string;
}

// Price level maps
const PRICE_LEVEL_MAP: Record<number, string> = {
  0: 'Free',
  1: '€',
  2: '€€',
  3: '€€€',
  4: '€€€€',
};

const PRICE_RANGE_MAP: Record<number, string> = {
  0: 'Free',
  1: 'Budget-friendly',
  2: 'Moderate',
  3: 'Upscale',
  4: 'Fine Dining',
};

// ═══════════════════════════════════════════════════════════════════════════
// Single Place Generator Service
// ═══════════════════════════════════════════════════════════════════════════

class SinglePlaceGeneratorService {
  private client: OpenAI;

  constructor() {
    this.client = new OpenAI({
      apiKey: config.OPENAI_API_KEY,
    });

    logger.info('✅ Single Place Generator Service initialized');
  }

  /**
   * Generate a single place recommendation based on user intent
   */
  async generatePlace(intent: SinglePlaceIntent): Promise<SinglePlaceResult> {
    const startTime = Date.now();

    logger.info('═══════════════════════════════════════════════════════');
    logger.info('🏪 Starting Single Place Generation');
    logger.info(`   City: ${intent.city}`);
    logger.info(`   Place Type: ${intent.placeType}`);
    logger.info(`   Requirements: ${intent.specialRequirements?.join(', ') || 'none'}`);
    logger.info('═══════════════════════════════════════════════════════');

    try {
      // Step 1: Search for relevant places using Google Places
      const places = await this.searchPlaces(intent);

      if (places.length === 0) {
        throw new Error(`No ${intent.placeType}s found in ${intent.city} matching your criteria`);
      }

      // Step 2: Use AI to select the best match and generate recommendation
      const recommendation = await this.selectBestPlace(intent, places);

      logger.info(`📋 AI Selection: includeAlternatives=${recommendation.includeAlternatives}, alternatives count=${recommendation.alternatives?.length || 0}`);

      // Step 3: Get place details for the selected place
      const placeDetails = await this.getPlaceDetails(recommendation.selectedPlaceId);

      // Step 4: Build final result
      const result = await this.buildResult(intent, recommendation, placeDetails, places);

      const duration = Date.now() - startTime;
      logger.info(`✅ Single place generated in ${duration}ms`);
      logger.info(`   Recommended: ${result.place.name}`);

      return result;
    } catch (error) {
      logger.error('❌ Failed to generate single place:', error);
      throw error;
    }
  }

  /**
   * Search for places matching the intent
   */
  private async searchPlaces(intent: SinglePlaceIntent): Promise<GooglePlace[]> {
    const searchQueries = this.buildSearchQueries(intent);
    const allPlaces: GooglePlace[] = [];

    for (const query of searchQueries) {
      try {
        const places = await googlePlacesService.textSearch({
          query,
        });

        if (places && places.length > 0) {
          allPlaces.push(...(places as GooglePlace[]));
        }
      } catch (error) {
        logger.warn(`Search failed for query "${query}":`, error);
      }
    }

    // Deduplicate by place_id
    const uniquePlaces = Array.from(
      new Map(allPlaces.map(p => [p.place_id, p])).values()
    );

    logger.info(`Found ${uniquePlaces.length} unique places`);
    return uniquePlaces.slice(0, 10); // Limit to top 10
  }

  /**
   * Build search queries based on intent
   */
  private buildSearchQueries(intent: SinglePlaceIntent): string[] {
    const queries: string[] = [];
    const city = intent.city;

    // Base query
    const placeTypeMap: Record<string, string> = {
      restaurant: 'restaurant',
      cafe: 'cafe coffee shop',
      bar: 'bar',
      hotel: 'hotel',
      attraction: 'tourist attraction landmark',
      museum: 'museum',
      park: 'park garden',
      shop: 'shopping store',
      nightclub: 'nightclub club',
      spa: 'spa wellness',
      beach: 'beach',
      viewpoint: 'viewpoint observation deck',
    };

    const baseType = placeTypeMap[intent.placeType] || intent.placeType;

    // Add special requirements to query
    if (intent.specialRequirements && intent.specialRequirements.length > 0) {
      const requirements = intent.specialRequirements.join(' ');
      queries.push(`${requirements} ${baseType} in ${city}`);
    }

    // Add cuisine type for restaurants
    if (intent.cuisineType && intent.cuisineType.length > 0) {
      for (const cuisine of intent.cuisineType.slice(0, 2)) {
        queries.push(`${cuisine} ${baseType} in ${city}`);
      }
    }

    // Add criteria-based query
    if (intent.criteria && intent.criteria.length > 0) {
      const criteria = intent.criteria.slice(0, 3).join(' ');
      queries.push(`${criteria} ${baseType} in ${city}`);
    }

    // Fallback base query
    if (queries.length === 0) {
      queries.push(`best ${baseType} in ${city}`);
    }

    return queries.slice(0, 3); // Limit to 3 search queries
  }

  /**
   * Use AI to select the best place from search results
   */
  private async selectBestPlace(
    intent: SinglePlaceIntent,
    places: GooglePlace[]
  ): Promise<{
    selectedPlaceId: string;
    description: string;
    whyRecommended: string;
    alternatives: Array<{ placeId: string; description: string }>;
    includeAlternatives: boolean
  }> {
    return await rateLimiter.execute('openai', async () => {
      return retry(async () => {
        const placesJson = places.map(p => ({
          id: p.place_id,
          name: p.name,
          rating: p.rating || 0,
          reviewCount: p.user_ratings_total || 0,
          priceLevel: p.price_level,
          address: p.formatted_address,
          types: p.types,
          isOpenNow: p.opening_hours?.open_now,
        }));

        const response = await this.client.chat.completions.create({
          model: config.OPENAI_MODEL,
          messages: [
            {
              role: 'system',
              content: `You are an expert local guide who recommends the PERFECT place based on user requirements.

TASK: Select the BEST place from the list that matches the user's criteria.

USER REQUIREMENTS:
- Place Type: ${intent.placeType}
- City: ${intent.city}
- Special Requirements: ${intent.specialRequirements?.join(', ') || 'none'}
- Cuisine Type: ${intent.cuisineType?.join(', ') || 'any'}
- Budget: ${intent.budget || 'any'}
- Criteria: ${intent.criteria?.join(', ') || 'best available'}

SELECTION CRITERIA:
1. Match special requirements (e.g., if user wants Michelin, prioritize fine dining)
2. Consider rating and review count
3. Match price level to budget
4. Consider opening hours if relevant
5. Match cuisine type for restaurants

ALTERNATIVES LOGIC:
- ALWAYS include alternatives (includeAlternatives: true) for these place types:
  restaurant, cafe, bar, hotel, shop, nightclub, spa
- These are category-based searches where users benefit from seeing options
- Do NOT include alternatives (includeAlternatives: false) ONLY for:
  - Specific named landmarks (e.g., "Louvre Museum", "Eiffel Tower", "Colosseum")
  - Unique monuments or viewpoints
  - Museums with unique collections

Return JSON:
{
  "selectedPlaceId": "the place_id of the best match",
  "description": "A detailed 4-6 sentence description of the place. Include atmosphere, signature dishes/features, history if notable, what makes it special, and what visitors can expect. Make it engaging and informative.",
  "whyRecommended": "1-2 sentences explaining why this is the perfect choice for the user",
  "includeAlternatives": true/false,
  "alternatives": [
    { "placeId": "place_id1", "description": "2-3 sentence description of this alternative. What makes it unique, its atmosphere, and why someone might prefer it." },
    { "placeId": "place_id2", "description": "2-3 sentence description of this alternative. What makes it unique, its atmosphere, and why someone might prefer it." }
  ]
}`,
            },
            {
              role: 'user',
              content: `User query: "${intent.rawQuery}"

Available places:
${JSON.stringify(placesJson, null, 2)}

Select the best place that matches the user's requirements.`,
            },
          ],
          temperature: 0.3,
          max_tokens: 800,
          response_format: { type: 'json_object' },
        });

        const content = response.choices[0]?.message?.content;
        if (!content) {
          throw new Error('Empty response from OpenAI');
        }

        return JSON.parse(content);
      });
    });
  }

  /**
   * Get detailed information about a place
   */
  private async getPlaceDetails(placeId: string): Promise<GooglePlace | null> {
    try {
      const details = await googlePlacesService.getPlaceDetails(placeId);
      return details;
    } catch (error) {
      logger.warn(`Failed to get place details for ${placeId}:`, error);
      return null;
    }
  }

  /**
   * Helper to build photo URL
   */
  private buildPhotoUrl(photoReference: string): string {
    return `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=${photoReference}&key=${config.GOOGLE_PLACES_API_KEY}`;
  }

  /**
   * Build the final result object
   */
  private async buildResult(
    intent: SinglePlaceIntent,
    recommendation: {
      selectedPlaceId: string;
      description: string;
      whyRecommended: string;
      alternatives: Array<{ placeId: string; description: string }>;
      includeAlternatives?: boolean
    },
    placeDetails: GooglePlace | null,
    allPlaces: GooglePlace[]
  ): Promise<SinglePlaceResult> {
    // Find the selected place from our search results
    const selectedPlace = allPlaces.find(p => p.place_id === recommendation.selectedPlaceId) || allPlaces[0];

    // Use placeDetails if available (has more info), otherwise use selectedPlace
    // Cast to any to merge properties from both sources
    const detailsData = placeDetails as any;
    const searchData = selectedPlace as any;

    // Merge data - prefer details over search results
    const place = {
      place_id: detailsData?.place_id || searchData?.place_id,
      name: detailsData?.name || searchData?.name,
      formatted_address: detailsData?.formatted_address || searchData?.formatted_address,
      geometry: detailsData?.geometry || searchData?.geometry,
      rating: detailsData?.rating || searchData?.rating,
      user_ratings_total: detailsData?.user_ratings_total || searchData?.user_ratings_total,
      price_level: detailsData?.price_level ?? searchData?.price_level,
      opening_hours: detailsData?.opening_hours || searchData?.opening_hours,
      photos: detailsData?.photos || searchData?.photos,
      website: detailsData?.website || searchData?.website,
      formatted_phone_number: detailsData?.formatted_phone_number || searchData?.formatted_phone_number,
    };

    // Get image URLs - up to 10 photos
    let imageUrl: string | undefined;
    const images: string[] = [];

    if (place.photos && place.photos.length > 0) {
      // First photo as main image
      imageUrl = this.buildPhotoUrl(place.photos[0].photo_reference);

      // Get up to 10 photos for gallery
      const maxPhotos = Math.min(place.photos.length, 10);
      for (let i = 0; i < maxPhotos; i++) {
        images.push(this.buildPhotoUrl(place.photos[i].photo_reference));
      }
    }

    // Build opening hours in format expected by Flutter
    // Flutter expects: { open_now: bool, weekday_text: string[] }
    let openingHoursFormatted: { open_now?: boolean; weekday_text?: string[] } | undefined;
    if (place.opening_hours) {
      openingHoursFormatted = {
        open_now: place.opening_hours.open_now,
        weekday_text: place.opening_hours.weekday_text,
      };
    }

    // Build alternatives only if AI decided to include them
    const shouldIncludeAlternatives = recommendation.includeAlternatives !== false;
    let alternatives: Array<{
      id: string;
      name: string;
      description: string;
      rating: number;
      reviewCount: number;
      priceLevel: string;
      priceRange: string;
      whyAlternative: string;
      googlePlaceId: string;
      imageUrl?: string;
      images: string[];
      address: string;
      city: string;
      country: string;
      placeType: string;
      openingHours?: { open_now?: boolean; weekday_text?: string[] };
      isOpenNow?: boolean;
      phone?: string;
      website?: string;
    }> = [];

    if (shouldIncludeAlternatives && recommendation.alternatives.length > 0) {
      // Get details for each alternative in parallel
      const altDetailsPromises = recommendation.alternatives.map(async (altRec) => {
        const altId = altRec.placeId;
        const altDescription = altRec.description || 'Great alternative option';

        const altFromSearch = allPlaces.find(p => p.place_id === altId);
        if (!altFromSearch) return null;

        try {
          const altDetails = await this.getPlaceDetails(altId);
          const altData = altDetails || altFromSearch;

          // Build images for alternative
          let altImageUrl: string | undefined;
          const altImages: string[] = [];
          if (altData.photos && altData.photos.length > 0) {
            altImageUrl = this.buildPhotoUrl(altData.photos[0].photo_reference);
            const maxAltPhotos = Math.min(altData.photos.length, 5);
            for (let i = 0; i < maxAltPhotos; i++) {
              altImages.push(this.buildPhotoUrl(altData.photos[i].photo_reference));
            }
          }

          // Build opening hours for alternative
          let altOpeningHours: { open_now?: boolean; weekday_text?: string[] } | undefined;
          if (altData.opening_hours) {
            altOpeningHours = {
              open_now: altData.opening_hours.open_now,
              weekday_text: altData.opening_hours.weekday_text,
            };
          }

          return {
            id: uuidv4(),
            name: altData.name,
            description: altDescription,
            rating: altData.rating || 0,
            reviewCount: altData.user_ratings_total || 0,
            priceLevel: PRICE_LEVEL_MAP[altData.price_level ?? 2] || '€€',
            priceRange: PRICE_RANGE_MAP[altData.price_level ?? 2] || 'Moderate',
            whyAlternative: altDescription,
            googlePlaceId: altData.place_id,
            imageUrl: altImageUrl,
            images: altImages,
            address: altData.formatted_address || '',
            city: intent.city,
            country: intent.country || '',
            placeType: intent.placeType,
            openingHours: altOpeningHours,
            isOpenNow: altData.opening_hours?.open_now,
            phone: (altData as any).formatted_phone_number,
            website: (altData as any).website,
          };
        } catch (error) {
          logger.warn(`Failed to get details for alternative ${altId}:`, error);
          return null;
        }
      });

      const altResults = await Promise.all(altDetailsPromises);
      alternatives = altResults.filter((alt): alt is NonNullable<typeof alt> => alt !== null);
      logger.info(`📸 Got details for ${alternatives.length} alternatives`);
    }

    logger.info(`📸 Place photos: ${place.photos?.length || 0}, Images built: ${images.length}`);

    return {
      id: uuidv4(),
      type: 'single_place',
      place: {
        id: uuidv4(),
        name: place.name,
        description: recommendation.description,
        placeType: intent.placeType,
        category: intent.placeType,
        address: place.formatted_address || '',
        city: intent.city,
        country: intent.country || '',
        latitude: place.geometry?.location?.lat || 0,
        longitude: place.geometry?.location?.lng || 0,
        rating: place.rating || 0,
        reviewCount: place.user_ratings_total || 0,
        priceLevel: PRICE_LEVEL_MAP[place.price_level ?? 2] || '€€',
        priceRange: PRICE_RANGE_MAP[place.price_level ?? 2] || 'Moderate',
        phone: place.formatted_phone_number,
        website: place.website,
        openingHours: openingHoursFormatted,
        isOpenNow: place.opening_hours?.open_now,
        cuisineTypes: intent.cuisineType,
        features: intent.specialRequirements,
        whyRecommended: recommendation.whyRecommended,
        imageUrl,
        images,
        googlePlaceId: place.place_id,
      },
      alternatives,
      _meta: {
        originalQuery: intent.rawQuery,
        intent,
        generatedAt: new Date().toISOString(),
      },
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Singleton Instance
// ═══════════════════════════════════════════════════════════════════════════

const singlePlaceGeneratorService = new SinglePlaceGeneratorService();

export default singlePlaceGeneratorService;
