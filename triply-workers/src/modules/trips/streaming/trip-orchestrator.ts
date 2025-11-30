/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Trip Generation Orchestrator
 * Coordinates parallel pipelines for real-time trip generation
 * Uses same quality as flexible-trip-generator but with streaming
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { v4 as uuidv4 } from 'uuid';
import { TripEventEmitter, tripEventManager } from './trip-event-emitter.js';
import type {
  GenerationRequest,
  StreamingPlace,
  PlacePlaceholder,
} from './types.js';
import queryAnalyzerService from '../../ai/services/query-analyzer.service.js';
import type { TripIntent, ConversationMessage } from '../../ai/services/query-analyzer.service.js';
import geminiService from '../../ai/services/gemini.service.js';
import googlePlacesService from '../../google-places/services/google-places.service.js';
import googlePlacesPhotosService from '../../google-places/services/google-places-photos.service.js';
import { convertTripPricesToEUR } from '../../../shared/utils/currency-converter.js';
import logger from '../../../shared/utils/logger.js';

// ═══════════════════════════════════════════════════════════════════════════
// Types
// ═══════════════════════════════════════════════════════════════════════════

interface SkeletonResult {
  title: string;
  description: string;
  city: string;
  country: string;
  durationDays: number;
  theme: string | null;
  thematicKeywords: string[];
  vibe: string[];
  activities: string[];
  itinerary: ItineraryDay[];
  estimatedBudget: {
    min: number;
    max: number;
    currency: string;
  };
  highlights: string[];
}

interface ItineraryDay {
  day: number;
  title: string;
  description: string;
  places: ItineraryPlace[];
}

interface ItineraryPlace {
  placeId: string;
  name: string;
  category: string;
  description: string;
  duration_minutes: number;
  price: string;
  price_value: number;
  rating: number;
  address: string;
  latitude: number;
  longitude: number;
  best_time: string;
  transportation: {
    from_previous: string;
    method: string;
    duration_minutes: number;
    cost: string;
  };
}

interface SearchedPlace {
  placeId: string;
  name: string;
  category: string;
  lat: number;
  lng: number;
  rating?: number;
  address?: string;
  photoReference?: string;
  types?: string[];
}

// ═══════════════════════════════════════════════════════════════════════════
// Trip Orchestrator Class
// ═══════════════════════════════════════════════════════════════════════════

class TripOrchestrator {
  constructor() {
    logger.info('✅ Trip Orchestrator initialized');
  }

  /**
   * Start trip generation with streaming events
   */
  async generateTrip(request: GenerationRequest): Promise<TripEventEmitter> {
    const emitter = tripEventManager.createEmitter(request.tripId);

    // Start generation in background (non-blocking)
    this.runGenerationPipeline(emitter, request).catch(error => {
      logger.error(`[${request.tripId}] Pipeline failed:`, error);
      emitter.emitError('PIPELINE_FAILED', error.message, 'pipeline', false);
    });

    return emitter;
  }

