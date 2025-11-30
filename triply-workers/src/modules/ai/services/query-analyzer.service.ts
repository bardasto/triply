/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Query Analyzer Service
 * Analyzes free-form user queries to extract trip parameters
 * ═══════════════════════════════════════════════════════════════════════════
 */

import logger from '../../../shared/utils/logger.js';
import geminiService from './gemini.service.js';

// ═══════════════════════════════════════════════════════════════════════════
// Types
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Request type classification:
 * - 'trip': Full multi-day itinerary with multiple places
 * - 'single_place': Single specific place (restaurant, attraction, hotel, etc.)
 * - 'modification': Modify previous result based on feedback
 */
export type RequestType = 'trip' | 'single_place' | 'modification';

/**
 * Place type for single place requests
 */
export type SinglePlaceType =
  | 'restaurant'
  | 'cafe'
  | 'bar'
  | 'hotel'
  | 'attraction'
  | 'museum'
  | 'park'
  | 'shop'
  | 'nightclub'
  | 'spa'
  | 'beach'
  | 'viewpoint'
  | 'other';

export interface TripIntent {
  /** Type of request - trip or single place */
  requestType: RequestType;
  city: string;
  country?: string;
  durationDays: number;
  activities: string[];
  vibe: string[];
  budget?: 'budget' | 'mid-range' | 'luxury';
  travelStyle?: string[];
  specificInterests?: string[];
  rawQuery: string;
  /** Places from conversation context that MUST be included in the trip */
  mustIncludePlaces?: string[];
  /**
   * Main theme extracted from conversation context
   * E.g., "anime", "food", "history", "romance", "adventure"
   * This ensures the ENTIRE trip follows a consistent theme
   */
  conversationTheme?: string;
  /**
   * Keywords/interests extracted from the entire conversation
   * Used for thematic consistency across the trip
   */
  thematicKeywords?: string[];
}

export interface SinglePlaceIntent {
  /** Type of request - always 'single_place' */
  requestType: 'single_place';
  /** Type of place being requested */
  placeType: SinglePlaceType;
  /** City where the place should be located */
  city: string;
  /** Country (if mentioned or inferred) */
  country?: string;
  /** Specific criteria for the place */
  criteria: string[];
  /** Budget level */
  budget?: 'budget' | 'mid-range' | 'luxury';
  /** Cuisine type (for restaurants) */
  cuisineType?: string[];
  /** Special requirements (Michelin, rooftop, romantic, etc.) */
  specialRequirements?: string[];
  /** Original user query */
  rawQuery: string;
  /**
   * If user asks for a SPECIFIC named place (e.g., "Louvre Museum", "Eiffel Tower", "Central Park")
   * This is the exact name they want - we should search for THIS place, not recommend alternatives
   */
  specificPlaceName?: string;
  /**
   * Original location mentioned by user (before resolving to city)
   * E.g., "Banff National Park" -> originalLocation: "Banff National Park", city: "Banff"
   */
  originalLocation?: string;
  /**
   * Type of the original location (landmark, national_park, museum, etc.)
   */
  originalLocationType?: string;
}

/**
 * Modification intent - user wants to change previous result
 */
export interface ModificationIntent {
  /** Type of request - always 'modification' */
  requestType: 'modification';
  /** What type of content is being modified */
  modifyingType: 'single_place' | 'trip';
  /** The modification request */
  modification: string;
  /** Modification category */
  modificationCategory: 'cheaper' | 'expensive' | 'different_style' | 'different_location' | 'other';
  /** New budget level if changing price */
  newBudget?: 'budget' | 'mid-range' | 'luxury';
  /** New criteria to apply */
  newCriteria?: string[];
  /** City from context (extracted from conversation) */
  city?: string;
  /** Place type from context */
  placeType?: SinglePlaceType;
  /** Original user query */
  rawQuery: string;
}

export type AnalyzedIntent = TripIntent | SinglePlaceIntent | ModificationIntent;

/**
 * Conversation context message from the chat history
 * Contains full context about user preferences and generated results
 */
export interface ConversationMessage {
  role: 'user' | 'assistant';
  content?: string;
  type?: 'places' | 'trip';
  places?: Array<{
    name: string;
    type?: string;
    category?: string;
    city?: string;
    country?: string;
    address?: string;
    rating?: number;
    review_count?: number;
    price?: string;
    price_level?: string;
    price_range?: string;
    estimated_price?: string;
    cuisine_types?: string[];
    features?: string[];
    opening_hours?: any;
    is_open_now?: boolean;
    day?: number;
  }>;
  // Context state
  city?: string;
  country?: string;
  duration_days?: number;
  activity_type?: string;
}

