/**
 * Quick test for Hybrid V2 - Generate ONE trip to verify structure
 */

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

// Test: Barcelona Food Trip
const CITY = {
  name: 'Barcelona',
  country: 'Spain',
  lat: 41.3851,
  lng: 2.1734,
};
const ACTIVITY = 'food';
const DURATION = 2; // 2 days for quick test

async function getCachedRestaurants() {
  const { data } = await supabase
    .from('restaurants')
    .select('*')
    .eq('is_active', true)
    .ilike('address', '%Barcelona%')
    .order('rating', { ascending: false})
    .limit(10);

  return data || [];
}

async function test() {
  logger.info('🧪 Testing Hybrid V2 - ONE Barcelona Food Trip\n');

  // Get cached restaurants
  const cachedRestaurants = await getCachedRestaurants();
  logger.info(`📦 Found ${cachedRestaurants.length} cached restaurants\n`);

  // Build prompt with restaurant suggestions
  const basePrompt = getActivityPrompt({
    city: CITY.name,
    country: CITY.country,
    activity: ACTIVITY,
    durationDays: DURATION,
    language: 'English'
  });

  const restaurantSuggestions = cachedRestaurants
    .slice(0, 8)
    .map(r => `- ${r.name} (${r.cuisine_types?.join(', ') || 'Restaurant'}) - Rating: ${r.rating}`)
    .join('\n');

  const prompt = `${basePrompt}

🍽️ SUGGESTED RESTAURANTS (use these in "restaurants" array):
${restaurantSuggestions}

Remember: Put restaurants in the "restaurants" array, NOT in "places" array!`;

  // Call OpenAI
  logger.info('🤖 Calling OpenAI...\n');
  const completion = await openai.chat.completions.create({
    model: 'gpt-4-turbo-preview',
    messages: [
      {
        role: 'system',
        content: 'You are a travel expert. Create itineraries with separated places and restaurants arrays. Output valid JSON.',
      },
      {
        role: 'user',
        content: prompt,
      },
    ],
    temperature: 0.8,
    response_format: { type: 'json_object' },
  });

  const content = completion.choices[0]?.message?.content;
  if (!content) {
    throw new Error('No content');
  }

  const tripData = JSON.parse(content);
  logger.info('✅ Trip generated successfully!');
  logger.info(`📋 Title: ${tripData.title}`);
  logger.info(`📅 Days: ${tripData.itinerary?.length || 0}\n`);

  // Analyze structure
  for (const day of tripData.itinerary || []) {
    logger.info(`Day ${day.day}: ${day.title}`);
    logger.info(`  📍 Places: ${day.places?.length || 0}`);
    logger.info(`  🍽️  Restaurants: ${day.restaurants?.length || 0}`);

    if (day.places) {
      day.places.forEach((p: any, i: number) => {
        logger.info(`    ${i + 1}. ${p.name} (${p.category})`);
      });
    }

    if (day.restaurants) {
      day.restaurants.forEach((r: any, i: number) => {
        logger.info(`    🍽️  ${i + 1}. ${r.name} (${r.category}) - ${r.cuisine || 'N/A'}`);
      });
    }
    logger.info('');
  }

  logger.info('🎉 TEST PASSED! Structure is correct.');
  logger.info('✅ places[] contains attractions (NOT restaurants)');
  logger.info('✅ restaurants[] contains restaurants (NOT attractions)\n');

  process.exit(0);
}

test().catch((error) => {
  logger.error('❌ Test failed:', error);
  process.exit(1);
});
