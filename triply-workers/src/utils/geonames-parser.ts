
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * GeoNames Parser
 * Парсинг TSV файлов GeoNames в TypeScript объекты
 * ═══════════════════════════════════════════════════════════════════════════
 */

import fs from 'fs';
import readline from 'readline';
import path from 'path';
import logger from './logger.js';
import type { CityInput, Continent, ActivityType } from '../models/index.js';

// ═══════════════════════════════════════════════════════════════════════════
// GeoNames Raw Record Interface
// ═══════════════════════════════════════════════════════════════════════════

interface GeoNamesRecord {
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
  elevation: string;
  dem: string;
  timezone: string;
  modification_date: string;
}

// ═══════════════════════════════════════════════════════════════════════════
// Country Info Mapping
// ═══════════════════════════════════════════════════════════════════════════

const COUNTRY_TO_CONTINENT: Record<string, Continent> = {
  // Europe
  GB: 'Europe',
  FR: 'Europe',
  DE: 'Europe',
  IT: 'Europe',
  ES: 'Europe',
  PT: 'Europe',
  NL: 'Europe',
  BE: 'Europe',
  CH: 'Europe',
  AT: 'Europe',
  SE: 'Europe',
  NO: 'Europe',
  DK: 'Europe',
  FI: 'Europe',
  IS: 'Europe',
  IE: 'Europe',
  PL: 'Europe',
  CZ: 'Europe',
  HU: 'Europe',
  RO: 'Europe',
  GR: 'Europe',
  BG: 'Europe',
  HR: 'Europe',
  RS: 'Europe',
  UA: 'Europe',
  RU: 'Europe',
  TR: 'Europe',
  SK: 'Europe',
  SI: 'Europe',
  LT: 'Europe',

  // Asia
  CN: 'Asia',
  JP: 'Asia',
  KR: 'Asia',
  IN: 'Asia',
  ID: 'Asia',
  TH: 'Asia',
  VN: 'Asia',
  MY: 'Asia',
  SG: 'Asia',
  PH: 'Asia',
  PK: 'Asia',
  BD: 'Asia',
  MM: 'Asia',
  KH: 'Asia',
  LA: 'Asia',
  AE: 'Asia',
  SA: 'Asia',
  IL: 'Asia',
  IQ: 'Asia',
  IR: 'Asia',

  // North America
  US: 'North America',
  CA: 'North America',
  MX: 'North America',
  CU: 'North America',
  JM: 'North America',
  CR: 'North America',
  PA: 'North America',
  GT: 'North America',

  // South America
  BR: 'South America',
  AR: 'South America',
  CL: 'South America',
  CO: 'South America',
  PE: 'South America',
  VE: 'South America',
  EC: 'South America',
  BO: 'South America',
  UY: 'South America',

  // Africa
  EG: 'Africa',
  ZA: 'Africa',
  KE: 'Africa',
  MA: 'Africa',
  TN: 'Africa',
  NG: 'Africa',
  GH: 'Africa',
  ET: 'Africa',
  TZ: 'Africa',
  DZ: 'Africa',

  // Oceania
  AU: 'Oceania',
  NZ: 'Oceania',
  FJ: 'Oceania',
  PG: 'Oceania',
};

const COUNTRY_NAMES: Record<string, string> = {
  US: 'United States',
  GB: 'United Kingdom',
  FR: 'France',
  DE: 'Germany',
  IT: 'Italy',
  ES: 'Spain',
  JP: 'Japan',
  CN: 'China',
  IN: 'India',
  BR: 'Brazil',
  AU: 'Australia',
  CA: 'Canada',
  MX: 'Mexico',
  RU: 'Russia',
  TR: 'Turkey',
  TH: 'Thailand',
  GR: 'Greece',
  PT: 'Portugal',
  NL: 'Netherlands',
  AT: 'Austria',
  CH: 'Switzerland',
  SE: 'Sweden',
  NO: 'Norway',
  DK: 'Denmark',
  FI: 'Finland',
  PL: 'Poland',
  CZ: 'Czechia',
  // Add more as needed
};

// ═══════════════════════════════════════════════════════════════════════════
// Default Activity Mapping based on city characteristics
// ═══════════════════════════════════════════════════════════════════════════

function inferActivities(record: GeoNamesRecord): ActivityType[] {
  const activities: ActivityType[] = ['sightseeing', 'cultural'];

  // Large cities get more activities
  if (record.population > 1000000) {
    activities.push('shopping', 'nightlife', 'food');
  }

  // Coastal cities
  if (record.feature_code === 'PPLA' || record.feature_code === 'PPLC') {
    activities.push('food', 'shopping');
  }

  return activities;
}

// ═══════════════════════════════════════════════════════════════════════════
// Calculate Popularity Score
// ═══════════════════════════════════════════════════════════════════════════

