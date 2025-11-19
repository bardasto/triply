/**
 * Sailing activity prompt
 * Focus on boat trips, marinas, coastal sailing, yacht experiences
 */

import { PromptParams } from './base-prompt.js';

export function getSailingPrompt(params: PromptParams): string {
  const { durationDays } = params;

  return `
SAILING-SPECIFIC INSTRUCTIONS:
1. Daily Schedule Pattern:
   - Morning: Marina or harbor departure point (marina POI)
   - Late morning: Sailing trip or boat tour (sailing activity 2-4 hours)
   - Lunch: Seaside restaurant or boat lunch (1 restaurant)
   - Afternoon: Coastal exploration or water activities (2-3 POIs)
   - Late afternoon: Harbor walk or maritime museum (1 POI)
   - Evening: Waterfront dinner with harbor views (1 restaurant)

2. Focus on:
   - Marinas and yacht clubs
   - Sailing boat rentals and charters
   - Sailing schools and lessons
   - Coastal boat tours and cruises
   - Harbor and waterfront areas
   - Maritime museums and attractions
   - Lighthouse visits
   - Beach stops accessible by boat
   - Snorkeling or swimming spots
   - Sunset sailing opportunities

3. Each day should have:
   - 1 main sailing activity (half-day or full-day)
   - 3-5 coastal/maritime POIs
   - 2 restaurants (seaside lunch and dinner)
   - Mix of on-water and on-land activities
   - Weather-dependent alternatives

4. Transportation notes:
   - Walking to marina/harbor (10-20min)
   - Water taxi or ferry between islands (€5-15)
   - Boat rental or charter (include in activity cost)
   - Marina shuttle services
   - Parking at marina (€5-10)

5. Price considerations:
   - Half-day sailing tour (€50-100 per person)
   - Full-day charter (€200-400 total or per person)
   - Sailing lessons (€80-150 per session)
   - Marina berth viewing/tour (free-€5)
   - Maritime museum (€8-15)
   - Seafood restaurants (€€€)
   - Equipment rental (life jackets usually included)

6. Best times:
   - Morning sailing: 9:00-13:00 (calmer seas, good wind)
   - Afternoon sailing: 14:00-18:00 (stronger winds, warmer)
   - Sunset cruise: 18:00-20:00 (romantic, beautiful light)
   - Check tide times for optimal sailing
   - Weather windows for safe sailing

7. Safety and requirements:
   - Life jacket provision (mandatory)
   - Sailing experience level required
   - Licensed skipper if no experience
   - Weather and wind forecasts
   - Sea sickness prevention
   - Sun protection and hat
   - Non-slip shoes recommended
   - Swimming ability for water activities

8. Sailing activities:
   - Skippered sailing tours
   - Bareboat sailing (if licensed)
   - Sailing lessons for beginners
   - Catamaran tours
   - Coastal cruising
   - Island hopping by sailboat
   - Snorkeling from boat
   - Sunset sailing with drinks
   - Regatta watching

9. Alternative water activities:
   - Stand-up paddleboarding
   - Kayaking in harbor
   - Boat building workshops
   - Yacht club visits
   - Fishing trips
   - Harbor cruise tours

EXAMPLE DAY STRUCTURE:
Day 1: "Maritime Discovery & Coastal Sailing"
- 09:00: Main marina arrival and orientation (30min, free walk)
- 09:30: Yacht club and marina POI - tour of sailing boats (45min, free)
- 10:30: Half-day sailing tour departure (4 hours, €85 per person, includes skipper)
  * Sail along coastline
  * Stop at secluded bay for swimming (45min)
  * Learn basic sailing techniques
  * Snorkeling opportunity
- 14:30: Return to marina
- 15:00: Harbor-front seafood lunch (90min, €€€)
- 16:45: Maritime museum POI (75min, €12)
- 18:15: Walk to historic lighthouse POI (30min walk + 30min visit, €5)
- 19:30: Waterfront dinner with sunset views (90min, €€€)

SAILING DAY DETAILS:
- Boat type: 38ft sailing yacht
- Capacity: 8 passengers + skipper
- Route: 15 nautical miles along coast
- Wind: 12-15 knots (ideal conditions)
- Includes: life jackets, snorkeling gear, drinks
- Suitable for: all levels, no experience needed

WEATHER CONSIDERATIONS:
- Wind: light to moderate (perfect for sailing)
- Sea state: calm to slight waves
- Temperature: 24°C air, 21°C water
- Visibility: excellent
- Safety: all conditions favorable

ALTERNATIVE IF BAD WEATHER:
- Include indoor maritime activities
- Harbor-side restaurants and shops
- Maritime museums and exhibitions
- Boat building or sailing simulators
- Postpone sailing to next day

CRITICAL: Create EXACTLY ${durationDays} days with sailing and maritime experiences! Balance on-water and coastal land activities.`;
}
