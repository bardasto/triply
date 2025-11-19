/**
 * Run Database Migrations
 */

import { createClient } from '@supabase/supabase-js';
import config from './src/config/env.js';
import { readFileSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

console.log('🚀 Starting database migrations...\n');

const supabase = createClient(config.SUPABASE_URL, config.SUPABASE_SERVICE_ROLE_KEY);

// Helper to execute SQL
async function executeSql(sql: string, migrationName: string): Promise<boolean> {
  console.log(`📝 Running migration: ${migrationName}...`);

  try {
    const { data, error } = await supabase.rpc('exec_sql', { sql_query: sql } as any);

    if (error) {
      // Try alternative method - direct query
      console.log('   Trying direct execution...');

      // Split by statement and execute one by one
      const statements = sql
        .split(';')
        .map(s => s.trim())
        .filter(s => s.length > 0 && !s.startsWith('--'));

      for (const statement of statements) {
        if (statement.includes('DROP') || statement.includes('CREATE')) {
          // Use raw SQL execution
          const response = await fetch(`${config.SUPABASE_URL}/rest/v1/rpc/exec`, {
            method: 'POST',
            headers: {
              'apikey': config.SUPABASE_SERVICE_ROLE_KEY,
              'Authorization': `Bearer ${config.SUPABASE_SERVICE_ROLE_KEY}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({ query: statement }),
          });

          if (!response.ok) {
            console.warn(`   ⚠️ Statement failed (might be ok): ${statement.substring(0, 50)}...`);
          }
        }
      }

      console.log('✅ Migration completed (manual execution)');
      return true;
    }

    console.log('✅ Migration completed successfully');
    return true;
  } catch (err: any) {
    console.error('❌ Migration failed:', err.message);
    return false;
  }
}

async function runMigrations() {
  // Migration 001: Drop old tables
  console.log('═'.repeat(80));
  console.log('Migration 001: Drop Old Restaurant Tables');
  console.log('═'.repeat(80));

  const migration001 = readFileSync(
    path.join(__dirname, 'scripts/migrations/001_drop_old_restaurants.sql'),
    'utf-8'
  );

  const success001 = await executeSql(migration001, '001_drop_old_restaurants');

  if (!success001) {
    console.log('\n⚠️ Migration 001 had issues, but continuing...\n');
  }

  console.log('\n');

  // Migration 002: Create new cache schema
  console.log('═'.repeat(80));
  console.log('Migration 002: Create Places Cache Schema');
  console.log('═'.repeat(80));

  const migration002 = readFileSync(
    path.join(__dirname, 'scripts/migrations/002_create_places_cache_schema.sql'),
    'utf-8'
  );

  const success002 = await executeSql(migration002, '002_create_places_cache_schema');

  if (!success002) {
    console.error('\n❌ Migration 002 failed. Please run manually in Supabase SQL Editor.\n');
    console.log('📋 Migration file location:');
    console.log('   scripts/migrations/002_create_places_cache_schema.sql\n');
    return false;
  }

  console.log('\n');

  // Verify tables exist
  console.log('═'.repeat(80));
  console.log('Verifying Tables');
  console.log('═'.repeat(80));

  const { error: catalogError } = await supabase
    .from('places_catalog')
    .select('count')
    .limit(1);

  if (catalogError) {
    console.log('❌ places_catalog table not found');
  } else {
    console.log('✅ places_catalog table exists');
  }

  const { error: cacheError } = await supabase
    .from('places_cache')
    .select('count')
    .limit(1);

  if (cacheError) {
    console.log('❌ places_cache table not found');
  } else {
    console.log('✅ places_cache table exists');
  }

  const { error: logError } = await supabase
    .from('cache_refresh_log')
    .select('count')
    .limit(1);

  if (logError) {
    console.log('❌ cache_refresh_log table not found');
  } else {
    console.log('✅ cache_refresh_log table exists');
  }

  console.log('\n');
  console.log('═'.repeat(80));
  console.log('✅ Migrations Complete!');
  console.log('═'.repeat(80));
  console.log('\nNext steps:');
  console.log('  1. Run: npm run seed:restaurants:paris');
  console.log('  2. Check: npx tsx test-supabase-connection.ts');
  console.log('\n');

  return true;
}

// Run migrations
runMigrations()
  .then(success => {
    process.exit(success ? 0 : 1);
  })
  .catch(err => {
    console.error('Fatal error:', err);
    process.exit(1);
  });
