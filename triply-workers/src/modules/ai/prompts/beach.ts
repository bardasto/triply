/**
 * Beach activity prompt
 * Focus on coastal activities, water sports, beach relaxation
 */

import { PromptParams } from './base-prompt.js';

export function getBeachPrompt(params: PromptParams): string {
  const { durationDays } = params;

  return `
BEACH-SPECIFIC INSTRUCTIONS:
1. Daily Schedule Pattern:
   - Morning: Beach time or water sports (beach location POI)
   - Late morning: Coastal walk or beachfront attraction (1-2 POIs)
   - Lunch: Seafood restaurant or beachfront cafe (1 restaurant)
   - Afternoon: Beach relaxation or water activities (beach POI)
   - Late afternoon: Coastal viewpoint or marina walk (1 POI)
   - Evening: Beachfront or harbor dinner (1 restaurant)

2. Focus on:
   - Best beaches and swimming spots
   - Water sports facilities (surfing, snorkeling, kayaking, paddleboarding)
   - Beach clubs and sun lounger rentals
   - Coastal walks and promenades
   - Marine attractions (aquariums, marinas, harbors)
   - Sunset viewpoints by the sea
   - Beach safety and lifeguard information

3. Each day should have:
   - 2-3 beach locations or coastal POIs
   - 2-3 other coastal attractions (ports, lighthouses, coastal towns)
   - 2 restaurants (seaside lunch and dinner with ocean views)
   - Water activity options (equipment rental, lessons)

4. Transportation notes:
   - Walking along beach promenades
   - Beach shuttle or tram services
   - Water taxis or boat transfers between beaches
   - Car/scooter rental for remote beaches

5. Price considerations:
   - Beach access fees (if any)
   - Sun lounger and umbrella rental (€10-20 per day)
   - Water sports equipment rental
   - Seafood restaurants (€€-€€€)
   - Beach club entry fees

6. Best times:
   - Early morning for calm water and fewer crowds
   - Midday for peak sunshine (11am-3pm)
   - Late afternoon for sunset views
   - Mention seasonal considerations (water temperature, wind conditions)

7. Beach essentials:
   - Sunscreen and sun protection
   - Beach towel and swimwear
   - Water sports equipment availability
   - Shower and changing facilities
   - Beach safety flags and lifeguard stations

8. Activities to include:
   - Swimming and sunbathing
   - Snorkeling or diving spots
   - Beach volleyball or water sports
   - Coastal hiking trails
   - Beach bars and sunset cocktails

EXAMPLE DAY STRUCTURE:
Day 1: "Golden Sands & Coastal Delights"
- 09:00: Main city beach arrival (15min walk)
- 09:30: Beach time - swimming and sunbathing (2.5 hours, sun lounger €15)
- 12:00: Beachfront seafood lunch (90min, €€€)
- 14:00: Walk along coastal promenade to second beach (3km, 45min)
- 15:00: Water sports - kayaking or paddleboarding (90min, €25)
- 17:00: Coastal viewpoint or lighthouse POI (45min, €5 or free)
- 18:00: Watch sunset from beach bar (60min, €10 drinks)
- 19:30: Harbor-side dinner with sea views (90min, €€€)

CRITICAL: Create EXACTLY ${durationDays} days with beach and coastal activities!`;
}
