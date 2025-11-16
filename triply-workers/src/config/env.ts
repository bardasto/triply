

import dotenv from 'dotenv';
import { z } from 'zod';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Загрузить .env файл
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

// ═══════════════════════════════════════════════════════════════════════════
// Zod Schema для валидации
// ═══════════════════════════════════════════════════════════════════════════

const envSchema = z.object({
  // Supabase
  SUPABASE_URL: z.string().url(),
  SUPABASE_ANON_KEY: z.string().min(1),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),

  // OpenAI
  OPENAI_API_KEY: z.string().startsWith('sk-'),
  OPENAI_MODEL: z.string().default('gpt-4-turbo-preview'),
  OPENAI_MAX_TOKENS: z.coerce.number().default(2000),
  OPENAI_TEMPERATURE: z.coerce.number().default(0.7),

  // Google APIs
  GOOGLE_PLACES_API_KEY: z.string().min(1),
  GOOGLE_MAPS_API_KEY: z.string().min(1),

  // Image APIs
  UNSPLASH_ACCESS_KEY: z.string().min(1),
  PEXELS_API_KEY: z.string().min(1),

  // TripAdvisor (optional)
  TRIPADVISOR_API_KEY: z.string().optional(),
  TRIPADVISOR_ENABLED: z
    .string()
    .transform(v => v === 'true')
    .default('false'),

  // Redis
  REDIS_HOST: z.string().default('localhost'),
  REDIS_PORT: z.coerce.number().default(6379),
  REDIS_PASSWORD: z.string().optional(),
  REDIS_DB: z.coerce.number().default(0),
  REDIS_TLS_ENABLED: z
    .string()
    .transform(v => v === 'true')
    .default('false'),

  // Worker Config
  NODE_ENV: z
    .enum(['development', 'production', 'test'])
    .default('development'),
  LOG_LEVEL: z
    .enum(['trace', 'debug', 'info', 'warn', 'error', 'fatal'])
    .default('info'),
  PORT: z.coerce.number().default(3000),

  // Batch Processing
  BATCH_SIZE: z.coerce.number().default(200),
  MAX_CONCURRENT_JOBS: z.coerce.number().default(5),
  JOB_TIMEOUT_MS: z.coerce.number().default(300000),

  // Cities
  CITIES_SEED_BATCH_SIZE: z.coerce.number().default(50),
  MIN_CITY_POPULATION: z.coerce.number().default(100000),
  MIN_CITY_POPULARITY: z.coerce.number().default(0.3),

  // POIs
  POIS_PER_CITY: z.coerce.number().default(50),
  POIS_SEARCH_RADIUS_METERS: z.coerce.number().default(50000),

  // Trip Generation
  TRIPS_PER_CITY: z.coerce.number().default(10),
  TRIP_MIN_DAYS: z.coerce.number().default(2),
  TRIP_MAX_DAYS: z.coerce.number().default(7),

  // Rate Limits
  RATE_LIMIT_OPENAI: z.coerce.number().default(3500),
  RATE_LIMIT_GOOGLE_PLACES: z.coerce.number().default(1000),
  RATE_LIMIT_UNSPLASH: z.coerce.number().default(50),
  RATE_LIMIT_PEXELS: z.coerce.number().default(200),

  // Retry Config
  MAX_RETRIES: z.coerce.number().default(3),
  RETRY_DELAY_MS: z.coerce.number().default(1000),
  RETRY_BACKOFF_MULTIPLIER: z.coerce.number().default(2),

  // Circuit Breaker
  CIRCUIT_BREAKER_THRESHOLD: z.coerce.number().default(5),
  CIRCUIT_BREAKER_TIMEOUT_MS: z.coerce.number().default(60000),

  // Monitoring
  ENABLE_METRICS: z
    .string()
    .transform(v => v === 'true')
    .default('true'),
  METRICS_PORT: z.coerce.number().default(9090),
  LOG_FILE_PATH: z.string().default('./logs/worker.log'),
  LOG_MAX_FILES: z.coerce.number().default(7),
  LOG_MAX_SIZE: z.string().default('10m'),

  // Sentry (optional)
  SENTRY_DSN: z.string().optional(),
  SENTRY_ENVIRONMENT: z.string().default('development'),

  // Geographical
  ENABLED_CONTINENTS: z
    .string()
    .default('Europe,Asia,North America,South America,Africa,Oceania'),
  PRIORITY_COUNTRIES: z
    .string()
    .default('US,FR,GB,ES,IT,DE,JP,CN,AU,BR,MX,CA,TH,TR,GR'),

  // Activities
  SUPPORTED_ACTIVITIES: z
    .string()
    .default(
      'sightseeing,cultural,adventure,beach,food,shopping,nightlife,nature,relaxation,family'
    ),

  // Cache TTL
  CACHE_TTL_CITIES_HOURS: z.coerce.number().default(168),
  CACHE_TTL_POIS_HOURS: z.coerce.number().default(72),
  CACHE_TTL_WEATHER_HOURS: z.coerce.number().default(6),
  CACHE_TTL_PLACES_STATUS_HOURS: z.coerce.number().default(24),
  CACHE_TTL_IMAGES_HOURS: z.coerce.number().default(720),

  // Security
  ENABLE_CORS: z
    .string()
    .transform(v => v === 'true')
    .default('true'),
  ALLOWED_ORIGINS: z.string().optional(),
  INTERNAL_API_KEY: z.string().min(1),

  // Debug
  DEBUG_MODE: z
    .string()
    .transform(v => v === 'true')
    .default('false'),
  DRY_RUN: z
    .string()
    .transform(v => v === 'true')
    .default('false'),
  SKIP_RATE_LIMITS: z
    .string()
    .transform(v => v === 'true')
    .default('false'),

  // Test Mode
  TEST_MODE: z
    .string()
    .transform(v => v === 'true')
    .default('false'),
  TEST_BATCH_SIZE: z.coerce.number().default(5),
  TEST_CITIES_LIMIT: z.coerce.number().default(10),
});

