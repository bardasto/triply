/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Single Place Generator Service
 * Generates recommendations for single places (restaurants, hotels, etc.)
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { v4 as uuidv4 } from 'uuid';
import config from '../../../shared/config/env.js';
import logger from '../../../shared/utils/logger.js';
import retry from '../../../shared/utils/retry.js';
import rateLimiter from '../../../shared/utils/rate-limiter.js';
import googlePlacesService from '../../google-places/services/google-places.service.js';
import { SinglePlaceIntent } from './query-analyzer.service.js';
import geminiService from './gemini.service.js';

// ═══════════════════════════════════════════════════════════════════════════
// Types
// ═══════════════════════════════════════════════════════════════════════════

export interface SinglePlaceResult {
  id: string;
  type: 'single_place';
  place: {
    id: string;
    name: string;
    description: string;
    placeType: string;
    category: string;
    address: string;
    city: string;
    country: string;
    latitude: number;
    longitude: number;
    rating: number;
    reviewCount: number;
    priceLevel: string;
    priceRange: string;
    estimatedPrice: string; // Real estimated price like "€20-40 per person"
    phone?: string;
    website?: string;
    openingHours?: {
      open_now?: boolean;
      weekday_text?: string[];
    };
    isOpenNow?: boolean;
    cuisineTypes?: string[];
    features?: string[];
    whyRecommended: string;
    imageUrl?: string;
    images?: string[];
    googlePlaceId?: string;
  };
  alternatives?: Array<{
    id: string;
    name: string;
    description: string;
    rating: number;
    priceLevel: string;
    estimatedPrice: string; // Real estimated price
    whyAlternative: string;
    googlePlaceId?: string;
    imageUrl?: string;
    address?: string;
  }>;
  _meta: {
    originalQuery: string;
    intent: SinglePlaceIntent;
    generatedAt: string;
  };
}

interface GooglePlace {
  place_id: string;
  name: string;
  formatted_address?: string;
  geometry?: {
    location: {
      lat: number;
      lng: number;
    };
  };
  rating?: number;
  user_ratings_total?: number;
  price_level?: number;
  opening_hours?: {
    open_now?: boolean;
    weekday_text?: string[];
  };
  types?: string[];
  photos?: Array<{
    photo_reference: string;
  }>;
  website?: string;
  formatted_phone_number?: string;
}

// Price level maps
const PRICE_LEVEL_MAP: Record<number, string> = {
  0: 'Free',
  1: '€',
  2: '€€',
  3: '€€€',
  4: '€€€€',
};

const PRICE_RANGE_MAP: Record<number, string> = {
  0: 'Free',
  1: 'Budget-friendly',
  2: 'Moderate',
  3: 'Upscale',
  4: 'Fine Dining',
};

// Realistic price intervals based on place type and Google price_level (0-4)
// These are real average prices for European cities
const REALISTIC_PRICE_INTERVALS: Record<string, Record<number, string>> = {
  restaurant: {
    0: 'Free',
    1: '€8-15 per person',
    2: '€20-35 per person',
    3: '€40-70 per person',
    4: '€80-200+ per person',
  },
  cafe: {
    0: 'Free',
    1: '€3-8',
    2: '€8-15',
    3: '€15-25',
    4: '€25-40',
  },
  bar: {
    0: 'Free',
    1: '€5-10 per drink',
    2: '€10-15 per drink',
    3: '€15-25 per drink',
    4: '€25-50+ per drink',
  },
  museum: {
    0: 'Free',
    1: '€5-10',
    2: '€10-18',
    3: '€18-30',
    4: '€30-50',
  },
  attraction: {
    0: 'Free',
    1: '€5-12',
    2: '€12-25',
    3: '€25-50',
    4: '€50-100+',
  },
  park: {
    0: 'Free',
    1: 'Free',
    2: '€5-10',
    3: '€10-20',
    4: '€20-40',
  },
  nightclub: {
    0: 'Free',
    1: '€10-20 entry',
    2: '€20-30 entry',
    3: '€30-50 entry',
    4: '€50-100+ entry',
  },
  spa: {
    0: 'Free',
    1: '€30-60',
    2: '€60-120',
    3: '€120-250',
    4: '€250-500+',
  },
  // Default for other types
  default: {
    0: 'Free',
    1: '€5-15',
    2: '€15-35',
    3: '€35-70',
    4: '€70-150+',
  },
};

/**
 * Get realistic price interval based on place type and price level
 */
