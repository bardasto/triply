/**
 * ═══════════════════════════════════════════════════════════════════════════
 * OpenAI Service
 * Генерация travel itineraries через GPT-4 с ДЕТАЛЬНЫМИ местами
 * ═══════════════════════════════════════════════════════════════════════════
 */

import OpenAI from 'openai';
import config from '../config/env.js';
import logger, { logApiCall, logGeneration } from '../utils/logger.js';
import retry from '../utils/retry.js';
import rateLimiter from '../utils/rate-limiter.js';
import { circuitBreakers } from '../utils/retry.js';

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

export interface GenerateTripParams {
  city: string;
  country: string;
  activity: string;
  durationDays: number;
  poiList: POIReference[];
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
                max_tokens: config.OPENAI_MAX_TOKENS * 2, // Увеличиваем для детализации
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
  // Build DETAILED Prompt
  // ═════════════════════════════════════════════════════════════════════════

  private buildDetailedTripPrompt(params: GenerateTripParams): string {
    const {
      city,
      country,
      activity,
      durationDays,
      poiList,
      language = 'en',
    } = params;

    const poiListJson = poiList.map(poi => ({
      id: poi.id,
      name: poi.name,
      category: poi.category,
      lat: poi.lat,
      lon: poi.lon,
    }));

    return `Create a DETAILED ${durationDays}-day ${activity} trip itinerary for ${city}, ${country}.

INPUT DATA:
{
  "city": "${city}",
  "country": "${country}",
  "activity": "${activity}",
  "durationDays": ${durationDays},
  "poiList": ${JSON.stringify(poiListJson, null, 2)},
  "language": "${language}"
}

INSTRUCTIONS:
1. For EACH day, create a detailed schedule with:
   - Morning activity (attraction/museum from POI list)
   - Lunch recommendation (restaurant - you can suggest popular ones)
   - Afternoon activities (2-3 POIs from the list)
   - Dinner recommendation (restaurant - you can suggest popular ones)

2. For EACH place, provide:
   - Name, type, category
   - Description (50-80 words)
   - Duration in minutes
   - Price (use €, €€, €€€ or specific amount like "€15")
   - Rating (0-5, be realistic)
   - Address
   - Coordinates (use POI coords from list)
   - Opening hours (estimate realistic hours)
   - Best time to visit
   - Transportation from previous location (walk/metro/bus, duration, cost)
   - For restaurants: cuisine type

3. Categories:
   - "attraction" for POIs from list
   - "breakfast", "lunch", "dinner" for restaurants
   - Types: museum, restaurant, cafe, monument, park, etc.

4. Use ONLY POI IDs from the provided list for attractions
5. For restaurants, you can suggest real popular places in ${city}

REQUIRED OUTPUT FORMAT (strict JSON):
{
  "title": "Engaging trip title (max 60 chars)",
  "description": "1-2 paragraph overview (100-150 words)",
  "duration": "${durationDays} days",
  "activityType": "${activity}",
  "itinerary": [
    {
      "day": 1,
      "title": "Day theme title",
      "description": "Overview of the day (max 50 words)",
      "places": [
        {
          "poi_id": "uuid-from-poi-list",
          "name": "Louvre Museum",
          "type": "museum",
          "category": "attraction",
          "description": "World's largest art museum featuring iconic works like the Mona Lisa...",
          "duration_minutes": 180,
          "price": "€17",
          "price_value": 17,
          "rating": 4.7,
          "address": "Rue de Rivoli, 75001 Paris",
          "latitude": 48.8606,
          "longitude": 2.3376,
          "opening_hours": "9:00 - 18:00",
          "best_time": "Morning to avoid crowds",
          "transportation": {
            "from_previous": "Start of the day",
            "method": "metro",
            "duration_minutes": 15,
            "cost": "€2"
          }
        },
        {
          "poi_id": null,
          "name": "Café de Flore",
          "type": "restaurant",
          "category": "lunch",
          "cuisine": "French",
          "description": "Historic Parisian café serving classic French cuisine...",
          "duration_minutes": 60,
          "price": "€€",
          "price_value": 25,
          "rating": 4.3,
          "address": "172 Boulevard Saint-Germain, 75006 Paris",
          "latitude": 48.8543,
          "longitude": 2.3324,
          "opening_hours": "7:00 - 1:30",
          "best_time": "Lunch hours",
          "transportation": {
            "from_previous": "10 min walk from Louvre",
            "method": "walk",
            "duration_minutes": 10,
            "cost": "€0"
          }
        }
      ]
    }
  ],
  "highlights": ["highlight 1", "highlight 2", "highlight 3"],
  "includes": ["Transportation guide", "Restaurant recommendations", "Entry tickets info"],
  "recommendedBudget": {
    "min": 150,
    "max": 400,
    "currency": "EUR"
  },
  "bestSeasons": ["spring", "summer"]
}

IMPORTANT: 
- Output ONLY valid JSON
- Each day should have 5-7 places (mix of attractions and restaurants)
- Be realistic with prices, ratings, and durations
- Use real restaurant names popular in ${city}
- Provide logical routing between places`;
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
