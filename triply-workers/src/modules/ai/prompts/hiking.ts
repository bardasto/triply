/**
 * Hiking activity prompt
 * Focus on nature trails, national parks, outdoor exploration
 */

import { PromptParams } from './base-prompt.js';

export function getHikingPrompt(params: PromptParams): string {
  const { durationDays } = params;

  return `
HIKING-SPECIFIC INSTRUCTIONS:
1. Daily Schedule Pattern:
   - Early morning: Trailhead arrival and preparation (transport/parking POI)
   - Morning: Main hiking trail with scenic points (2-3 POIs along trail)
   - Midday: Trail lunch spot or summit (picnic or trail restaurant)
   - Afternoon: Continue trail or alternative route (2-3 POIs)
   - Late afternoon: Return and optional easy nature walk (1 POI)
   - Evening: Recovery dinner near nature area (1 restaurant)

2. Focus on:
   - Nature trails and hiking paths (varying difficulty)
   - National parks and protected areas
   - Forest trails and woodland walks
   - Viewpoints and scenic overlooks
   - Waterfalls and natural landmarks
   - Wildlife observation spots
   - Trail markers and navigation
   - Rest areas and facilities

3. Each day should have:
   - 1 main hiking trail (4-12km)
   - 4-6 POIs along the trail (viewpoints, landmarks, rest stops)
   - 1-2 restaurants (packed lunch or trail restaurant + evening meal)
   - Clear trail difficulty rating (easy/moderate/challenging)
   - Total distance and elevation information

4. Transportation notes:
   - Bus or car to trailhead (30-60min)
   - Parking availability and fees
   - Shuttle services to popular trails
   - Return transport arrangements
   - Alternative routes in case of trail closure

5. Price considerations:
   - National park entry fees (€5-15)
   - Parking fees (€5-10)
   - Trail guide or map (€5)
   - Restaurant meals (€€)
   - Equipment rental if needed (hiking poles €8-12)

6. Best times:
   - Start early: 7:00-8:00 AM to avoid afternoon heat
   - Complete main hike before 2:00 PM (weather safety)
   - Golden hour hikes: late afternoon for photography
   - Seasonal considerations (snow, rain, temperature)

7. Safety and preparation:
   - Required fitness level for each trail
   - Weather forecasts and conditions
   - Proper hiking boots and clothing
   - Water (2-3 liters per person)
   - Trail snacks and packed lunch
   - First aid kit and emergency contacts
   - Offline maps and GPS tracking
   - Wildlife awareness (bears, snakes, etc.)

8. Trail details to include:
   - Distance: e.g., "8.5 km"
   - Duration: e.g., "3.5-4 hours"
   - Elevation gain: e.g., "+450m / -450m"
   - Difficulty: "Moderate - requires good fitness"
   - Trail type: "Loop trail / Out-and-back / Point-to-point"
   - Surface: "Rocky / Forest path / Well-maintained"
   - Waypoints: Notable points along the trail

EXAMPLE DAY STRUCTURE:
Day 1: "Forest Trails & Waterfall Discovery"
- 07:30: Bus to national park entrance (45min, €5)
- 08:30: Trailhead - trail map and preparation (15min, park fee €8)
- 09:00: Begin main forest trail (2km, 30min, easy)
- 09:45: Forest viewpoint POI (15min, photography)
- 10:00: Continue to waterfall (3km, 1 hour, moderate incline)
- 11:15: Waterfall viewpoint POI - main destination (45min, lunch spot)
- 12:15: Return via alternative scenic route (2.5km, 45min)
- 13:15: Forest lake POI (30min, rest and photos)
- 14:00: Complete trail back to trailhead (1.5km, 30min, easy descent)
- 14:45: Visitor center or nature museum POI (45min, €5)
- 15:45: Return bus to city (45min, €5)
- 17:00: Rest time
- 19:00: Restaurant with local organic food (90min, €€)

TRAIL SUMMARY:
- Total distance: 9 km
- Elevation: +380m / -380m
- Type: Loop trail
- Difficulty: Moderate
- Duration: 4-5 hours including breaks
- Best for: Hikers with regular fitness

PACKING LIST MENTION:
- Suggest what hikers should bring
- Weather-appropriate clothing
- Water and snacks
- Sun protection
- Camera for scenic spots

CRITICAL: Create EXACTLY ${durationDays} days with varied hiking adventures! Include different trail types and difficulty levels.`;
}