function getRealisticPriceInterval(placeType: string, priceLevel: number | undefined): string {
  if (priceLevel === undefined || priceLevel === null) {
    return ''; // No price info available
  }

  const type = placeType.toLowerCase();
  const priceMap = REALISTIC_PRICE_INTERVALS[type] || REALISTIC_PRICE_INTERVALS.default;

  return priceMap[priceLevel] || '';
}


// ═══════════════════════════════════════════════════════════════════════════
// Single Place Generator Service
// ═══════════════════════════════════════════════════════════════════════════

class SinglePlaceGeneratorService {
  constructor() {
    logger.info('✅ Single Place Generator Service initialized (using Gemini)');
  }

  /**
   * Generate a single place recommendation based on user intent
   */
  async generatePlace(intent: SinglePlaceIntent): Promise<SinglePlaceResult> {
    const startTime = Date.now();

    logger.info('═══════════════════════════════════════════════════════');
    logger.info('🏪 Starting Single Place Generation');
    logger.info(`   City: ${intent.city}`);
    logger.info(`   Place Type: ${intent.placeType}`);
    logger.info(`   Requirements: ${intent.specialRequirements?.join(', ') || 'none'}`);
    logger.info('═══════════════════════════════════════════════════════');

    try {
      // Step 1: Search for relevant places using Google Places
      const places = await this.searchPlaces(intent);

      if (places.length === 0) {
        throw new Error(`No ${intent.placeType}s found in ${intent.city} matching your criteria`);
      }

      // Step 2: Use AI to select the best match and generate recommendation
      const recommendation = await this.selectBestPlace(intent, places);

      logger.info(`📋 AI Selection: includeAlternatives=${recommendation.includeAlternatives}, alternatives count=${recommendation.alternatives?.length || 0}`);

      // Step 3: Get place details for the selected place
      const placeDetails = await this.getPlaceDetails(recommendation.selectedPlaceId);

      // Step 4: Build final result
      const result = await this.buildResult(intent, recommendation, placeDetails, places);

      const duration = Date.now() - startTime;
      logger.info(`✅ Single place generated in ${duration}ms`);
      logger.info(`   Recommended: ${result.place.name}`);

      return result;
    } catch (error) {
      logger.error('❌ Failed to generate single place:', error);
      throw error;
    }
  }

  /**
   * Search for places matching the intent
   */
  private async searchPlaces(intent: SinglePlaceIntent): Promise<GooglePlace[]> {
    const allPlaces: GooglePlace[] = [];

    // If user wants a SPECIFIC place by name, search for it directly first
    if (intent.specificPlaceName) {
      logger.info(`🎯 Searching for specific place: "${intent.specificPlaceName}" in ${intent.city}`);

      try {
        // Direct search for the specific place
        const specificQuery = `${intent.specificPlaceName} ${intent.city}`;
        const specificPlaces = await googlePlacesService.textSearch({
          query: specificQuery,
        });

        if (specificPlaces && specificPlaces.length > 0) {
          // Put specific place matches first
          allPlaces.push(...(specificPlaces as GooglePlace[]));
          logger.info(`✅ Found ${specificPlaces.length} results for specific place "${intent.specificPlaceName}"`);
        }
      } catch (error) {
        logger.warn(`Search for specific place "${intent.specificPlaceName}" failed:`, error);
      }
    }

    // If we found the specific place, we're done (no need for more searches)
    if (intent.specificPlaceName && allPlaces.length > 0) {
      return allPlaces.slice(0, 5); // Return top matches for specific place
    }

    // Otherwise, do regular recommendation search
    const searchQueries = this.buildSearchQueries(intent);

    for (const query of searchQueries) {
      try {
        const places = await googlePlacesService.textSearch({
          query,
        });

        if (places && places.length > 0) {
          allPlaces.push(...(places as GooglePlace[]));
        }
      } catch (error) {
        logger.warn(`Search failed for query "${query}":`, error);
      }
    }

    // Deduplicate by place_id
    const uniquePlaces = Array.from(
      new Map(allPlaces.map(p => [p.place_id, p])).values()
    );

    // Shuffle places to get different results each time
    // This ensures AI sees places in different order and picks differently
    const shuffledPlaces = uniquePlaces.sort(() => Math.random() - 0.5);

    logger.info(`Found ${uniquePlaces.length} unique places (shuffled for variety)`);
    return shuffledPlaces.slice(0, 15); // Increased to 15 for more variety
  }