function calculatePopularityScore(record: GeoNamesRecord): number {
  let score = 0.5; // Base score

  // Population factor (0-0.3)
  if (record.population > 5000000) score += 0.3;
  else if (record.population > 1000000) score += 0.25;
  else if (record.population > 500000) score += 0.2;
  else if (record.population > 100000) score += 0.15;

  // Capital city bonus
  if (record.feature_code === 'PPLC') score += 0.2;

  // Cap at 1.0
  return Math.min(score, 1.0);
}

// ═══════════════════════════════════════════════════════════════════════════
// Parse TSV Line
// ═══════════════════════════════════════════════════════════════════════════

function parseTSVLine(line: string): GeoNamesRecord | null {
  const parts = line.split('\t');

  if (parts.length < 19) {
    return null;
  }

  try {
    return {
      geonameid: parts[0],
      name: parts[1],
      asciiname: parts[2],
      alternatenames: parts[3],
      latitude: parseFloat(parts[4]),
      longitude: parseFloat(parts[5]),
      feature_class: parts[6],
      feature_code: parts[7],
      country_code: parts[8],
      cc2: parts[9],
      admin1_code: parts[10],
      admin2_code: parts[11],
      admin3_code: parts[12],
      admin4_code: parts[13],
      population: parseInt(parts[14]) || 0,
      elevation: parts[15],
      dem: parts[16],
      timezone: parts[17],
      modification_date: parts[18],
    };
  } catch (error) {
    logger.warn(`Failed to parse line: ${line.substring(0, 100)}`);
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Convert to CityInput
// ═══════════════════════════════════════════════════════════════════════════

function toCityInput(record: GeoNamesRecord): CityInput | null {
  const continent = COUNTRY_TO_CONTINENT[record.country_code];

  if (!continent) {
    return null; // Skip countries not in our continent map
  }

  const country = COUNTRY_NAMES[record.country_code] || record.country_code;

  return {
    name: record.name,
    country,
    country_code: record.country_code,
    continent,
    latitude: record.latitude,
    longitude: record.longitude,
    timezone: record.timezone || undefined,
    population: record.population > 0 ? record.population : undefined,
    popularity_score: calculatePopularityScore(record),
    supported_activities: inferActivities(record),
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Parse GeoNames File (Streaming)
// ═══════════════════════════════════════════════════════════════════════════

export async function parseGeoNamesFile(
  filePath: string,
  options?: {
    minPopulation?: number;
    countries?: string[];
    limit?: number;
    onProgress?: (count: number) => void;
  }
): Promise<CityInput[]> {
  const cities: CityInput[] = [];
  const minPop = options?.minPopulation || 0;
  const countries = options?.countries ? new Set(options.countries) : null;
  const limit = options?.limit || Infinity;

  logger.info(`Parsing GeoNames file: ${filePath}`);
  logger.info(
    `Filters: minPopulation=${minPop}, countries=${
      countries?.size || 'all'
    }, limit=${limit}`
  );

  const fileStream = fs.createReadStream(filePath);
  const rl = readline.createInterface({
    input: fileStream,
    crlfDelay: Infinity,
  });

  let lineCount = 0;
  let parsedCount = 0;

  for await (const line of rl) {
    lineCount++;

    if (cities.length >= limit) {
      break;
    }

    const record = parseTSVLine(line);
    if (!record) continue;

    // Apply filters
    if (record.population < minPop) continue;
    if (countries && !countries.has(record.country_code)) continue;

    const city = toCityInput(record);
    if (city) {
      cities.push(city);
      parsedCount++;

      if (options?.onProgress && parsedCount % 1000 === 0) {
        options.onProgress(parsedCount);
      }
    }
  }

  logger.info(`Parsed ${parsedCount} cities from ${lineCount} lines`);

  return cities;
}

// ═══════════════════════════════════════════════════════════════════════════
// Get Priority Cities (Top destinations)
// ═══════════════════════════════════════════════════════════════════════════

export async function getPriorityCities(
  filePath: string
): Promise<CityInput[]> {
  const PRIORITY_COUNTRIES = [
    'US',
    'FR',
    'GB',
    'ES',
    'IT',
    'DE',
    'JP',
    'CN',
    'AU',
    'BR',
    'MX',
    'CA',
    'TH',
    'TR',
    'GR',
    'PT',
    'NL',
    'AT',
    'CH',
    'AE',
  ];

  return parseGeoNamesFile(filePath, {
    minPopulation: 100000,
    countries: PRIORITY_COUNTRIES,
    onProgress: count => {
      logger.info(`Priority cities parsed: ${count}`);
    },
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Export
// ═══════════════════════════════════════════════════════════════════════════

export default {
  parseGeoNamesFile,
  getPriorityCities,
  toCityInput,
};

