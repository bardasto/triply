/**
 * Activity-specific prompt templates for trip generation
 * These prompts guide the AI to generate REAL specific places for each activity type
 */

export interface ActivityPromptParams {
  city: string;
  country: string;
  activity: string;
  durationDays: number;
  language: string;
}

/**
 * Get activity-specific instructions for the AI
 */
export function getActivitySpecificInstructions(activity: string, city: string): string {
  const instructions: Record<string, string> = {
    cycling: `
🚴 CYCLING TRIP - REAL CYCLING ROUTES & PATHS:
- Focus on ACTUAL cycling routes, bike paths, and scenic cycling roads in ${city}
- Include coastal paths, mountain bike trails, urban cycling routes, park loops
- Examples for Barcelona: Passeig Marítim (beachfront), Carretera de les Aigües (mountain road),
  Ronda Verda (green ring), Parc de Collserola trails
- DO NOT use museums or tourist attractions unless they're part of a cycling route
- Each place should be a cycling route/path with distance, elevation, difficulty level
- Include bike rental locations, rest stops, scenic viewpoints along routes
`,

    beach: `
🏖️ BEACH TRIP - REAL BEACHES & COASTAL AREAS:
- Focus on ACTUAL beaches, coves, coastal areas in ${city}
- Include beach names, facilities, water sports, beach clubs
- Examples for Barcelona: Barceloneta Beach, Bogatell Beach, Nova Icaria, Mar Bella,
  Ocata Beach (nearby)
- DO NOT use museums or city attractions
- Each place should be a beach/coastal location with activities, amenities, accessibility
- Include beach clubs, water sports centers, seaside promenades
`,

    skiing: `
⛷️ SKIING TRIP - SKI RESORTS & WINTER SPORTS:
- Focus on ACTUAL ski resorts, slopes, winter sports areas near ${city}
- Include ski stations, ski runs, equipment rental, après-ski locations
- Examples for Barcelona area: La Molina, Masella, Vallter 2000, Port del Comte
- Each place should be a ski resort/slope with difficulty levels, lift info, facilities
- Include ski schools, equipment rental shops, mountain restaurants
`,

    mountains: `
⛰️ MOUNTAIN TRIP - REAL MOUNTAIN LOCATIONS & PEAKS:
- Focus on ACTUAL mountains, peaks, viewpoints near ${city}
- Include mountain ranges, specific peaks, mountain villages
- Examples for Barcelona: Tibidabo, Montjuïc, Montserrat, Collserola Natural Park
- Each place should be a mountain location with elevation, trails, viewpoints
- Include cable cars, funiculars, mountain restaurants, scenic overlooks
`,

    hiking: `
🥾 HIKING TRIP - REAL HIKING TRAILS & PATHS:
- Focus on ACTUAL hiking trails, nature walks, trekking routes near ${city}
- Include trail names, difficulty levels, distances, elevation gain
- Examples for Barcelona: Carretera de les Aigües trail, Montserrat trails,
  Collserola park trails, Bunkers del Carmel
- Each place should be a hiking trail/path with distance, difficulty, estimated time
- Include trailheads, water fountains, viewpoints, refuges
`,

    sailing: `
⛵ SAILING TRIP - MARINAS, PORTS & SAILING SPOTS:
- Focus on ACTUAL marinas, sailing clubs, coastal sailing routes near ${city}
- Include ports, yacht clubs, sailing schools, boat rental locations
- Examples for Barcelona: Port Vell, Port Olímpic, Marina Port Forum,
  Real Club Náutico de Barcelona
- Each place should be a marina/sailing location with facilities, boat types, rentals
- Include sailing schools, boat charters, coastal routes, anchoring spots
`,

    desert: `
🌵 DESERT TRIP - DESERT LANDSCAPES & ARID AREAS:
- Focus on ACTUAL desert or arid landscapes near ${city}
- Include desert areas, canyons, arid natural parks
- Examples for Barcelona region: Bardenas Reales (Navarra), Monegros Desert
- Each place should be a desert/arid location with unique features, activities
- Include desert trails, viewpoints, oases, desert wildlife areas
`,

    camping: `
🏕️ CAMPING TRIP - REAL CAMPSITES & NATURE AREAS:
- Focus on ACTUAL campsites, camping areas, nature reserves near ${city}
- Include campground names, facilities, nearby nature activities
- Examples for Barcelona: Camping Masnou, Camping Gavà, camping in Collserola,
  Montserrat area campsites
- Each place should be a campsite/camping area with facilities, capacity, activities
- Include nature parks, outdoor activity centers, hiking from campsites
`,

    city: `
🏙️ CITY TRIP - URBAN EXPLORATION & CULTURE:
- Focus on iconic city landmarks, neighborhoods, cultural sites in ${city}
- Include famous buildings, plazas, markets, museums, viewpoints
- Examples for Barcelona: Sagrada Família, Park Güell, Gothic Quarter, La Rambla,
  Boqueria Market, Casa Batlló
- Each place should be a significant urban location with cultural/historical value
- Include neighborhoods to explore, local markets, city viewpoints
`,

    wellness: `
🧘 WELLNESS TRIP - SPAS, THERMAL BATHS & RELAXATION:
- Focus on ACTUAL spas, thermal baths, wellness centers in ${city}
- Include spa hotels, thermal springs, yoga studios, wellness retreats
- Examples for Barcelona: Aire de Barcelona (Arab baths), Spa at W Hotel,
  Flotarium, thermal baths in Caldes de Montbui (nearby)
- Each place should be a wellness/spa location with treatments, facilities, pricing
- Include yoga centers, meditation spots, healthy restaurants, parks for tai chi
`,

    road_trip: `
🚗 ROAD TRIP - SCENIC DRIVES & ROADSIDE ATTRACTIONS:
- Focus on ACTUAL scenic roads, driving routes, roadside stops from/around ${city}
- Include coastal roads, mountain passes, scenic viewpoints accessible by car
- Examples from Barcelona: Costa Brava coastal road, Montserrat mountain road,
  Sitges coastal route, Penedès wine region drive
- Each place should be a scenic drive/road with distance, driving time, stops
- Include roadside viewpoints, photo stops, roadside restaurants, scenic routes
`,
  };

  return instructions[activity.toLowerCase()] || instructions['city'];
}

