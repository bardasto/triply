/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Import Cities from GeoNames TSV
 * Парсинг cities15000.txt и загрузка в Supabase
 * ═══════════════════════════════════════════════════════════════════════════
 */

import fs from 'fs';
import readline from 'readline';
import path from 'path';
import { fileURLToPath } from 'url';
import getSupabaseAdmin, { batchInsert } from '../config/supabase.js';
import logger from '../utils/logger.js';
import config from '../config/env.js';
import type { City, Continent, ActivityType, CityInput } from '../models/index.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ═══════════════════════════════════════════════════════════════════════════
// GeoNames TSV Row Interface
// ═══════════════════════════════════════════════════════════════════════════

interface GeoNamesRow {
  geonameid: string;
  name: string;
  asciiname: string;
  alternatenames: string;
  latitude: number;
  longitude: number;
  feature_class: string;
  feature_code: string;
  country_code: string;
  cc2: string;
  admin1_code: string;
  admin2_code: string;
  admin3_code: string;
  admin4_code: string;
  population: number;
  elevation: number;
  dem: number;
  timezone: string;
  modification_date: string;
}

// ═══════════════════════════════════════════════════════════════════════════
// Country → Continent Mapping
// ═══════════════════════════════════════════════════════════════════════════

const COUNTRY_TO_CONTINENT: Record<string, Continent> = {
  // Europe
  GB: 'Europe', FR: 'Europe', DE: 'Europe', IT: 'Europe', ES: 'Europe',
  NL: 'Europe', BE: 'Europe', CH: 'Europe', AT: 'Europe', SE: 'Europe',
  NO: 'Europe', DK: 'Europe', FI: 'Europe', PL: 'Europe', CZ: 'Europe',
  GR: 'Europe', PT: 'Europe', IE: 'Europe', RO: 'Europe', HU: 'Europe',
  BG: 'Europe', HR: 'Europe', SK: 'Europe', SI: 'Europe', LT: 'Europe',
  LV: 'Europe', EE: 'Europe', RS: 'Europe', UA: 'Europe', BY: 'Europe',
  AL: 'Europe', BA: 'Europe', MK: 'Europe', ME: 'Europe', MD: 'Europe',
  IS: 'Europe', LU: 'Europe', MT: 'Europe', CY: 'Europe', LI: 'Europe',
  MC: 'Europe', AD: 'Europe', SM: 'Europe', VA: 'Europe',
  
  // Asia
  CN: 'Asia', JP: 'Asia', IN: 'Asia', TH: 'Asia', VN: 'Asia',
  ID: 'Asia', MY: 'Asia', SG: 'Asia', PH: 'Asia', KR: 'Asia',
  TR: 'Asia', SA: 'Asia', AE: 'Asia', IL: 'Asia', JO: 'Asia',
  LB: 'Asia', IQ: 'Asia', IR: 'Asia', AF: 'Asia', PK: 'Asia',
  BD: 'Asia', NP: 'Asia', LK: 'Asia', MM: 'Asia', KH: 'Asia',
  LA: 'Asia', MN: 'Asia', KZ: 'Asia', UZ: 'Asia', TM: 'Asia',
  KG: 'Asia', TJ: 'Asia', AM: 'Asia', AZ: 'Asia', GE: 'Asia',
  SY: 'Asia', YE: 'Asia', OM: 'Asia', KW: 'Asia', QA: 'Asia',
  BH: 'Asia', BN: 'Asia', MV: 'Asia', BT: 'Asia', TL: 'Asia',
  
  // North America
  US: 'North America', CA: 'North America', MX: 'North America',
  GT: 'North America', CU: 'North America', DO: 'North America',
  HN: 'North America', SV: 'North America', NI: 'North America',
  CR: 'North America', PA: 'North America', JM: 'North America',
  HT: 'North America', BS: 'North America', BZ: 'North America',
  TT: 'North America', BB: 'North America', LC: 'North America',
  
  // South America
  BR: 'South America', AR: 'South America', CL: 'South America',
  CO: 'South America', PE: 'South America', VE: 'South America',
  EC: 'South America', BO: 'South America', PY: 'South America',
  UY: 'South America', GY: 'South America', SR: 'South America',
  GF: 'South America',
  
  // Africa
  ZA: 'Africa', EG: 'Africa', MA: 'Africa', TN: 'Africa', KE: 'Africa',
  GH: 'Africa', NG: 'Africa', ET: 'Africa', TZ: 'Africa', UG: 'Africa',
  DZ: 'Africa', SD: 'Africa', AO: 'Africa', MZ: 'Africa', CM: 'Africa',
  CI: 'Africa', NE: 'Africa', ML: 'Africa', BF: 'Africa', MW: 'Africa',
  ZM: 'Africa', SN: 'Africa', SO: 'Africa', TD: 'Africa', GN: 'Africa',
  RW: 'Africa', BJ: 'Africa', TG: 'Africa', LY: 'Africa', LR: 'Africa',
  MU: 'Africa', NA: 'Africa', BW: 'Africa', LS: 'Africa', SZ: 'Africa',
  
  // Oceania
  AU: 'Oceania', NZ: 'Oceania', PG: 'Oceania', FJ: 'Oceania',
  SB: 'Oceania', VU: 'Oceania', NC: 'Oceania', PF: 'Oceania',
  WS: 'Oceania', GU: 'Oceania', KI: 'Oceania', FM: 'Oceania',
  TO: 'Oceania', PW: 'Oceania', MH: 'Oceania', NR: 'Oceania',
  
  // Russia (spans both continents, но ставим Европу для удобства)
  RU: 'Europe',
};

