/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Flexible Trip Generator Service
 * Generates trips from free-form user queries without templates
 * ═══════════════════════════════════════════════════════════════════════════
 */

import OpenAI from 'openai';
import config from '../../../shared/config/env.js';
import logger from '../../../shared/utils/logger.js';
import retry from '../../../shared/utils/retry.js';
import rateLimiter from '../../../shared/utils/rate-limiter.js';
import queryAnalyzerService, { TripIntent } from './query-analyzer.service.js';
import googlePlacesService from '../../google-places/services/google-places.service.js';
import hybridImageGalleryService from '../../photos/services/hybrid-image-gallery.service.js';
import { v4 as uuidv4 } from 'uuid';

// ═══════════════════════════════════════════════════════════════════════════
// Types
// ═══════════════════════════════════════════════════════════════════════════

export interface FlexibleTripParams {
  userQuery: string;
}

export interface FlexibleTripResult {
  id: string;
  title: string;
  description: string;
  city: string;
  country: string;
  duration: string;
  durationDays: number;
  price: string;
  currency: string;
  itinerary: any[];
  highlights: string[];
  includes: string[];
  images: any[];
  heroImageUrl: string | null;
  estimatedCostMin: number;
  estimatedCostMax: number;
  activityType: string;
  bestSeason: string[];
  tripIntent: TripIntent;
  rating: number;
  reviews: number;
}

interface DynamicPlace {
  placeId: string;
  name: string;
  category: string;
  lat: number;
  lng: number;
  rating?: number;
  address?: string;
  photoReference?: string;
}

// ═══════════════════════════════════════════════════════════════════════════
// Flexible Trip Generator Service
// ═══════════════════════════════════════════════════════════════════════════

class FlexibleTripGeneratorService {
  private client: OpenAI;

  constructor() {
    this.client = new OpenAI({
      apiKey: config.OPENAI_API_KEY,
    });

    logger.info('✅ Flexible Trip Generator Service initialized');
  }

  /**
   * Generate trip from free-form user query
   */
  async generateTrip(params: FlexibleTripParams): Promise<FlexibleTripResult> {
    const startTime = Date.now();
    logger.info('═══════════════════════════════════════════════════════');
    logger.info(`🎯 Generating flexible trip from query: "${params.userQuery}"`);
    logger.info('═══════════════════════════════════════════════════════');

    // Step 1: Analyze user query to extract intent
    logger.info('[1/6] Analyzing user query...');
    const tripIntent = await queryAnalyzerService.analyzeQuery(params.userQuery);
    logger.info(`✓ Intent extracted: ${tripIntent.city}, ${tripIntent.durationDays} days`);
    logger.info(`  Activities: ${tripIntent.activities.join(', ')}`);
    logger.info(`  Vibe: ${tripIntent.vibe.join(', ')}`);

    // Step 2: Validate city
    logger.info('[2/6] Validating city...');
    const cityInfo = await queryAnalyzerService.validateCity(tripIntent.city);
    if (!cityInfo) {
      throw new Error(`City "${tripIntent.city}" not found or invalid`);
    }
    logger.info(`✓ City validated: ${cityInfo.city}, ${cityInfo.country}`);

    // Step 3: Search for relevant places dynamically using Google Places
    logger.info('[3/6] Searching for relevant places...');
    const places = await this.searchRelevantPlaces(
      cityInfo.city,
      tripIntent.activities,
      tripIntent.specificInterests || []
    );
    logger.info(`✓ Found ${places.length} relevant places`);

    // Step 4: Generate itinerary with AI (no templates!)
    logger.info('[4/6] Generating personalized itinerary with AI...');
    const tripSkeleton = await this.generateFlexibleItinerary({
      city: cityInfo.city,
      country: cityInfo.country,
      durationDays: tripIntent.durationDays,
      activities: tripIntent.activities,
      vibe: tripIntent.vibe,
      specificInterests: tripIntent.specificInterests || [],
      places,
      userQuery: params.userQuery,
      budget: tripIntent.budget,
    });
    logger.info(`✓ Itinerary generated with ${tripSkeleton.itinerary.length} days`);

    // Step 5: Fetch images
    logger.info('[5/6] Fetching images...');
    const gallery = await this.fetchImages(cityInfo.city, tripSkeleton.itinerary, tripIntent);
    logger.info(`✓ Images fetched: ${gallery.allImages.length} total`);

    // Step 6: Build final trip object
    logger.info('[6/6] Building final trip object...');
    const trip = this.buildTripObject(tripSkeleton, cityInfo, tripIntent, gallery);

    const duration = Date.now() - startTime;
    logger.info('═══════════════════════════════════════════════════════');
    logger.info(`✅ Trip generated successfully in ${(duration / 1000).toFixed(1)}s`);
    logger.info(`   Title: ${trip.title}`);
    logger.info(`   Duration: ${trip.durationDays} days`);
    logger.info(`   Places: ${trip.itinerary.reduce((sum, day) => sum + day.places.length, 0)}`);
    logger.info('═══════════════════════════════════════════════════════');

    return trip;
  }

