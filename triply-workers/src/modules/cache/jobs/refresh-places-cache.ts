/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Refresh Places Cache Job
 * Automatically refresh cache every 15 days to keep data fresh
 * Run daily to check for places that need refresh
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { createClient } from '@supabase/supabase-js';
import config from '../../../../shared/config/env.js';
import logger from '../../../../shared/utils/logger.js';
import PlacesCacheService from '../services/places-cache.service.js';

// ═══════════════════════════════════════════════════════════════════════════
// Types
// ═══════════════════════════════════════════════════════════════════════════

interface RefreshJobResult {
  total_checked: number;
  needs_refresh: number;
  refreshed: number;
  failed: number;
  skipped: number;
  errors: string[];
  duration_ms: number;
}

// ═══════════════════════════════════════════════════════════════════════════
// Job Configuration
// ═══════════════════════════════════════════════════════════════════════════

const JOB_CONFIG = {
  BATCH_SIZE: 100, // Process 100 places per run
  MAX_API_CALLS_PER_RUN: 50, // Limit API calls to avoid quota issues
  DELAY_BETWEEN_CALLS_MS: 500, // 500ms between API calls
};

// ═══════════════════════════════════════════════════════════════════════════
// Main Job Function
// ═══════════════════════════════════════════════════════════════════════════

export async function refreshPlacesCache(): Promise<RefreshJobResult> {
  const startTime = Date.now();
  logger.info('🔄 Starting places cache refresh job...');

  const result: RefreshJobResult = {
    total_checked: 0,
    needs_refresh: 0,
    refreshed: 0,
    failed: 0,
    skipped: 0,
    errors: [],
    duration_ms: 0,
  };

  const supabase = createClient(
    config.SUPABASE_URL,
    config.SUPABASE_SERVICE_ROLE_KEY
  );

  try {
    // Get places that need refresh using SQL function
    const { data: placesNeedingRefresh, error } = await supabase.rpc(
      'get_places_needing_refresh',
      { batch_size: JOB_CONFIG.BATCH_SIZE }
    );

    if (error) {
      throw new Error(`Failed to get places needing refresh: ${error.message}`);
    }

    result.total_checked = placesNeedingRefresh?.length || 0;
    logger.info(`Found ${result.total_checked} places to check`);

    if (result.total_checked === 0) {
      logger.info('✅ No places need refresh');
      result.duration_ms = Date.now() - startTime;
      return result;
    }

    // Process each place
    for (const place of placesNeedingRefresh || []) {
      // Stop if we've hit the API call limit
      if (result.refreshed >= JOB_CONFIG.MAX_API_CALLS_PER_RUN) {
        logger.warn(
          `⚠️ Reached max API calls limit (${JOB_CONFIG.MAX_API_CALLS_PER_RUN}), stopping`
        );
        result.skipped = result.total_checked - (result.refreshed + result.failed);
        break;
      }

      result.needs_refresh++;

      try {
        logger.info(
          `[${result.refreshed + 1}/${JOB_CONFIG.MAX_API_CALLS_PER_RUN}] Refreshing: ${place.google_place_id} (${place.place_type})`
        );

        const refreshResult = await PlacesCacheService.refreshCache(
          place.catalog_id,
          'scheduled'
        );

        if (refreshResult.success) {
          result.refreshed++;
          logger.info(
            `✅ Refreshed: ${place.google_place_id} (${refreshResult.latency_ms}ms)`
          );
        } else {
          result.failed++;
          const errorMsg = `Failed to refresh ${place.google_place_id}: ${refreshResult.error}`;
          result.errors.push(errorMsg);
          logger.error(errorMsg);
        }

        // Rate limiting delay
        await sleep(JOB_CONFIG.DELAY_BETWEEN_CALLS_MS);
      } catch (error: any) {
        result.failed++;
        const errorMsg = `Error refreshing ${place.google_place_id}: ${error.message}`;
        result.errors.push(errorMsg);
        logger.error(errorMsg);
      }
    }

    result.duration_ms = Date.now() - startTime;

    // Log summary
    logger.info('\n' + '═'.repeat(80));
    logger.info('📊 Cache Refresh Job Summary');
    logger.info('═'.repeat(80));
    logger.info(`Total Checked:    ${result.total_checked}`);
    logger.info(`Needs Refresh:    ${result.needs_refresh}`);
    logger.info(`✅ Refreshed:     ${result.refreshed}`);
    logger.info(`❌ Failed:        ${result.failed}`);
    logger.info(`⏭️  Skipped:       ${result.skipped}`);
    logger.info(`⏱️  Duration:      ${(result.duration_ms / 1000).toFixed(2)}s`);
    logger.info('═'.repeat(80));

    if (result.errors.length > 0) {
      logger.error('\n🚨 Errors:');
      result.errors.forEach((err, i) => logger.error(`  ${i + 1}. ${err}`));
    }

    return result;
  } catch (error: any) {
    logger.error('❌ Cache refresh job failed:', error);
    result.errors.push(`Job failed: ${error.message}`);
    result.duration_ms = Date.now() - startTime;
    throw error;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Get Refresh Statistics
// ═══════════════════════════════════════════════════════════════════════════

export async function getCacheRefreshStats() {
  logger.info('📊 Getting cache refresh statistics...');

  const stats = await PlacesCacheService.getCacheStatistics();

  logger.info('\n' + '═'.repeat(80));
  logger.info('📊 Cache Statistics by Place Type');
  logger.info('═'.repeat(80));

  stats.forEach((stat: any) => {
    logger.info(`\n${stat.place_type.toUpperCase()}:`);
    logger.info(`  Total Places:        ${stat.total_places}`);
    logger.info(`  Cached:              ${stat.cached_places}`);
    logger.info(`  Fresh:               ${stat.fresh_cache}`);
    logger.info(`  Needs Refresh:       ${stat.needs_refresh}`);
    logger.info(`  Expired:             ${stat.expired_cache}`);
    logger.info(`  Coverage:            ${stat.cache_coverage_percent}%`);
  });

  logger.info('═'.repeat(80));

  return stats;
}

// ═══════════════════════════════════════════════════════════════════════════
// Helper Functions
// ═══════════════════════════════════════════════════════════════════════════

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ═══════════════════════════════════════════════════════════════════════════
// CLI Execution
// ═══════════════════════════════════════════════════════════════════════════

if (import.meta.url === `file://${process.argv[1]}`) {
  (async () => {
    try {
      // Show stats first
      await getCacheRefreshStats();

      console.log('\n');

      // Run refresh job
      const result = await refreshPlacesCache();

      console.log('\n');

      // Show stats after refresh
      await getCacheRefreshStats();

      process.exit(result.failed > 0 ? 1 : 0);
    } catch (error) {
      logger.error('Job execution failed:', error);
      process.exit(1);
    }
  })();
}