// ═══════════════════════════════════════════════════════════════════════════
// Query Analyzer Service
// ═══════════════════════════════════════════════════════════════════════════

class QueryAnalyzerService {
  constructor() {
    logger.info('✅ Query Analyzer Service initialized (using Gemini)');
  }

  /**
   * Analyze user query and classify intent (trip vs single place)
   * This is the main entry point that intelligently routes to the correct analyzer
   * @param userQuery - The current user query
   * @param conversationContext - Optional conversation history for context-aware analysis
   */
  async analyzeQuery(userQuery: string, conversationContext?: ConversationMessage[]): Promise<AnalyzedIntent> {
    const startTime = Date.now();

    // Build context summary if available
    const contextSummary = this.buildContextSummary(conversationContext);
    const hasContext = contextSummary.length > 0;

    const systemPrompt = `You are an expert travel query analyzer. Your job is to classify user queries and extract parameters.

═══════════════════════════════════════════════════════════════════════════════
STEP 1: CLASSIFY THE REQUEST TYPE
═══════════════════════════════════════════════════════════════════════════════

CRITICAL: You MUST first determine if the user wants:
1. "trip" - A full travel itinerary with multiple places over multiple days
2. "single_place" - ONE specific place (restaurant, hotel, attraction, etc.)
3. "modification" - MODIFY/CHANGE the previous result (cheaper, more expensive, different style, etc.)

MODIFICATION INDICATORS (requestType = "modification") - HIGHEST PRIORITY when context exists:
- Price feedback: "too expensive", "слишком дорого", "cheaper", "more budget", "дешевле"
- Quality upgrade: "more prestigious", "more luxury", "higher end", "престижнее", "дороже"
- Style change: "something different", "другой стиль", "more romantic", "more casual"
- Negative feedback about previous: "don't like it", "не нравится", "something else"
- Short feedback phrases after receiving recommendations: "no", "нет", "another one", "другой"
- Explicit change requests: "change it", "поменяй", "find another", "найди другой"

SINGLE PLACE INDICATORS (requestType = "single_place"):
- Asks for ONE specific place: "a restaurant", "a hotel", "a cafe", "a bar"
- Uses singular form: "recommend me a...", "find me a...", "I want a..."
- Mentions specific place types: "Michelin restaurant", "rooftop bar", "best cafe"
- Asks for recommendations: "where can I eat...", "where should I stay..."
- Food/dining focused WITHOUT trip context: "I want sushi", "best pizza place"
- Specific establishment requests: "romantic restaurant", "cheap hotel", "quiet cafe"
- NO mention of days/duration/itinerary

TRIP INDICATORS (requestType = "trip"):
- Mentions duration: "3 days", "weekend", "week", "5 day trip"
- Uses plural places: "places to visit", "things to do", "attractions"
- Asks for itinerary: "plan a trip", "create an itinerary", "travel plan"
- Multiple activities: "sightseeing and food and nightlife"
- Exploration focus: "explore Paris", "discover Tokyo", "adventure in..."
- References to previous places: "make a trip from these places", "create a trip", "full itinerary"
- Wants to EXPAND previous recommendations into a trip
- IMPORTANT: If query mentions "create a X-day trip" and mentions "include" or "with" a specific place → requestType = "trip"
- Queries like "Create a 3-day trip to Paris with Restaurant X" → ALWAYS trip, never single_place

${hasContext ? `
═══════════════════════════════════════════════════════════════════════════════
CONVERSATION CONTEXT (Previous messages in this chat)
═══════════════════════════════════════════════════════════════════════════════
${contextSummary}

IMPORTANT CONTEXT RULES:
- If user gives FEEDBACK about previous result (price, style, quality) → requestType = "modification"
- If user says "make a trip", "create trip", "full itinerary" after receiving places → requestType = "trip"
- Extract city from context if not mentioned in current query
- If user wants a trip based on previously shown places, include those places in "mustIncludePlaces"
- The "mustIncludePlaces" field should contain names of places from context that user wants included
- CRITICAL: If query contains "with [place name]" or "include [place name]" or mentions a specific place name from context, add it to "mustIncludePlaces"
- When creating a trip after single places were shown, ALWAYS include those places in mustIncludePlaces
` : ''}

═══════════════════════════════════════════════════════════════════════════════
STEP 2: EXTRACT PARAMETERS BASED ON TYPE
═══════════════════════════════════════════════════════════════════════════════

FOR MODIFICATION requests, return:
{
  "requestType": "modification",
  "modifyingType": "single_place" or "trip" (based on what was shown in context),
  "modification": "user's modification request in clear terms",
  "modificationCategory": "cheaper|expensive|different_style|different_location|other",
  "newBudget": "budget|mid-range|luxury" (if price-related),
  "newCriteria": ["new requirements to apply"],
  "city": "city from conversation context (REQUIRED! Look at previous places/trips)",
  "placeType": "place type from context (restaurant, cafe, etc.)"
}

FOR SINGLE_PLACE requests, return:
{
  "requestType": "single_place",
  "placeType": "restaurant|cafe|bar|hotel|attraction|museum|park|shop|nightclub|spa|beach|viewpoint|other",
  "city": "city name (the nearest city for trip planning)",
  "country": "country name",
  "criteria": ["specific criteria mentioned"],
  "budget": "budget|mid-range|luxury" (if mentioned),
  "cuisineType": ["cuisine types"] (for restaurants/cafes),
  "specialRequirements": ["michelin", "rooftop", "romantic", "view", "quiet", etc.],
  "specificPlaceName": "EXACT name of the place if user wants a SPECIFIC place (e.g., 'Louvre Museum', 'Eiffel Tower', 'Central Park', 'Noma'). Set to null if user wants a RECOMMENDATION (e.g., 'a good restaurant', 'best museum').",
  "originalLocation": "The original location mentioned by user before resolving to city (e.g., 'Banff National Park', 'Great Barrier Reef'). Set to null if user mentioned a city directly.",
  "originalLocationType": "Type of original location: city|landmark|museum|national_park|restaurant|beach|island|natural_wonder|etc. Only set if originalLocation is set."
}

CRITICAL DISTINCTION FOR specificPlaceName:
- "I want to visit the Louvre Museum" → specificPlaceName: "Louvre Museum" (user wants THIS exact place)
- "I want to visit a museum in Paris" → specificPlaceName: null (user wants a RECOMMENDATION)
- "Show me Central Park" → specificPlaceName: "Central Park" (user wants THIS exact place)
- "Show me a nice park in New York" → specificPlaceName: null (user wants a RECOMMENDATION)
- "Noma restaurant in Copenhagen" → specificPlaceName: "Noma" (user wants THIS exact restaurant)
- "best restaurant in Copenhagen" → specificPlaceName: null (user wants a RECOMMENDATION)

WHEN TO SET originalLocation:
- "Banff National Park hiking" → originalLocation: "Banff National Park", city: "Banff"
- "Great Barrier Reef diving" → originalLocation: "Great Barrier Reef", city: "Cairns"
- "trip to Paris" → originalLocation: null, city: "Paris" (user mentioned city directly)

FOR TRIP requests, return:
{
  "requestType": "trip",
  "city": "city name",
  "country": "country name",
  "durationDays": number (default 3 if not specified),
  "activities": ["activities"],
  "vibe": ["vibes"],
  "budget": "budget|mid-range|luxury",
  "travelStyle": ["styles"],
  "specificInterests": ["interests"],
  "mustIncludePlaces": ["place names from context that MUST be included in the trip"],
  "conversationTheme": "The MAIN theme of the entire conversation (e.g., 'anime', 'food', 'history', 'romance'). Extract from previous user messages and place types.",
  "thematicKeywords": ["All relevant keywords from conversation that define the trip's character (e.g., ['anime', 'manga', 'otaku', 'pop culture'] for anime theme)"]
}

CRITICAL - EXTRACTING CONVERSATION THEME:
When user creates a trip after previous searches, you MUST extract the theme from conversation:
- If user searched "anime restaurant" then creates trip → conversationTheme: "anime", thematicKeywords: ["anime", "manga", "otaku", "japanese pop culture", "themed cafes"]
- If user searched "Michelin restaurant" then creates trip → conversationTheme: "fine dining", thematicKeywords: ["gourmet", "haute cuisine", "culinary excellence"]
- If user searched "romantic spots" then creates trip → conversationTheme: "romance", thematicKeywords: ["romantic", "couples", "intimate", "sunset"]
- If user searched "hiking trails" then creates trip → conversationTheme: "adventure", thematicKeywords: ["hiking", "nature", "outdoor", "trails", "active"]

The theme should define the ENTIRE trip character, not just include one place!

Return ONLY valid JSON, no additional text.`;

    const userPrompt = `Analyze this query: "${userQuery}"`;

    try {
      const result = await geminiService.generateJSON<any>({
        systemPrompt,
        userPrompt,
        temperature: 0.2,
        maxTokens: 600,
      });

      const duration = Date.now() - startTime;
      logger.info(`Query analyzed in ${duration}ms`);

      result.rawQuery = userQuery;

      logger.info('═══════════════════════════════════════════════════════');
      logger.info(`📊 Query Classification Result:`);
      logger.info(`   Type: ${result.requestType}`);
      if (result.requestType === 'modification') {
        logger.info(`   Modifying: ${result.modifyingType}`);
        logger.info(`   Category: ${result.modificationCategory}`);
        logger.info(`   Request: ${result.modification}`);
      } else if (result.requestType === 'single_place') {
        logger.info(`   City: ${result.city}`);
        logger.info(`   Place Type: ${result.placeType}`);
        logger.info(`   Special Requirements: ${result.specialRequirements?.join(', ') || 'none'}`);
      } else {
        logger.info(`   City: ${result.city}`);
        logger.info(`   Duration: ${result.durationDays} days`);
        logger.info(`   Activities: ${result.activities?.join(', ') || 'none'}`);
      }
      logger.info('═══════════════════════════════════════════════════════');

      return result as AnalyzedIntent;
    } catch (error) {
      logger.error('Failed to analyze query:', error);
      throw error;
    }
  }

