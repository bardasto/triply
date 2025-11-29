/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Gemini Service
 * Генерация travel itineraries через Gemini 2.0 Flash
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { GoogleGenerativeAI } from '@google/generative-ai';
import config from '../../../shared/config/env.js';
import logger, { logApiCall, logGeneration } from '../../../shared/utils/logger.js';
import retry from '../../../shared/utils/retry.js';
import rateLimiter from '../../../shared/utils/rate-limiter.js';

// ═══════════════════════════════════════════════════════════════════════════
// Types (same as OpenAI service for compatibility)
// ═══════════════════════════════════════════════════════════════════════════

export interface POIReference {
  id: string;
  name: string;
  category: string;
  lat: number;
  lon: number;
}

export interface RestaurantReference {
  id: string;
  name: string;
  cuisine_types: string[];
  rating?: number;
  price_level?: number;
  address?: string;
  lat: number;
  lon: number;
  google_place_id?: string;
  primary_photo?: string;
  photos?: string[];
  description?: string;
}

export interface GenerateTripParams {
  city: string;
  country: string;
  activity: string;
  durationDays: number;
  poiList: POIReference[];
  restaurantList?: RestaurantReference[];
  language?: string;
}

export interface TripPlace {
  poi_id: string;
  name: string;
  type: string;
  category: string;
  description: string;
  duration_minutes: number;
  price: string;
  price_value: number | null;
  rating: number;
  address: string;
  latitude: number;
  longitude: number;
  google_place_id?: string;
  image_url?: string;
  opening_hours?: string;
  best_time?: string;
  cuisine?: string;
  transportation?: {
    from_previous: string;
    method: string;
    duration_minutes: number;
    cost: string;
  };
}

export interface TripDay {
  day: number;
  title: string;
  description: string;
  places: TripPlace[];
}

export interface TripSkeleton {
  title: string;
  description: string;
  duration: string;
  activityType: string;
  itinerary: TripDay[];
  highlights: string[];
  includes: string[];
  recommendedBudget: {
    min: number;
    max: number;
    currency: string;
  };
  bestSeasons: string[];
}

// ═══════════════════════════════════════════════════════════════════════════
// Gemini Service Class
// ═══════════════════════════════════════════════════════════════════════════

class GeminiService {
  private client: GoogleGenerativeAI;
  private model: any;