  /**
   * Main generation pipeline - same quality as flexible-trip-generator
   */
  private async runGenerationPipeline(
    emitter: TripEventEmitter,
    request: GenerationRequest
  ): Promise<void> {
    const startTime = Date.now();
    const tripId = request.tripId;

    try {
      // ═══════════════════════════════════════════════════════════════════
      // Phase 1: Initialize
      // ═══════════════════════════════════════════════════════════════════
      emitter.emitInit();

      // ═══════════════════════════════════════════════════════════════════
      // Phase 2: Analyze Query & Validate City (parallel)
      // ═══════════════════════════════════════════════════════════════════
      emitter.setPhase('analyzing', 5);

      const [tripIntent, cityInfo] = await Promise.all([
        this.analyzeQuery(request.userQuery, request.conversationContext),
        this.validateCityFromQuery(request.userQuery),
      ]);

      if (!cityInfo) {
        throw new Error(`Could not determine destination from query`);
      }

      logger.info(`[${tripId}] Analysis complete: ${cityInfo.city}, ${tripIntent.durationDays} days`);

      // ═══════════════════════════════════════════════════════════════════
      // Phase 3: Search Places (parallel searches)
      // ═══════════════════════════════════════════════════════════════════
      emitter.setPhase('searching_places', 15);

      const enrichedActivities = [
        ...(tripIntent.thematicKeywords || []),
        ...(tripIntent.conversationTheme ? [tripIntent.conversationTheme] : []),
        ...tripIntent.activities,
        ...(cityInfo.interests || []),
      ].slice(0, 15);

      const places = await this.searchRelevantPlaces(
        cityInfo.city,
        enrichedActivities,
        tripIntent.specificInterests || []
      );

      logger.info(`[${tripId}] Found ${places.length} places`);

      // ═══════════════════════════════════════════════════════════════════
      // Phase 4: Generate Complete Itinerary with AI
      // This is the key difference - AI generates full trip with descriptions
      // ═══════════════════════════════════════════════════════════════════
      emitter.setPhase('generating_skeleton', 25);

      const tripData = await this.generateCompleteItinerary({
        city: cityInfo.city,
        country: cityInfo.country,
        durationDays: tripIntent.durationDays,
        activities: enrichedActivities,
        vibe: tripIntent.vibe || [],
        specificInterests: tripIntent.specificInterests || [],
        places,
        userQuery: request.userQuery,
        conversationTheme: tripIntent.conversationTheme,
        thematicKeywords: tripIntent.thematicKeywords || [],
      });

      // Emit skeleton with real title and description
      emitter.emitSkeleton({
        title: tripData.title,
        description: tripData.description,
        theme: tripIntent.conversationTheme || null,
        thematicKeywords: tripIntent.thematicKeywords || [],
        city: cityInfo.city,
        country: cityInfo.country,
        duration: `${tripIntent.durationDays} days`,
        durationDays: tripIntent.durationDays,
        vibe: tripIntent.vibe || [],
        estimatedBudget: tripData.estimatedBudget || { min: 200, max: 500, currency: 'EUR' },
      });

      // ═══════════════════════════════════════════════════════════════════
      // Phase 5: Stream Days and Places with Real Data
      // ═══════════════════════════════════════════════════════════════════
      emitter.setPhase('assigning_places', 40);

      // Create a map of places for quick lookup
      const placesMap = new Map(places.map(p => [p.placeId, p]));

      for (const day of tripData.itinerary) {
        // Emit day event
        emitter.emitDay({
          day: day.day,
          title: day.title,
          description: day.description || '',
          placeholders: day.places.map((p, idx) => ({
            slot: p.category as any,
            index: idx,
            hint: p.description,
          })),
        });

        // Stream each place with full details
        for (let idx = 0; idx < day.places.length; idx++) {
          const place = day.places[idx];
          const searchedPlace = placesMap.get(place.placeId);

          // Build image URL
          const imageUrl = searchedPlace?.photoReference
            ? `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=${searchedPlace.photoReference}&key=${process.env.GOOGLE_PLACES_API_KEY}`
            : null;

          const streamingPlace: StreamingPlace = {
            id: uuidv4(),
            placeId: place.placeId,
            name: place.name,
            category: place.category,
            description: place.description, // Real AI-generated description!
            duration_minutes: place.duration_minutes,
            price: place.price,
            price_value: place.price_value,
            rating: place.rating || searchedPlace?.rating || 4.0,
            address: place.address || searchedPlace?.address || cityInfo.city,
            latitude: place.latitude || searchedPlace?.lat || 0,
            longitude: place.longitude || searchedPlace?.lng || 0,
            best_time: place.best_time,
            image_url: imageUrl,
            transportation: place.transportation,
          };

          emitter.emitPlace({
            day: day.day,
            slot: place.category,
            index: idx,
            place: streamingPlace,
          });

          // Small delay for smooth streaming
          await this.sleep(80);
        }
      }

      // ═══════════════════════════════════════════════════════════════════
      // Phase 6: Load Images (Hero + Place Photos)
      // ═══════════════════════════════════════════════════════════════════
      emitter.setPhase('loading_images', 70);

      await this.loadAndStreamImages(emitter, tripData, places, cityInfo.city);

      // ═══════════════════════════════════════════════════════════════════
      // Phase 7: Final Prices
      // ═══════════════════════════════════════════════════════════════════
      emitter.setPhase('finalizing', 90);

      const prices = this.calculateTotalPrices(tripData);
      emitter.emitPrices(prices);

      // ═══════════════════════════════════════════════════════════════════
      // Phase 8: Complete
      // ═══════════════════════════════════════════════════════════════════
      emitter.emitComplete();

      const duration = Date.now() - startTime;
      logger.info(`[${tripId}] ✅ Pipeline completed in ${(duration / 1000).toFixed(1)}s`);

    } catch (error: any) {
      logger.error(`[${tripId}] Pipeline error:`, error);
      emitter.emitError(
        'GENERATION_FAILED',
        error.message || 'Unknown error',
        emitter.getState().phase,
        false
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Pipeline Steps
  // ═══════════════════════════════════════════════════════════════════════════

  private async analyzeQuery(
    userQuery: string,
    context?: ConversationMessage[]
  ): Promise<TripIntent> {
    const intent = await queryAnalyzerService.analyzeQuery(userQuery, context) as TripIntent;
    intent.requestType = 'trip';
    intent.activities = intent.activities || [];
    intent.vibe = intent.vibe || [];
    intent.specificInterests = intent.specificInterests || [];
    intent.thematicKeywords = intent.thematicKeywords || [];
    return intent;
  }

  private async validateCityFromQuery(
    userQuery: string
  ): Promise<{ city: string; country: string; locationType?: string; interests?: string[] } | null> {
    const cityMatch = userQuery.match(/(?:in|to|visit|explore)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)/i);
    const cityName = cityMatch?.[1] || userQuery.split(' ').slice(-2).join(' ');
    return queryAnalyzerService.validateCity(cityName);
  }

  /**
   * Search for relevant places using Google Places API
   * Same approach as flexible-trip-generator
   */
  private async searchRelevantPlaces(
    city: string,
    activities: string[],
    specificInterests: string[]
  ): Promise<SearchedPlace[]> {
    const allPlaces: SearchedPlace[] = [];
    const searchQueries = this.buildSearchQueries(activities, specificInterests);

    // Run searches in parallel batches
    const batchSize = 5;
    for (let i = 0; i < searchQueries.length; i += batchSize) {
      const batch = searchQueries.slice(i, i + batchSize);

      const results = await Promise.allSettled(
        batch.map(async (query) => {
          try {
            const places = await googlePlacesService.textSearch({
              query: `${query} in ${city}`,
            });
            return (places || []).slice(0, 5).map((p: any) => ({
              placeId: p.place_id,
              name: p.name,
              category: this.categorizePlaceFromTypes(p.types || []),
              lat: p.geometry?.location?.lat || 0,
              lng: p.geometry?.location?.lng || 0,
              rating: p.rating,
              address: p.formatted_address,
              photoReference: p.photos?.[0]?.photo_reference,
              types: p.types,
            }));
          } catch (error) {
            logger.warn(`Search failed for "${query}":`, error);
            return [];
          }
        })
      );

      for (const result of results) {
        if (result.status === 'fulfilled') {
          allPlaces.push(...result.value);
        }
      }
    }

    // Deduplicate by placeId
    return Array.from(new Map(allPlaces.map(p => [p.placeId, p])).values());
  }

  private buildSearchQueries(activities: string[], specificInterests: string[]): string[] {
    const queries = new Set<string>();

    // Add specific interests first (highest priority)
    for (const interest of specificInterests.slice(0, 5)) {
      queries.add(interest);
    }

    // Add activities
    for (const activity of activities.slice(0, 8)) {
      queries.add(activity);
      // Add themed restaurant/cafe searches
      if (!activity.includes('restaurant') && !activity.includes('cafe')) {
        queries.add(`${activity} restaurant`);
        queries.add(`${activity} cafe`);
      }
    }

    // Add basic categories
    queries.add('best restaurants');
    queries.add('popular cafes');
    queries.add('top attractions');
    queries.add('famous landmarks');
    queries.add('museums');

    return Array.from(queries).slice(0, 15);
  }

  /**
   * Generate complete itinerary with AI - same quality as flexible-trip-generator
   */
  private async generateCompleteItinerary(params: {
    city: string;
    country: string;
    durationDays: number;
    activities: string[];
    vibe: string[];
    specificInterests: string[];
    places: SearchedPlace[];
    userQuery: string;
    conversationTheme?: string;
    thematicKeywords: string[];
  }): Promise<SkeletonResult> {
    const { city, country, durationDays, activities, vibe, specificInterests, places, userQuery, conversationTheme, thematicKeywords } = params;

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

    const themeContext = conversationTheme
      ? `\n🎨 THEME: "${conversationTheme.toUpperCase()}"
The ENTIRE trip MUST be themed around "${conversationTheme}".
- ALL restaurants should be ${conversationTheme}-themed
- ALL attractions should relate to ${conversationTheme}
- Day titles should reference ${conversationTheme}
- Keywords: ${thematicKeywords.join(', ')}`
      : '';

    const prompt = `Create a PERSONALIZED ${durationDays}-day trip for ${city}, ${country}.

USER REQUEST: "${userQuery}"
${themeContext}

TRIP PARAMETERS:
- City: ${city}, ${country}
- Duration: ${durationDays} days
- Activities: ${activities.join(', ')}
- Vibe: ${vibe.join(', ') || 'general exploration'}
- Interests: ${specificInterests.join(', ') || 'general'}

AVAILABLE PLACES (use placeId from this list):
${placesJson}

CRITICAL INSTRUCTIONS:
1. Create EXACTLY ${durationDays} days
2. Each day MUST have 5-7 places:
   - 1 breakfast (category: "breakfast")
   - 2-3 attractions (category: "attraction")
   - 1 lunch (category: "lunch")
   - 1-2 more attractions
   - 1 dinner (category: "dinner")

3. For EACH place provide:
   - placeId (from the list above!)
   - name (exact name from list)
   - category: "breakfast" | "lunch" | "dinner" | "attraction"
   - description: 40-60 words explaining WHY this place fits the user's request
   - duration_minutes: realistic time to spend
   - price: estimated cost (e.g., "€15", "€25")
   - price_value: numeric value (e.g., 15, 25)
   - rating: from list or estimate (e.g., 4.5)
   - address: from list
   - latitude, longitude: from list
   - best_time: "Morning", "Midday", "Afternoon", "Evening"
   - transportation: { from_previous, method, duration_minutes, cost }

4. Create ENGAGING day titles that reflect the theme
5. Write PERSONALIZED descriptions showing you understand the user

REQUIRED JSON FORMAT:
{
  "title": "Catchy trip title (max 60 chars)",
  "description": "Engaging 100-150 word description of why this trip is perfect",
  "itinerary": [
    {
      "day": 1,
      "title": "Day theme title",
      "description": "What makes this day special (30-50 words)",
      "places": [
        {
          "placeId": "ChIJ...",
          "name": "Place Name",
          "category": "breakfast",
          "description": "Why this place is perfect for the user...",
          "duration_minutes": 60,
          "price": "€15",
          "price_value": 15,
          "rating": 4.5,
          "address": "Full address",
          "latitude": 51.5074,
          "longitude": -0.1278,
          "best_time": "Morning",
          "transportation": {
            "from_previous": "Start of day",
            "method": "walk",
            "duration_minutes": 0,
            "cost": "€0"
          }
        }
      ]
    }
  ],
  "highlights": ["Highlight 1", "Highlight 2", "Highlight 3"],
  "estimatedBudget": { "min": 200, "max": 500, "currency": "EUR" }
}`;

    const result = await geminiService.generateJSON<any>({
      systemPrompt: 'You are an expert travel planner. Create detailed, personalized trip itineraries. Return valid JSON only.',
      userPrompt: prompt,
      temperature: 0.8,
      maxTokens: 8192,
    });

    // Validate and fix the result
    const itinerary = result.itinerary || [];
    if (itinerary.length === 0) {
      throw new Error('AI returned empty itinerary');
    }

    return {
      title: result.title || `${city} Adventure`,
      description: result.description || `Explore the best of ${city}`,
      city,
      country,
      durationDays,
      theme: conversationTheme || null,
      thematicKeywords,
      vibe,
      activities,
      itinerary,
      estimatedBudget: result.estimatedBudget || { min: 200, max: 500, currency: 'EUR' },
      highlights: result.highlights || [],
    };
  }

  /**
   * Load and stream images - hero from Unsplash, places from Google
   */
  private async loadAndStreamImages(
    emitter: TripEventEmitter,
    tripData: SkeletonResult,
    places: SearchedPlace[],
    city: string
  ): Promise<void> {
    try {
      // 1. Get hero image from Unsplash
      const heroImage = await this.fetchHeroImage(city, tripData.theme);
      if (heroImage) {
        emitter.emitImage({
          imageType: 'hero',
          url: heroImage,
        });
      }

      // 2. Get multiple photos for each place from Google Places
      const placesMap = new Map(places.map(p => [p.placeId, p]));
      const emittedPlaces = new Set<string>();

      for (const day of tripData.itinerary) {
        for (const place of day.places) {
          if (emittedPlaces.has(place.placeId)) continue;
          emittedPlaces.add(place.placeId);

          const searchedPlace = placesMap.get(place.placeId);
          if (!searchedPlace) continue;

          try {
            // Get multiple photos for each place
            const photos = await googlePlacesPhotosService.getPOIPhotos(place.placeId, 5);

            for (const photo of photos) {
              emitter.emitImage({
                imageType: 'place',
                url: photo.url,
                placeId: place.placeId,
                placeName: place.name,
              });
            }
          } catch (err) {
            // Fallback to single photo from search
            if (searchedPlace.photoReference) {
              const url = `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=${searchedPlace.photoReference}&key=${process.env.GOOGLE_PLACES_API_KEY}`;
              emitter.emitImage({
                imageType: 'place',
                url,
                placeId: place.placeId,
                placeName: place.name,
              });
            }
          }
        }
      }
    } catch (error) {
      logger.warn('Error loading images:', error);
    }
  }

  private async fetchHeroImage(city: string, theme: string | null): Promise<string | null> {
    // Get hero image from Google Places
    try {
      const searchQuery = theme ? `${city} ${theme} landmark` : `${city} landmark scenic`;
      const results = await googlePlacesService.textSearch({
        query: searchQuery,
      });
      const photoRef = results?.[0]?.photos?.[0]?.photo_reference;
      if (photoRef) {
        return `https://maps.googleapis.com/maps/api/place/photo?maxwidth=1200&photo_reference=${photoRef}&key=${process.env.GOOGLE_PLACES_API_KEY}`;
      }
    } catch (error) {
      logger.warn('Google Places hero image failed:', error);
    }

    return null;
  }

  private calculateTotalPrices(tripData: SkeletonResult): {
    totalMin: number;
    totalMax: number;
    currency: string;
    breakdown: {
      accommodation: { min: number; max: number };
      food: { min: number; max: number };
      activities: { min: number; max: number };
      transport: { min: number; max: number };
    };
  } {
    let foodTotal = 0;
    let activitiesTotal = 0;

    for (const day of tripData.itinerary) {
      for (const place of day.places) {
        const value = place.price_value || 0;
        if (['breakfast', 'lunch', 'dinner'].includes(place.category)) {
          foodTotal += value;
        } else {
          activitiesTotal += value;
        }
      }
    }

    const days = tripData.durationDays;
    const accommodationMin = 60 * days;
    const accommodationMax = 180 * days;
    const transportMin = 15 * days;
    const transportMax = 40 * days;

    return {
      totalMin: tripData.estimatedBudget?.min || (foodTotal + activitiesTotal + accommodationMin + transportMin),
      totalMax: tripData.estimatedBudget?.max || (foodTotal * 1.5 + activitiesTotal * 1.5 + accommodationMax + transportMax),
      currency: 'EUR',
      breakdown: {
        accommodation: { min: accommodationMin, max: accommodationMax },
        food: { min: foodTotal, max: Math.round(foodTotal * 1.5) },
        activities: { min: activitiesTotal, max: Math.round(activitiesTotal * 1.5) },
        transport: { min: transportMin, max: transportMax },
      },
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Utility Methods
  // ═══════════════════════════════════════════════════════════════════════════

  private categorizePlaceFromTypes(types: string[]): string {
    const typeMap: Record<string, string> = {
      restaurant: 'restaurant',
      cafe: 'cafe',
      bar: 'nightlife',
      museum: 'museum',
      park: 'park',
      tourist_attraction: 'attraction',
      shopping_mall: 'shopping',
      night_club: 'nightlife',
    };

    for (const type of types) {
      if (typeMap[type]) return typeMap[type];
    }
    return 'attraction';
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Singleton Instance
// ═══════════════════════════════════════════════════════════════════════════

const tripOrchestrator = new TripOrchestrator();

export default tripOrchestrator;
