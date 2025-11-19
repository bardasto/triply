/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Generate Restaurant Descriptions
 * Creates AI-generated descriptions for restaurants in database
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * Purpose:
 * - Generate engaging descriptions for restaurants ONCE in the database
 * - These descriptions will be reused for all trips
 * - Reduces token usage during trip generation
 * - Ensures consistent restaurant descriptions across all trips
 */

import { getSupabaseAdmin } from '../../../../shared/config/supabase.js';
import openAIService from '../services/openai.service.js';
import logger from '../../../../shared/utils/logger.js';

interface RestaurantForDescription {
  id: string;
  name: string;
  cuisine_types: string[];
  address: string;
  rating: number;
  google_rating: number;
  price_level: number;
  description: string | null;
}

async function generateRestaurantDescriptions(options?: {
  force?: boolean; // Force regenerate even if description exists
  city?: string; // Filter by city
  limit?: number; // Limit number of restaurants to process
}) {
  const startTime = Date.now();
  const force = options?.force || false;
  const city = options?.city;
  const limit = options?.limit || 100;

  logger.info('🍽️  Starting restaurant description generation...');
  logger.info(`   Force mode: ${force ? 'YES (will replace existing)' : 'NO (skip existing)'}`);
  if (city) logger.info(`   City filter: ${city}`);
  logger.info(`   Limit: ${limit} restaurants`);

  const supabase = getSupabaseAdmin();

  try {
    // Build query
    let query = supabase
      .from('restaurants')
      .select('id, name, cuisine_types, address, rating, google_rating, price_level, description')
      .eq('is_active', true)
      .order('rating', { ascending: false });

    // Apply filters
    if (city) {
      query = query.ilike('address', `%${city}%`);
    }

    if (!force) {
      // Only get restaurants without descriptions
      query = query.is('description', null);
    }

    query = query.limit(limit);

    const { data: restaurants, error: fetchError } = await query;

    if (fetchError) {
      logger.error('❌ Error fetching restaurants:', fetchError);
      return;
    }

    if (!restaurants || restaurants.length === 0) {
      logger.info('✅ No restaurants need descriptions');
      return;
    }

    logger.info(`📋 Found ${restaurants.length} restaurants to process\n`);

    let successCount = 0;
    let errorCount = 0;
    let skippedCount = 0;

    for (let i = 0; i < restaurants.length; i++) {
      const restaurant = restaurants[i] as RestaurantForDescription;

      logger.info(`\n[${i + 1}/${restaurants.length}] ${restaurant.name}`);

      // Skip if has description and not force mode
      if (restaurant.description && !force) {
        logger.info('  ℹ️  Already has description, skipping...');
        skippedCount++;
        continue;
      }

      try {
        // Generate description
        logger.info('  🤖 Generating AI description...');

        const description = await generateSingleRestaurantDescription(restaurant);

        if (!description) {
          logger.warn('  ⚠️  Failed to generate description');
          errorCount++;
          continue;
        }

        // Update database
        logger.info('  💾 Saving to database...');
        const { error: updateError } = await supabase
          .from('restaurants')
          .update({ description })
          .eq('id', restaurant.id);

        if (updateError) {
          logger.error('  ❌ Error saving:', updateError.message);
          errorCount++;
          continue;
        }

        logger.info('  ✅ Description saved successfully');
        logger.info(`  📝 "${description.substring(0, 80)}..."`);
        successCount++;

        // Rate limiting: small delay between requests
        await sleep(500);
      } catch (error: any) {
        logger.error(`  ❌ Error processing ${restaurant.name}:`, error.message);
        errorCount++;
      }
    }

    // Summary
    const duration = (Date.now() - startTime) / 1000;
    logger.info('\n═══════════════════════════════════════════════════════════════');
    logger.info('📊 DESCRIPTION GENERATION SUMMARY');
    logger.info('═══════════════════════════════════════════════════════════════');
    logger.info(`✅ Successfully generated: ${successCount}`);
    logger.info(`⏭️  Skipped (already have): ${skippedCount}`);
    logger.info(`❌ Errors: ${errorCount}`);
    logger.info(`⏱️  Total duration: ${duration.toFixed(2)}s`);
    logger.info('═══════════════════════════════════════════════════════════════\n');

    return { success: true, count: successCount, skipped: skippedCount, errors: errorCount };
  } catch (error) {
    logger.error('❌ Fatal error in description generation:', error);
    throw error;
  }
}

/**
 * Generate description for a single restaurant using OpenAI
 */
async function generateSingleRestaurantDescription(
  restaurant: RestaurantForDescription
): Promise<string | null> {
  const prompt = buildRestaurantDescriptionPrompt(restaurant);

  try {
    const response = await openAIService.generateText({
      prompt,
      maxTokens: 200, // Short description, ~50-80 words
      temperature: 0.8, // Slightly creative
    });

    return response.trim();
  } catch (error) {
    logger.error('OpenAI error:', error);
    return null;
  }
}

/**
 * Build prompt for restaurant description generation
 */
function buildRestaurantDescriptionPrompt(restaurant: RestaurantForDescription): string {
  const cuisineTypes = restaurant.cuisine_types?.join(', ') || 'restaurant';
  const rating = restaurant.rating || restaurant.google_rating || 'highly rated';
  const priceLevel = '€'.repeat(restaurant.price_level || 2);

  return `Write an engaging, informative description for this restaurant in 50-70 words:

Restaurant Name: ${restaurant.name}
Cuisine: ${cuisineTypes}
Location: ${restaurant.address}
Rating: ${rating}/5
Price Level: ${priceLevel}

Requirements:
- Write in present tense, third person
- Focus on the atmosphere, cuisine quality, and unique features
- Mention the cuisine type naturally
- Be engaging and appetizing
- 50-70 words MAXIMUM
- Do NOT use superlatives excessively
- Make it sound authentic and honest

Example style: "This cozy bistro specializes in traditional French cuisine with a modern twist. The intimate dining room features exposed brick walls and candlelight, creating a romantic atmosphere. Known for their perfectly executed coq au vin and house-made pastries, the restaurant attracts both locals and food enthusiasts seeking authentic flavors."

Now write the description for ${restaurant.name}:`;
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ═══════════════════════════════════════════════════════════════════════════
// CLI Execution
// ═══════════════════════════════════════════════════════════════════════════

if (import.meta.url === `file://${process.argv[1]}`) {
  const args = process.argv.slice(2);
  const force = args.includes('--force') || args.includes('-f');
  const cityArg = args.find(arg => arg.startsWith('--city='));
  const city = cityArg ? cityArg.split('=')[1] : undefined;
  const limitArg = args.find(arg => arg.startsWith('--limit='));
  const limit = limitArg ? parseInt(limitArg.split('=')[1]) : 100;

  logger.info('🚀 Starting with options:');
  logger.info(`   Force: ${force}`);
  logger.info(`   City: ${city || 'all cities'}`);
  logger.info(`   Limit: ${limit}`);
  logger.info('');

  generateRestaurantDescriptions({ force, city, limit })
    .then((result) => {
      if (result) {
        logger.info(`✅ Description generation completed: ${result.count} descriptions created`);
      }
      process.exit(0);
    })
    .catch((error) => {
      logger.error('❌ Description generation failed:', error);
      process.exit(1);
    });
}

export default generateRestaurantDescriptions;