  constructor() {
    this.client = new GoogleGenerativeAI(config.GEMINI_API_KEY);
    this.model = this.client.getGenerativeModel({
      model: 'gemini-2.0-flash-exp',
      generationConfig: {
        responseMimeType: 'application/json',
      },
    });

    logger.info('✅ Gemini Service initialized (gemini-2.0-flash-exp)');
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Generate JSON (main method for structured output)
  // ═════════════════════════════════════════════════════════════════════════

  async generateJSON<T = any>(params: {
    systemPrompt: string;
    userPrompt: string;
    temperature?: number;
    maxTokens?: number;
  }): Promise<T> {
    const { systemPrompt, userPrompt, temperature = 0.7, maxTokens = 4096 } = params;
    const startTime = Date.now();

    try {
      return await rateLimiter.execute('gemini', async () => {
        return retry(
          async () => {
            const chat = this.model.startChat({
              generationConfig: {
                temperature,
                maxOutputTokens: maxTokens,
                responseMimeType: 'application/json',
              },
            });

            // Combine system and user prompts
            const fullPrompt = `${systemPrompt}\n\n${userPrompt}`;

            const result = await chat.sendMessage(fullPrompt);
            const response = await result.response;
            const text = response.text();

            const duration = Date.now() - startTime;
            logApiCall('gemini', 'generateJSON', duration, true);

            // Parse JSON response
            const parsed = JSON.parse(text);
            return parsed as T;
          },
          {
            maxRetries: 2,
            shouldRetry: (error: any) => {
              if (error.message?.includes('429')) return true;
              if (error.message?.includes('RESOURCE_EXHAUSTED')) return true;
              return false;
            },
          }
        );
      });
    } catch (error) {
      const duration = Date.now() - startTime;
      logger.error({ error, duration }, 'Gemini generateJSON failed');
      throw error;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Generate Text (for simple text responses)
  // ═════════════════════════════════════════════════════════════════════════

  async generateText(params: {
    prompt: string;
    maxTokens?: number;
    temperature?: number;
  }): Promise<string> {
    const { prompt, maxTokens = 200, temperature = 0.7 } = params;
    const startTime = Date.now();

    try {
      return await rateLimiter.execute('gemini', async () => {
        const textModel = this.client.getGenerativeModel({
          model: 'gemini-2.0-flash-exp',
        });

        const result = await textModel.generateContent({
          contents: [{ role: 'user', parts: [{ text: prompt }] }],
          generationConfig: {
            temperature,
            maxOutputTokens: maxTokens,
          },
        });

        const response = await result.response;
        const duration = Date.now() - startTime;
        logApiCall('gemini', 'generateText', duration, true);

        return response.text().trim();
      });
    } catch (error) {
      logger.error({ error }, 'Gemini generateText failed');
      throw error;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Generate Trip Skeleton (compatible with OpenAI service interface)
  // ═════════════════════════════════════════════════════════════════════════

  async generateTripSkeleton(params: GenerateTripParams): Promise<TripSkeleton> {
    const startTime = Date.now();
    logger.info(`[GENERATION] trip - Starting generation for ${params.city}`);

    try {
      const prompt = this.buildDetailedTripPrompt(params);

      const tripData = await this.generateJSON<any>({
        systemPrompt: 'You are a professional travel planner. Create detailed, realistic itineraries with specific places, restaurants, prices, and logistics. Return valid JSON only.',
        userPrompt: prompt,
        temperature: config.OPENAI_TEMPERATURE,
        maxTokens: 4096,
      });

      const validated = this.validateTripSkeleton(tripData, params.poiList);

      const duration = Date.now() - startTime;
      logGeneration('trip', duration, 1, { city: params.city });

      return validated;
    } catch (error) {
      const duration = Date.now() - startTime;
      logger.error(`[GENERATION] trip - Failed for ${params.city} in ${duration}ms`, { error });
      throw error;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Build DETAILED Prompt
  // ═════════════════════════════════════════════════════════════════════════

  private buildDetailedTripPrompt(params: GenerateTripParams): string {
    const {
      city,
      country,
      activity,
      durationDays,
      poiList,
      restaurantList = [],
      language = 'en',
    } = params;

    const poiListJson = JSON.stringify(
      poiList.map(poi => ({
        id: poi.id,
        name: poi.name,
        category: poi.category,
        lat: poi.lat,
        lon: poi.lon,
      })),
      null,
      2
    );

    const restaurantListJson = JSON.stringify(
      restaurantList.map(restaurant => ({
        id: restaurant.id,
        name: restaurant.name,
        cuisine_types: restaurant.cuisine_types,
        rating: restaurant.rating,
        price_level: restaurant.price_level,
        address: restaurant.address,
        lat: restaurant.lat,
        lon: restaurant.lon,
        primary_photo: restaurant.primary_photo,
        description: restaurant.description,
      })),
      null,
      2
    );

    // Import and use activity-specific prompts
    const { getActivityPrompt } = require('../prompts/index.js');
    return getActivityPrompt({
      city,
      country,
      activity,
      durationDays,
      poiListJson,
      restaurantListJson,
      language,
    });
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Validate Trip Skeleton
  // ═════════════════════════════════════════════════════════════════════════

  private validateTripSkeleton(data: any, poiList: POIReference[]): TripSkeleton {
    const validPoiIds = new Set(poiList.map(poi => poi.id));

    if (data.itinerary) {
      for (const day of data.itinerary) {
        if (!day.places || !Array.isArray(day.places)) {
          logger.warn(`Day ${day.day} has no places array`);
          day.places = [];
          continue;
        }

        day.places = day.places.filter((place: any) => {
          if (
            place.category === 'lunch' ||
            place.category === 'dinner' ||
            place.category === 'breakfast'
          ) {
            return true;
          }

          if (place.poi_id && validPoiIds.has(place.poi_id)) {
            return true;
          }

          logger.warn(`Invalid place filtered out: ${place.name}`);
          return false;
        });

        for (const place of day.places) {
          if (place.poi_id) {
            const poi = poiList.find(p => p.id === place.poi_id);
            if (poi) {
              place.latitude = poi.lat;
              place.longitude = poi.lon;
            }
          }
        }

        if (day.places.length === 0) {
          logger.warn(`Day ${day.day} has no valid places after filtering`);
        }
      }
    }

    if (!data.title || !data.description || !data.itinerary) {
      throw new Error('Invalid trip skeleton: missing required fields');
    }

    return data as TripSkeleton;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Improve Marketing Copy
  // ═════════════════════════════════════════════════════════════════════════

  async improveMarketingCopy(
    skeleton: TripSkeleton
  ): Promise<{ title: string; description: string }> {
    try {
      return await this.generateJSON({
        systemPrompt: 'You are a marketing copywriter. Improve travel titles and descriptions to be more engaging and SEO-friendly.',
        userPrompt: `Improve this trip title and description for marketing:

Current title: ${skeleton.title}
Current description: ${skeleton.description}

Return JSON with improved versions:
{
  "title": "improved title (max 60 chars)",
  "description": "improved description (100-150 words, engaging tone)"
}`,
        temperature: 0.8,
        maxTokens: 300,
      });
    } catch (error) {
      return { title: skeleton.title, description: skeleton.description };
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Generate Hero Image Prompt
  // ═════════════════════════════════════════════════════════════════════════

  async generateImagePrompt(city: string, activity: string): Promise<string> {
    try {
      const result = await this.generateText({
        prompt: `Create a short Unsplash search query (max 5 words) for a travel photo of ${city} with ${activity} theme. Return only the search query, no quotes or formatting.`,
        temperature: 0.7,
        maxTokens: 20,
      });
      return result || `${city} ${activity}`;
    } catch (error) {
      return `${city} ${activity}`;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Estimate Tokens
  // ═════════════════════════════════════════════════════════════════════════

  estimateTokens(text: string): number {
    return Math.ceil(text.length / 4);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Singleton Instance
// ═══════════════════════════════════════════════════════════════════════════

const geminiService = new GeminiService();

export default geminiService;
