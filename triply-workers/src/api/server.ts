/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Triply AI API Server
 * Handles flexible trip generation from free-form user queries
 * ═══════════════════════════════════════════════════════════════════════════
 */

import express, { Request, Response } from 'express';
import cors from 'cors';
import flexibleTripGeneratorService from '../modules/ai/services/flexible-trip-generator.service.js';
import logger from '../shared/utils/logger.js';

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
 * Generate trip from free-form query
 *
 * POST /api/trips/generate
 * Body: {
 *   "query": "romantic weekend in Paris",
 *   "city": "Paris" (optional - will be extracted from query),
 *   "activity": "romantic exploration" (optional - will be extracted from query),
 *   "durationDays": 2 (optional - will be extracted from query or default to 3)
 * }
 */
app.post('/api/trips/generate', async (req: Request, res: Response) => {
  try {
    const { query, city, activity, durationDays } = req.body;

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
    logger.info(`📝 Received trip generation request`);
    logger.info(`   Query: "${userQuery}"`);
    logger.info('═══════════════════════════════════════════════════════');

    // Generate trip using flexible AI generator
    const trip = await flexibleTripGeneratorService.generateTrip({
      userQuery,
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
        // Include original query intent for reference
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
    logger.error('❌ Trip generation failed:', error);

    res.status(500).json({
      success: false,
      error: {
        code: 'GENERATION_FAILED',
        message: error.message || 'Failed to generate trip',
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
app.listen(PORT, '0.0.0.0', () => {
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
