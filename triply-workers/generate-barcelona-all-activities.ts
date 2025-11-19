import getSupabaseAdmin from './src/shared/config/supabase.js';
import logger from './src/shared/utils/logger.js';
import { getActivityPrompt } from './src/modules/ai/prompts/activity-prompts.js';
import googlePlacesService from './src/modules/google-places/services/google-places.service.js';
import googlePlacesPhotosService from './src/modules/google-places/services/google-places-photos.service.js';
import OpenAI from 'openai';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const supabase = getSupabaseAdmin();
const barcelonaId = 'd0045c38-048f-4f44-976f-c91b94d2b900';

// All 11 activity types with variable duration
const allActivities = [
  { type: 'cycling', days: 2 },
  { type: 'beach', days: 4 },
  { type: 'skiing', days: 5 },
  { type: 'mountains', days: 3 },
  { type: 'hiking', days: 4 },
  { type: 'sailing', days: 3 },
  { type: 'desert', days: 5 },
  { type: 'camping', days: 4 },
  { type: 'city', days: 3 },
  { type: 'wellness', days: 3 },
  { type: 'road_trip', days: 7 },
];

// Get hero image from Google Places
async function getHeroImageFromGooglePlaces(
  tripTitle: string,
  activity: string
): Promise<string | null> {
  try {
    // Search for the main attraction in Barcelona for this activity
    const searchQuery = `${activity} Barcelona Spain`;
    logger.info(`🔍 Searching Google Places for: "${searchQuery}"`);

    const results = await googlePlacesService.textSearch({
      query: searchQuery,
      location: { lat: 41.3851, lng: 2.1734 },
      radius: 50000,
    });

    if (results.length === 0) {
      logger.warn(`No places found for: ${searchQuery}`);
      return null;
    }

    const firstPlace = results[0];
    logger.info(`✓ Found place: ${firstPlace.name} (${firstPlace.place_id})`);

    if (!firstPlace.place_id) {
      logger.warn(`No place_id for: ${firstPlace.name}`);
      return null;
    }

    // Get photos for this place
    const photos = await googlePlacesPhotosService.getPOIPhotos(
      firstPlace.place_id,
      1
    );

    if (photos.length > 0) {
      logger.info(`✓ Got hero image from: ${firstPlace.name}`);
      return photos[0].url;
    }

    logger.warn(`No photos found for: ${firstPlace.name}`);
    return null;
  } catch (error: any) {
    logger.error(`Failed to get hero image from Google Places:`, error.message);
    return null;
  }
}

logger.info('🗑️  Step 1: Deleting old Barcelona trips...');
const { error: deleteError, data: deletedTrips } = await supabase
  .from('public_trips')
  .delete()
  .eq('city', 'Barcelona')
  .select();

if (deleteError) {
  logger.warn(`⚠️  Delete warning: ${deleteError.message} - continuing anyway`);
} else {
  logger.info(`✅ Deleted ${deletedTrips?.length || 0} old Barcelona trips`);
}

logger.info(`\n🚀 Step 2: Generating trips for ALL ${allActivities.length} activity types\n`);

let successCount = 0;
let failCount = 0;