  /**
   * Search for relevant places using Google Places API
   */
  private async searchRelevantPlaces(
    city: string,
    activities: string[],
    specificInterests: string[]
  ): Promise<DynamicPlace[]> {
    const allPlaces: DynamicPlace[] = [];
    const searchQueries = this.buildSearchQueries(activities, specificInterests);

    logger.info(`  Searching with ${searchQueries.length} queries...`);

    for (const query of searchQueries.slice(0, 10)) {
      // Limit to 10 searches to avoid rate limits
      try {
        logger.info(`    - "${query}" in ${city}`);

        // Use Google Places Text Search
        const results = await googlePlacesService.textSearch({
          query: `${query} in ${city}`,
        });

        if (results && results.length > 0) {
          const places = results.slice(0, 5).map((place: any) => ({
            placeId: place.place_id,
            name: place.name,
            category: this.categorizePlaceFromTypes(place.types || []),
            lat: place.geometry?.location?.lat || 0,
            lng: place.geometry?.location?.lng || 0,
            rating: place.rating,
            address: place.formatted_address,
            photoReference: place.photos?.[0]?.photo_reference,
          }));

          allPlaces.push(...places);
          logger.info(`      Found ${places.length} places`);
        }

        // Rate limiting
        await this.sleep(500);
      } catch (error) {
        logger.warn(`    ⚠️ Failed to search for "${query}":`, error);
      }
    }

    // Remove duplicates by place_id
    const uniquePlaces = Array.from(
      new Map(allPlaces.map(p => [p.placeId, p])).values()
    );

    logger.info(`  Total unique places found: ${uniquePlaces.length}`);
    return uniquePlaces;
  }

  /**
   * Build search queries from activities and interests
   */
  private buildSearchQueries(activities: string[], specificInterests: string[]): string[] {
    const queries: string[] = [];

    // Add activities as search queries
    queries.push(...activities);

    // Add specific interests
    queries.push(...specificInterests);

    // Add common travel categories
    queries.push(
      'restaurants',
      'cafes',
      'tourist attractions',
      'landmarks',
      'museums'
    );

    return queries;
  }

  /**
   * Categorize place from Google Places types
   */
  private categorizePlaceFromTypes(types: string[]): string {
    const typeMap: { [key: string]: string } = {
      restaurant: 'restaurant',
      cafe: 'cafe',
      bar: 'nightlife',
      museum: 'museum',
      park: 'park',
      tourist_attraction: 'attraction',
      shopping_mall: 'shopping',
      store: 'shopping',
      night_club: 'nightlife',
      church: 'religious',
      art_gallery: 'museum',
      beach: 'beach',
      natural_feature: 'nature',
    };

    for (const type of types) {
      if (typeMap[type]) {
        return typeMap[type];
      }
    }

    return 'attraction';
  }

