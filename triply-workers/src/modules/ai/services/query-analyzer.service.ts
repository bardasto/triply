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

export interface TripIntent {
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
   * Analyze user query and extract trip parameters
   */
  async analyzeQuery(userQuery: string): Promise<TripIntent> {
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
  "city": "Berlin",
  "country": "Germany",
  "durationDays": 5,
  "activities": ["anime", "manga", "Japanese culture", "city exploration"],
  "vibe": ["pop culture", "alternative"],
  "specificInterests": ["anime", "manga", "Japanese culture", "cosplay"]
}

Query: "2-day cruise in Barcelona for couples"
Output: {
  "city": "Barcelona",
  "country": "Spain",
  "durationDays": 2,
  "activities": ["cruise", "beach", "romantic", "coastal"],
  "vibe": ["romantic", "relaxing", "maritime"],
  "travelStyle": ["couples"],
  "specificInterests": ["cruises", "sailing"]
}

Query: "budget student trip in Krakow for 3 days"
Output: {
  "city": "Krakow",
  "country": "Poland",
  "durationDays": 3,
  "activities": ["city exploration", "nightlife", "budget activities"],
  "vibe": ["social", "budget-friendly"],
  "budget": "budget",
  "travelStyle": ["student", "backpacker"]
}

Return JSON only, no additional text.`,
              },
              {
                role: 'user',
                content: `Analyze this travel query: "${userQuery}"`,
              },
            ],
            temperature: 0.3, // Lower temperature for more consistent extraction
            max_tokens: 500,
            response_format: { type: 'json_object' },
          });

          const duration = Date.now() - startTime;
          logger.info(`Query analyzed in ${duration}ms`);

          const content = response.choices[0]?.message?.content;
          if (!content) {
            throw new Error('Empty response from OpenAI');
          }

          const result = JSON.parse(content) as TripIntent;
          result.rawQuery = userQuery;

          logger.info('Extracted trip intent:', result);

          return result;
        });
      });
    } catch (error) {
      logger.error('Failed to analyze query:', error);
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