  /**
   * Analyze query specifically for trip generation (assumes trip context)
   * This skips the intent classification and always returns TripIntent
   */
  async analyzeQueryForTrip(userQuery: string): Promise<TripIntent> {
    const startTime = Date.now();

    const systemPrompt = `You are a travel query analyzer. Extract trip parameters from user queries.

CRITICAL RULES:
- Extract the city name and country (if mentioned)
- Determine trip duration in days (default to 3 if not specified)
- Identify all activities and interests mentioned
- Detect the vibe/mood (romantic, adventure, relaxing, cultural, party, family, solo, etc.)
- Determine budget level if mentioned (budget/mid-range/luxury)
- Extract specific interests (anime, photography, food, history, architecture, etc.)
- Return ONLY valid JSON`;

    const userPrompt = `Analyze this travel query: "${userQuery}"`;

    try {
      const result = await geminiService.generateJSON<TripIntent>({
        systemPrompt,
        userPrompt,
        temperature: 0.3,
        maxTokens: 500,
      });

      const duration = Date.now() - startTime;
      logger.info(`Query analyzed for trip in ${duration}ms`);

      result.rawQuery = userQuery;
      result.requestType = 'trip';

      logger.info('Extracted trip intent:', result);

      return result;
    } catch (error) {
      logger.error('Failed to analyze query for trip:', error);
      throw error;
    }
  }

