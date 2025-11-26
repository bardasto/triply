/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Currency Converter Utility
 * Converts prices from various currencies to EUR using real-time exchange rates
 *
 * Uses Frankfurter API (European Central Bank data) - free, no API key needed
 * Rates are cached for 6 hours (ECB updates once daily around 16:00 CET)
 * ═══════════════════════════════════════════════════════════════════════════
 */

import logger from './logger.js';

// ═══════════════════════════════════════════════════════════════════════════
// Types
// ═══════════════════════════════════════════════════════════════════════════

interface ExchangeRatesCache {
  rates: { [currency: string]: number };
  lastUpdated: Date;
  base: string;
}

// ═══════════════════════════════════════════════════════════════════════════
// Cache Configuration
// ═══════════════════════════════════════════════════════════════════════════

const CACHE_TTL_MS = 6 * 60 * 60 * 1000; // 6 hours
const FRANKFURTER_API = 'https://api.frankfurter.app';

let ratesCache: ExchangeRatesCache | null = null;

// ═══════════════════════════════════════════════════════════════════════════
// Fallback Rates (used when API is unavailable)
// ═══════════════════════════════════════════════════════════════════════════

const FALLBACK_RATES_TO_EUR: { [currency: string]: number } = {
  USD: 0.92, GBP: 1.17, JPY: 0.0061, CNY: 0.13, CHF: 1.05,
  AUD: 0.60, CAD: 0.68, NZD: 0.56, SEK: 0.087, NOK: 0.086,
  DKK: 0.134, PLN: 0.23, CZK: 0.040, HUF: 0.0026, RON: 0.20,
  BGN: 0.51, HRK: 0.13, TRY: 0.029, ISK: 0.0067, KRW: 0.00069,
  HKD: 0.12, SGD: 0.69, TWD: 0.029, THB: 0.026, MYR: 0.20,
  IDR: 0.000059, PHP: 0.016, VND: 0.000038, INR: 0.011,
  AED: 0.25, SAR: 0.24, ILS: 0.25, EGP: 0.019, ZAR: 0.050,
  MAD: 0.092, MXN: 0.054, BRL: 0.18, ARS: 0.0011, CLP: 0.0010,
  COP: 0.00023, PEN: 0.25, RUB: 0.010, UAH: 0.025,
  EUR: 1.0,
};

// ═══════════════════════════════════════════════════════════════════════════
// Country to Currency Mapping
// ═══════════════════════════════════════════════════════════════════════════

const COUNTRY_CURRENCIES: { [country: string]: string } = {
  // Europe - EUR
  'France': 'EUR', 'Germany': 'EUR', 'Italy': 'EUR', 'Spain': 'EUR',
  'Portugal': 'EUR', 'Netherlands': 'EUR', 'Belgium': 'EUR', 'Austria': 'EUR',
  'Greece': 'EUR', 'Ireland': 'EUR', 'Finland': 'EUR', 'Estonia': 'EUR',
  'Latvia': 'EUR', 'Lithuania': 'EUR', 'Slovakia': 'EUR', 'Slovenia': 'EUR',
  'Malta': 'EUR', 'Cyprus': 'EUR', 'Luxembourg': 'EUR', 'Croatia': 'EUR',
  // Europe - Other
  'United Kingdom': 'GBP', 'UK': 'GBP', 'England': 'GBP', 'Scotland': 'GBP',
  'Switzerland': 'CHF', 'Sweden': 'SEK', 'Norway': 'NOK', 'Denmark': 'DKK',
  'Poland': 'PLN', 'Czech Republic': 'CZK', 'Czechia': 'CZK', 'Hungary': 'HUF',
  'Romania': 'RON', 'Bulgaria': 'BGN', 'Turkey': 'TRY', 'Iceland': 'ISK',
  'Ukraine': 'UAH', 'Russia': 'RUB',
  // Asia
  'Japan': 'JPY', 'China': 'CNY', 'South Korea': 'KRW', 'Korea': 'KRW',
  'Hong Kong': 'HKD', 'Taiwan': 'TWD', 'Singapore': 'SGD', 'Thailand': 'THB',
  'Malaysia': 'MYR', 'Indonesia': 'IDR', 'Philippines': 'PHP', 'Vietnam': 'VND',
  'India': 'INR',
  // Middle East
  'United Arab Emirates': 'AED', 'UAE': 'AED', 'Dubai': 'AED',
  'Saudi Arabia': 'SAR', 'Israel': 'ILS', 'Egypt': 'EGP',
  // Africa
  'South Africa': 'ZAR', 'Morocco': 'MAD',
  // Americas
  'United States': 'USD', 'USA': 'USD', 'US': 'USD', 'Canada': 'CAD',
  'Mexico': 'MXN', 'Brazil': 'BRL', 'Argentina': 'ARS', 'Chile': 'CLP',
  'Colombia': 'COP', 'Peru': 'PEN',
  // Oceania
  'Australia': 'AUD', 'New Zealand': 'NZD',
};

