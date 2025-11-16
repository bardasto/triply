
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Supabase Client Configuration
 * Service Role client для backend операций (bypass RLS)
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js';
import config from './env.js';
import logger from '../utils/logger.js';

// ═══════════════════════════════════════════════════════════════════════════
// Database Types (можно сгенерировать через supabase gen types typescript)
// ═══════════════════════════════════════════════════════════════════════════

export interface Database {
  public: {
    Tables: {
      cities: any;
      pois: any;
      generated_trips: any;
      user_preferences: any;
      api_cache: any;
      generation_logs: any;
      trip_images_metadata: any;
      trip_interactions: any;
      rate_limits: any;
    };
    Functions: {
      get_personalized_trips: any;
      get_pois_for_city: any;
      search_cities: any;
      calculate_distance_km: any;
    };
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Service Role Client (bypass RLS)
// ═══════════════════════════════════════════════════════════════════════════

let supabaseAdmin: SupabaseClient<Database> | null = null;

export const getSupabaseAdmin = (): SupabaseClient<Database> => {
  if (!supabaseAdmin) {
    supabaseAdmin = createClient<Database>(
      config.SUPABASE_URL,
      config.SUPABASE_SERVICE_ROLE_KEY,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
        db: {
          schema: 'public',
        },
        global: {
          headers: {
            'x-client-info': 'triply-workers/1.0.0',
          },
        },
      }
    );

    logger.info('✅ Supabase Admin client initialized');
  }

  return supabaseAdmin;
};

// ═══════════════════════════════════════════════════════════════════════════
// Anon Client (for read-only operations respecting RLS)
// ═══════════════════════════════════════════════════════════════════════════

let supabaseAnon: SupabaseClient<Database> | null = null;

export const getSupabaseAnon = (): SupabaseClient<Database> => {
  if (!supabaseAnon) {
    supabaseAnon = createClient<Database>(
      config.SUPABASE_URL,
      config.SUPABASE_ANON_KEY,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    );

    logger.info('✅ Supabase Anon client initialized');
  }

  return supabaseAnon;
};

// ═══════════════════════════════════════════════════════════════════════════
// Helper: Execute RPC with error handling
// ═══════════════════════════════════════════════════════════════════════════

export const executeRpc = async <T = any>(
  functionName: string,
  params?: Record<string, any>
): Promise<T> => {
  const supabase = getSupabaseAdmin();
  const startTime = Date.now();

  try {
    const { data, error } = await supabase.rpc(functionName, params);

    const duration = Date.now() - startTime;

    if (error) {
      logger.error(
        { functionName, params, error, duration },
        `RPC call failed: ${functionName}`
      );
      throw new Error(`Supabase RPC error: ${error.message}`);
    }

    logger.debug(
      { functionName, params, duration },
      `RPC call success: ${functionName}`
    );

    return data as T;
  } catch (err) {
    const duration = Date.now() - startTime;
    logger.error(
      { functionName, params, err, duration },
      `RPC call exception: ${functionName}`
    );
    throw err;
  }
};

// ═══════════════════════════════════════════════════════════════════════════
// Helper: Batch insert with conflict handling
// ═══════════════════════════════════════════════════════════════════════════

export const batchInsert = async <T extends Record<string, any>>(
  table: string,
  records: T[],
  options?: {
    onConflict?: string;
    returning?: boolean;
    chunkSize?: number;
  }
): Promise<{ success: number; failed: number; errors: any[] }> => {
  const supabase = getSupabaseAdmin();
  const chunkSize = options?.chunkSize || 100;
  const chunks = [];

  // Split into chunks
  for (let i = 0; i < records.length; i += chunkSize) {
    chunks.push(records.slice(i, i + chunkSize));
  }

  let success = 0;
  let failed = 0;
  const errors: any[] = [];

  // Insert chunks
  for (const chunk of chunks) {
    try {
      let query = supabase.from(table).insert(chunk);

      if (options?.onConflict) {
        query = query as any; // Type fix for onConflict
      }

      const { error, count } = await query;

      if (error) {
        failed += chunk.length;
        errors.push({ chunk, error });
        logger.error(
          { table, count: chunk.length, error },
          'Batch insert failed'
        );
      } else {
        success += chunk.length;
        logger.debug({ table, count: chunk.length }, 'Batch insert success');
      }
    } catch (err) {
      failed += chunk.length;
      errors.push({ chunk, error: err });
      logger.error(
        { table, count: chunk.length, err },
        'Batch insert exception'
      );
    }
  }

  return { success, failed, errors };
};

// ═══════════════════════════════════════════════════════════════════════════
// Export default as admin client
// ═══════════════════════════════════════════════════════════════════════════

export default getSupabaseAdmin;