  /**
   * Validate and normalize ANY location - finds the nearest city/region for trip planning
   * Works with: cities, landmarks, attractions, national parks, specific places, etc.
   */
  async validateCity(locationName: string): Promise<{ city: string; country: string; locationType?: string; interests?: string[] } | null> {
    const systemPrompt = `You are a travel expert. Given ANY location or place name, determine the best city/region to use for trip planning and identify relevant interests/themes.`;
    const userPrompt = `Analyze this location: "${locationName}"

Your task:
1. If it's a city/region - return it directly
2. If it's a specific place (landmark, attraction, restaurant, park, etc.) - find the nearest major city or tourist region
3. Identify what type of location this is and what interests/themes it suggests

EXAMPLES:
"Paris" -> {"city": "Paris", "country": "France", "locationType": "city", "interests": ["culture", "art", "cuisine", "history"]}
"Eiffel Tower" -> {"city": "Paris", "country": "France", "locationType": "landmark", "interests": ["landmarks", "photography", "romantic"]}
"Banff National Park" -> {"city": "Banff", "country": "Canada", "locationType": "national_park", "interests": ["nature", "hiking", "wildlife", "mountains", "outdoor_adventure"]}
"Louvre Museum" -> {"city": "Paris", "country": "France", "locationType": "museum", "interests": ["art", "history", "culture", "museums"]}
"Central Park" -> {"city": "New York", "country": "USA", "locationType": "park", "interests": ["nature", "walking", "relaxation", "outdoor"]}
"Shibuya Crossing" -> {"city": "Tokyo", "country": "Japan", "locationType": "landmark", "interests": ["urban", "culture", "photography", "shopping"]}
"Great Barrier Reef" -> {"city": "Cairns", "country": "Australia", "locationType": "natural_wonder", "interests": ["diving", "snorkeling", "marine_life", "nature"]}
"Noma Restaurant" -> {"city": "Copenhagen", "country": "Denmark", "locationType": "restaurant", "interests": ["fine_dining", "gastronomy", "culinary"]}
"Machu Picchu" -> {"city": "Cusco", "country": "Peru", "locationType": "archaeological_site", "interests": ["history", "hiking", "archaeology", "adventure"]}
"Santorini" -> {"city": "Santorini", "country": "Greece", "locationType": "island", "interests": ["beaches", "romantic", "sunsets", "photography"]}
"Swiss Alps" -> {"city": "Interlaken", "country": "Switzerland", "locationType": "mountain_region", "interests": ["skiing", "hiking", "mountains", "nature", "adventure"]}
"XYZ123" -> {"city": null, "country": null, "locationType": null, "interests": []}

Return JSON with:
- city: The nearest major city or tourist hub for trip planning (or null if invalid)
- country: The country
- locationType: What type of place this is (city, landmark, museum, national_park, restaurant, beach, island, etc.)
- interests: Array of relevant travel interests/themes this place suggests`;

    try {
      const result = await geminiService.generateJSON<{
        city: string | null;
        country: string | null;
        locationType?: string;
        interests?: string[];
      }>({
        systemPrompt,
        userPrompt,
        temperature: 0.2,
        maxTokens: 200,
      });

      if (result.city) {
        logger.info(`  📍 Location "${locationName}" resolved to: ${result.city}, ${result.country} (${result.locationType})`);
        logger.info(`  🎯 Suggested interests: ${result.interests?.join(', ') || 'general'}`);
        return {
          city: result.city,
          country: result.country || '',
          locationType: result.locationType,
          interests: result.interests || []
        };
      }
      return null;
    } catch (error) {
      logger.error('Failed to validate location:', error);
      return null;
    }
  }