  /**
   * Generate flexible itinerary without templates
   */
  private async generateFlexibleItinerary(params: {
    city: string;
    country: string;
    durationDays: number;
    activities: string[];
    vibe: string[];
    specificInterests: string[];
    places: DynamicPlace[];
    userQuery: string;
    budget?: string;
  }): Promise<any> {
    const { city, country, durationDays, activities, vibe, specificInterests, places, userQuery, budget } = params;

    const placesJson = JSON.stringify(
      places.slice(0, 50).map(p => ({
        placeId: p.placeId,
        name: p.name,
        category: p.category,
        lat: p.lat,
        lng: p.lng,
        rating: p.rating,
        address: p.address,
      })),
      null,
      2
    );

    const prompt = `You are a creative travel planner. Create a UNIQUE and PERSONALIZED ${durationDays}-day trip itinerary for ${city}, ${country}.

USER REQUEST:
"${userQuery}"

TRIP PARAMETERS:
- City: ${city}, ${country}
- Duration: ${durationDays} days
- Activities: ${activities.join(', ')}
- Vibe: ${vibe.join(', ')}
- Specific Interests: ${specificInterests.join(', ') || 'none'}
- Budget: ${budget || 'mid-range'}

AVAILABLE PLACES:
${placesJson}

CRITICAL INSTRUCTIONS:
1. Create EXACTLY ${durationDays} days (no more, no less)
2. Each day should have 4-7 places/activities
3. Include a mix of:
   - Main attractions
   - Restaurants/cafes (breakfast, lunch, dinner)
   - Unique experiences related to user's interests
   - Hidden gems
4. Use ONLY places from the provided list (match by placeId)
5. For each place provide:
   - placeId (from list)
   - name
   - category (attraction/restaurant/cafe/etc)
   - description (40-60 words explaining WHY it fits the user's request)
   - duration_minutes
   - price (estimated in local currency)
   - price_value (numeric)
   - rating
   - address
   - latitude
   - longitude
   - best_time (when to visit)
   - transportation (from previous place: method, duration, cost)

6. Make the itinerary TRULY PERSONALIZED to the user's query
   - For "romantic": include romantic restaurants, sunset spots, couples activities
   - For "anime/manga": include anime shops, themed cafes, pop culture spots
   - For "food": focus on markets, cooking classes, fine dining
   - For "adventure": include outdoor activities, hiking, extreme sports
   - For "budget": prioritize free/cheap activities, street food
   - For "luxury": include high-end restaurants, spas, premium experiences

7. Create engaging day titles that reflect the theme
8. Write descriptions that show you understand the user's desires

REQUIRED JSON FORMAT:
{
  "title": "Catchy trip title (max 60 chars, reflects user's request)",
  "description": "Engaging description (100-150 words) explaining how this trip fulfills the user's desires",
  "duration": "${durationDays} days",
  "activityType": "${activities[0] || 'exploration'}",
  "itinerary": [
    {
      "day": 1,
      "title": "Day theme (relates to user's interests)",
      "description": "What makes this day special (max 50 words)",
      "places": [
        {
          "placeId": "ChIJxxxxx (from list)",
          "name": "Place Name",
          "category": "restaurant/cafe/attraction/etc",
          "description": "Why this fits the user's request (40-60 words)",
          "duration_minutes": 120,
          "price": "€20",
          "price_value": 20,
          "rating": 4.5,
          "address": "Full address",
          "latitude": 48.8606,
          "longitude": 2.3376,
          "best_time": "Morning/Afternoon/Evening",
          "transportation": {
            "from_previous": "Start of day",
            "method": "walk/metro/bus/taxi",
            "duration_minutes": 15,
            "cost": "€2"
          }
        }
      ]
    }
  ],
  "highlights": ["Highlight 1", "Highlight 2", "Highlight 3"],
  "includes": ["What's included 1", "What's included 2"],
  "recommendedBudget": {
    "min": 200,
    "max": 500,
    "currency": "EUR"
  },
  "bestSeasons": ["spring", "summer"]
}

Return ONLY valid JSON. Be creative and personalized!`;

    try {
      return await rateLimiter.execute('openai', async () => {
        return retry(async () => {
          const response = await this.client.chat.completions.create({
            model: config.OPENAI_MODEL,
            messages: [
              {
                role: 'system',
                content:
                  'You are a creative travel planner who creates unique, personalized itineraries. You understand user desires and create trips that perfectly match their interests. Return valid JSON only.',
              },
              {
                role: 'user',
                content: prompt,
              },
            ],
            temperature: 0.8, // Higher temperature for more creative responses
            max_tokens: 4096, // Max supported by standard GPT-4
            response_format: { type: 'json_object' },
          });

          const content = response.choices[0]?.message?.content;
          if (!content) {
            throw new Error('Empty response from OpenAI');
          }

          return JSON.parse(content);
        });
      });
    } catch (error) {
      logger.error('Failed to generate itinerary:', error);
      throw error;
    }
  }

