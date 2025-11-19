/**
 * Road Trip activity prompt
 * Focus on scenic drives, roadside attractions, freedom of the open road
 */

import { PromptParams } from './base-prompt.js';

export function getRoadTripPrompt(params: PromptParams): string {
  const { durationDays } = params;

  return `
ROAD TRIP-SPECIFIC INSTRUCTIONS:
1. Daily Schedule Pattern:
   - Morning: Departure and scenic drive (driving route POI)
   - Mid-morning: Roadside attraction or viewpoint stop (2-3 POIs)
   - Lunch: Local roadside restaurant or town (1 restaurant)
   - Afternoon: Continue driving with attractions (2-3 POIs)
   - Late afternoon: Arrive at destination town or city (1-2 POIs)
   - Evening: Dinner at destination (1 restaurant)
   - Night: Accommodation in new location

2. Focus on:
   - Scenic driving routes and highways
   - Roadside viewpoints and photo stops
   - Interesting small towns and villages
   - Natural landmarks visible from road
   - Quirky roadside attractions
   - Historic sites along route
   - Local diners and authentic restaurants
   - Scenic overlooks and rest areas
   - Cultural stops in different regions
   - Freedom and spontaneity

3. Each day should have:
   - 1 main driving route (100-250km)
   - 5-7 POIs (stops along the way)
   - 2 restaurants (lunch stop and dinner destination)
   - Mix of planned and spontaneous stops
   - Different overnight locations (travel progression)

4. Transportation notes:
   - Car rental (€40-80 per day)
   - Fuel costs (calculate per route)
   - Parking fees at attractions (€3-8)
   - Toll roads if applicable (€5-15)
   - GPS navigation and offline maps
   - Driving time estimates (realistic with stops)

5. Price considerations:
   - Car rental (€40-80 per day + insurance)
   - Fuel (€0.10-0.15 per km)
   - Parking (€5-15 per day)
   - Roadside attractions (free-€10)
   - Meals (€-€€€ - variety)
   - Accommodation changes each night (€50-120)
   - Unexpected stops and experiences (budget flexibility)

6. Best times:
   - Early departure: 8:00-9:00 AM (beat traffic, good light)
   - Morning driving: best visibility and energy
   - Lunch stop: 12:00-14:00 (local town exploration)
   - Afternoon: 14:00-17:00 (continue route)
   - Arrive destination: before 18:00 (check-in, explore)
   - Flexible schedule for spontaneous stops

7. Road trip essentials:
   - Valid driver's license and insurance
   - GPS device or smartphone navigation
   - Offline maps backup
   - Car emergency kit
   - Phone charger and power bank
   - Snacks and water for the road
   - Music playlist or podcasts
   - Sunglasses and sun protection
   - Comfortable clothing for driving
   - Camera for roadside moments

8. Road trip activities:
   - Scenic coastal or mountain drives
   - Stops at viewpoints and overlooks
   - Exploring small towns and villages
   - Visiting local markets
   - Roadside food discoveries
   - Photography at unique locations
   - Meeting locals at small cafes
   - Spontaneous detours
   - Playlist singing and podcasts
   - Freedom to change plans

9. Road trip experiences:
   - Sunrise or sunset drives
   - Discovering hidden gems
   - Regional food specialties
   - Changing landscapes
   - Small-town character and charm
   - Freedom and independence
   - Journey as important as destination
   - Creating route memories

EXAMPLE DAY STRUCTURE:
Day 1: "Coastal Drive & Village Charm" (Barcelona to Girona via Costa Brava)
- 08:30: Pick up rental car in Barcelona (45min, €65 per day)
- 09:15: Departure - Drive north on C-32 coastal highway (scenic route)
- 10:00: Stop at Calella de Palafrugell POI - coastal viewpoint (30min, free parking €3)
- 10:45: Continue drive along coast (beautiful views)
- 11:30: Stop at medieval village of Pals POI (60min, €5 parking)
- 12:45: Lunch at traditional Catalan restaurant in village (90min, €€)
- 14:30: Drive to Empúries archaeological site POI (30min drive)
- 15:15: Explore Greek and Roman ruins (90min, €6 entry)
- 17:00: Drive to Girona (45min)
- 18:00: Arrive Girona, check into accommodation
- 18:30: Walk through Girona old town POI (60min, free)
- 19:45: Dinner at Girona riverside restaurant (90min, €€€)

DRIVING DAY DETAILS:
- Route: Barcelona → Costa Brava → Girona
- Total distance: 135 km
- Total driving time: 2.5 hours (without stops)
- Total time with stops: 10 hours
- Fuel cost: approximately €18
- Toll roads: none (scenic coastal route)
- Parking: €3-8 at various stops
- Overnight: Girona (new location)

ROUTE HIGHLIGHTS:
- Costa Brava coastal scenery
- Mediterranean Sea views
- Medieval villages
- Archaeological sites
- Regional Catalan culture
- Change from city to coast to historic town

DRIVING NOTES:
- Road conditions: excellent
- Traffic: light to moderate
- Scenic rating: 9/10 (stunning coastal views)
- Difficulty: easy, well-maintained roads
- Rest stops: available every 30-40km
- Photo opportunities: numerous coastal viewpoints

FLEXIBILITY BUILT IN:
- Alternative stop if weather is bad: indoor attraction
- Extra time for spontaneous discoveries
- Option to extend stay at favorite spots
- Can adjust route based on interests

CAR RENTAL DETAILS:
- Type: Compact car (economical fuel)
- Insurance: full coverage recommended
- GPS: included or use phone navigation
- Fuel policy: full-to-full (refill before return)
- Mileage: unlimited
- Additional driver: +€8 per day if needed
- Pick-up/drop-off: different locations allowed

ROAD TRIP SOUNDTRACK:
- Create playlist matching journey mood
- Local radio stations for cultural immersion
- Podcasts for longer driving stretches
- Quiet moments to enjoy scenery

WHAT TO PACK FOR CAR:
- Phone mount for GPS
- Car charger for devices
- Sunglasses and sun visor
- Reusable water bottles
- Road snacks (nuts, fruit, energy bars)
- Wet wipes and tissues
- Plastic bags for trash
- Light jacket (air conditioning)
- Camera easily accessible
- Paper maps as backup

ROAD TRIP PHILOSOPHY:
- Journey matters as much as destination
- Embrace spontaneous stops
- Take time at places that resonate
- Meet locals and ask recommendations
- Document memories with photos
- Stay flexible with schedule
- Enjoy freedom of the open road

CRITICAL: Create EXACTLY ${durationDays} days with road trip progression! Each day should end in a NEW location, showing travel across region. Include realistic driving times, fuel costs, and route details.`;
}
