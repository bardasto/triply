import { createClient } from '@supabase/supabase-js';
import config from './src/shared/config/env.js';

const supabase = createClient(
  config.SUPABASE_URL,
  config.SUPABASE_SERVICE_ROLE_KEY
);

async function checkTripRestaurants() {
  console.log(`🔍 Checking public_trips for restaurants...\n`);

  const { data: trips, error } = await supabase
    .from('public_trips')
    .select('*')
    .ilike('title', '%Paris%')
    .limit(1);

  if (error) {
    console.error('❌ Error:', error);
    return;
  }

  if (!trips || trips.length === 0) {
    console.log('❌ No Paris trips found');
    return;
  }

  const trip = trips[0];
  console.log(`✅ Found trip: "${trip.title}"`);
  console.log(`   Trip ID: ${trip.id}`);
  console.log(`   Fields: ${Object.keys(trip).join(', ')}\n`);

  // Check for itinerary field
  const itinerary = trip.itinerary || trip.itinerary_days || [];

  if (!itinerary || itinerary.length === 0) {
    console.log('❌ No itinerary found');
    return;
  }

  console.log(`✅ Found ${itinerary.length} days in itinerary\n`);

  itinerary.forEach((day: any, dayIndex: number) => {
    console.log(`📅 Day ${day.day || dayIndex + 1}: ${day.title || 'No title'}`);

    const places = day.places || [];
    const restaurants = places.filter((p: any) =>
      ['breakfast', 'lunch', 'dinner'].includes(p.category)
    );

    if (restaurants.length > 0) {
      restaurants.forEach((r: any) => {
        console.log(`  🍽️  ${r.name}`);
        console.log(`     poi_id: ${r.poi_id || '❌ NULL'}`);
        console.log(`     category: ${r.category}`);
        console.log(`     image_url: ${r.image_url ? '✓ EXISTS' : '✗ NULL'}`);
        console.log(`     images: ${r.images ? `✓ Array(${r.images.length})` : '✗ NULL'}`);
        if (r.images && r.images.length > 0) {
          console.log(`       → First: ${r.images[0].substring(0, 70)}...`);
        }
        console.log('');
      });
    } else {
      console.log(`  (No restaurants on this day)\n`);
    }
  });
}

checkTripRestaurants().catch(console.error);