  /**
   * Fetch images for trip
   */
  private async fetchImages(
    city: string,
    itinerary: any[],
    tripIntent: TripIntent
  ): Promise<{ allImages: any[]; heroImage: any }> {
    // Build itinerary for image service
    const itineraryForImages = itinerary.map((day, dayIndex) => ({
      title: day.title,
      pois: (day.places || [])
        .filter((p: any) => p.placeId)
        .map((p: any) => ({
          place_id: p.placeId,
          name: p.name,
        })),
    }));

    const gallery = await hybridImageGalleryService.getCompleteTripGallery(
      city,
      tripIntent.activities[0] || 'exploration',
      itineraryForImages
    );

    const allImages: any[] = [];

    if (gallery.heroImage) {
      allImages.push({ ...gallery.heroImage, type: 'hero', order: 0 });
    }

    gallery.cityGallery.forEach((img, index) => {
      allImages.push({ ...img, type: 'city_gallery', order: index + 1 });
    });

    let orderCounter = allImages.length;

    gallery.itineraryImages.forEach((dayPlacePhotos, dayNumber) => {
      dayPlacePhotos.forEach((photos, placeName) => {
        photos.forEach((img, photoIndex) => {
          allImages.push({
            ...img,
            type: 'itinerary',
            day: dayNumber,
            place_name: placeName,
            photo_index: photoIndex,
            order: orderCounter++,
          });
        });
      });
    });

    return { allImages, heroImage: gallery.heroImage };
  }

  /**
   * Build final trip object
   */
  private buildTripObject(
    skeleton: any,
    cityInfo: { city: string; country: string },
    tripIntent: TripIntent,
    gallery: { allImages: any[]; heroImage: any }
  ): FlexibleTripResult {
    // Enrich itinerary with images
    const enrichedItinerary = skeleton.itinerary.map((day: any, dayIndex: number) => {
      const dayImages = gallery.allImages.filter(
        img => img.type === 'itinerary' && img.day === dayIndex + 1
      );

      const enrichedPlaces = day.places.map((place: any) => {
        const placeImages = dayImages.filter(img => img.place_name === place.name);

        return {
          ...place,
          image_url: placeImages[0]?.url || null,
          images: placeImages.map(img => img.url),
        };
      });

      return {
        ...day,
        places: enrichedPlaces,
        images: dayImages.map(img => img.url),
      };
    });

    return {
      id: uuidv4(),
      title: skeleton.title,
      description: skeleton.description,
      city: cityInfo.city,
      country: cityInfo.country,
      duration: skeleton.duration || `${tripIntent.durationDays} days`,
      durationDays: tripIntent.durationDays,
      price: `€${skeleton.recommendedBudget?.min || 300}`,
      currency: skeleton.recommendedBudget?.currency || 'EUR',
      itinerary: enrichedItinerary,
      highlights: skeleton.highlights || [],
      includes: skeleton.includes || [],
      images: gallery.allImages,
      heroImageUrl: gallery.heroImage?.url || null,
      estimatedCostMin: skeleton.recommendedBudget?.min || 200,
      estimatedCostMax: skeleton.recommendedBudget?.max || 600,
      activityType: skeleton.activityType || tripIntent.activities[0] || 'exploration',
      bestSeason: skeleton.bestSeasons || ['spring', 'summer', 'autumn'],
      tripIntent,
      rating: 4.5,
      reviews: 0,
    };
  }

  /**
   * Helper: sleep
   */
  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Singleton Instance
// ═══════════════════════════════════════════════════════════════════════════

const flexibleTripGeneratorService = new FlexibleTripGeneratorService();

export default flexibleTripGeneratorService;
