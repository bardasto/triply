import getSupabaseAdmin from './src/config/supabase.js';

async function checkPlaceImages() {
  const supabase = getSupabaseAdmin();

  const { data: trips } = await supabase
    .from('public_trips')
    .select('id, title, city, itinerary')
    .order('created_at', { ascending: false })
    .limit(1);

  if (trips && trips.length > 0) {
    const trip = trips[0];
    console.log(`\n✅ Latest trip: ${trip.title} (${trip.city})\n`);

    if (trip.itinerary && trip.itinerary[0]) {
      const day1 = trip.itinerary[0];
      console.log(`Day 1: ${day1.title}`);
      console.log(`Places count: ${day1.places?.length || 0}\n`);

      if (day1.places) {
        day1.places.slice(0, 3).forEach((place: any, i: number) => {
          console.log(`\n${i + 1}. ${place.name} (${place.category})`);
          console.log(`   poi_id: ${place.poi_id || 'N/A'}`);
          console.log(`   google_place_id: ${place.google_place_id || 'N/A'}`);
          console.log(`   image_url: ${place.image_url ? '✅ YES' : '❌ NO'}`);

          if (place.images) {
            console.log(`   images[]: ✅ ${place.images.length} photos`);
            place.images.forEach((img: string, idx: number) => {
              console.log(`      [${idx}] ${img.substring(0, 60)}...`);
            });
          } else {
            console.log(`   images[]: ❌ NO`);
          }
        });
      }
    }
  }

  process.exit(0);
}

checkPlaceImages().catch(console.error);
