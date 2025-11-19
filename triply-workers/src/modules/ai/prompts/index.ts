/**
 * Activity-specific prompts manager
 * Routes activity types to their specialized prompts
 */

import { getBasePromptStructure, PromptParams } from './base-prompt.js';
import { getCyclingPrompt } from './cycling.js';
import { getBeachPrompt } from './beach.js';
import { getMountainsPrompt } from './mountains.js';
import { getCityPrompt } from './city.js';
import { getHikingPrompt } from './hiking.js';
import { getSkiingPrompt } from './skiing.js';
import { getSailingPrompt } from './sailing.js';
import { getDesertPrompt } from './desert.js';
import { getCampingPrompt } from './camping.js';
import { getWellnessPrompt } from './wellness.js';
import { getRoadTripPrompt } from './road_trip.js';
import { getCulturalPrompt } from './cultural.js';
import { getFoodPrompt } from './food.js';
import { getNightlifePrompt } from './nightlife.js';
import { getShoppingPrompt } from './shopping.js';

/**
 * Activity type mapping
 */
export type ActivityType =
  | 'cycling'
  | 'beach'
  | 'skiing'
  | 'mountains'
  | 'hiking'
  | 'sailing'
  | 'desert'
  | 'camping'
  | 'city'
  | 'wellness'
  | 'road_trip'
  | 'cultural'
  | 'food'
  | 'nightlife'
  | 'shopping';

/**
 * Get activity-specific prompt
 * Returns the specialized prompt for the activity type,
 * combined with base prompt structure
 */
export function getActivityPrompt(params: PromptParams): string {
  const { city, country, activity, durationDays, poiListJson, restaurantListJson, language } = params;

  // Get base structure
  const basePrompt = getBasePromptStructure(params);

  // Get activity-specific instructions
  let activityInstructions = '';

  switch (activity.toLowerCase()) {
    case 'cycling':
      activityInstructions = getCyclingPrompt(params);
      break;

    case 'beach':
      activityInstructions = getBeachPrompt(params);
      break;

    case 'skiing':
      activityInstructions = getSkiingPrompt(params);
      break;

    case 'mountains':
      activityInstructions = getMountainsPrompt(params);
      break;

    case 'hiking':
      activityInstructions = getHikingPrompt(params);
      break;

    case 'sailing':
      activityInstructions = getSailingPrompt(params);
      break;

    case 'desert':
      activityInstructions = getDesertPrompt(params);
      break;

    case 'camping':
      activityInstructions = getCampingPrompt(params);
      break;

    case 'city':
      activityInstructions = getCityPrompt(params);
      break;

    case 'wellness':
      activityInstructions = getWellnessPrompt(params);
      break;

    case 'road_trip':
    case 'road trip':
      activityInstructions = getRoadTripPrompt(params);
      break;

    case 'cultural':
      activityInstructions = getCulturalPrompt(params);
      break;

    case 'food':
      activityInstructions = getFoodPrompt(params);
      break;

    case 'nightlife':
      activityInstructions = getNightlifePrompt(params);
      break;

    case 'shopping':
      activityInstructions = getShoppingPrompt(params);
      break;

    default:
      // Fallback to city prompt for unknown activities
      console.warn(`Unknown activity type: ${activity}, falling back to city prompt`);
      activityInstructions = getCityPrompt(params);
  }

  // Combine base prompt with activity-specific instructions
  return `${basePrompt}

${activityInstructions}`;
}

/**
 * Get list of all supported activities
 */
export function getSupportedActivities(): ActivityType[] {
  return [
    'cycling',
    'beach',
    'skiing',
    'mountains',
    'hiking',
    'sailing',
    'desert',
    'camping',
    'city',
    'wellness',
    'road_trip',
    'cultural',
    'food',
    'nightlife',
    'shopping',
  ];
}

/**
 * Check if activity is supported
 */
export function isActivitySupported(activity: string): boolean {
  const normalized = activity.toLowerCase().replace(/[_\s]+/g, '_');
  return getSupportedActivities().some(
    a => a.toLowerCase() === normalized || a.replace('_', ' ').toLowerCase() === normalized
  );
}
