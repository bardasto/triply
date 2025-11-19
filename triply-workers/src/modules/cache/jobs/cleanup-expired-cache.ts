/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Cleanup Expired Cache Job
 * Delete cache entries that have expired (>30 days old)
 * Run daily to ensure compliance with Google Places API policy
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { createClient } from '@supabase/supabase-js';
import config from '../../../../shared/config/env.js';
import logger from '../../../../shared/utils/logger.js';
import PlacesCacheService from '../services/places-cache.service.js';

// ═══════════════════════════════════════════════════════════════════════════
// Types
// ═══════════════════════════════════════════════════════════════════════════

interface CleanupJobResult {
  expired_entries: number;
  deleted_entries: number;
  failed_deletions: number;
  errors: string[];
  duration_ms: number;
}

// ═══════════════════════════════════════════════════════════════════════════
// Main Job Function
// ═══════════════════════════════════════════════════════════════════════════

export async function cleanupExpiredCache(): Promise<CleanupJobResult> {
  const startTime = Date.now();
  logger.info('🧹 Starting expired cache cleanup job...');

  const result: CleanupJobResult = {
    expired_entries: 0,
    deleted_entries: 0,
    failed_deletions: 0,
    errors: [],
    duration_ms: 0,
  };

  const supabase = createClient(
    config.SUPABASE_URL,
    config.SUPABASE_SERVICE_ROLE_KEY
  );

  try {
    // Get expired cache entries
    const { data: expiredEntries, error: queryError } = await supabase.rpc(
      'get_expired_cache_entries'
    );

    if (queryError) {
      throw new Error(`Failed to get expired entries: ${queryError.message}`);
    }

    result.expired_entries = expiredEntries?.length || 0;
    logger.info(`Found ${result.expired_entries} expired cache entries`);

    if (result.expired_entries === 0) {
      logger.info('✅ No expired cache entries to delete');
      result.duration_ms = Date.now() - startTime;
      return result;
    }

    // Log details of expired entries
    logger.info('\n📋 Expired Cache Entries:');
    expiredEntries?.forEach((entry: any, i: number) => {
      logger.info(
        `  ${i + 1}. ${entry.place_name} (expired ${Math.floor(entry.expired_since_days)} days ago)`
      );
    });

    // Delete expired cache entries
    logger.info(`\n🗑️  Deleting ${result.expired_entries} expired entries...`);

    const deletedCount = await PlacesCacheService.deleteExpiredCache();
    result.deleted_entries = deletedCount;

    result.duration_ms = Date.now() - startTime;

    // Log summary
    logger.info('\n' + '═'.repeat(80));
    logger.info('📊 Cache Cleanup Job Summary');
    logger.info('═'.repeat(80));
    logger.info(`Expired Entries Found:  ${result.expired_entries}`);
    logger.info(`✅ Deleted:              ${result.deleted_entries}`);
    logger.info(`❌ Failed:               ${result.failed_deletions}`);
    logger.info(`⏱️  Duration:             ${(result.duration_ms / 1000).toFixed(2)}s`);
    logger.info('═'.repeat(80));

    if (result.errors.length > 0) {
      logger.error('\n🚨 Errors:');
      result.errors.forEach((err, i) => logger.error(`  ${i + 1}. ${err}`));
    }

    return result;
  } catch (error: any) {
    logger.error('❌ Cache cleanup job failed:', error);
    result.errors.push(`Job failed: ${error.message}`);
    result.duration_ms = Date.now() - startTime;
    throw error;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Cleanup Old Refresh Logs (housekeeping)
// ═══════════════════════════════════════════════════════════════════════════

export async function cleanupOldRefreshLogs(
  olderThanDays: number = 90
): Promise<number> {
  logger.info(
    `🧹 Cleaning up refresh logs older than ${olderThanDays} days...`
  );

  const supabase = createClient(
    config.SUPABASE_URL,
    config.SUPABASE_SERVICE_ROLE_KEY
  );

  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - olderThanDays);

  const { data, error } = await supabase
    .from('cache_refresh_log')
    .delete()
    .lt('refreshed_at', cutoffDate.toISOString())
    .select();

  if (error) {
    logger.error('Failed to cleanup old refresh logs:', error);
    throw new Error(`Failed to cleanup old refresh logs: ${error.message}`);
  }

  const deletedCount = data?.length || 0;
  logger.info(`✅ Deleted ${deletedCount} old refresh log entries`);
  return deletedCount;
}

// ═══════════════════════════════════════════════════════════════════════════
// Full Cleanup (cache + logs)
// ═══════════════════════════════════════════════════════════════════════════

export async function fullCleanup(): Promise<{
  cache: CleanupJobResult;
  logs_deleted: number;
}> {
  logger.info('🧹 Starting full cleanup (cache + logs)...\n');

  // Clean expired cache
  const cacheResult = await cleanupExpiredCache();

  logger.info('\n');

  // Clean old logs (keep logs for 90 days)
  const logsDeleted = await cleanupOldRefreshLogs(90);

  return {
    cache: cacheResult,
    logs_deleted: logsDeleted,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// CLI Execution
// ═══════════════════════════════════════════════════════════════════════════

if (import.meta.url === `file://${process.argv[1]}`) {
  (async () => {
    try {
      const args = process.argv.slice(2);
      const runFullCleanup = args.includes('--full');

      if (runFullCleanup) {
        const result = await fullCleanup();
        logger.info('\n✅ Full cleanup completed successfully');
        process.exit(0);
      } else {
        const result = await cleanupExpiredCache();
        process.exit(result.failed_deletions > 0 ? 1 : 0);
      }
    } catch (error) {
      logger.error('Job execution failed:', error);
      process.exit(1);
    }
  })();
}