  /**
   * Build search queries based on intent with variety
   */
  private buildSearchQueries(intent: SinglePlaceIntent): string[] {
    const queries: string[] = [];
    const city = intent.city;

    // Base query
    const placeTypeMap: Record<string, string> = {
      restaurant: 'restaurant',
      cafe: 'cafe coffee shop',
      bar: 'bar',
      hotel: 'hotel',
      attraction: 'tourist attraction landmark',
      museum: 'museum',
      park: 'park garden',
      shop: 'shopping store',
      nightclub: 'nightclub club',
      spa: 'spa wellness',
      beach: 'beach',
      viewpoint: 'viewpoint observation deck',
    };

    const baseType = placeTypeMap[intent.placeType] || intent.placeType;

    // Variety modifiers to get different results each time
    const varietyModifiers = [
      'best', 'top rated', 'popular', 'recommended', 'famous',
      'authentic', 'local favorite', 'hidden gem', 'trendy', 'classic'
    ];

    // Pick random modifiers for variety
    const shuffledModifiers = varietyModifiers.sort(() => Math.random() - 0.5);
    const selectedModifier = shuffledModifiers[0];

    // Add special requirements to query
    if (intent.specialRequirements && intent.specialRequirements.length > 0) {
      const requirements = intent.specialRequirements.join(' ');
      queries.push(`${requirements} ${baseType} in ${city}`);
    }

    // Add cuisine type for restaurants
    if (intent.cuisineType && intent.cuisineType.length > 0) {
      for (const cuisine of intent.cuisineType.slice(0, 2)) {
        queries.push(`${cuisine} ${baseType} in ${city}`);
      }
    }

    // Add criteria-based query
    if (intent.criteria && intent.criteria.length > 0) {
      const criteria = intent.criteria.slice(0, 3).join(' ');
      queries.push(`${criteria} ${baseType} in ${city}`);
    }

    // Fallback base query with variety
    if (queries.length === 0) {
      queries.push(`${selectedModifier} ${baseType} in ${city}`);
    }

    // Always add a variety query for more options
    queries.push(`${shuffledModifiers[1]} ${baseType} ${city}`);

    return queries.slice(0, 4); // Increased to 4 search queries for more variety
  }

