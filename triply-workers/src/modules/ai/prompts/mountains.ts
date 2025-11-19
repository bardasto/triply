/**
 * Mountains activity prompt
 * Focus on hiking, mountain views, alpine experiences
 */

import { PromptParams } from './base-prompt.js';

export function getMountainsPrompt(params: PromptParams): string {
  const { durationDays } = params;

  return `
MOUNTAINS-SPECIFIC INSTRUCTIONS:
1. Daily Schedule Pattern:
   - Early morning: Mountain base or cable car station (transport POI)
   - Morning: Mountain summit or viewpoint (main mountain POI)
   - Lunch: Mountain hut or alpine restaurant (1 restaurant)
   - Afternoon: Mountain trail or scenic route (2-3 POIs along trail)
   - Late afternoon: Return valley activity or village POI (1 POI)
   - Evening: Valley restaurant or mountain lodge dinner (1 restaurant)

2. Focus on:
   - Mountain peaks and viewpoints
   - Cable cars, funiculars, and mountain railways
   - Hiking trails (easy, moderate, challenging)
   - Alpine lakes and waterfalls
   - Mountain villages and traditional architecture
   - Panoramic viewpoints and observation decks
   - Mountain wildlife and nature reserves
   - Alpine photography spots

3. Each day should have:
   - 1-2 major mountain peaks or viewpoints
   - 3-4 trail stops or scenic points
   - 2 restaurants (mountain lunch and valley dinner)
   - Cable car or transport options for accessibility
   - Hiking distance and elevation gain information

4. Transportation notes:
   - Cable car/gondola rides (include prices and duration)
   - Mountain train or bus services
   - Hiking between POIs (specify distance, elevation, difficulty)
   - Shuttle services to trailheads
   - Return transport options

5. Price considerations:
   - Cable car tickets (€20-45 round trip)
   - Mountain hut meals (€€)
   - Valley restaurants (€€-€€€)
   - Hiking trail fees (usually free, some protected areas €5-10)
   - Equipment rental (hiking poles, proper footwear info)

6. Best times:
   - Early morning for sunrise and clear visibility
   - Before noon for cloud-free mountain views
   - Avoid afternoon thunderstorms in summer
   - Check seasonal accessibility (snow, ice conditions)

7. Safety and preparation:
   - Weather conditions and forecast
   - Appropriate clothing and footwear requirements
   - Water and snacks for hiking
   - Trail difficulty levels (easy/moderate/challenging)
   - Emergency contacts and mountain rescue
   - Altitude considerations

8. Activities to include:
   - Scenic hiking trails
   - Cable car rides to summits
   - Mountain photography spots
   - Alpine lake visits
   - Traditional mountain village exploration
   - Mountain biking routes (if available)
   - Via ferrata or climbing spots (for adventure level)

EXAMPLE DAY STRUCTURE:
Day 1: "Alpine Heights & Scenic Trails"
- 08:00: Mountain base cable car station (30min, €0)
- 08:30: Cable car to summit (20min, €35 round trip)
- 09:00: Summit viewpoint and observation deck (60min, free)
- 10:30: Mountain trail to alpine lake (2.5km, 45min, moderate)
- 11:30: Alpine lake POI - photography and rest (30min, free)
- 12:30: Mountain hut lunch (90min, €€)
- 14:00: Continue trail to waterfall (1.5km, 30min, easy)
- 14:45: Waterfall viewpoint POI (30min, free)
- 15:30: Cable car descent to valley (20min, included)
- 16:30: Mountain village exploration POI (60min, free)
- 18:00: Traditional valley restaurant dinner (90min, €€€)

HIKING NOTES:
- Include total distance: e.g., "8km total hiking"
- Elevation gain: e.g., "+350m / -250m"
- Estimated time: "3-4 hours including breaks"
- Difficulty: "Moderate - suitable for regular hikers"

CRITICAL: Create EXACTLY ${durationDays} days with mountain and alpine activities!`;
}
