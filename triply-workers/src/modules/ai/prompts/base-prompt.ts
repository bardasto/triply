/**
 * Base prompt template for trip generation
 * Contains common structure used by all activity types
 */

export interface PromptParams {
  city: string;
  country: string;
  activity: string;
  durationDays: number;
  poiListJson: string;
  restaurantListJson: string;
  language: string;
}

export function getBasePromptStructure(params: PromptParams): string {
  const { city, country, activity, durationDays, poiListJson, restaurantListJson, language } = params;

  return `Create a DETAILED ${durationDays}-day ${activity} trip itinerary for ${city}, ${country}.

INPUT DATA:
{
  "city": "${city}",
  "country": "${country}",
  "activity": "${activity}",
  "durationDays": ${durationDays},
  "poiList": ${poiListJson},
  "restaurantList": ${restaurantListJson},
  "language": "${language}"
}

CRITICAL REQUIREMENTS:
- You MUST create EXACTLY ${durationDays} days (not less, not more)
- For restaurants: Set image_url to primary_photo, leave images array empty (will be filled after)

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
          "name": "Place Name",
          "type": "museum",
          "category": "attraction",
          "description": "Description (40-60 words)",
          "duration_minutes": 180,
          "price": "€17",
          "price_value": 17,
          "rating": 4.7,
          "address": "Full address",
          "latitude": 48.8606,
          "longitude": 2.3376,
          "best_time": "Morning to avoid crowds",
          "transportation": {
            "from_previous": "Start of the day",
            "method": "metro",
            "duration_minutes": 15,
            "cost": "€2"
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

GENERAL INSTRUCTIONS:
1. For EACH place, provide:
   - Name, type, category
   - Description (40-60 words, be concise!)
   - Duration in minutes
   - Price (use €, €€, €€€ or specific amount like "€15")
   - Rating (0-5, be realistic)
   - Address
   - Coordinates (use POI coords from list)
   - Opening hours (estimate realistic hours)
   - Best time to visit
   - Transportation from previous location (walk/metro/bus, duration, cost)
   - For restaurants: cuisine type

2. Categories:
   - "attraction" for POIs from list
   - "breakfast", "lunch", "dinner" for restaurants
   - Types: museum, restaurant, cafe, monument, park, etc.

3. Use ONLY POI IDs from the provided list for attractions

4. ⚠️ RESTAURANT HANDLING (CRITICAL):
   - If restaurantList is NOT empty: Use ONLY restaurants from restaurantList
   - If restaurantList IS empty: DO NOT add any restaurants to the itinerary
   - Use "poi_id" field with the exact ID from restaurantList (rename "id" to "poi_id")
   - Use exact name, coordinates, rating, address from restaurantList
   - Copy primary_photo to image_url field
   - Leave images array empty (will be filled from database after)
   - If description is provided: Use it EXACTLY as-is (do NOT modify!)
   - If no description: Create brief one (40-60 words)

5. Output ONLY valid JSON
6. Be realistic with prices, ratings, and durations
7. Keep descriptions CONCISE (40-60 words max)
8. Provide logical routing between places`;
}