  /**
   * Use AI to select the best place from search results
   */
  private async selectBestPlace(
    intent: SinglePlaceIntent,
    places: GooglePlace[]
  ): Promise<{
    selectedPlaceId: string;
    description: string;
    whyRecommended: string;
    realPrice: string | null;
    alternatives: Array<{ placeId: string; description: string; realPrice: string | null }>;
    includeAlternatives: boolean
  }> {
    const placesJson = places.map(p => ({
      id: p.place_id,
      name: p.name,
      rating: p.rating || 0,
      reviewCount: p.user_ratings_total || 0,
      priceLevel: p.price_level,
      address: p.formatted_address,
      types: p.types,
      isOpenNow: p.opening_hours?.open_now,
    }));

    // Generate a random seed for variety in selections
    const varietySeed = Math.floor(Math.random() * 1000);

    // Determine if this is a specific place request or a recommendation request
    const isSpecificPlaceRequest = !!intent.specificPlaceName;

    const systemPrompt = `You are an expert local guide who recommends places based on user requirements.

TASK: ${isSpecificPlaceRequest
      ? `Find the EXACT place "${intent.specificPlaceName}" from the list. The user wants THIS SPECIFIC place, NOT an alternative!`
      : 'Select a place from the list that BEST matches the user\'s query as a RECOMMENDATION.'}

USER REQUIREMENTS:
- Place Type: ${intent.placeType}
- City: ${intent.city}${intent.originalLocation ? ` (resolved from: ${intent.originalLocation})` : ''}
- Special Requirements: ${intent.specialRequirements?.join(', ') || 'none'}
- Cuisine Type: ${intent.cuisineType?.join(', ') || 'any'}
- Budget: ${intent.budget || 'any'}
- Criteria: ${intent.criteria?.join(', ') || 'best available'}
${isSpecificPlaceRequest ? `- **SPECIFIC PLACE REQUESTED**: "${intent.specificPlaceName}" - You MUST select this exact place!` : '- This is a RECOMMENDATION request - pick the best match based on criteria'}

${isSpecificPlaceRequest ? `
CRITICAL - SPECIFIC PLACE REQUEST:
The user wants "${intent.specificPlaceName}" specifically. You MUST:
1. Find and select the place that matches "${intent.specificPlaceName}" from the list
2. Do NOT select a different place - if user asked for "Louvre Museum", select THE Louvre Museum
3. Set includeAlternatives to FALSE - user doesn't want alternatives when asking for a specific place
4. If the exact place is not in the list, select the closest match but explain in whyRecommended

` : `
SELECTION RULES FOR RECOMMENDATIONS:
1. Pick the place that best matches the user's criteria
2. Consider rating, reviews, price level, cuisine type
3. Include alternatives for comparison
4. Be creative - show the user great options they might not know about

`}CRITICAL SELECTION RULES:
1. **EXACT NAME MATCH IS TOP PRIORITY** - If the user asks for a specific place by name (e.g., "Louvre", "Eiffel Tower", "Colosseum"), you MUST select that exact place from the list. Do NOT pick a different place!
2. If user asks for "Louvre" - select the Louvre Museum, NOT Eiffel Tower or anything else
3. If user asks for "Eiffel Tower" - select the Eiffel Tower, NOT the Louvre
4. Only if no exact match exists, then consider alternatives based on:
   - Rating and review count
   - Price level matching budget
   - Opening hours
   - Cuisine type for restaurants

REAL PRICE - VERY IMPORTANT:
You MUST provide the REAL, ACTUAL price for each place if you know it. This is critical!
- For museums/attractions with entry fees: provide the exact ticket price (e.g., "€17", "€15 adults, €8 children", "Free")
- For restaurants: provide average price per person (e.g., "€25-35 per person", "€80-120 per person")
- For cafes: provide typical order price (e.g., "€5-10")
- For hotels: DO NOT provide price (prices vary too much by date)
- If the place is FREE, say "Free"
- If you're NOT SURE about the real price, set realPrice to null

KNOWN PRICES FOR FAMOUS ATTRACTIONS (use these!):
- Louvre Museum, Paris: "€17" (free under 18)
- Eiffel Tower, Paris: "€18-29" (depends on level)
- Colosseum, Rome: "€18"
- Vatican Museums, Rome: "€17"
- Sagrada Familia, Barcelona: "€26"
- Uffizi Gallery, Florence: "€20"
- British Museum, London: "Free"
- Tower of London: "£30"
- Rijksmuseum, Amsterdam: "€22.50"
- Anne Frank House, Amsterdam: "€16"
- Prado Museum, Madrid: "€15"
- Acropolis, Athens: "€20"

ALTERNATIVES LOGIC:
- ALWAYS include alternatives (includeAlternatives: true) for these place types:
  restaurant, cafe, bar, hotel, shop, nightclub, spa
- These are category-based searches where users benefit from seeing options
- Make sure alternatives are DIFFERENT from the main selection
- Do NOT include alternatives (includeAlternatives: false) ONLY for:
  - Specific named landmarks (e.g., "Louvre Museum", "Eiffel Tower", "Colosseum")
  - Unique monuments or viewpoints
  - Museums with unique collections

Return JSON:
{
  "selectedPlaceId": "the place_id of a great match",
  "description": "A detailed 4-6 sentence description of the place. Include atmosphere, signature dishes/features, history if notable, what makes it special, and what visitors can expect. Make it engaging and informative.",
  "whyRecommended": "1-2 sentences explaining why this is a perfect choice for the user",
  "realPrice": "exact price if known (e.g., '€17', '€25-35 per person', 'Free'), or null if unknown",
  "includeAlternatives": true/false,
  "alternatives": [
    { "placeId": "place_id1", "description": "2-3 sentence description.", "realPrice": "price or null" },
    { "placeId": "place_id2", "description": "2-3 sentence description.", "realPrice": "price or null" }
  ]
}`;

    const userPrompt = `User query: "${intent.rawQuery}"
${intent.specificPlaceName ? `\n⚠️ SPECIFIC PLACE REQUESTED: "${intent.specificPlaceName}" - User wants THIS EXACT place, not alternatives!\n` : ''}${intent.originalLocation ? `\n📍 Original location: "${intent.originalLocation}" (resolved to city: ${intent.city})\n` : ''}
Available places:
${JSON.stringify(placesJson, null, 2)}

${intent.specificPlaceName
  ? `CRITICAL: You MUST select "${intent.specificPlaceName}" from the list. Do NOT pick a different place! Set includeAlternatives to false.`
  : 'Select the best recommendation from the list. Include alternatives for user to compare.'}`;

    return await geminiService.generateJSON({
      systemPrompt,
      userPrompt,
      temperature: 0.7,
      maxTokens: 800,
    });
  }