// ═══════════════════════════════════════════════════════════════════════════
// API Functions
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Fetch latest exchange rates from Frankfurter API (ECB data)
 */
async function fetchExchangeRates(): Promise<{ [currency: string]: number } | null> {
  try {
    // Frankfurter returns rates with EUR as base by default
    const response = await fetch(`${FRANKFURTER_API}/latest`);

    if (!response.ok) {
      throw new Error(`API returned ${response.status}`);
    }

    const data = await response.json() as { rates: { [currency: string]: number } };

    // API returns rates FROM EUR, we need rates TO EUR
    // So we invert: if 1 EUR = 1.08 USD, then 1 USD = 1/1.08 EUR
    const ratesToEUR: { [currency: string]: number } = { EUR: 1 };

    for (const [currency, rate] of Object.entries(data.rates)) {
      ratesToEUR[currency] = 1 / (rate as number);
    }

    logger.info(`✅ Fetched ${Object.keys(ratesToEUR).length} exchange rates from ECB`);
    return ratesToEUR;
  } catch (error) {
    logger.warn(`⚠️ Failed to fetch exchange rates: ${error}`);
    return null;
  }
}

/**
 * Get exchange rates (from cache or API)
 */
async function getExchangeRates(): Promise<{ [currency: string]: number }> {
  const now = new Date();

  // Check if cache is valid
  if (ratesCache && (now.getTime() - ratesCache.lastUpdated.getTime()) < CACHE_TTL_MS) {
    return ratesCache.rates;
  }

  // Fetch fresh rates
  const freshRates = await fetchExchangeRates();

  if (freshRates) {
    // Update cache
    ratesCache = {
      rates: freshRates,
      lastUpdated: now,
      base: 'EUR',
    };
    return freshRates;
  }

  // If API failed but we have old cache, use it
  if (ratesCache) {
    logger.warn('⚠️ Using stale exchange rates from cache');
    return ratesCache.rates;
  }

  // Last resort: fallback to hardcoded rates
  logger.warn('⚠️ Using fallback hardcoded exchange rates');
  return FALLBACK_RATES_TO_EUR;
}

/**
 * Get exchange rates synchronously (uses cache or fallback)
 * For use when async is not possible
 */
function getExchangeRatesSync(): { [currency: string]: number } {
  if (ratesCache) {
    return ratesCache.rates;
  }
  return FALLBACK_RATES_TO_EUR;
}

// ═══════════════════════════════════════════════════════════════════════════
// Conversion Functions
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Get currency code for a country
 */
export function getCurrencyForCountry(country: string): string {
  if (!country) return 'EUR';

  // Try exact match
  if (COUNTRY_CURRENCIES[country]) {
    return COUNTRY_CURRENCIES[country];
  }

  // Try case-insensitive
  const normalized = country.toLowerCase();
  for (const [key, value] of Object.entries(COUNTRY_CURRENCIES)) {
    if (key.toLowerCase() === normalized) {
      return value;
    }
  }

  return 'EUR';
}

/**
 * Convert amount from currency to EUR (async - fetches fresh rates if needed)
 */
export async function convertToEUR(amount: number, fromCurrency: string): Promise<number> {
  if (!amount || fromCurrency === 'EUR') return amount;

  const rates = await getExchangeRates();
  const rate = rates[fromCurrency.toUpperCase()];

  if (!rate) {
    logger.warn(`⚠️ Unknown currency: ${fromCurrency}, returning original amount`);
    return amount;
  }

  return Math.round(amount * rate * 100) / 100;
}

/**
 * Convert amount from currency to EUR (sync - uses cache/fallback)
 */
export function convertToEURSync(amount: number, fromCurrency: string): number {
  if (!amount || fromCurrency === 'EUR') return amount;

  const rates = getExchangeRatesSync();
  const rate = rates[fromCurrency.toUpperCase()];

  if (!rate) return amount;

  return Math.round(amount * rate * 100) / 100;
}

/**
 * Parse price string and extract value + currency
 */
export function parsePrice(priceStr: string): { value: number; currency: string } {
  if (!priceStr || typeof priceStr !== 'string') {
    return { value: 0, currency: 'EUR' };
  }

  const symbolMap: { [symbol: string]: string } = {
    '€': 'EUR', '$': 'USD', '£': 'GBP', '¥': 'JPY', '円': 'JPY',
    '元': 'CNY', '₹': 'INR', '₩': 'KRW', '฿': 'THB', '₫': 'VND',
    '₽': 'RUB', '₺': 'TRY', 'zł': 'PLN', 'Kč': 'CZK', 'R$': 'BRL',
  };

  let detectedCurrency = 'EUR';

  // Check currency codes
  const currencyCodes = ['USD', 'EUR', 'GBP', 'JPY', 'CNY', 'CHF', 'AUD', 'CAD', 'KRW', 'THB', 'SGD', 'HKD', 'MXN', 'BRL', 'INR'];
  for (const code of currencyCodes) {
    if (priceStr.toUpperCase().includes(code)) {
      detectedCurrency = code;
      break;
    }
  }

  // Check symbols
  for (const [symbol, currency] of Object.entries(symbolMap)) {
    if (priceStr.includes(symbol)) {
      detectedCurrency = currency;
      break;
    }
  }

  // Extract numeric value
  const numMatch = priceStr.match(/[\d,]+\.?\d*/);
  const value = numMatch ? parseFloat(numMatch[0].replace(/,/g, '')) : 0;

  return { value, currency: detectedCurrency };
}

