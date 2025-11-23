/**
 * ═══════════════════════════════════════════════════════════════════════════
 * OpenAI Service
 * Генерация travel itineraries через GPT-4 с ДЕТАЛЬНЫМИ местами
 * ═══════════════════════════════════════════════════════════════════════════
 */

import OpenAI from 'openai';
import config from '../../../shared/config/env.js';
import logger, { logApiCall, logGeneration } from '../../../shared/utils/logger.js';
import retry from '../../../shared/utils/retry.js';
import rateLimiter from '../../../shared/utils/rate-limiter.js';
import { circuitBreakers } from '../../../shared/utils/retry.js';
import { getActivityPrompt } from '../prompts/index.js';

// ═══════════════════════════════════════════════════════════════════════════
// Types
// ═══════════════════════════════════════════════════════════════════════════

export interface POIReference {
  id: string;
  name: string;
  category: string;
  lat: number;
  lon: number;
}

// ✅ NEW: Restaurant reference from database
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
  description?: string; // ✅ NEW: Pre-generated AI description from DB
}

export interface GenerateTripParams {
  city: string;
  country: string;
  activity: string;
  durationDays: number;
  poiList: POIReference[];
  restaurantList?: RestaurantReference[]; // ✅ NEW: Restaurants from database
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
  google_place_id?: string; // ✅ Добавлено для обогащения данными из Google Places
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
// OpenAI Service Class
// ═══════════════════════════════════════════════════════════════════════════

class OpenAIService {
  private client: OpenAI;