  /**
   * Get detailed information about a place
   */
  private async getPlaceDetails(placeId: string): Promise<GooglePlace | null> {
    try {
      const details = await googlePlacesService.getPlaceDetails(placeId);
      return details;
    } catch (error) {
      logger.warn(`Failed to get place details for ${placeId}:`, error);
      return null;
    }
  }

  /**
   * Helper to build photo URL
   */
  private buildPhotoUrl(photoReference: string): string {
    return `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=${photoReference}&key=${config.GOOGLE_PLACES_API_KEY}`;
  }


  /**
   * Build the final result object
   */
  private async buildResult(
    intent: SinglePlaceIntent,
    recommendation: {
      selectedPlaceId: string;
      description: string;
      whyRecommended: string;
      realPrice: string | null;
      alternatives: Array<{ placeId: string; description: string; realPrice: string | null }>;
      includeAlternatives?: boolean
    },
    placeDetails: GooglePlace | null,
    allPlaces: GooglePlace[]
  ): Promise<SinglePlaceResult> {
    // Find the selected place from our search results
    const selectedPlace = allPlaces.find(p => p.place_id === recommendation.selectedPlaceId) || allPlaces[0];

    // Use placeDetails if available (has more info), otherwise use selectedPlace
    // Cast to any to merge properties from both sources
    const detailsData = placeDetails as any;
    const searchData = selectedPlace as any;

    // Merge data - prefer details over search results
    const place = {
      place_id: detailsData?.place_id || searchData?.place_id,
      name: detailsData?.name || searchData?.name,
      formatted_address: detailsData?.formatted_address || searchData?.formatted_address,
      geometry: detailsData?.geometry || searchData?.geometry,
      rating: detailsData?.rating || searchData?.rating,
      user_ratings_total: detailsData?.user_ratings_total || searchData?.user_ratings_total,
      price_level: detailsData?.price_level ?? searchData?.price_level,
      opening_hours: detailsData?.opening_hours || searchData?.opening_hours,
      photos: detailsData?.photos || searchData?.photos,
      website: detailsData?.website || searchData?.website,
      formatted_phone_number: detailsData?.formatted_phone_number || searchData?.formatted_phone_number,
    };

    // Get image URLs - up to 10 photos
    let imageUrl: string | undefined;
    const images: string[] = [];

    if (place.photos && place.photos.length > 0) {
      // First photo as main image
      imageUrl = this.buildPhotoUrl(place.photos[0].photo_reference);

      // Get up to 10 photos for gallery
      const maxPhotos = Math.min(place.photos.length, 10);
      for (let i = 0; i < maxPhotos; i++) {
        images.push(this.buildPhotoUrl(place.photos[i].photo_reference));
      }
    }

    // Build opening hours in format expected by Flutter
    // Flutter expects: { open_now: bool, weekday_text: string[] }
    let openingHoursFormatted: { open_now?: boolean; weekday_text?: string[] } | undefined;
    if (place.opening_hours) {
      openingHoursFormatted = {
        open_now: place.opening_hours.open_now,
        weekday_text: place.opening_hours.weekday_text,
      };
    }

    // Build alternatives only if AI decided to include them
    const shouldIncludeAlternatives = recommendation.includeAlternatives !== false;
    let alternatives: Array<{
      id: string;
      name: string;
      description: string;
      rating: number;
      reviewCount: number;
      priceLevel: string;
      priceRange: string;
      estimatedPrice: string;
      whyAlternative: string;
      googlePlaceId: string;
      imageUrl?: string;
      images: string[];
      address: string;
      city: string;
      country: string;
      placeType: string;
      openingHours?: { open_now?: boolean; weekday_text?: string[] };
      isOpenNow?: boolean;
      phone?: string;
      website?: string;
    }> = [];

    if (shouldIncludeAlternatives && recommendation.alternatives.length > 0) {
      // Get details for each alternative in parallel
      const altDetailsPromises = recommendation.alternatives.map(async (altRec) => {
        const altId = altRec.placeId;
        const altDescription = altRec.description || 'Great alternative option';
        const altRealPrice = altRec.realPrice || ''; // Real price from AI

        const altFromSearch = allPlaces.find(p => p.place_id === altId);
        if (!altFromSearch) return null;

        try {
          const altDetails = await this.getPlaceDetails(altId);
          const altData = altDetails || altFromSearch;

          // Build images for alternative
          let altImageUrl: string | undefined;
          const altImages: string[] = [];
          if (altData.photos && altData.photos.length > 0) {
            altImageUrl = this.buildPhotoUrl(altData.photos[0].photo_reference);
            const maxAltPhotos = Math.min(altData.photos.length, 5);
            for (let i = 0; i < maxAltPhotos; i++) {
              altImages.push(this.buildPhotoUrl(altData.photos[i].photo_reference));
            }
          }

          // Build opening hours for alternative
          let altOpeningHours: { open_now?: boolean; weekday_text?: string[] } | undefined;
          if (altData.opening_hours) {
            altOpeningHours = {
              open_now: altData.opening_hours.open_now,
              weekday_text: altData.opening_hours.weekday_text,
            };
          }

          // Determine price for alternative: AI real price first, then realistic interval
          const altFallbackPrice = getRealisticPriceInterval(intent.placeType, altData.price_level);
          const altFinalPrice = altRealPrice || altFallbackPrice;

          return {
            id: uuidv4(),
            name: altData.name,
            description: altDescription,
            rating: altData.rating || 0,
            reviewCount: altData.user_ratings_total || 0,
            priceLevel: PRICE_LEVEL_MAP[altData.price_level ?? 2] || '€€',
            priceRange: PRICE_RANGE_MAP[altData.price_level ?? 2] || 'Moderate',
            // Use real price from AI if available, otherwise realistic interval
            estimatedPrice: altFinalPrice,
            whyAlternative: altDescription,
            googlePlaceId: altData.place_id,
            imageUrl: altImageUrl,
            images: altImages,
            address: altData.formatted_address || '',
            city: intent.city,
            country: intent.country || '',
            placeType: intent.placeType,
            openingHours: altOpeningHours,
            isOpenNow: altData.opening_hours?.open_now,
            phone: (altData as any).formatted_phone_number,
            website: (altData as any).website,
          };
        } catch (error) {
          logger.warn(`Failed to get details for alternative ${altId}:`, error);
          return null;
        }
      });

      const altResults = await Promise.all(altDetailsPromises);
      alternatives = altResults.filter((alt): alt is NonNullable<typeof alt> => alt !== null);
      logger.info(`📸 Got details for ${alternatives.length} alternatives`);
    }

    logger.info(`📸 Place photos: ${place.photos?.length || 0}, Images built: ${images.length}`);

    // Determine price: AI real price first, then realistic interval based on price_level
    const aiPrice = recommendation.realPrice || '';
    const fallbackPrice = getRealisticPriceInterval(intent.placeType, place.price_level);
    const finalPrice = aiPrice || fallbackPrice;

    logger.info(`💰 Price: AI="${aiPrice}", Fallback="${fallbackPrice}", Final="${finalPrice}"`);

    return {
      id: uuidv4(),
      type: 'single_place',
      place: {
        id: uuidv4(),
        name: place.name,
        description: recommendation.description,
        placeType: intent.placeType,
        category: intent.placeType,
        address: place.formatted_address || '',
        city: intent.city,
        country: intent.country || '',
        latitude: place.geometry?.location?.lat || 0,
        longitude: place.geometry?.location?.lng || 0,
        rating: place.rating || 0,
        reviewCount: place.user_ratings_total || 0,
        priceLevel: PRICE_LEVEL_MAP[place.price_level ?? 2] || '€€',
        priceRange: PRICE_RANGE_MAP[place.price_level ?? 2] || 'Moderate',
        // Use real price from AI if available, otherwise realistic interval based on price_level
        estimatedPrice: finalPrice,
        phone: place.formatted_phone_number,
        website: place.website,
        openingHours: openingHoursFormatted,
        isOpenNow: place.opening_hours?.open_now,
        cuisineTypes: intent.cuisineType,
        features: intent.specialRequirements,
        whyRecommended: recommendation.whyRecommended,
        imageUrl,
        images,
        googlePlaceId: place.place_id,
      },
      alternatives,
      _meta: {
        originalQuery: intent.rawQuery,
        intent,
        generatedAt: new Date().toISOString(),
      },
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Singleton Instance
// ═══════════════════════════════════════════════════════════════════════════

const singlePlaceGeneratorService = new SinglePlaceGeneratorService();

export default singlePlaceGeneratorService;