/**
 * Convert price string to EUR
 */
export async function convertPriceToEUR(priceStr: string, countryHint?: string): Promise<string> {
  const { value, currency } = parsePrice(priceStr);

  let finalCurrency = currency;

  // If couldn't detect currency but have country hint
  if (currency === 'EUR' && countryHint && !priceStr.includes('€') && !priceStr.toUpperCase().includes('EUR')) {
    finalCurrency = getCurrencyForCountry(countryHint);
  }

  // Handle ¥ ambiguity (JPY vs CNY)
  if (currency === 'JPY' && countryHint) {
    const countryCurrency = getCurrencyForCountry(countryHint);
    if (countryCurrency === 'CNY') {
      finalCurrency = 'CNY';
    }
  }

  const eurValue = await convertToEUR(value, finalCurrency);
  return `€${Math.round(eurValue)}`;
}

/**
 * Convert numeric price to EUR
 */
export async function convertNumericPriceToEUR(value: number, country: string): Promise<number> {
  const currency = getCurrencyForCountry(country);
  const converted = await convertToEUR(value, currency);
  return Math.round(converted);
}

/**
 * Convert all prices in a trip to EUR (main function)
 */
export async function convertTripPricesToEUR(trip: any): Promise<any> {
  const country = trip.country || '';
  const localCurrency = getCurrencyForCountry(country);

  // Preload exchange rates
  await getExchangeRates();

  // If already EUR, no conversion needed
  if (localCurrency === 'EUR') {
    return { ...trip, currency: 'EUR' };
  }

  logger.info(`💱 Converting prices from ${localCurrency} to EUR for ${country}`);

  const convertedTrip = { ...trip };

  // Convert main price
  if (trip.price) {
    convertedTrip.price = await convertPriceToEUR(trip.price, country);
  }

  // Convert estimated costs
  if (trip.estimatedCostMin) {
    convertedTrip.estimatedCostMin = await convertNumericPriceToEUR(trip.estimatedCostMin, country);
  }
  if (trip.estimatedCostMax) {
    convertedTrip.estimatedCostMax = await convertNumericPriceToEUR(trip.estimatedCostMax, country);
  }
  if (trip.estimated_cost_min) {
    convertedTrip.estimated_cost_min = await convertNumericPriceToEUR(trip.estimated_cost_min, country);
  }
  if (trip.estimated_cost_max) {
    convertedTrip.estimated_cost_max = await convertNumericPriceToEUR(trip.estimated_cost_max, country);
  }

  // Convert recommended budget
  if (trip.recommendedBudget) {
    convertedTrip.recommendedBudget = {
      ...trip.recommendedBudget,
      min: await convertNumericPriceToEUR(trip.recommendedBudget.min || 0, country),
      max: await convertNumericPriceToEUR(trip.recommendedBudget.max || 0, country),
      currency: 'EUR',
    };
  }

  // Convert itinerary prices
  if (trip.itinerary && Array.isArray(trip.itinerary)) {
    convertedTrip.itinerary = await Promise.all(
      trip.itinerary.map(async (day: any) => {
        if (!day.places || !Array.isArray(day.places)) return day;

        const convertedPlaces = await Promise.all(
          day.places.map(async (place: any) => {
            const convertedPlace = { ...place };

            if (place.price) {
              convertedPlace.price = await convertPriceToEUR(place.price, country);
            }
            if (place.price_value !== undefined) {
              convertedPlace.price_value = await convertNumericPriceToEUR(place.price_value, country);
            }
            if (place.transportation?.cost) {
              convertedPlace.transportation = {
                ...place.transportation,
                cost: await convertPriceToEUR(place.transportation.cost, country),
              };
            }

            return convertedPlace;
          })
        );

        return { ...day, places: convertedPlaces };
      })
    );
  }

  convertedTrip.currency = 'EUR';

  logger.info(`✅ Prices converted to EUR`);
  return convertedTrip;
}

/**
 * Initialize exchange rates cache on startup
 */
export async function initExchangeRates(): Promise<void> {
  logger.info('💱 Initializing exchange rates...');
  await getExchangeRates();
}

// ═══════════════════════════════════════════════════════════════════════════
// Exports
// ═══════════════════════════════════════════════════════════════════════════

export default {
  getCurrencyForCountry,
  convertToEUR,
  convertToEURSync,
  parsePrice,
  convertPriceToEUR,
  convertNumericPriceToEUR,
  convertTripPricesToEUR,
  initExchangeRates,
};
