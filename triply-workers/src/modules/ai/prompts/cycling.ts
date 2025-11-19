/**
 * Cycling activity prompt
 * Focus on bike-friendly routes, cycling infrastructure, scenic paths
 */

import { PromptParams } from './base-prompt.js';

export function getCyclingPrompt(params: PromptParams): string {
  const { durationDays } = params;

  return `
CYCLING-SPECIFIC INSTRUCTIONS:
1. Daily Schedule Pattern:
   - Morning: Start with bike rental location or cycling route planning (1 POI)
   - Mid-morning: Scenic cycling route with viewpoints (2-3 POIs along the route)
   - Lunch: Cyclist-friendly cafe/restaurant near bike paths (1 restaurant)
   - Afternoon: Continue cycling tour with cultural stops (2-3 POIs)
   - Evening: Return route and dinner near bike-friendly area (1 restaurant)

2. Focus on:
   - Bike rental shops and cycling infrastructure
   - Dedicated bike lanes and safe cycling routes
   - Scenic waterfront, park, or countryside cycling paths
   - Bike-friendly cafes and rest stops
   - Distance in km and elevation for each cycling segment
   - Bike repair shops and support services

3. Each day should have:
   - 4-6 POIs (including cycling route landmarks and viewpoints)
   - 2 restaurants (lunch and dinner, bike-friendly locations)
   - Total cycling distance: 20-40km per day
   - Mix of urban and scenic routes

4. Transportation notes:
   - Primary method: cycling (specify distance and estimated cycling time)
   - Include walking time at each POI
   - Mention bike parking availability
   - For longer distances: mention metro/train options with bike transport

5. Price considerations:
   - Include bike rental costs (€15-25 per day)
   - Budget-friendly to mid-range restaurants
   - Free or low-cost outdoor attractions

6. Best times:
   - Early morning or late afternoon for comfortable cycling temperatures
   - Avoid midday heat in summer
   - Consider weather and traffic patterns

7. Safety notes:
   - Mention bike lane availability
   - Helmet rental information
   - Traffic safety considerations

EXAMPLE DAY STRUCTURE:
Day 1: "Waterfront Cycling Adventure"
- 09:00: Bike rental shop (30min, €20)
- 09:30: Cycling route to waterfront (10km, 45min, free)
- 11:00: Coastal viewpoint POI (30min, free)
- 12:00: Seaside lunch spot (90min, €€)
- 14:00: Continue cycling to historic district (8km, 40min)
- 15:00: Museum or landmark POI (60min, €12)
- 16:30: Park or garden POI (45min, free)
- 18:00: Return cycle to dinner location (6km, 30min)
- 19:00: Dinner near cycling route (90min, €€)

CRITICAL: Create EXACTLY ${durationDays} days with cycling-focused activities!`;
}