/**
 * Generate complete prompt for activity-specific trip
 */
export function getActivityPrompt(params: ActivityPromptParams): string {
  const { city, country, activity, durationDays, language } = params;
  const specificInstructions = getActivitySpecificInstructions(activity, city);

  return `Create a DETAILED ${durationDays}-day ${activity} trip itinerary for ${city}, ${country}.

${specificInstructions}

CRITICAL REQUIREMENTS:
1. Generate REAL, SPECIFIC places for ${activity} activities in ${city}
2. Use your knowledge of ${city} to suggest authentic locations
3. DO NOT limit yourself to a provided POI list - generate real places based on your knowledge
4. Focus on places that are RELEVANT to ${activity} - not generic tourist attractions
5. Each place must have: name, coordinates, description, realistic pricing, ratings

REQUIRED OUTPUT FORMAT (strict JSON):
{
  "title": "Engaging ${activity} trip title for ${city} (max 60 chars)",
  "description": "1-2 paragraph overview focusing on ${activity} experience (100-150 words)",
  "duration": "${durationDays} days",
  "activityType": "${activity}",
  "itinerary": [
    {
      "day": 1,
      "title": "Day theme title (related to ${activity})",
      "description": "Overview of the day (max 50 words)",
      "places": [
        {
          "name": "Real specific place name",
          "type": "relevant to ${activity}",
          "category": "attraction",
          "description": "Description (40-60 words)",
          "duration_minutes": 180,
          "price": "€17",
          "price_value": 17,
          "rating": 4.7,
          "address": "Full real address in ${city}",
          "latitude": 41.3851,
          "longitude": 2.1734,
          "best_time": "Best time to visit",
          "transportation": {
            "from_previous": "Start of the day",
            "method": "metro/walk/car/bike",
            "duration_minutes": 15,
            "cost": "€2"
          }
        }
      ],
      "restaurants": [
        {
          "name": "Real restaurant name",
          "type": "restaurant",
          "category": "breakfast/lunch/dinner",
          "cuisine": "Cuisine type (e.g., Tapas, French, Mediterranean)",
          "description": "Restaurant description (40-60 words)",
          "duration_minutes": 90,
          "price": "€€",
          "price_value": 35,
          "rating": 4.5,
          "address": "Full real address in ${city}",
          "latitude": 41.3851,
          "longitude": 2.1734,
          "best_time": "Lunch time/Dinner time",
          "transportation": {
            "from_previous": "Previous place",
            "method": "walk/metro",
            "duration_minutes": 10,
            "cost": "€2"
          }
        }
      ]
    }
  ],
  "highlights": ["${activity}-specific highlight 1", "highlight 2", "highlight 3"],
  "includes": ["What's included in this ${activity} trip"],
  "recommendedBudget": {
    "min": 150,
    "max": 400,
    "currency": "EUR"
  },
  "bestSeasons": ["best seasons for ${activity}"]
}

CRITICAL STRUCTURE RULES:
1. ⚠️  SEPARATE ARRAYS: "places" = ONLY attractions/museums/activities (NO restaurants)
2. ⚠️  SEPARATE ARRAYS: "restaurants" = ONLY restaurants (breakfast/lunch/dinner)
3. ⚠️  DO NOT MIX: Never put restaurants in "places" array or attractions in "restaurants" array

PLACE GENERATION RULES:
1. Generate EXACTLY ${durationDays} days with 4-6 PLACES per day (attractions, museums, NOT restaurants)
2. Generate 2-3 RESTAURANTS per day (breakfast, lunch, dinner) in separate "restaurants" array
3. Each place must be REAL and specific to ${city}
4. Focus on ${activity}-appropriate locations
5. Include realistic coordinates for ${city}
6. Add realistic prices in local currency
7. Provide authentic addresses
8. Include practical information (duration, best time, transportation)
9. Keep descriptions concise (40-60 words)
10. Output ONLY valid JSON

Language: ${language}`;
}
