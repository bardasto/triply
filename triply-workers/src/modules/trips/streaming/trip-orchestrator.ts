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
  // No estimatedBudget - will be calculated from actual place prices
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
  opening_hours?: string;
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
  opening_hours?: {
    open_now?: boolean;
    weekday_text?: string[];
  };
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

      // Log incoming request for debugging
      logger.info(`[${tripId}] ════════════════════════════════════════════════════════`);
      logger.info(`[${tripId}] 📥 INCOMING REQUEST:`);
      logger.info(`[${tripId}]   Query: "${request.userQuery}"`);
      logger.info(`[${tripId}]   Context entries: ${request.conversationContext?.length ?? 0}`);
      if (request.conversationContext && request.conversationContext.length > 0) {
        for (let i = 0; i < Math.min(request.conversationContext.length, 10); i++) {
          const ctx = request.conversationContext[i];
          const role = ctx.role || 'unknown';
          const type = (ctx as any).type || 'text';

          if (ctx.content) {
            const truncated = ctx.content.length > 150 ? ctx.content.substring(0, 150) + '...' : ctx.content;
            logger.info(`[${tripId}]   [${i}] ${role.toUpperCase()} (${type}): "${truncated}"`);
          } else if ((ctx as any).places) {
            const places = (ctx as any).places as any[];
            const placeInfo = places.slice(0, 3).map((p: any) => `${p.name} (${p.type || p.category || 'unknown'})`).join(', ');
            logger.info(`[${tripId}]   [${i}] ${role.toUpperCase()} (${type}): ${places.length} places - ${placeInfo}`);
          } else {
            logger.info(`[${tripId}]   [${i}] ${role.toUpperCase()} (${type}): ${JSON.stringify(ctx).substring(0, 100)}...`);
          }
        }
      }
      logger.info(`[${tripId}] ════════════════════════════════════════════════════════`);

      // ═══════════════════════════════════════════════════════════════════
      // Phase 2: Analyze Query & Validate City (parallel)
      // ═══════════════════════════════════════════════════════════════════
      emitter.setPhase('analyzing', 5);

      // First analyze the query to get AI-extracted city
      const tripIntent = await this.analyzeQuery(request.userQuery, request.conversationContext);

      // Use the city from AI analysis (more reliable than regex)
      const cityToValidate = tripIntent.city || this.extractCityFromQuery(request.userQuery);
      const cityInfo = await queryAnalyzerService.validateCity(cityToValidate);

      if (!cityInfo) {
        throw new Error(`Could not determine destination from query`);
      }

      logger.info(`[${tripId}] ════════════════════════════════════════════════════════`);
      logger.info(`[${tripId}] 🔍 ANALYSIS COMPLETE:`);
      logger.info(`[${tripId}]   City: ${cityInfo.city}, ${cityInfo.country}`);
      logger.info(`[${tripId}]   Duration: ${tripIntent.durationDays} days`);
      logger.info(`[${tripId}]   🎨 Theme: "${tripIntent.conversationTheme || 'NONE'}"`);
      logger.info(`[${tripId}]   🏷️ Keywords: ${tripIntent.thematicKeywords?.join(', ') || 'NONE'}`);
      logger.info(`[${tripId}]   🎭 Vibe: ${tripIntent.vibe?.join(', ') || 'NONE'}`);
      logger.info(`[${tripId}]   🎯 Activities: ${tripIntent.activities?.join(', ') || 'NONE'}`);
      logger.info(`[${tripId}]   📍 Must Include: ${tripIntent.mustIncludePlaces?.join(', ') || 'NONE'}`);
      logger.info(`[${tripId}] ════════════════════════════════════════════════════════`);

      // ═══════════════════════════════════════════════════════════════════
      // Phase 2.5: Emit EARLY skeleton with basic info (fast feedback!)
      // Only send city and duration immediately - title will come soon
      // Budget will be calculated later from actual place prices
      // ═══════════════════════════════════════════════════════════════════

      emitter.emitSkeleton({
        title: '', // Will be updated after quick title generation
        description: '',
        theme: tripIntent.conversationTheme || null,
        thematicKeywords: tripIntent.thematicKeywords || [],
        city: cityInfo.city,
        country: cityInfo.country,
        duration: `${tripIntent.durationDays} days`,
        durationDays: tripIntent.durationDays,
        vibe: tripIntent.vibe || [],
        // No estimatedBudget here - will be calculated from actual prices
      });

      // ═══════════════════════════════════════════════════════════════════
      // Phase 3: Generate Title + Search Places (PARALLEL for speed!)
      // ═══════════════════════════════════════════════════════════════════
      emitter.setPhase('searching_places', 15);

      const enrichedActivities = [
        ...(tripIntent.thematicKeywords || []),
        ...(tripIntent.conversationTheme ? [tripIntent.conversationTheme] : []),
        ...tripIntent.activities,
        ...(cityInfo.interests || []),
      ].slice(0, 15);

      // Run title generation and place search in parallel
      const [quickTitle, places] = await Promise.all([
        this.generateQuickTitle(
          cityInfo.city,
          tripIntent.durationDays,
          tripIntent.conversationTheme,
          tripIntent.vibe || [],
          request.userQuery
        ),
        this.searchRelevantPlaces(
          cityInfo.city,
          enrichedActivities,
          tripIntent.specificInterests || []
        ),
      ]);

      // Emit skeleton with title as soon as we have it
      if (quickTitle) {
        emitter.emitSkeleton({
          title: quickTitle.title,
          description: quickTitle.description,
          theme: tripIntent.conversationTheme || null,
          thematicKeywords: tripIntent.thematicKeywords || [],
          city: cityInfo.city,
          country: cityInfo.country,
          duration: `${tripIntent.durationDays} days`,
          durationDays: tripIntent.durationDays,
          vibe: tripIntent.vibe || [],
          // No estimatedBudget - will be calculated from actual prices
        });
      }

      logger.info(`[${tripId}] Found ${places.length} places, title: "${quickTitle?.title}"`);

      // Enrich places with opening hours from Google Places Details API
      // This runs in parallel with skeleton generation preparation
      await this.enrichOpeningHours(places);

      // ═══════════════════════════════════════════════════════════════════
      // Phase 4: Generate Complete Itinerary with AI
      // This is the key difference - AI generates full trip with descriptions
      // ═══════════════════════════════════════════════════════════════════
      emitter.setPhase('generating_skeleton', 25);

      const tripDataRaw = await this.generateCompleteItinerary({
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

      // Post-process: Ensure all restaurant/cafe categories are converted to meal times
      const tripData = this.fixPlaceCategories(tripDataRaw);

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
        // No estimatedBudget - will be calculated from actual prices
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
          placeholders: day.places.map((p: ItineraryPlace, idx: number) => ({
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
            // Use real opening hours from Google Places API
            opening_hours: searchedPlace?.opening_hours || null,
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

  /**
   * Fallback regex extraction of city from query (used only if AI fails)
   */
  private extractCityFromQuery(userQuery: string): string {
    // Try multiple patterns to extract city name
    const patterns = [
      /(?:trip\s+(?:to|in))\s+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)?)/i,  // "trip to Paris", "trip in London"
      /^([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)?)\s+(?:\d+\s*days?|trip)/i, // "Paris 2 days", "London trip"
      /(?:in|to|visit|explore)\s+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)?)/i, // "in Paris", "to London"
    ];

    for (const pattern of patterns) {
      const match = userQuery.match(pattern);
      if (match?.[1]) {
        return match[1];
      }
    }

    // Last resort: first capitalized word
    const firstCapitalized = userQuery.match(/\b([A-Z][a-zA-Z]+)\b/);
    return firstCapitalized?.[1] || userQuery.split(' ')[0];
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
              opening_hours: p.opening_hours ? {
                open_now: p.opening_hours.open_now,
                weekday_text: p.opening_hours.weekday_text,
              } : undefined,
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

  /**
   * Generate a quick title, description and budget estimate
   * Runs in parallel with place search for faster skeleton display
   */
  private async generateQuickTitle(
    city: string,
    durationDays: number,
    theme: string | null | undefined,
    vibe: string[],
    userQuery: string
  ): Promise<{ title: string; description: string } | null> {
    try {
      const themeContext = theme ? `Theme: "${theme}". ` : '';
      const vibeContext = vibe.length > 0 ? `Vibe: ${vibe.join(', ')}. ` : '';

      const prompt = `Create a trip title and short description for: "${userQuery}"
City: ${city}, Duration: ${durationDays} days
${themeContext}${vibeContext}

Return JSON:
{
  "title": "Creative trip title (max 40 chars, catchy and specific to the theme/vibe)",
  "description": "2-3 sentences describing what makes this trip special"
}`;

      const result = await geminiService.generateJSON<{
        title: string;
        description: string;
      }>({
        systemPrompt: 'You are a creative travel copywriter. Generate catchy, specific trip titles. Return valid JSON only.',
        userPrompt: prompt,
        temperature: 0.9,
        maxTokens: 300,
      });

      return {
        title: result.title || `${city} Adventure`,
        description: result.description || `Explore the best of ${city}`,
      };
    } catch (error) {
      logger.warn('Quick title generation failed:', error);
      return null;
    }
  }

  private buildSearchQueries(activities: string[], specificInterests: string[]): string[] {
    // CRITICAL: Restaurants/cafes MUST be searched first to guarantee meal places
    const priorityQueries = [
      'best restaurants',
      'popular cafes',
    ];

    const otherQueries = new Set<string>();

    // Add specific interests (limited)
    for (const interest of specificInterests.slice(0, 3)) {
      otherQueries.add(interest);
    }

    // Add activities (limited)
    for (const activity of activities.slice(0, 5)) {
      otherQueries.add(activity);
      // Add themed restaurant/cafe searches for thematic trips
      if (!activity.includes('restaurant') && !activity.includes('cafe')) {
        otherQueries.add(`${activity} restaurant`);
      }
    }

    // Add basic categories
    otherQueries.add('top attractions');
    otherQueries.add('famous landmarks');
    otherQueries.add('museums');

    // Combine: priority first, then others (total max 15)
    return [...priorityQueries, ...Array.from(otherQueries)].slice(0, 15);
  }

  /**
   * Fix place categories - ensure restaurant/cafe are converted to meal times
   * This is a safety net in case AI doesn't follow instructions
   */
  private fixPlaceCategories(tripData: any): any {
    const foodCategories = ['restaurant', 'cafe', 'bar', 'food', 'dining'];
    const validCategories = ['breakfast', 'lunch', 'dinner', 'attraction'];
    let fixedCount = 0;

    const fixedItinerary = (tripData.itinerary || []).map((day: any) => {
      const places = day.places || [];
      let hasBreakfast = places.some((p: any) => p.category === 'breakfast');
      let hasLunch = places.some((p: any) => p.category === 'lunch');
      let hasDinner = places.some((p: any) => p.category === 'dinner');

      const fixedPlaces = places.map((place: any, index: number) => {
        const category = (place.category || '').toLowerCase();

        // If category is already valid, keep it
        if (validCategories.includes(category)) {
          return place;
        }

        // If it's a food-related category, convert to meal time based on position
        if (foodCategories.includes(category)) {
          let newCategory: string;
          const position = index / places.length;

          if (!hasBreakfast && position < 0.3) {
            newCategory = 'breakfast';
            hasBreakfast = true;
          } else if (!hasLunch && position >= 0.3 && position < 0.6) {
            newCategory = 'lunch';
            hasLunch = true;
          } else if (!hasDinner && position >= 0.6) {
            newCategory = 'dinner';
            hasDinner = true;
          } else {
            if (position < 0.3) newCategory = 'breakfast';
            else if (position < 0.6) newCategory = 'lunch';
            else newCategory = 'dinner';
          }

          fixedCount++;
          logger.info(`  🔧 Fixed category: "${place.name}" from "${category}" to "${newCategory}"`);
          return { ...place, category: newCategory };
        }

        // For any other unknown category, default to attraction
        if (!validCategories.includes(category)) {
          fixedCount++;
          logger.info(`  🔧 Fixed category: "${place.name}" from "${category}" to "attraction"`);
          return { ...place, category: 'attraction' };
        }

        return place;
      });

      return { ...day, places: fixedPlaces };
    });

    if (fixedCount > 0) {
      logger.info(`✓ Fixed ${fixedCount} place categories`);
    }

    return { ...tripData, itinerary: fixedItinerary };
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

    const prompt = `Create ${durationDays}-day trip for ${city}, ${country}. Request: "${userQuery}"
${themeContext}

Activities: ${activities.slice(0, 5).join(', ') || 'exploration'}
Vibe: ${vibe.slice(0, 3).join(', ') || 'general'}

PLACES (use these placeIds):
${placesJson}

RULES:
- ${durationDays} days, 5-6 places/day
- Categories: breakfast, lunch, dinner, attraction
- Use placeIds from list above

PRICE GUIDELINES (REALISTIC!):
- Breakfast/Cafe: €5-15 per person
- Lunch: €10-20 per person
- Dinner: €15-35 per person
- Museum/Attraction: €5-20 (many are FREE or €5-10)
- Parks/Viewpoints: €0 (FREE!)
- Be realistic for Eastern European cities like Bratislava/Prague - prices are LOWER than Paris/London

JSON FORMAT:
{
  "title": "Trip title (max 50 chars)",
  "description": "200-250 word description explaining why this trip is perfect for the user, what they'll experience, and what makes it special",
  "itinerary": [{
    "day": 1,
    "title": "Day title",
    "description": "30 words about this day",
    "places": [{
      "placeId": "ChIJ...",
      "name": "Name",
      "category": "breakfast|lunch|dinner|attraction",
      "description": "30-40 words why this fits",
      "duration_minutes": 60,
      "price": "€15",
      "price_value": 15,
      "rating": 4.5,
      "address": "Address",
      "latitude": 0.0,
      "longitude": 0.0,
      "best_time": "Morning|Afternoon|Evening",
      "transportation": {"from_previous": "Start", "method": "walk|metro|taxi", "duration_minutes": 10, "cost": "€0"}
    }]
  }],
  "highlights": ["3 highlights"]
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
      // No estimatedBudget - will be calculated from actual place prices
      highlights: result.highlights || [],
    };
  }

  /**
   * Load and stream images - hero from Unsplash, places from Google
   * Uses parallel batches to speed up loading
   */
  private async loadAndStreamImages(
    emitter: TripEventEmitter,
    tripData: SkeletonResult,
    places: SearchedPlace[],
    city: string
  ): Promise<void> {
    try {
      // 1. Get hero image (non-blocking)
      const heroPromise = this.fetchHeroImage(city, tripData.theme);

      // 2. Collect unique places to fetch photos for
      const placesMap = new Map(places.map(p => [p.placeId, p]));
      const uniquePlaces: Array<{ placeId: string; name: string; photoReference?: string }> = [];
      const seenPlaceIds = new Set<string>();

      for (const day of tripData.itinerary) {
        for (const place of day.places) {
          if (seenPlaceIds.has(place.placeId)) continue;
          seenPlaceIds.add(place.placeId);

          const searchedPlace = placesMap.get(place.placeId);
          uniquePlaces.push({
            placeId: place.placeId,
            name: place.name,
            photoReference: searchedPlace?.photoReference,
          });
        }
      }

      logger.info(`[Images] Loading photos for ${uniquePlaces.length} unique places in parallel batches`);

      // 3. Emit hero image as soon as it's ready
      const heroImage = await heroPromise;
      if (heroImage) {
        emitter.emitImage({
          imageType: 'hero',
          url: heroImage,
        });
      }

      // 4. Load place photos in parallel batches (5 places at a time to avoid rate limits)
      const BATCH_SIZE = 5;
      let successCount = 0;
      let fallbackCount = 0;

      for (let i = 0; i < uniquePlaces.length; i += BATCH_SIZE) {
        const batch = uniquePlaces.slice(i, i + BATCH_SIZE);

        const batchResults = await Promise.allSettled(
          batch.map(async (place) => {
            try {
              // First try: Get photos via Place Details API
              const photos = await googlePlacesPhotosService.getPOIPhotos(place.placeId, 5);

              if (photos.length > 0) {
                return { place, photos, success: true, method: 'details' };
              }

              // Second try: Use photo reference from search results
              if (place.photoReference) {
                const url = `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=${place.photoReference}&key=${process.env.GOOGLE_PLACES_API_KEY}`;
                return {
                  place,
                  photos: [{ url, source: 'google_places', alt_text: place.name }],
                  success: true,
                  method: 'search_ref',
                };
              }

              // Third try: Search for the place by name to get photos
              try {
                const searchResults = await googlePlacesService.textSearch({
                  query: `${place.name} ${city}`,
                });
                const photoRef = searchResults?.[0]?.photos?.[0]?.photo_reference;
                if (photoRef) {
                  const url = `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=${photoRef}&key=${process.env.GOOGLE_PLACES_API_KEY}`;
                  return {
                    place,
                    photos: [{ url, source: 'google_places', alt_text: place.name }],
                    success: true,
                    method: 'search_fallback',
                  };
                }
              } catch (searchErr) {
                // Search failed, continue to next fallback
              }

              return { place, photos: [], success: false, method: 'none' };
            } catch (err) {
              // Fallback on error - try photo reference
              if (place.photoReference) {
                const url = `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=${place.photoReference}&key=${process.env.GOOGLE_PLACES_API_KEY}`;
                return {
                  place,
                  photos: [{ url, source: 'google_places', alt_text: place.name }],
                  success: true,
                  method: 'error_fallback',
                };
              }
              return { place, photos: [], success: false, method: 'error' };
            }
          })
        );

        // Emit photos immediately after each batch completes
        for (const result of batchResults) {
          if (result.status === 'fulfilled' && result.value.photos.length > 0) {
            const { place, photos, method } = result.value;
            if (method !== 'details') fallbackCount++;
            successCount++;

            for (const photo of photos) {
              emitter.emitImage({
                imageType: 'place',
                url: photo.url,
                placeId: place.placeId,
                placeName: place.name,
              });
            }
          }
        }

        // Small delay between batches to avoid rate limits
        if (i + BATCH_SIZE < uniquePlaces.length) {
          await new Promise(resolve => setTimeout(resolve, 200));
        }
      }

      logger.info(`[Images] Finished: ${successCount}/${uniquePlaces.length} places have photos (${fallbackCount} via fallback)`);
    } catch (error) {
      logger.warn('Error loading images:', error);
    }
  }

  /**
   * Enrich places with opening_hours from Google Places Details API
   * This fetches the full weekday_text for each unique place
   */
  private async enrichOpeningHours(places: SearchedPlace[]): Promise<void> {
    // Only enrich places that don't have weekday_text
    const placesToEnrich = places.filter(
      p => !p.opening_hours?.weekday_text || p.opening_hours.weekday_text.length === 0
    );

    if (placesToEnrich.length === 0) {
      logger.info(`[OpeningHours] All ${places.length} places already have opening hours`);
      return;
    }

    logger.info(`[OpeningHours] Enriching ${placesToEnrich.length}/${places.length} places with opening hours`);

    // Batch requests to avoid rate limits (5 at a time)
    const BATCH_SIZE = 5;
    let enrichedCount = 0;

    for (let i = 0; i < placesToEnrich.length; i += BATCH_SIZE) {
      const batch = placesToEnrich.slice(i, i + BATCH_SIZE);

      const results = await Promise.allSettled(
        batch.map(async (place) => {
          try {
            const details = await googlePlacesService.getPlaceDetails(place.placeId);
            if (details?.opening_hours) {
              place.opening_hours = {
                open_now: details.opening_hours.open_now,
                weekday_text: details.opening_hours.weekday_text,
              };
              return true;
            }
            return false;
          } catch (err) {
            logger.debug(`[OpeningHours] Failed to get details for ${place.name}: ${err}`);
            return false;
          }
        })
      );

      enrichedCount += results.filter(r => r.status === 'fulfilled' && r.value).length;
    }

    logger.info(`[OpeningHours] Successfully enriched ${enrichedCount}/${placesToEnrich.length} places`);
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
        if (['breakfast', 'lunch', 'dinner', 'cafe', 'restaurant'].includes(place.category)) {
          foodTotal += value;
        } else {
          activitiesTotal += value;
        }
      }
    }

    // Only show activities/attractions cost (museums, attractions, etc.)
    // Don't include food - user might eat anywhere at different price points
    const calculatedMin = activitiesTotal;
    const calculatedMax = Math.round(activitiesTotal * 1.3); // Small variance

    logger.info(`💰 Price calculation: activities=€${activitiesTotal} (food €${foodTotal} not included)`);
    logger.info(`💰 Total (activities only): €${calculatedMin}-${calculatedMax}`);

    return {
      totalMin: calculatedMin,
      totalMax: calculatedMax,
      currency: 'EUR',
      breakdown: {
        accommodation: { min: 0, max: 0 },
        food: { min: foodTotal, max: Math.round(foodTotal * 1.2) },
        activities: { min: activitiesTotal, max: Math.round(activitiesTotal * 1.2) },
        transport: { min: 0, max: 0 },
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
