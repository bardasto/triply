/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Trip Generation Orchestrator
 * Coordinates parallel pipelines for real-time trip generation
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
import hybridImageGalleryService from '../../photos/services/hybrid-image-gallery.service.js';
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
  days: DaySkeleton[];
  estimatedBudget: {
    min: number;
    max: number;
    currency: string;
  };
}

interface DaySkeleton {
  day: number;
  title: string;
  description: string;
  placeholders: PlacePlaceholder[];
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
   * Main generation pipeline
   */
  private async runGenerationPipeline(
    emitter: TripEventEmitter,
    request: GenerationRequest
  ): Promise<void> {
    const startTime = Date.now();
    const tripId = request.tripId;

    try {
      // ═══════════════════════════════════════════════════════════════════
      // Phase 1: Initialize & Emit Init Event
      // ═══════════════════════════════════════════════════════════════════
      emitter.emitInit();

      // ═══════════════════════════════════════════════════════════════════
      // Phase 2: Parallel Analysis (Query + City Validation)
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
      // Phase 3: Generate Skeleton (title, days structure)
      // ═══════════════════════════════════════════════════════════════════
      emitter.setPhase('generating_skeleton', 10);

      const skeleton = await this.generateSkeleton(
        tripIntent,
        cityInfo,
        request.userQuery
      );

      // Emit skeleton event
      emitter.emitSkeleton({
        title: skeleton.title,
        description: skeleton.description,
        theme: skeleton.theme,
        thematicKeywords: skeleton.thematicKeywords,
        city: skeleton.city,
        country: skeleton.country,
        duration: `${skeleton.durationDays} days`,
        durationDays: skeleton.durationDays,
        vibe: skeleton.vibe,
        estimatedBudget: skeleton.estimatedBudget,
      });

      // Emit each day structure
      for (const day of skeleton.days) {
        emitter.emitDay({
          day: day.day,
          title: day.title,
          description: day.description,
          placeholders: day.placeholders,
        });
      }

      // ═══════════════════════════════════════════════════════════════════
      // Phase 4: Parallel Place Search
      // ═══════════════════════════════════════════════════════════════════
      emitter.setPhase('searching_places', 40);

      const searchQueries = this.buildSearchQueries(skeleton);
      const places = await this.searchPlacesParallel(cityInfo.city, searchQueries);

      logger.info(`[${tripId}] Found ${places.length} places`);

      // ═══════════════════════════════════════════════════════════════════
      // Phase 5: Assign Places to Slots & Stream
      // ═══════════════════════════════════════════════════════════════════
      emitter.setPhase('assigning_places', 55);

      await this.assignAndStreamPlaces(emitter, skeleton, places, cityInfo);

      // ═══════════════════════════════════════════════════════════════════
      // Phase 6: Load Images in Background
      // ═══════════════════════════════════════════════════════════════════
      emitter.setPhase('loading_images', 75);

      // Start image loading (don't await - let it stream)
      this.loadAndStreamImages(emitter, skeleton, places).catch(err => {
        logger.warn(`[${tripId}] Image loading error:`, err);
      });

      // ═══════════════════════════════════════════════════════════════════
      // Phase 7: Calculate Final Prices
      // ═══════════════════════════════════════════════════════════════════
      emitter.setPhase('finalizing', 90);

      const prices = await this.calculatePrices(skeleton, emitter.getState());
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
    // Extract city from query first using simple analysis
    const cityMatch = userQuery.match(/(?:in|to|visit|explore)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)/i);
    const cityName = cityMatch?.[1] || userQuery.split(' ').slice(-2).join(' ');

    return queryAnalyzerService.validateCity(cityName);
  }

