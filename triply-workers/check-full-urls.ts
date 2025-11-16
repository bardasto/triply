import getSupabaseAdmin from './src/config/supabase.js';

async function checkFullUrls() {
  const supabase = getSupabaseAdmin();

  const { data: trips } = await supabase
    .from('public_trips')
    .select('id, title, city, itinerary')
    .order('created_at', { ascending: false })
    .limit(1);

  if (trips && trips.length > 0) {
    const trip = trips[0];
    console.log(`\n✅ Latest trip: ${trip.title}\n`);

    if (trip.itinerary && trip.itinerary[0]) {
      const day1 = trip.itinerary[0];

      if (day1.places && day1.places.length > 0) {
        const place = day1.places[0];
        console.log(`📍 Place: ${place.name}\n`);
        console.log(`image_url:`);
        console.log(place.image_url);
        console.log(`\nimages[] (${place.images?.length || 0} photos):`);
        if (place.images) {
          place.images.forEach((url: string, i: number) => {
            console.log(`\n[${i + 1}] ${url}`);
          });
        }
      }
    }
  }

  process.exit(0);
}

checkFullUrls().catch(console.error);
