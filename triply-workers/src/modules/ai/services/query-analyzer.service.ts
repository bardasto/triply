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
  "city": "city name",
  "country": "country name",
  "criteria": ["specific criteria mentioned"],
  "budget": "budget|mid-range|luxury" (if mentioned),
  "cuisineType": ["cuisine types"] (for restaurants/cafes),
  "specialRequirements": ["michelin", "rooftop", "romantic", "view", "quiet", etc.]
}

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
  "mustIncludePlaces": ["place names from context that MUST be included in the trip"]
}

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
   * Validate and normalize city name
   */
  async validateCity(cityName: string): Promise<{ city: string; country: string } | null> {
    const systemPrompt = `You validate city names and return their normalized form with country.`;
    const userPrompt = `Is "${cityName}" a real city? If yes, return JSON with normalized city name and country. If no, return {"city": null, "country": null}.

Examples:
"Paris" -> {"city": "Paris", "country": "France"}
"Barselona" -> {"city": "Barcelona", "country": "Spain"}
"Tokyo" -> {"city": "Tokyo", "country": "Japan"}
"XYZ123" -> {"city": null, "country": null}`;

    try {
      const result = await geminiService.generateJSON<{ city: string | null; country: string | null }>({
        systemPrompt,
        userPrompt,
        temperature: 0.1,
        maxTokens: 100,
      });

      return result.city ? { city: result.city, country: result.country || '' } : null;
    } catch (error) {
      logger.error('Failed to validate city:', error);
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
