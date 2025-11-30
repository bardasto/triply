/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Triply AI API Server
 * Handles flexible trip generation from free-form user queries
 * ═══════════════════════════════════════════════════════════════════════════
 */

import express, { Request, Response } from 'express';
import cors from 'cors';
import flexibleTripGeneratorService from '../modules/ai/services/flexible-trip-generator.service.js';
import singlePlaceGeneratorService from '../modules/ai/services/single-place-generator.service.js';
import queryAnalyzerService, { SinglePlaceIntent, TripIntent, ModificationIntent, ConversationMessage } from '../modules/ai/services/query-analyzer.service.js';
import logger from '../shared/utils/logger.js';
import { initExchangeRates } from '../shared/utils/currency-converter.js';

const app = express();
const PORT = process.env.PORT || 3000;

// ═══════════════════════════════════════════════════════════════════════════
// Middleware
// ═══════════════════════════════════════════════════════════════════════════

app.use(cors());
app.use(express.json());

// Request logging
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`);
  next();
});

// ═══════════════════════════════════════════════════════════════════════════
// Routes
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Health check endpoint
 */
app.get('/health', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'triply-ai-api',
  });
});

/**
 * Generate trip OR single place from free-form query
 * AI automatically determines if user wants a full trip or a single place
 *
 * POST /api/trips/generate
 * Body: {
 *   "query": "romantic weekend in Paris" | "I want a Michelin restaurant in Paris"
 * }
 *
 * Response type depends on query:
 * - Trip queries return full itinerary
 * - Single place queries return one place recommendation
 */
app.post('/api/trips/generate', async (req: Request, res: Response) => {
  try {
    const { query, city, activity, durationDays, conversationContext } = req.body;

    // Build user query from provided parameters
    let userQuery = query;

    // If no query but city/activity provided, construct query
    if (!userQuery && (city || activity || durationDays)) {
      const parts = [];
      if (activity) parts.push(activity);
      if (durationDays) parts.push(`${durationDays} days`);
      if (city) parts.push(`in ${city}`);
      userQuery = parts.join(' ');
    }

    if (!userQuery) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'MISSING_QUERY',
          message: 'Please provide either "query" or "city" + "activity" in the request body',
        },
      });
    }

    logger.info('═══════════════════════════════════════════════════════');
    logger.info(`📝 Received generation request`);
    logger.info(`   Query: "${userQuery}"`);
    if (conversationContext?.length > 0) {
      logger.info(`   📚 Conversation context: ${conversationContext.length} messages`);
      // Debug: log context structure
      for (const msg of conversationContext) {
        if (msg.role === 'assistant' && msg.type === 'places' && msg.places?.length > 0) {
          logger.info(`   📍 Context has places: ${msg.places.map((p: any) => `${p.name} in ${p.city}`).join(', ')}`);
        }
      }
    }
    logger.info('═══════════════════════════════════════════════════════');

    // Step 1: Analyze query to determine intent (trip vs single place)
    // Pass conversation context for context-aware analysis
    const intent = await queryAnalyzerService.analyzeQuery(userQuery, conversationContext);

    // Step 2: Route to appropriate generator based on intent type
    if (intent.requestType === 'modification') {
      // Handle modification request
      const modIntent = intent as ModificationIntent;
      logger.info('🔧 Routing to Modification Handler');
      logger.info(`   Modifying: ${modIntent.modifyingType}`);
      logger.info(`   Category: ${modIntent.modificationCategory}`);

      // Extract previous result from context to get city and other info
      // Look for the most recent assistant message with places or trips
      const previousPlace = conversationContext?.slice().reverse().find(
        (msg: ConversationMessage) => msg.role === 'assistant' && msg.type === 'places' && msg.places?.length
      );
      const previousTrip = conversationContext?.slice().reverse().find(
        (msg: ConversationMessage) => msg.role === 'assistant' && msg.type === 'trip'
      );

      // Extract full context from previous results
      const contextPlace = previousPlace?.places?.[0];
      const contextCity = previousPlace?.city || contextPlace?.city || previousTrip?.city;
      const contextCountry = previousPlace?.country || contextPlace?.country || previousTrip?.country;

      // Debug: log what we found in context
      logger.info(`   Context search: previousPlace=${!!previousPlace}, previousTrip=${!!previousTrip}`);
      if (contextPlace) {
        logger.info(`   Previous place: ${contextPlace.name} in ${contextCity}, ${contextCountry}`);
        logger.info(`   Previous place type: ${contextPlace.type}, price: ${contextPlace.estimated_price || contextPlace.price_level}`);
      }

      if (modIntent.modifyingType === 'single_place') {
        // Build new SinglePlaceIntent with modified criteria
        // Priority: AI extracted city > context city > fallback
        const city = modIntent.city || contextCity || 'Paris';
        const country = contextCountry;
        const placeType = modIntent.placeType
          || contextPlace?.type
          || contextPlace?.category
          || 'restaurant';

        // Preserve cuisine types from context if available
        const cuisineTypes = contextPlace?.cuisine_types;

        logger.info(`   Resolved: city=${city}, country=${country}, placeType=${placeType}`);

        // Map modification category to budget
        let budget: 'budget' | 'mid-range' | 'luxury' | undefined = modIntent.newBudget;
        if (!budget && modIntent.modificationCategory === 'cheaper') {
          budget = 'budget';
        } else if (!budget && modIntent.modificationCategory === 'expensive') {
          budget = 'luxury';
        }

        const modifiedIntent: SinglePlaceIntent = {
          requestType: 'single_place',
          placeType: placeType as any,
          city,
          country,
          criteria: modIntent.newCriteria || [modIntent.modification],
          budget,
          cuisineType: cuisineTypes,
          specialRequirements: modIntent.newCriteria,
          rawQuery: userQuery,
        };

        logger.info(`   Creating modified single_place request for ${city}, ${country}`);

        const placeResult = await singlePlaceGeneratorService.generatePlace(modifiedIntent);

        const response = {
          success: true,
          type: 'single_place',
          data: {
            id: placeResult.id,
            type: 'single_place',
            place: placeResult.place,
            alternatives: placeResult.alternatives,
            _meta: {
              original_query: userQuery,
              modification: modIntent.modification,
              intent: placeResult._meta.intent,
              generated_at: placeResult._meta.generatedAt,
            },
          },
        };

        logger.info('✅ Modified single place generated successfully');
        logger.info(`   Name: ${placeResult.place.name}`);
        logger.info('═══════════════════════════════════════════════════════');

        return res.json(response);
      } else {
        // Modify trip - use existing trip modification logic
        // For now, generate a new trip with modified criteria
        const city = previousTrip?.city || 'Paris';
        const modifiedQuery = `${city} trip with ${modIntent.modification}`;

        const trip = await flexibleTripGeneratorService.generateTrip({
          userQuery: modifiedQuery,
          conversationContext,
        });

        const response = {
          success: true,
          type: 'trip',
          data: {
            id: trip.id,
            type: 'trip',
            title: trip.title,
            description: trip.description,
            city: trip.city,
            country: trip.country,
            duration: trip.duration,
            duration_days: trip.durationDays,
            price: trip.price,
            currency: trip.currency,
            hero_image_url: trip.heroImageUrl,
            includes: trip.includes,
            highlights: trip.highlights,
            itinerary: trip.itinerary.map((day: any) => ({
              day: day.day,
              title: day.title,
              description: day.description,
              places: day.places || [],
              images: day.images || [],
            })),
            images: trip.images,
            rating: trip.rating,
            reviews: trip.reviews,
            estimated_cost_min: trip.estimatedCostMin,
            estimated_cost_max: trip.estimatedCostMax,
            activity_type: trip.activityType,
            best_season: trip.bestSeason,
            _meta: {
              original_query: userQuery,
              modification: modIntent.modification,
              extracted_intent: trip.tripIntent,
            },
          },
        };

        logger.info('✅ Modified trip generated successfully');
        logger.info(`   Title: ${trip.title}`);
        logger.info('═══════════════════════════════════════════════════════');

        return res.json(response);
      }
    }

    if (intent.requestType === 'single_place') {
      // Generate single place recommendation
      const singlePlaceIntent = intent as SinglePlaceIntent;
      logger.info('🏪 Routing to Single Place Generator');
      if (singlePlaceIntent.specificPlaceName) {
        logger.info(`   🎯 Specific place requested: "${singlePlaceIntent.specificPlaceName}"`);
      }
      if (singlePlaceIntent.originalLocation) {
        logger.info(`   📍 Original location: "${singlePlaceIntent.originalLocation}" -> ${singlePlaceIntent.city}`);
      }

      const placeResult = await singlePlaceGeneratorService.generatePlace(singlePlaceIntent);

      // Convert to Flutter app format
      const response = {
        success: true,
        type: 'single_place',
        data: {
          id: placeResult.id,
          type: 'single_place',
          place: placeResult.place,
          alternatives: placeResult.alternatives,
          _meta: {
            original_query: userQuery,
            intent: placeResult._meta.intent,
            generated_at: placeResult._meta.generatedAt,
            // Include original location info for landmarks/natural wonders resolved to cities
            original_location: singlePlaceIntent.originalLocation || null,
            original_location_type: singlePlaceIntent.originalLocationType || null,
            resolved_city: singlePlaceIntent.originalLocation ? singlePlaceIntent.city : null,
          },
        },
      };

      logger.info('✅ Single place generated successfully');
      logger.info(`   Name: ${placeResult.place.name}`);
      logger.info(`   Type: ${placeResult.place.placeType}`);
      logger.info('═══════════════════════════════════════════════════════');

      return res.json(response);
    }

    // Generate full trip
    logger.info('🗺️ Routing to Trip Generator');

    const trip = await flexibleTripGeneratorService.generateTrip({
      userQuery,
      conversationContext,
    });

    // Convert to Flutter app format
    const response = {
      success: true,
      type: 'trip',
      data: {
        id: trip.id,
        type: 'trip',
        title: trip.title,
        description: trip.description,
        city: trip.city,
        country: trip.country,
        duration: trip.duration,
        duration_days: trip.durationDays,
        price: trip.price,
        currency: trip.currency,
        hero_image_url: trip.heroImageUrl,
        includes: trip.includes,
        highlights: trip.highlights,
        itinerary: trip.itinerary.map((day: any) => ({
          day: day.day,
          title: day.title,
          description: day.description,
          places: day.places || [],
          images: day.images || [],
        })),
        images: trip.images,
        rating: trip.rating,
        reviews: trip.reviews,
        estimated_cost_min: trip.estimatedCostMin,
        estimated_cost_max: trip.estimatedCostMax,
        activity_type: trip.activityType,
        best_season: trip.bestSeason,
        _meta: {
          original_query: userQuery,
          extracted_intent: trip.tripIntent,
        },
      },
    };

    logger.info('✅ Trip generated successfully');
    logger.info(`   ID: ${trip.id}`);
    logger.info(`   Title: ${trip.title}`);
    logger.info('═══════════════════════════════════════════════════════');

    res.json(response);
  } catch (error: any) {
    logger.error('❌ Generation failed:', error);

    res.status(500).json({
      success: false,
      error: {
        code: 'GENERATION_FAILED',
        message: error.message || 'Failed to generate',
        details: process.env.NODE_ENV === 'development' ? error.stack : undefined,
      },
    });
  }
});

/**
 * Modify an existing trip based on user request
 *
 * POST /api/trips/modify
 * Body: {
 *   "existingTrip": { ... trip data ... },
 *   "modificationRequest": "make it cheaper"
 * }
 */
app.post('/api/trips/modify', async (req: Request, res: Response) => {
  try {
    const { existingTrip, modificationRequest } = req.body;

    if (!existingTrip) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'MISSING_TRIP',
          message: 'Please provide "existingTrip" in the request body',
        },
      });
    }

    if (!modificationRequest) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'MISSING_REQUEST',
          message: 'Please provide "modificationRequest" in the request body',
        },
      });
    }

    logger.info('═══════════════════════════════════════════════════════');
    logger.info(`🔧 Received trip modification request`);
    logger.info(`   Trip: "${existingTrip.title || 'Untitled'}"`);
    logger.info(`   Request: "${modificationRequest}"`);
    logger.info('═══════════════════════════════════════════════════════');

    // Modify trip using flexible AI generator
    const trip = await flexibleTripGeneratorService.modifyTrip({
      existingTrip,
      modificationRequest,
    });

    // Convert to Flutter app format
    const response = {
      success: true,
      data: {
        id: trip.id,
        title: trip.title,
        description: trip.description,
        city: trip.city,
        country: trip.country,
        duration: trip.duration,
        duration_days: trip.durationDays,
        price: trip.price,
        currency: trip.currency,
        hero_image_url: trip.heroImageUrl,
        includes: trip.includes,
        highlights: trip.highlights,
        itinerary: trip.itinerary.map((day: any) => ({
          day: day.day,
          title: day.title,
          description: day.description,
          places: day.places || [],
          images: day.images || [],
        })),
        images: trip.images,
        rating: trip.rating,
        reviews: trip.reviews,
        estimated_cost_min: trip.estimatedCostMin,
        estimated_cost_max: trip.estimatedCostMax,
        activity_type: trip.activityType,
        best_season: trip.bestSeason,
        _meta: {
          modification_request: modificationRequest,
          modified_at: new Date().toISOString(),
        },
      },
    };

    logger.info('✅ Trip modified successfully');
    logger.info(`   ID: ${trip.id}`);
    logger.info(`   Title: ${trip.title}`);
    logger.info('═══════════════════════════════════════════════════════');

    res.json(response);
  } catch (error: any) {
    logger.error('❌ Trip modification failed:', error);

    res.status(500).json({
      success: false,
      error: {
        code: 'MODIFICATION_FAILED',
        message: error.message || 'Failed to modify trip',
        details: process.env.NODE_ENV === 'development' ? error.stack : undefined,
      },
    });
  }
});

/**
 * Get available cities (for autocomplete)
 * This could be expanded to query Supabase cities table
 */
app.get('/api/cities', async (req: Request, res: Response) => {
  try {
    // For now, return empty array as we support ANY city
    // This endpoint can be enhanced later to return popular cities from DB
    res.json({
      success: true,
      data: {
        message: 'All cities are supported! Just type any city name in your query.',
        examples: [
          'Paris, France',
          'Tokyo, Japan',
          'New York, USA',
          'Barcelona, Spain',
          'Berlin, Germany',
        ],
      },
    });
  } catch (error: any) {
    logger.error('Failed to fetch cities:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'FETCH_FAILED',
        message: 'Failed to fetch cities',
      },
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// Error handling
// ═══════════════════════════════════════════════════════════════════════════

app.use((req: Request, res: Response) => {
  res.status(404).json({
    success: false,
    error: {
      code: 'NOT_FOUND',
      message: 'Endpoint not found',
    },
  });
});

app.use((err: any, req: Request, res: Response, next: any) => {
  logger.error('Unhandled error:', err);
  res.status(500).json({
    success: false,
    error: {
      code: 'INTERNAL_ERROR',
      message: 'Internal server error',
    },
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// Start server
// ═══════════════════════════════════════════════════════════════════════════

// Always start server when this file is run directly
// Listen on 0.0.0.0 to allow connections from local network (real iOS devices)
// Initialize exchange rates before starting server
initExchangeRates().then(() => {
  logger.info('✅ Exchange rates initialized');
}).catch((err) => {
  logger.warn('⚠️ Failed to initialize exchange rates, will use fallback:', err);
});

app.listen(Number(PORT), '0.0.0.0', () => {
  logger.info('═══════════════════════════════════════════════════════');
  logger.info('🚀 Triply AI API Server');
  logger.info('═══════════════════════════════════════════════════════');
  logger.info(`✓ Server running on http://localhost:${PORT}`);
  logger.info(`✓ Local network: http://192.168.0.7:${PORT}`);
  logger.info(`✓ Health check: http://localhost:${PORT}/health`);
  logger.info(`✓ Generate trip: POST http://localhost:${PORT}/api/trips/generate`);
  logger.info('═══════════════════════════════════════════════════════');
  logger.info('');
  logger.info('Example request:');
  logger.info('  curl -X POST http://localhost:3000/api/trips/generate \\');
  logger.info('    -H "Content-Type: application/json" \\');
  logger.info('    -d \'{"query": "romantic weekend in Paris"}\'');
  logger.info('');
  logger.info('═══════════════════════════════════════════════════════');
});

export default app;
