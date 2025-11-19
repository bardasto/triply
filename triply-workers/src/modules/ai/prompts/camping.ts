/**
 * Camping activity prompt
 * Focus on outdoor camping, nature immersion, wilderness experience
 */

import { PromptParams } from './base-prompt.js';

export function getCampingPrompt(params: PromptParams): string {
  const { durationDays } = params;

  return `
CAMPING-SPECIFIC INSTRUCTIONS:
1. Daily Schedule Pattern:
   - Early morning: Sunrise at campsite and breakfast preparation (camp POI)
   - Morning: Nature activity or hiking trail (2-3 POIs)
   - Midday: Campsite lunch and relaxation (at camp or picnic spot)
   - Afternoon: Outdoor activities (kayaking, fishing, swimming - 2-3 POIs)
   - Late afternoon: Campfire preparation and dinner cooking (camp POI)
   - Evening: Campfire activities, star-gazing (camp POI)

2. Focus on:
   - Campsites and camping grounds
   - National park camping areas
   - Wild camping spots (where legal)
   - Hiking trails near campsites
   - Lakes, rivers, and natural swimming spots
   - Fishing locations
   - Wildlife observation points
   - Scenic viewpoints
   - Campfire areas
   - Outdoor shower and facilities

3. Each day should have:
   - 1 main campsite location
   - 4-6 outdoor POIs (trails, lakes, viewpoints)
   - 2 meal preparations (campsite cooking or simple restaurants nearby)
   - Mix of active and relaxing outdoor activities
   - Evening campfire or social activities

4. Transportation notes:
   - Car to campsite (parking at camp)
   - Hiking from camp to attractions (1-5km)
   - Bicycle for nearby areas
   - Shuttle to trailheads if available
   - All gear transport to campsite

5. Price considerations:
   - Campsite fee (€15-35 per night)
   - National park entry (€5-15)
   - Camping equipment rental if needed (€30-80 per day)
   - Firewood (€5-10)
   - Food supplies for self-cooking (€€)
   - Occasional restaurant meal (€-€€)
   - Guided activities (€30-60)

6. Best times:
   - Early morning: sunrise activities (6:00-8:00)
   - Morning: hiking and active pursuits (8:00-12:00)
   - Midday: swimming or rest (12:00-15:00)
   - Afternoon: relaxed activities (15:00-18:00)
   - Evening: campfire and dinner (18:00-21:00)
   - Night: star-gazing (21:00+)
   - Seasonal camping: spring, summer, early autumn best

7. Safety and preparation:
   - Camping checklist: tent, sleeping bags, mats
   - Cooking equipment: stove, pots, utensils
   - Food storage (bear-proof containers if needed)
   - Water purification method
   - First aid kit (essential)
   - Weather-appropriate clothing
   - Headlamp or flashlight
   - Maps and navigation
   - Fire safety and extinguisher
   - Wildlife awareness
   - Leave No Trace principles

8. Camping activities:
   - Tent setup and camp organization
   - Hiking and nature walks
   - Fishing (check if license required)
   - Swimming in natural waters
   - Kayaking or canoeing
   - Wildlife watching and photography
   - Campfire cooking and stories
   - Star-gazing and astronomy
   - Nature journaling
   - Outdoor games
   - Foraging (with expert guidance)

9. Camping experiences:
   - Morning coffee with nature sounds
   - Cooking meals over campfire
   - Evening campfire gatherings
   - Sleeping under stars (tent or hammock)
   - Sunrise and sunset from camp
   - Wildlife encounters
   - Disconnecting from technology
   - Building camp skills
   - Connecting with fellow campers

EXAMPLE DAY STRUCTURE:
Day 1: "Wilderness Camping & Lake Adventure"
- 07:00: Wake up at campsite, sunrise viewing (30min, free)
- 07:30: Campfire breakfast preparation (60min, self-catered €5)
- 09:00: Pack day bags, leave for hiking trail (15min walk from camp)
- 09:15: Forest trail to lake POI (3km, 60min, moderate)
- 10:30: Mountain lake POI - swimming and relaxation (2 hours, free)
- 12:30: Picnic lunch by lake (45min, packed from camp €8)
- 13:30: Continue trail to waterfall POI (2km, 45min)
- 14:30: Waterfall viewpoint (45min, photography and rest)
- 15:30: Return hike to campsite (3.5km, 90min)
- 17:30: Rest at camp, campfire preparation (60min)
- 18:30: Campfire dinner cooking (90min, self-catered €12)
- 20:00: Evening campfire - stories and songs (2 hours)
- 22:00: Star-gazing from campsite (optional, 60min)

CAMPING DAY DETAILS:
- Campsite: Forest camping ground with facilities
- Amenities: toilets, cold showers, fire pits, water source
- Camping spot: tent pitch in woods
- Total hiking: 8.5 km
- Activities: hiking, swimming, cooking
- Meals: all self-prepared at camp

CAMPSITE INFORMATION:
- Name: Pine Forest Camp
- Fee: €22 per night (2 people with tent)
- Facilities: basic toilets, water tap, designated fire areas
- Firewood: €8 for evening bundle
- Parking: next to tent area (€5 per day)
- Shower: cold water only
- Rules: quiet hours 22:00-7:00, no amplified music
- Booking: recommended in peak season

WHAT TO BRING:
- Tent (2-person, waterproof)
- Sleeping bags (rated for season)
- Sleeping pads or air mattresses
- Camping stove and fuel
- Cooking pots, utensils, plates
- Food for all meals (non-perishable + fresh)
- 10 liters of water + purification tablets
- Cooler with ice for perishables
- Headlamps and extra batteries
- Multi-tool or knife
- Rope for clothesline or food hanging
- Trash bags (pack it out)
- Biodegradable soap
- Toilet paper and trowel
- Insect repellent
- Weather-appropriate layers

CAMPING MEALS SUGGESTION:
- Breakfast: oatmeal, coffee, fruit, granola
- Lunch: sandwiches, trail mix, energy bars
- Dinner: one-pot pasta, grilled vegetables, campfire cooking
- Snacks: nuts, dried fruit, chocolate

LEAVE NO TRACE:
- Pack out all trash
- Use established fire rings only
- Minimize campfire impact
- Respect wildlife (observe from distance)
- Leave what you find
- Stay on designated trails
- Dispose of waste properly

CRITICAL: Create EXACTLY ${durationDays} days with authentic camping and outdoor experiences! Emphasize self-sufficiency, nature connection, and responsible camping.`;
}