  /**
   * Build a summary of conversation context for the AI prompt
   */
  private buildContextSummary(context?: ConversationMessage[]): string {
    if (!context || context.length === 0) {
      return '';
    }

    const parts: string[] = [];

    for (const msg of context) {
      if (msg.role === 'user' && msg.content) {
        // Include full user message - this is the key context!
        parts.push(`USER: "${msg.content}"`);
      } else if (msg.role === 'assistant') {
        if (msg.type === 'places' && msg.places && msg.places.length > 0) {
          // Build detailed place info
          const placeDetails = msg.places.map(p => {
            const details: string[] = [];
            details.push(`"${p.name}"`);
            if (p.type) details.push(`type: ${p.type}`);
            if (p.city) details.push(`city: ${p.city}`);
            if (p.country) details.push(`country: ${p.country}`);
            if (p.rating) details.push(`rating: ${p.rating}`);
            if (p.estimated_price) details.push(`price: ${p.estimated_price}`);
            if (p.price_level) details.push(`price_level: ${p.price_level}`);
            if (p.cuisine_types && p.cuisine_types.length > 0) {
              details.push(`cuisine: ${p.cuisine_types.join(', ')}`);
            }
            if (p.features && p.features.length > 0) {
              details.push(`features: ${p.features.join(', ')}`);
            }
            return `  - ${details.join(', ')}`;
          }).join('\n');

          parts.push(`AI RECOMMENDED PLACES:\n${placeDetails}`);

          // Add summary of current context state
          if (msg.city) {
            parts.push(`CURRENT CONTEXT: City=${msg.city}, Country=${msg.country || 'unknown'}`);
          }
        } else if (msg.type === 'trip') {
          const tripDetails: string[] = [];
          if (msg.city) tripDetails.push(`city: ${msg.city}`);
          if (msg.country) tripDetails.push(`country: ${msg.country}`);
          if (msg.duration_days) tripDetails.push(`duration: ${msg.duration_days} days`);
          if (msg.activity_type) tripDetails.push(`activity: ${msg.activity_type}`);

          let tripInfo = `AI GENERATED TRIP: ${tripDetails.join(', ')}`;

          if (msg.places && msg.places.length > 0) {
            const placeNames = msg.places.map(p => p.name).join(', ');
            tripInfo += `\n  Places: ${placeNames}`;
          }
          parts.push(tripInfo);
        }
      }
    }

    // Add instruction for AI to use this context
    if (parts.length > 0) {
      parts.push(`
---
REMEMBER: Use ALL information from above as memory. The user's previous messages contain their preferences, requirements, and constraints. When they ask for modifications, apply them to the SAME city/context unless they explicitly mention a different location.`);
    }

    return parts.join('\n\n');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Singleton Instance
// ═══════════════════════════════════════════════════════════════════════════

const queryAnalyzerService = new QueryAnalyzerService();

export default queryAnalyzerService;