  private async generateSkeleton(
    intent: TripIntent,
    cityInfo: { city: string; country: string; locationType?: string; interests?: string[] },
    userQuery: string
  ): Promise<SkeletonResult> {
    const theme = intent.conversationTheme || null;
    const thematicKeywords = intent.thematicKeywords || [];
    const activities = [
      ...thematicKeywords,
      ...(theme ? [theme] : []),
      ...intent.activities,
      ...(cityInfo.interests || []),
    ].slice(0, 10);

    const prompt = `Create a trip skeleton for ${cityInfo.city}, ${cityInfo.country}.

USER REQUEST: "${userQuery}"
DURATION: ${intent.durationDays} days
${theme ? `THEME: ${theme.toUpperCase()} (The entire trip must follow this theme!)` : ''}
${thematicKeywords.length > 0 ? `THEMATIC KEYWORDS: ${thematicKeywords.join(', ')}` : ''}
ACTIVITIES: ${activities.join(', ')}
VIBE: ${intent.vibe?.join(', ') || 'general'}

Generate a JSON with:
{
  "title": "Catchy trip title (max 50 chars)",
  "description": "Engaging 2-3 sentence description",
  "days": [
    {
      "day": 1,
      "title": "Day title reflecting theme",
      "description": "Brief day description (1 sentence)",
      "placeholders": [
        { "slot": "breakfast", "index": 0, "hint": "Themed cafe or restaurant" },
        { "slot": "attraction", "index": 1, "hint": "Main morning activity" },
        { "slot": "attraction", "index": 2, "hint": "Secondary activity" },
        { "slot": "lunch", "index": 3, "hint": "Lunch spot" },
        { "slot": "attraction", "index": 4, "hint": "Afternoon activity" },
        { "slot": "dinner", "index": 5, "hint": "Dinner restaurant" }
      ]
    }
  ],
  "estimatedBudget": { "min": 200, "max": 500, "currency": "EUR" }
}

Create EXACTLY ${intent.durationDays} days. Each day should have 5-7 placeholders.
${theme ? `All placeholders hints should relate to "${theme}" theme!` : ''}`;

    const result = await geminiService.generateJSON<any>({
      systemPrompt: 'You are a travel planner. Create trip skeletons with themed day structures. Return valid JSON only.',
      userPrompt: prompt,
      temperature: 0.7,
      maxTokens: 2000,
    });

    return {
      title: result.title || `${cityInfo.city} Adventure`,
      description: result.description || `Explore the best of ${cityInfo.city}`,
      city: cityInfo.city,
      country: cityInfo.country,
      durationDays: intent.durationDays,
      theme,
      thematicKeywords,
      vibe: intent.vibe || [],
      activities,
      days: result.days || [],
      estimatedBudget: result.estimatedBudget || { min: 200, max: 500, currency: 'EUR' },
    };
  }

  private buildSearchQueries(skeleton: SkeletonResult): string[] {
    const queries: string[] = [];

    // Add thematic keywords first (priority)
    for (const keyword of skeleton.thematicKeywords.slice(0, 5)) {
      queries.push(keyword);
    }

    // Add theme
    if (skeleton.theme) {
      queries.push(skeleton.theme);
      queries.push(`${skeleton.theme} restaurant`);
      queries.push(`${skeleton.theme} cafe`);
    }

    // Add activities
    for (const activity of skeleton.activities.slice(0, 5)) {
      queries.push(activity);
    }

    // Add basic categories
    queries.push('restaurants', 'cafes', 'attractions', 'landmarks');

    // Deduplicate
    return [...new Set(queries)].slice(0, 12);
  }

