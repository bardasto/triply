/**
 * Nightlife activity prompt
 * Focus on bars, clubs, evening entertainment, night experiences
 */

import { PromptParams } from './base-prompt.js';

export function getNightlifePrompt(params: PromptParams): string {
  const { durationDays } = params;

  return `
NIGHTLIFE-SPECIFIC INSTRUCTIONS:
1. Daily Schedule Pattern:
   - Late morning: Recovery brunch or late breakfast (1 restaurant)
   - Afternoon: Relaxed daytime activity or rest (1-2 POIs)
   - Early evening: Pre-drinks neighborhood exploration (1 POI)
   - Evening: Dinner at trendy restaurant (1 restaurant)
   - Night: Bar hopping or club experience (3-4 nightlife POIs)
   - Late night: Dance club or late-night venue (1-2 POIs)

2. Focus on:
   - Cocktail bars and speakeasies
   - Nightclubs and dance venues
   - Live music venues
   - Rooftop bars with views
   - Pub crawls and bar districts
   - Late-night food spots
   - Entertainment shows and cabaret
   - Beer gardens and breweries
   - Wine bars and lounges
   - Alternative and underground venues
   - LGBTQ+ friendly venues

3. Each day should have:
   - 2 restaurants (late brunch + dinner)
   - 2-3 daytime relaxation POIs
   - 4-6 nightlife venues (bars, clubs, entertainment)
   - Variety of nightlife styles
   - Progression from relaxed to energetic

4. Transportation notes:
   - Night buses and metro (check late-night schedules)
   - Taxis and ride-sharing for safety (€10-20 between venues)
   - Walking between bars in same district (5-15min)
   - Plan routes in safe, well-lit areas
   - Keep accommodation central to nightlife

5. Price considerations:
   - Bar drinks (€8-15 per cocktail)
   - Club entry (€10-30, often free before midnight)
   - VIP table service (€200-500+)
   - Pub crawl tours (€20-40 with drinks included)
   - Late-night food (€-€€)
   - Trendy dinner spots (€€-€€€)
   - Concert tickets (€25-60)

6. Best times:
   - Brunch: 11:00-14:00 (recovery meal)
   - Afternoon: 15:00-18:00 (rest or light activity)
   - Aperitivo/Pre-drinks: 18:00-21:00
   - Dinner: 20:00-22:00
   - First bars: 22:00-24:00 (warm up)
   - Clubs: 00:00-03:00+ (peak energy)
   - After-hours: 03:00-06:00 (if available)
   - Local nightlife culture timing varies by city

7. Nightlife etiquette and safety:
   - Dress codes (smart casual to upscale, check ahead)
   - ID required (passport or ID card)
   - Minimum age (18-21 depending on country)
   - Drink responsibly and stay hydrated
   - Never leave drinks unattended
   - Stay with friends/group
   - Keep valuables secure
   - Use official taxis or ride-sharing
   - Know your accommodation address
   - Have emergency contacts

8. Nightlife experiences:
   - Cocktail masterclasses
   - Themed club nights
   - Live DJ sets and concerts
   - Rooftop sunset sessions
   - Pub crawls and bar tours
   - Speakeasy discoveries
   - Local music scenes
   - Dance styles (salsa, techno, house, etc.)
   - Karaoke nights
   - Comedy shows
   - Late-night jazz clubs

9. Entertainment options:
   - Electronic music clubs
   - Live band venues
   - Jazz and blues bars
   - Latin dance clubs
   - Alternative/indie scenes
   - LGBTQ+ venues and pride events
   - Cabaret and burlesque shows
   - Casino nights
   - Stand-up comedy
   - Open mic nights

EXAMPLE DAY STRUCTURE:
Day 1: "Sunset to Sunrise - Urban Nightlife"
- 11:30: Hangover brunch at trendy cafe (90min, €€)
  * Healthy recovery options
  * Strong coffee essential
- 13:30: Walk along river or park POI (60min, relaxed recovery)
- 15:00: Return to accommodation - rest and prepare (2-3 hours)
- 18:00: Rooftop bar POI - sunset drinks (2 hours, €15 per drink)
  * City views and golden hour
  * Pre-game atmosphere
  * Light bites available
- 20:00: Walk to dinner location (15min)
- 20:15: Trendy restaurant in nightlife district (90min, €€€)
  * Hip atmosphere
  * Shared plates
  * Sets mood for night
- 22:00: Craft cocktail bar POI (90min, €12-15 per cocktail)
  * Expert mixologists
  * Creative cocktails
  * Speakeasy vibe
- 23:45: Walk to next venue (10min)
- 00:00: Live music bar POI (90min, €10 cover + drinks)
  * Local band or DJ
  * Dance floor warming up
- 01:30: Main nightclub POI (3+ hours, €20 entry)
  * Peak hours: 01:00-04:00
  * International DJs or top local talent
  * Multiple rooms/music styles
  * Dance until exhausted
- 04:30: Late-night food spot POI (45min, €)
  * Essential recovery fuel
  * Local late-night favorite
- 05:30: Return to accommodation (taxi €15)

NIGHTLIFE DAY DETAILS:
- Venues visited: 6 (rooftop bar, restaurant, cocktail bar, live music, club, late food)
- Music styles: sunset lounge → cocktail vibes → live bands → dance club
- Progression: relaxed → social → energetic → peak party
- Total nightlife time: 10+ hours (18:00-05:30)
- Energy flow: gradual build to peak at 02:00-03:00

CLUB NIGHT HIGHLIGHTS:
- Club name and reputation
- Music style and genre (techno, house, hip-hop, etc.)
- Famous DJs or residents
- Atmosphere and crowd
- Multiple rooms/areas
- Capacity and space
- Sound system quality
- Lighting and production

BAR RECOMMENDATIONS:
- Signature cocktails to try
- Bar specialty (gin, rum, whiskey, etc.)
- Atmosphere and decor
- Price range
- Crowd type
- Best time to visit
- Reservation needed or walk-in

DRESS CODE GUIDE:
- Rooftop bars: smart casual
- Cocktail bars: business casual to smart
- Nightclubs: varies (check ahead)
  * No sportswear or sneakers (some clubs)
  * Collared shirt for men (some venues)
  * Dressy for women works everywhere
- Alternative venues: casual, express yourself
- LGBTQ+ venues: welcoming, be yourself

NIGHTLIFE NEIGHBORHOODS:
- Identify 2-3 key nightlife districts
- Character of each area (trendy, alternative, mainstream, LGBTQ+)
- Safety and atmosphere
- Concentration of venues
- Easy to bar hop within area

PUB CRAWL OPTION:
- Organized tour or DIY route
- 4-5 bars in one night
- Includes drinks and club entry
- Meet other travelers
- Local guides with insider knowledge
- Price: €25-40 all-inclusive
- Time: 21:00-02:00

DRINKING CULTURE:
- Local drinking customs
- Typical bar hours
- Tipping expectations
- How to order drinks
- Pace of drinking
- Social etiquette
- When clubs get busy

SAFETY FIRST:
- Stay aware of surroundings
- Travel in groups when possible
- Use reputable taxi services
- Keep phone charged
- Don't accept drinks from strangers
- Know your limits
- Emergency numbers saved
- Accommodation address saved

RECOVERY PLAN:
- Hydrate before bed
- Late checkout if possible
- Brunch spots open late morning
- Relaxation options for next afternoon
- Pharmacy for headache relief

ALTERNATIVE IF CALMER NIGHT:
- Wine bars instead of cocktails
- Jazz clubs instead of dance clubs
- Dinner shows or cabaret
- Rooftop lounges
- Cultural evening events
- Later start, earlier finish

WHAT TO BRING:
- ID/Passport (required for clubs)
- Cash (some bars don't take cards)
- Phone charger or power bank
- Light jacket (venues can be hot or cold)
- Comfortable yet stylish shoes
- Small bag/wallet (secure)
- Emergency contact info
- Accommodation address saved

NIGHTLIFE TIPS:
- Arrive before midnight to avoid long lines
- Pre-drink to save money (drinks cheaper before clubs)
- Check event calendars for special nights
- Guest lists can save on cover charges
- VIP worth it for groups (table service)
- Pace yourself - it's a long night
- Eat before and during drinking
- Know when to call it a night

CRITICAL: Create EXACTLY ${durationDays} days with exciting NIGHTLIFE experiences! Balance recovery time during day with energetic nights. Include progression from sunset drinks to late-night dancing. Emphasize safety and local nightlife culture.`;
}
