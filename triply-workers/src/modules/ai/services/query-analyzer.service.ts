/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Query Analyzer Service
 * Analyzes free-form user queries to extract trip parameters
 * ═══════════════════════════════════════════════════════════════════════════
 */

import OpenAI from 'openai';
import config from '../../../shared/config/env.js';
import logger from '../../../shared/utils/logger.js';
import retry from '../../../shared/utils/retry.js';
import rateLimiter from '../../../shared/utils/rate-limiter.js';

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
  private client: OpenAI;

  constructor() {
    this.client = new OpenAI({
      apiKey: config.OPENAI_API_KEY,
    });

    logger.info('✅ Query Analyzer Service initialized');
  }

  /**
   * Analyze user query and classify intent (trip vs single place)
   * This is the main entry point that intelligently routes to the correct analyzer
   */
  async analyzeQuery(userQuery: string): Promise<AnalyzedIntent> {
    const startTime = Date.now();

    try {
      return await rateLimiter.execute('openai', async () => {
        return retry(async () => {
          const response = await this.client.chat.completions.create({
            model: config.OPENAI_MODEL,
            messages: [
              {
                role: 'system',
                content: `You are an expert travel query analyzer. Your job is to classify user queries and extract parameters.

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

═══════════════════════════════════════════════════════════════════════════════
EXAMPLES
═══════════════════════════════════════════════════════════════════════════════

Query: "I want a Michelin restaurant in Paris"
Output: {
  "requestType": "single_place",
  "placeType": "restaurant",
  "city": "Paris",
  "country": "France",
  "criteria": ["fine dining", "upscale"],
  "budget": "luxury",
  "cuisineType": ["french"],
  "specialRequirements": ["michelin"]
}

Query: "recommend me a rooftop bar in Barcelona with good views"
Output: {
  "requestType": "single_place",
  "placeType": "bar",
  "city": "Barcelona",
  "country": "Spain",
  "criteria": ["rooftop", "views", "drinks"],
  "specialRequirements": ["rooftop", "view", "scenic"]
}

Query: "where can I get the best ramen in Tokyo"
Output: {
  "requestType": "single_place",
  "placeType": "restaurant",
  "city": "Tokyo",
  "country": "Japan",
  "criteria": ["authentic", "best rated"],
  "cuisineType": ["japanese", "ramen"],
  "specialRequirements": ["best", "authentic"]
}

Query: "romantic weekend in Paris"
Output: {
  "requestType": "trip",
  "city": "Paris",
  "country": "France",
  "durationDays": 2,
  "activities": ["romantic", "city exploration", "fine dining"],
  "vibe": ["romantic", "relaxing"],
  "budget": "mid-range"
}

Query: "plan a 5 day cultural trip to Rome"
Output: {
  "requestType": "trip",
  "city": "Rome",
  "country": "Italy",
  "durationDays": 5,
  "activities": ["museums", "historical sites", "art", "architecture"],
  "vibe": ["cultural", "educational"],
  "specificInterests": ["history", "art", "ancient ruins"]
}

Query: "cheap hostel in Amsterdam"
Output: {
  "requestType": "single_place",
  "placeType": "hotel",
  "city": "Amsterdam",
  "country": "Netherlands",
  "criteria": ["hostel", "affordable", "backpacker"],
  "budget": "budget",
  "specialRequirements": ["cheap", "budget-friendly"]
}

Query: "best coffee shop in Vienna"
Output: {
  "requestType": "single_place",
  "placeType": "cafe",
  "city": "Vienna",
  "country": "Austria",
  "criteria": ["traditional", "best rated"],
  "specialRequirements": ["best", "traditional viennese"]
}

Return ONLY valid JSON, no additional text.`,
              },
              {
                role: 'user',
                content: `Analyze this query: "${userQuery}"`,
              },
            ],
            temperature: 0.2, // Very low temperature for consistent classification
            max_tokens: 600,
            response_format: { type: 'json_object' },
          });

          const duration = Date.now() - startTime;
          logger.info(`Query analyzed in ${duration}ms`);

          const content = response.choices[0]?.message?.content;
          if (!content) {
            throw new Error('Empty response from OpenAI');
          }

          const result = JSON.parse(content);
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
        });
      });
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

    try {
      return await rateLimiter.execute('openai', async () => {
        return retry(async () => {
          const response = await this.client.chat.completions.create({
            model: config.OPENAI_MODEL,
            messages: [
              {
                role: 'system',
                content: `You are a travel query analyzer. Extract trip parameters from user queries.

CRITICAL RULES:
- Extract the city name and country (if mentioned)
- Determine trip duration in days (default to 3 if not specified)
- Identify all activities and interests mentioned
- Detect the vibe/mood (romantic, adventure, relaxing, cultural, party, family, solo, etc.)
- Determine budget level if mentioned (budget/mid-range/luxury)
- Extract specific interests (anime, photography, food, history, architecture, etc.)
- Return ONLY valid JSON

EXAMPLES:
Query: "romantic weekend in Paris"
Output: {
  "requestType": "trip",
  "city": "Paris",
  "country": "France",
  "durationDays": 2,
  "activities": ["romantic", "city exploration", "fine dining"],
  "vibe": ["romantic", "relaxing"],
  "budget": "mid-range",
  "specificInterests": []
}

Query: "anime Tokyo-style trip but in Berlin for 5 days"
Output: {
  "requestType": "trip",
  "city": "Berlin",
  "country": "Germany",
  "durationDays": 5,
  "activities": ["anime", "manga", "Japanese culture", "city exploration"],
  "vibe": ["pop culture", "alternative"],
  "specificInterests": ["anime", "manga", "Japanese culture", "cosplay"]
}

Return JSON only, no additional text.`,
              },
              {
                role: 'user',
                content: `Analyze this travel query: "${userQuery}"`,
              },
            ],
            temperature: 0.3,
            max_tokens: 500,
            response_format: { type: 'json_object' },
          });

          const duration = Date.now() - startTime;
          logger.info(`Query analyzed for trip in ${duration}ms`);

          const content = response.choices[0]?.message?.content;
          if (!content) {
            throw new Error('Empty response from OpenAI');
          }

          const result = JSON.parse(content) as TripIntent;
          result.rawQuery = userQuery;
          result.requestType = 'trip';

          logger.info('Extracted trip intent:', result);

          return result;
        });
      });
    } catch (error) {
      logger.error('Failed to analyze query for trip:', error);
      throw error;
    }
  }

  /**
   * Validate and normalize city name
   */
  async validateCity(cityName: string): Promise<{ city: string; country: string } | null> {
    try {
      return await rateLimiter.execute('openai', async () => {
        const response = await this.client.chat.completions.create({
          model: 'gpt-3.5-turbo',
          messages: [
            {
              role: 'user',
              content: `Is "${cityName}" a real city? If yes, return JSON with normalized city name and country. If no, return null.

Examples:
"Paris" -> {"city": "Paris", "country": "France"}
"Barselona" -> {"city": "Barcelona", "country": "Spain"}
"Tokyo" -> {"city": "Tokyo", "country": "Japan"}
"XYZ123" -> null

Return JSON only.`,
            },
          ],
          temperature: 0.1,
          max_tokens: 100,
          response_format: { type: 'json_object' },
        });

        const content = response.choices[0]?.message?.content;
        if (!content) return null;

        const result = JSON.parse(content);
        return result.city ? result : null;
      });
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