  private async searchPlacesParallel(
    city: string,
    queries: string[]
  ): Promise<SearchedPlace[]> {
    const allPlaces: SearchedPlace[] = [];
    const batchSize = 5; // Run 5 searches in parallel

    for (let i = 0; i < queries.length; i += batchSize) {
      const batch = queries.slice(i, i + batchSize);

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
    const unique = Array.from(
      new Map(allPlaces.map(p => [p.placeId, p])).values()
    );

    return unique;
  }

  private async assignAndStreamPlaces(
    emitter: TripEventEmitter,
    skeleton: SkeletonResult,
    places: SearchedPlace[],
    cityInfo: { city: string; country: string }
  ): Promise<void> {
    const usedPlaceIds = new Set<string>();

    for (const day of skeleton.days) {
      for (const placeholder of day.placeholders) {
        // Find best matching place for this slot
        const matchingPlace = this.findBestPlace(
          placeholder,
          places,
          usedPlaceIds,
          skeleton.theme
        );

        if (matchingPlace) {
          usedPlaceIds.add(matchingPlace.placeId);

          const streamingPlace: StreamingPlace = {
            id: uuidv4(),
            placeId: matchingPlace.placeId,
            name: matchingPlace.name,
            category: placeholder.slot,
            description: `${placeholder.hint} - ${matchingPlace.name}`,
            duration_minutes: this.getDurationForSlot(placeholder.slot),
            price: this.getPriceForSlot(placeholder.slot),
            price_value: this.getPriceValueForSlot(placeholder.slot),
            rating: matchingPlace.rating || 4.0,
            address: matchingPlace.address || cityInfo.city,
            latitude: matchingPlace.lat,
            longitude: matchingPlace.lng,
            best_time: this.getBestTimeForSlot(placeholder.slot),
            transportation: {
              from_previous: placeholder.index === 0 ? 'Start of day' : 'Previous location',
              method: 'walk',
              duration_minutes: 10,
              cost: '€0',
            },
          };

          emitter.emitPlace({
            day: day.day,
            slot: placeholder.slot,
            index: placeholder.index,
            place: streamingPlace,
          });

          // Small delay between places for smooth streaming
          await this.sleep(100);
        }
      }
    }
  }

  private findBestPlace(
    placeholder: PlacePlaceholder,
    places: SearchedPlace[],
    usedIds: Set<string>,
    theme: string | null
  ): SearchedPlace | null {
    const availablePlaces = places.filter(p => !usedIds.has(p.placeId));

    if (availablePlaces.length === 0) return null;

    // Score places by relevance
    const scored = availablePlaces.map(place => {
      let score = 0;

      // Category match
      if (placeholder.slot === 'breakfast' || placeholder.slot === 'lunch' || placeholder.slot === 'dinner') {
        if (place.category === 'restaurant' || place.category === 'cafe') score += 10;
      } else {
        if (place.category === 'attraction' || place.category === 'museum') score += 10;
      }

      // Theme match (check in name)
      if (theme && place.name.toLowerCase().includes(theme.toLowerCase())) {
        score += 20;
      }

      // Rating bonus
      if (place.rating) score += place.rating;

      return { place, score };
    });

    scored.sort((a, b) => b.score - a.score);
    return scored[0]?.place || null;
  }

  private async loadAndStreamImages(
    emitter: TripEventEmitter,
    skeleton: SkeletonResult,
    places: SearchedPlace[]
  ): Promise<void> {
    try {
      // First, emit hero image
      const heroImage = await this.fetchHeroImage(skeleton.city);
      if (heroImage) {
        emitter.emitImage({
          imageType: 'hero',
          url: heroImage,
        });
      }

      // Then load place images in parallel
      const placeImages = places.slice(0, 20).map(async (place) => {
        if (place.photoReference) {
          const url = `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=${place.photoReference}&key=${process.env.GOOGLE_PLACES_API_KEY}`;
          emitter.emitImage({
            imageType: 'place',
            url,
            placeId: place.placeId,
            placeName: place.name,
          });
        }
      });

      await Promise.allSettled(placeImages);
    } catch (error) {
      logger.warn('Error loading images:', error);
    }
  }

  private async fetchHeroImage(city: string): Promise<string | null> {
    try {
      const results = await googlePlacesService.textSearch({
        query: `${city} landmark scenic`,
      });
      const photoRef = results?.[0]?.photos?.[0]?.photo_reference;
      if (photoRef) {
        return `https://maps.googleapis.com/maps/api/place/photo?maxwidth=1200&photo_reference=${photoRef}&key=${process.env.GOOGLE_PLACES_API_KEY}`;
      }
    } catch (error) {
      logger.warn('Error fetching hero image:', error);
    }
    return null;
  }

  private async calculatePrices(
    skeleton: SkeletonResult,
    state: any
  ): Promise<{
    totalMin: number;
    totalMax: number;
    currency: string;
    breakdown: {
      accommodation: { min: number; max: number };
      food: { min: number; max: number };
      activities: { min: number; max: number };
      transport: { min: number; max: number };
    };
  }> {
    const days = skeleton.durationDays;

    return {
      totalMin: skeleton.estimatedBudget.min,
      totalMax: skeleton.estimatedBudget.max,
      currency: 'EUR',
      breakdown: {
        accommodation: { min: 50 * days, max: 150 * days },
        food: { min: 30 * days, max: 80 * days },
        activities: { min: 20 * days, max: 60 * days },
        transport: { min: 10 * days, max: 30 * days },
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

  private getDurationForSlot(slot: string): number {
    const durations: Record<string, number> = {
      breakfast: 45,
      lunch: 60,
      dinner: 90,
      attraction: 120,
    };
    return durations[slot] || 60;
  }

  private getPriceForSlot(slot: string): string {
    const prices: Record<string, string> = {
      breakfast: '€15',
      lunch: '€25',
      dinner: '€45',
      attraction: '€20',
    };
    return prices[slot] || '€20';
  }

  private getPriceValueForSlot(slot: string): number {
    const prices: Record<string, number> = {
      breakfast: 15,
      lunch: 25,
      dinner: 45,
      attraction: 20,
    };
    return prices[slot] || 20;
  }

  private getBestTimeForSlot(slot: string): string {
    const times: Record<string, string> = {
      breakfast: 'Morning (8:00-10:00)',
      lunch: 'Midday (12:00-14:00)',
      dinner: 'Evening (19:00-21:00)',
      attraction: 'Flexible',
    };
    return times[slot] || 'Any time';
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
