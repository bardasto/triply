/**
 * Desert activity prompt
 * Focus on desert landscapes, sand dunes, oases, arid region exploration
 */

import { PromptParams } from './base-prompt.js';

export function getDesertPrompt(params: PromptParams): string {
  const { durationDays } = params;

  return `
DESERT-SPECIFIC INSTRUCTIONS:
1. Daily Schedule Pattern:
   - Early morning: Desert excursion start (4x4 departure point or camel station)
   - Morning: Desert landscape exploration (2-3 POIs - dunes, oases)
   - Late morning: Desert activity (sandboarding, camel ride, 4x4 tour)
   - Lunch: Desert camp or oasis restaurant (1 restaurant)
   - Afternoon: More desert exploration (2-3 POIs - canyons, rock formations)
   - Late afternoon: Sunset viewpoint in desert (1 POI)
   - Evening: Traditional dinner under stars or in desert lodge (1 restaurant)

2. Focus on:
   - Sand dunes and dune fields
   - Desert oases and palm groves
   - Rock formations and canyons
   - Desert wildlife viewing points
   - Bedouin camps and traditional culture
   - Desert sunset and sunrise viewpoints
   - Ancient desert trade routes
   - Desert national parks
   - Star-gazing locations

3. Each day should have:
   - 1-2 major desert excursions
   - 4-6 POIs (dunes, oases, viewpoints, cultural sites)
   - 2 restaurants (desert lunch and dinner)
   - Mix of active and contemplative desert experiences
   - Cultural encounters with local desert communities

4. Transportation notes:
   - 4x4 vehicle for desert access (€80-150 per day)
   - Camel trekking (€30-60 per person for 2-3 hours)
   - Guided desert tour (includes transport)
   - Sandboards for dune activities (€20 rental)
   - Desert camp transfers (often included)

5. Price considerations:
   - Full-day desert tour (€100-200 per person)
   - Half-day 4x4 safari (€60-100)
   - Camel ride experience (€40-80)
   - Desert camp overnight (€150-300 with meals)
   - Sandboarding (€25-40)
   - Traditional meals (€€-€€€)
   - National park entry (€10-20)

6. Best times:
   - Start very early: 5:00-6:00 AM for sunrise (cooler temperatures)
   - Morning activities: 6:00-10:00 AM (before intense heat)
   - Midday: rest in shade or air-conditioned spaces (11:00-15:00)
   - Late afternoon: 16:00-19:00 (golden hour and sunset)
   - Evening: star-gazing after dark (20:00+)
   - Avoid midday sun (dangerous heat)

7. Safety and preparation:
   - Essential: 3-4 liters of water per person
   - Sun protection: hat, sunglasses, SPF 50+ sunscreen
   - Light, long-sleeved clothing (protect from sun)
   - Closed shoes for sand and rocks
   - GPS and navigation for remote areas
   - Emergency supplies in vehicles
   - Local guide highly recommended
   - Phone signal may be limited
   - Inform others of desert plans

8. Desert activities:
   - Camel trekking across dunes
   - 4x4 dune bashing
   - Sandboarding down dunes
   - Desert hiking (early morning only)
   - Quad biking
   - Hot air balloon rides at sunrise
   - Traditional Bedouin tea ceremonies
   - Star-gazing and astrophotography
   - Wildlife spotting (desert foxes, reptiles, birds)

9. Cultural experiences:
   - Bedouin camp visits
   - Traditional desert hospitality
   - Desert survival techniques
   - Local crafts and textiles
   - Traditional music and dance
   - Desert cuisine tasting
   - Stories and legends of the desert

EXAMPLE DAY STRUCTURE:
Day 1: "Golden Dunes & Desert Magic"
- 05:30: 4x4 pickup from hotel (30min to desert edge, included in tour)
- 06:00: Sunrise at Big Dune POI - photography spot (45min, included)
- 07:00: Camel trekking through dune field (90min, €50)
- 08:45: Desert oasis POI - palm grove and water source (45min, free)
- 09:45: Sandboarding on tall dunes (75min, €30 with equipment)
- 11:15: 4x4 drive to desert camp (30min)
- 12:00: Traditional lunch at Bedouin camp (90min, €€)
- 14:00: Rest during peak heat at camp (or drive to next location)
- 15:00: Ancient rock formation POI - desert canyon (60min, free)
- 16:15: 4x4 dune bashing experience (45min, included in tour)
- 17:15: Sunset viewpoint POI - highest dune (60min, included)
- 18:30: Return to desert lodge
- 19:30: Traditional dinner under stars with local music (120min, €€€)
- 21:30: Star-gazing session (optional, 60min)

DESERT TOUR DETAILS:
- Type: Full-day guided desert safari
- Group size: 6-8 people in 4x4
- Distance: approximately 80km off-road
- Includes: transport, guide, camel ride, sandboarding, lunch
- Duration: 14 hours (6:00-20:00)
- Price: €180 per person all-inclusive

TEMPERATURE & CONDITIONS:
- Sunrise: 18°C (comfortable)
- Midday: 38°C (very hot - avoid activities)
- Sunset: 28°C (pleasant)
- Night: 15°C (cool - bring jacket)
- Humidity: very low (<20%)
- Sun intensity: extreme - constant protection needed

WHAT TO BRING:
- 4 liters of water per person (minimum)
- Wide-brimmed hat and sunglasses
- SPF 50+ sunscreen (reapply every 2 hours)
- Light, breathable long clothing
- Scarf or shemagh for sand protection
- Camera with extra batteries (heat drains them)
- Power bank for phone
- Small first aid kit
- Snacks (trail mix, energy bars)

CRITICAL: Create EXACTLY ${durationDays} days with authentic desert experiences! Emphasize safety, proper timing, and cultural respect.`;
}