for (const activity of allActivities) {
  try {
    logger.info(`\n${'='.repeat(60)}`);
    logger.info(`🎯 Generating ${activity.type.toUpperCase()} trip for Barcelona (${activity.days} days)...`);
    logger.info(`${'='.repeat(60)}\n`);

    // Generate activity-specific prompt
    const prompt = getActivityPrompt({
      city: 'Barcelona',
      country: 'Spain',
      activity: activity.type,
      durationDays: activity.days,
      language: 'English',
    });

    logger.info('📝 Calling OpenAI with activity-specific prompt...');

    // Call OpenAI to generate trip
    const completion = await openai.chat.completions.create({
      model: 'gpt-4-turbo-preview',
      messages: [
        {
          role: 'system',
          content: 'You are a travel expert who creates detailed, authentic trip itineraries with REAL specific places.',
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      temperature: 0.8, // Higher creativity for diverse suggestions
      response_format: { type: 'json_object' },
    });

    const content = completion.choices[0]?.message?.content;
    if (!content) {
      throw new Error('No content in OpenAI response');
    }

    const tripData = JSON.parse(content);
    logger.info(`✓ Generated trip: "${tripData.title}"`);
    logger.info(`✓ Days: ${tripData.itinerary?.length || 0}`);

    // Count total places
    const totalPlaces = tripData.itinerary?.reduce(
      (sum: number, day: any) => sum + (day.places?.length || 0),
      0
    );
    logger.info(`✓ Total places: ${totalPlaces}`);

    // Get hero image and photos for all places
    logger.info('🖼️  Fetching hero image from Google Places...');
    const heroImage = await getHeroImageFromGooglePlaces(
      tripData.title,
      activity.type
    );
    if (heroImage) {
      logger.info(`✓ Hero image: ${heroImage.substring(0, 60)}...`);
    } else {
      logger.warn('⚠️  No hero image found from Google Places');
    }

    // Fetch photos for EACH place in the itinerary
    logger.info('📸 Fetching photos for all places in itinerary...');
    let totalPhotos = 0;
    let photosSuccess = 0;
    let photosFailed = 0;

    for (const day of tripData.itinerary || []) {
      for (const place of day.places || []) {
        try {
          // Search for this specific place
          const searchQuery = `${place.name} ${place.address || 'Barcelona'}`;
          logger.info(`  🔍 Searching for: ${place.name}`);

          const results = await googlePlacesService.textSearch({
            query: searchQuery,
            location: { lat: place.latitude || 41.3851, lng: place.longitude || 2.1734 },
            radius: 1000,
          });

          if (results.length > 0 && results[0].place_id) {
            // Get 10-15 photos for this place
            const photos = await googlePlacesPhotosService.getPOIPhotos(
              results[0].place_id,
              12
            );

            if (photos.length > 0) {
              place.images = photos.map((p) => ({
                url: p.url,
                source: 'google_places',
                alt_text: `${place.name} - ${place.type}`,
              }));
              logger.info(`    ✓ Got ${photos.length} photos for ${place.name}`);
              totalPhotos += photos.length;
              photosSuccess++;
            } else {
              logger.warn(`    ⚠️  No photos found for ${place.name}`);
              place.images = [];
              photosFailed++;
            }
          } else {
            logger.warn(`    ⚠️  Place not found in Google: ${place.name}`);
            place.images = [];
            photosFailed++;
          }

          // Small delay to avoid rate limiting
          await new Promise((resolve) => setTimeout(resolve, 300));
        } catch (error: any) {
          logger.error(`    ❌ Error fetching photos for ${place.name}: ${error.message}`);
          place.images = [];
          photosFailed++;
        }
      }
    }

    logger.info(`📊 Photos summary: ${totalPhotos} total, ${photosSuccess} places with photos, ${photosFailed} failed`);

    // Save to database
    logger.info('💾 Saving to database...');

    const budget = tripData.recommendedBudget || { min: 150, max: 400, currency: 'EUR' };

    const { data: insertedTrip, error: insertError } = await supabase
      .from('public_trips')
      .insert({
        id: crypto.randomUUID(),
        city: 'Barcelona',
        country: 'Spain',
        continent: 'Europe',
        title: tripData.title,
        description: tripData.description,
        duration: tripData.duration || `${activity.days} days`,
        price: '€€€',
        rating: 4.5 + Math.random() * 0.5,
        reviews: Math.floor(Math.random() * 500) + 100,
        latitude: 41.3851,
        longitude: 2.1734,
        activity_type: activity.type,
        difficulty_level: 'moderate',
        best_season: tripData.bestSeasons || ['spring', 'summer'],
        includes: tripData.includes || [],
        highlights: tripData.highlights || [],
        itinerary: tripData.itinerary,
        images: [],
        hero_image_url: heroImage,
        poi_data: [],
        attractions: [],
        estimated_cost_min: budget.min,
        estimated_cost_max: budget.max,
        currency: budget.currency || 'EUR',
        generation_id: crypto.randomUUID(),
        relevance_score: 0.9 + Math.random() * 0.1,
        data_sources: {
          pois: 'ai_generated',
          itinerary: 'openai_gpt4',
          hero_image: 'google_places',
        },
        generation_model: 'gpt-4-turbo-preview',
        status: 'active',
      })
      .select()
      .single();

    if (insertError) {
      throw new Error(`Database insert error: ${insertError.message}`);
    }

    logger.info(`✅ SUCCESS: ${activity.type} trip saved (ID: ${insertedTrip.id})`);
    successCount++;

    // Log sample places from first day
    if (tripData.itinerary?.[0]?.places?.length > 0) {
      logger.info('\n📍 Sample places from Day 1:');
      tripData.itinerary[0].places.slice(0, 5).forEach((place: any, idx: number) => {
        logger.info(`  ${idx + 1}. ${place.name} (${place.type})`);
      });
    }

    // Small delay to avoid rate limits
    await new Promise((resolve) => setTimeout(resolve, 2000));
  } catch (error: any) {
    logger.error(`\n❌ FAILED: ${activity.type} trip generation failed`);
    logger.error(`Error: ${error.message}`);
    failCount++;
  }
}

logger.info('\n' + '='.repeat(60));
logger.info('📊 GENERATION SUMMARY');
logger.info('='.repeat(60));
logger.info(`✅ Successful: ${successCount}/${allActivities.length}`);
logger.info(`❌ Failed: ${failCount}/${allActivities.length}`);
logger.info('='.repeat(60));

if (successCount === allActivities.length) {
  logger.info('\n🎉 ALL TRIPS GENERATED SUCCESSFULLY!');
} else {
  logger.warn(`\n⚠️  Some trips failed. Check logs above.`);
}

process.exit(0);