  constructor() {
    this.client = new OpenAI({
      apiKey: config.OPENAI_API_KEY,
    });

    logger.info('✅ OpenAI Service initialized');
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Generate Trip Skeleton
  // ═════════════════════════════════════════════════════════════════════════

  async generateTripSkeleton(
    params: GenerateTripParams
  ): Promise<TripSkeleton> {
    const startTime = Date.now();
    logGeneration('trip', 'started', {
      city: params.city,
      activity: params.activity,
    });

    try {
      return await rateLimiter.execute('openai', async () => {
        return circuitBreakers.openai.execute(async () => {
          return retry(
            async () => {
              const prompt = this.buildDetailedTripPrompt(params);

              const response = await this.client.chat.completions.create({
                model: config.OPENAI_MODEL,
                messages: [
                  {
                    role: 'system',
                    content:
                      'You are a professional travel planner. Create detailed, realistic itineraries with specific places, restaurants, prices, and logistics. Return valid JSON only.',
                  },
                  {
                    role: 'user',
                    content: prompt,
                  },
                ],
                temperature: config.OPENAI_TEMPERATURE,
                max_tokens: 4096, // Max supported by standard GPT-4
                response_format: { type: 'json_object' },
              });

              const duration = Date.now() - startTime;
              const usage = response.usage;

              logApiCall('openai', 'POST', '/chat/completions', 200, duration);

              logger.info({
                promptTokens: usage?.prompt_tokens,
                completionTokens: usage?.completion_tokens,
                totalTokens: usage?.total_tokens,
                duration,
              });

              const content = response.choices[0]?.message?.content;
              if (!content) {
                throw new Error('Empty response from OpenAI');
              }

              const tripData = JSON.parse(content);
              const validated = this.validateTripSkeleton(
                tripData,
                params.poiList
              );

              logGeneration('trip', 'completed', {
                city: params.city,
                tokens: usage?.total_tokens,
              });

              return validated;
            },
            {
              maxRetries: 2,
              shouldRetry: (error: any) => {
                if (error.status === 429) return true;
                if (error.code === 'ECONNRESET') return true;
                return false;
              },
            }
          );
        });
      });
    } catch (error) {
      const duration = Date.now() - startTime;
      logGeneration(
        'trip',
        'failed',
        { city: params.city, duration },
        error as Error
      );
      throw error;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Build DETAILED Prompt (Activity-Specific)
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

    // ✅ Include restaurants from database
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

    // ✅ Use activity-specific prompts
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

  private validateTripSkeleton(
    data: any,
    poiList: POIReference[]
  ): TripSkeleton {
    const validPoiIds = new Set(poiList.map(poi => poi.id));

    // Проверяем структуру itinerary
    if (data.itinerary) {
      for (const day of data.itinerary) {
        if (!day.places || !Array.isArray(day.places)) {
          logger.warn(`Day ${day.day} has no places array`);
          day.places = [];
          continue;
        }

        // Фильтруем и валидируем места
        day.places = day.places.filter((place: any) => {
          // Рестораны могут иметь poi_id = null
          if (
            place.category === 'lunch' ||
            place.category === 'dinner' ||
            place.category === 'breakfast'
          ) {
            return true;
          }

          // Аттракционы должны иметь валидный POI ID
          if (place.poi_id && validPoiIds.has(place.poi_id)) {
            return true;
          }

          logger.warn(`Invalid place filtered out: ${place.name}`);
          return false;
        });

        // Обогащаем координатами из POI list
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

    // Проверяем обязательные поля
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
    const startTime = Date.now();

    return rateLimiter.execute('openai', async () => {
      return retry(async () => {
        const response = await this.client.chat.completions.create({
          model: config.OPENAI_MODEL,
          messages: [
            {
              role: 'system',
              content:
                'You are a marketing copywriter. Improve travel titles and descriptions to be more engaging and SEO-friendly.',
            },
            {
              role: 'user',
              content: `Improve this trip title and description for marketing:

Current title: ${skeleton.title}
Current description: ${skeleton.description}

Return JSON with improved versions:
{
  "title": "improved title (max 60 chars)",
  "description": "improved description (100-150 words, engaging tone)"
}`,
            },
          ],
          temperature: 0.8,
          max_tokens: 300,
          response_format: { type: 'json_object' },
        });

        const duration = Date.now() - startTime;
        logApiCall('openai', 'POST', '/chat/completions', 200, duration);

        const content = response.choices[0]?.message?.content;
        if (!content) {
          return { title: skeleton.title, description: skeleton.description };
        }

        return JSON.parse(content);
      });
    });
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Generate Hero Image Prompt
  // ═════════════════════════════════════════════════════════════════════════

  async generateImagePrompt(city: string, activity: string): Promise<string> {
    return rateLimiter.execute('openai', async () => {
      return retry(async () => {
        const response = await this.client.chat.completions.create({
          model: 'gpt-3.5-turbo',
          messages: [
            {
              role: 'user',
              content: `Create a short Unsplash search query (max 5 words) for a travel photo of ${city} with ${activity} theme. 
Return only the search query, no quotes or formatting.`,
            },
          ],
          temperature: 0.7,
          max_tokens: 20,
        });

        return (
          response.choices[0]?.message?.content?.trim() || `${city} ${activity}`
        );
      });
    });
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Generate Simple Text (for descriptions, summaries, etc.)
  // ═════════════════════════════════════════════════════════════════════════

  async generateText(params: {
    prompt: string;
    maxTokens?: number;
    temperature?: number;
  }): Promise<string> {
    const { prompt, maxTokens = 200, temperature = 0.7 } = params;

    return circuitBreakers.openai.execute(async () => {
      return rateLimiter.execute('openai', async () => {
        const response = await this.client.chat.completions.create({
          model: config.OPENAI_MODEL,
          messages: [
            {
              role: 'user',
              content: prompt,
            },
          ],
          temperature,
          max_tokens: maxTokens,
        });

        return response.choices[0]?.message?.content?.trim() || '';
      });
    });
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Check Token Usage
  // ═════════════════════════════════════════════════════════════════════════

  estimateTokens(text: string): number {
    return Math.ceil(text.length / 4);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Singleton Instance
// ═══════════════════════════════════════════════════════════════════════════

const openAIService = new OpenAIService();

export default openAIService;
