/**
 * Test activity prompts system
 */

import { getActivityPrompt, getSupportedActivities, isActivitySupported } from './src/modules/ai/prompts/index.js';

console.log('═══════════════════════════════════════════════════════');
console.log('Testing Activity-Specific Prompts System');
console.log('═══════════════════════════════════════════════════════\n');

// Test 1: List all supported activities
console.log('1. Supported Activities:');
console.log(getSupportedActivities());
console.log('');

// Test 2: Check if activities are supported
console.log('2. Activity Support Check:');
console.log('  - cycling:', isActivitySupported('cycling'));
console.log('  - beach:', isActivitySupported('beach'));
console.log('  - unknown:', isActivitySupported('unknown'));
console.log('  - road_trip:', isActivitySupported('road_trip'));
console.log('  - road trip:', isActivitySupported('road trip'));
console.log('');

// Test 3: Generate prompts for different activities
console.log('3. Testing Prompt Generation:');

const testActivities = ['cycling', 'beach', 'mountains', 'city', 'food'];

for (const activity of testActivities) {
  console.log(`\n  Testing ${activity}:`);

  const prompt = getActivityPrompt({
    city: 'Barcelona',
    country: 'Spain',
    activity,
    durationDays: 3,
    poiListJson: JSON.stringify([
      { id: '1', name: 'Sagrada Familia', category: 'attraction', lat: 41.4036, lon: 2.1744 },
      { id: '2', name: 'Park Güell', category: 'park', lat: 41.4145, lon: 2.1527 }
    ], null, 2),
    restaurantListJson: JSON.stringify([
      { id: 'r1', name: 'El Nacional', cuisine_types: ['Spanish', 'Tapas'], rating: 4.5, lat: 41.3924, lon: 2.1649 }
    ], null, 2),
    language: 'en'
  });

  // Just check that prompt contains activity-specific keywords
  const promptLower = prompt.toLowerCase();

  if (activity === 'cycling' && promptLower.includes('bike')) {
    console.log('    ✅ Contains cycling-specific content (bike)');
  } else if (activity === 'beach' && promptLower.includes('beach')) {
    console.log('    ✅ Contains beach-specific content');
  } else if (activity === 'mountains' && promptLower.includes('mountain')) {
    console.log('    ✅ Contains mountains-specific content');
  } else if (activity === 'city' && promptLower.includes('museum')) {
    console.log('    ✅ Contains city-specific content');
  } else if (activity === 'food' && promptLower.includes('culinary')) {
    console.log('    ✅ Contains food-specific content');
  } else {
    console.log('    ⚠️  Prompt generated but specific keywords not found');
  }

  console.log(`    📝 Prompt length: ${prompt.length} characters`);
}

console.log('\n═══════════════════════════════════════════════════════');
console.log('✅ All tests completed!');
console.log('═══════════════════════════════════════════════════════');