// ═══════════════════════════════════════════════════════════════════════════
// Parse и валидация
// ═══════════════════════════════════════════════════════════════════════════

export type Env = z.infer<typeof envSchema>;

let env: Env;

try {
  env = envSchema.parse(process.env);
} catch (error) {
  console.error('❌ Invalid environment variables:');
  if (error instanceof z.ZodError) {
    error.errors.forEach(err => {
      console.error(`  - ${err.path.join('.')}: ${err.message}`);
    });
  }
  process.exit(1);
}

// ═══════════════════════════════════════════════════════════════════════════
// Helper Functions
// ═══════════════════════════════════════════════════════════════════════════

export const config = {
  ...env,

  // Parsed arrays
  enabledContinents: env.ENABLED_CONTINENTS.split(',').map(c => c.trim()),
  priorityCountries: env.PRIORITY_COUNTRIES.split(',').map(c => c.trim()),
  supportedActivities: env.SUPPORTED_ACTIVITIES.split(',').map(a => a.trim()),
  allowedOrigins: env.ALLOWED_ORIGINS?.split(',').map(o => o.trim()) || [],

  // Computed values
  isProd: env.NODE_ENV === 'production',
  isDev: env.NODE_ENV === 'development',
  isTest: env.NODE_ENV === 'test',

  // Redis URL
  redisUrl: `redis://${env.REDIS_PASSWORD ? `:${env.REDIS_PASSWORD}@` : ''}${
    env.REDIS_HOST
  }:${env.REDIS_PORT}/${env.REDIS_DB}`,
};

// ═══════════════════════════════════════════════════════════════════════════
// Export
// ═══════════════════════════════════════════════════════════════════════════

export default config;

// Validate на старте
if (config.isDev) {
  console.log('✅ Environment variables loaded successfully');
  console.log(`📍 Mode: ${config.NODE_ENV}`);
  console.log(`📍 Supabase: ${config.SUPABASE_URL}`);
  console.log(`📍 Redis: ${config.REDIS_HOST}:${config.REDIS_PORT}`);
}

