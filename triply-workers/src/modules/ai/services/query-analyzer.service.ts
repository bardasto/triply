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
 */
export type RequestType = 'trip' | 'single_place';

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

export type AnalyzedIntent = TripIntent | SinglePlaceIntent;

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
   */
  async analyzeQuery(userQuery: string): Promise<AnalyzedIntent> {
    const startTime = Date.now();

    const systemPrompt = `You are an expert travel query analyzer. Your job is to classify user queries and extract parameters.

═══════════════════════════════════════════════════════════════════════════════
STEP 1: CLASSIFY THE REQUEST TYPE
═══════════════════════════════════════════════════════════════════════════════

CRITICAL: You MUST first determine if the user wants:
1. "trip" - A full travel itinerary with multiple places over multiple days
2. "single_place" - ONE specific place (restaurant, hotel, attraction, etc.)

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

═══════════════════════════════════════════════════════════════════════════════
STEP 2: EXTRACT PARAMETERS BASED ON TYPE
═══════════════════════════════════════════════════════════════════════════════

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
  "specificInterests": ["interests"]
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
      logger.info(`   City: ${result.city}`);
      if (result.requestType === 'single_place') {
        logger.info(`   Place Type: ${result.placeType}`);
        logger.info(`   Special Requirements: ${result.specialRequirements?.join(', ') || 'none'}`);
      } else {
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
}

// ═══════════════════════════════════════════════════════════════════════════
// Singleton Instance
// ═══════════════════════════════════════════════════════════════════════════

const queryAnalyzerService = new QueryAnalyzerService();

export default queryAnalyzerService;