// ═══════════════════════════════════════════════════════════════════════════
// Priority Countries (для туристических приложений)
// ═══════════════════════════════════════════════════════════════════════════

const PRIORITY_COUNTRIES = new Set([
  'US', 'FR', 'GB', 'ES', 'IT', 'DE', 'JP', 'CN', 'AU', 'BR',
  'MX', 'CA', 'TH', 'TR', 'GR', 'NL', 'PT', 'AT', 'CH', 'AE',
  'IN', 'SG', 'MY', 'VN', 'ID', 'PH', 'ZA', 'EG', 'MA', 'AR',
]);

// ═══════════════════════════════════════════════════════════════════════════
// Main Import Function
// ═══════════════════════════════════════════════════════════════════════════

export async function importGeoNamesCities(options?: {
  filePath?: string;
  minPopulation?: number;
  countries?: string[];
  batchSize?: number;
  dryRun?: boolean;
}) {
  const startTime = Date.now();
  
  const filePath = options?.filePath || path.resolve(__dirname, '../../data/seeds/cities15000.txt');
  const minPopulation = options?.minPopulation || config.MIN_CITY_POPULATION;
  const batchSize = options?.batchSize || config.BATCH_SIZE;
  const dryRun = options?.dryRun || false;
  const filterCountries = options?.countries ? new Set(options.countries) : null;

  logger.info('🏙️  Starting GeoNames cities import...', {
    filePath,
    minPopulation,
    batchSize,
    dryRun,
  });

  // Check file exists
  if (!fs.existsSync(filePath)) {
    throw new Error(`File not found: ${filePath}`);
  }

  const fileStream = fs.createReadStream(filePath);
  const rl = readline.createInterface({
    input: fileStream,
    crlfDelay: Infinity,
  });

  let totalLines = 0;
  let filteredCities = 0;
  let batch: CityInput[] = [];
  let insertedCount = 0;
  let errorCount = 0;

  for await (const line of rl) {
    totalLines++;

    try {
      const city = parseTSVLine(line);

      // Apply filters
      if (!shouldIncludeCity(city, minPopulation, filterCountries)) {
        continue;
      }

      const cityInput = mapToCityInput(city);
      batch.push(cityInput);
      filteredCities++;

      // Batch insert
      if (batch.length >= batchSize) {
        if (!dryRun) {
          const result = await insertCitiesBatch(batch);
          insertedCount += result.success;
          errorCount += result.failed;
        }
        
        logger.info(`📦 Processed ${filteredCities} cities (${insertedCount} inserted, ${errorCount} errors)`);
        batch = [];
      }
    } catch (error) {
      logger.error(`Failed to parse line ${totalLines}:`, error);
      errorCount++;
    }
  }

  // Insert remaining batch
  if (batch.length > 0 && !dryRun) {
    const result = await insertCitiesBatch(batch);
    insertedCount += result.success;
    errorCount += result.failed;
  }

  const duration = Date.now() - startTime;

  logger.info('✅ GeoNames import completed', {
    totalLines,
    filteredCities,
    insertedCount,
    errorCount,
    durationMs: duration,
  });

  return {
    totalLines,
    filteredCities,
    insertedCount,
    errorCount,
    duration,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Parse TSV Line
// ═══════════════════════════════════════════════════════════════════════════

function parseTSVLine(line: string): GeoNamesRow {
  const fields = line.split('\t');

  return {
    geonameid: fields[0],
    name: fields[1],
    asciiname: fields[2],
    alternatenames: fields[3] || '',
    latitude: parseFloat(fields[4]),
    longitude: parseFloat(fields[5]),
    feature_class: fields[6],
    feature_code: fields[7],
    country_code: fields[8],
    cc2: fields[9] || '',
    admin1_code: fields[10] || '',
    admin2_code: fields[11] || '',
    admin3_code: fields[12] || '',
    admin4_code: fields[13] || '',
    population: parseInt(fields[14]) || 0,
    elevation: parseInt(fields[15]) || 0,
    dem: parseInt(fields[16]) || 0,
    timezone: fields[17] || '',
    modification_date: fields[18] || '',
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Filters
// ═══════════════════════════════════════════════════════════════════════════

function shouldIncludeCity(
  city: GeoNamesRow,
  minPopulation: number,
  filterCountries: Set<string> | null
): boolean {
  // Population filter
  if (city.population < minPopulation) {
    return false;
  }

  // Country filter
  if (filterCountries && !filterCountries.has(city.country_code)) {
    return false;
  }

  // Feature code filter (only cities)
  if (!city.feature_code.startsWith('PPL')) {
    return false;
  }

  // Must have continent mapping
  if (!COUNTRY_TO_CONTINENT[city.country_code]) {
    return false;
  }

  return true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Map to CityInput
// ═══════════════════════════════════════════════════════════════════════════

function mapToCityInput(city: GeoNamesRow): CityInput {
  const continent = COUNTRY_TO_CONTINENT[city.country_code];
  const isPriority = PRIORITY_COUNTRIES.has(city.country_code);

  // Calculate popularity score (0-1)
  const popularityScore = calculatePopularityScore(city.population, isPriority);

  // Default supported activities
  const supportedActivities: ActivityType[] = [
    'sightseeing',
    'cultural',
    'food',
  ];

  return {
    name: city.name,
    country: getCountryName(city.country_code),
    country_code: city.country_code,
    continent,
    latitude: city.latitude,
    longitude: city.longitude,
    timezone: city.timezone,
    population: city.population,
    popularity_score: popularityScore,
    google_place_id: undefined,
    supported_activities: supportedActivities,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Calculate Popularity Score
// ═══════════════════════════════════════════════════════════════════════════

function calculatePopularityScore(population: number, isPriority: boolean): number {
  let score = 0.3; // Base score

  // Population bonus
  if (population > 5000000) score += 0.4;
  else if (population > 1000000) score += 0.3;
  else if (population > 500000) score += 0.2;
  else if (population > 100000) score += 0.1;

  // Priority country bonus
  if (isPriority) score += 0.2;

  return Math.min(score, 1.0);
}

// ═══════════════════════════════════════════════════════════════════════════
// Get Country Name (можно расширить через countryInfo.txt)
// ═══════════════════════════════════════════════════════════════════════════

const COUNTRY_NAMES: Record<string, string> = {
  US: 'United States', GB: 'United Kingdom', FR: 'France', DE: 'Germany',
  IT: 'Italy', ES: 'Spain', JP: 'Japan', CN: 'China', AU: 'Australia',
  BR: 'Brazil', MX: 'Mexico', CA: 'Canada', TH: 'Thailand', TR: 'Turkey',
  GR: 'Greece', NL: 'Netherlands', PT: 'Portugal', AT: 'Austria',
  CH: 'Switzerland', AE: 'United Arab Emirates', IN: 'India',
  SG: 'Singapore', MY: 'Malaysia', VN: 'Vietnam', ID: 'Indonesia',
  PH: 'Philippines', ZA: 'South Africa', EG: 'Egypt', MA: 'Morocco',
  AR: 'Argentina', CL: 'Chile', CO: 'Colombia', PE: 'Peru',
  // Добавь остальные по необходимости
};

function getCountryName(code: string): string {
  return COUNTRY_NAMES[code] || code;
}

// ═══════════════════════════════════════════════════════════════════════════
// Insert Batch
// ═══════════════════════════════════════════════════════════════════════════

async function insertCitiesBatch(cities: CityInput[]) {
  return batchInsert('cities', cities, {
    chunkSize: 100,
    onConflict: 'name,country_code',
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// CLI Execution
// ═══════════════════════════════════════════════════════════════════════════

if (import.meta.url === `file://${process.argv[1]}`) {
  importGeoNamesCities({
    minPopulation: 50000, // Только города > 50k населения
    dryRun: false,
  })
    .then((result) => {
      logger.info('Import finished', result);
      process.exit(0);
    })
    .catch((error) => {
      logger.error('Import failed', error);
      process.exit(1);
    });
}

export default importGeoNamesCities;

