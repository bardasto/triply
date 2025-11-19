/**
 * Cultural activity prompt
 * Focus on arts, history, museums, heritage, cultural immersion
 */

import { PromptParams } from './base-prompt.js';

export function getCulturalPrompt(params: PromptParams): string {
  const { durationDays } = params;

  return `
CULTURAL-SPECIFIC INSTRUCTIONS:
1. Daily Schedule Pattern:
   - Morning: Major museum or art gallery (1-2 POIs)
   - Late morning: Historic site or monument (1-2 POIs)
   - Lunch: Traditional local restaurant (1 restaurant, regional cuisine)
   - Afternoon: Cultural district or heritage site (2-3 POIs)
   - Late afternoon: Art gallery or cultural center (1 POI)
   - Evening: Traditional dinner or cultural performance (1 restaurant + optional show)

2. Focus on:
   - World-class museums and galleries
   - UNESCO World Heritage sites
   - Historic monuments and architecture
   - Cultural neighborhoods and districts
   - Traditional theaters and performance venues
   - Religious and spiritual sites
   - Archaeological sites
   - Art studios and creative spaces
   - Local markets and craft centers
   - Libraries and cultural institutions
   - Heritage buildings and palaces

3. Each day should have:
   - 2-3 major museums or galleries
   - 3-4 historic or cultural POIs
   - 2 restaurants (authentic local cuisine)
   - Mix of ancient and modern cultural experiences
   - Storytelling and historical context

4. Transportation notes:
   - Walking between cultural sites in historic centers
   - Metro to different cultural districts (€2-3)
   - Cultural pass for multiple museums (€40-60 for 3 days)
   - Audio guides or guided tours (€8-15)
   - Respect for sacred and heritage sites

5. Price considerations:
   - Museum entry (€12-25 per major museum)
   - Historic site tickets (€8-20)
   - Combined passes for savings (€50-80 for multiple sites)
   - Guided cultural tours (€25-50)
   - Traditional restaurants (€€-€€€)
   - Theater or performance tickets (€20-60)
   - Audio guides (€5-8)

6. Best times:
   - Museums: opening time (9:00-10:00) to avoid crowds
   - Historic sites: early morning or late afternoon (better light, fewer tourists)
   - Churches: avoid service times unless attending
   - Galleries: weekday mornings (quieter)
   - Cultural performances: evening shows (19:00-21:00)
   - Traditional restaurants: authentic dinner times (local schedule)

7. Cultural etiquette:
   - Dress codes at religious sites (covered shoulders/knees)
   - Photography rules in museums (no flash, some prohibit photos)
   - Respect for sacred spaces
   - Silence in certain cultural venues
   - Queue etiquette at popular sites
   - Tipping customs (varies by country)
   - Greetings and social customs
   - Support local artisans and authentic crafts

8. Cultural activities:
   - Museum and gallery visits
   - Guided historical tours
   - Architecture walks
   - Traditional craft workshops
   - Cooking classes (local cuisine)
   - Language exchange meetups
   - Attending classical concerts or opera
   - Traditional dance or music performances
   - Visiting artist studios
   - Literary landmarks and tours
   - Archaeological site exploration

9. Cultural immersion:
   - Learn basic local phrases
   - Understand historical context
   - Engage with local traditions
   - Appreciate artistic movements
   - Taste regional specialties
   - Listen to local stories and legends
   - Respect cultural differences
   - Support authentic cultural experiences

EXAMPLE DAY STRUCTURE:
Day 1: "Artistic Heritage & Historic Grandeur"
- 09:00: National art museum POI (2.5 hours, €18, pre-book to skip line)
  * Renaissance collection (1 hour)
  * Impressionist gallery (45min)
  * Modern art section (45min)
- 11:45: Walk to historic cathedral (15min walk)
- 12:00: Gothic cathedral POI (60min, €10, includes tower climb)
- 13:15: Traditional lunch at heritage restaurant (90min, €€€)
- 15:00: Royal palace museum POI (2 hours, €15)
  * State apartments tour
  * Throne room and royal collections
  * Palace gardens
- 17:15: Walk through historic Jewish quarter (30min, free)
- 17:45: Contemporary art gallery POI (75min, €12)
- 19:15: Cultural center with traditional architecture POI (30min, free)
- 20:00: Traditional regional dinner with live folk music (90min, €€€)
- 21:45: Optional: Evening classical concert at historic theater (€35, 2 hours)

CULTURAL DAY DETAILS:
- Focus: art history from medieval to modern
- Museums visited: 3 major + 1 gallery
- Historic sites: 3
- Traditional meals: 2 with regional specialties
- Cultural performances: folk music + optional concert
- Total cultural immersion time: 8+ hours

MUSEUM HIGHLIGHTS TO MENTION:
- Specific famous artworks or exhibits
- Historical significance
- Architecture of the building itself
- Must-see collections
- Special exhibitions (if any)
- Artist backgrounds and stories

HISTORICAL CONTEXT:
- Explain era and significance of monuments
- Tell stories behind historic sites
- Connect cultural sites to local history
- Mention famous historical figures
- Relate to broader cultural movements
- UNESCO heritage status (if applicable)

CULTURAL PASS OPTION:
- Name: City Cultural Pass
- Price: €55 for 3 days
- Includes: 15 museums and monuments
- Benefits: skip-the-line access, free public transport
- Savings: approximately €40 if visiting 5+ sites
- Where to buy: tourist office, online, first venue

TRADITIONAL FOOD EXPERIENCES:
- Regional specialties and dishes
- Historic restaurants or food markets
- Cooking techniques and ingredients
- Food history and cultural significance
- Wine or beverage pairings
- Traditional dining etiquette

CULTURAL EVENING OPTIONS:
- Classical music concerts
- Opera or ballet performances
- Traditional folk shows
- Theater productions
- Literary readings
- Art gallery openings
- Cultural festivals (seasonal)

WHAT TO BRING:
- Comfortable walking shoes (lots of standing in museums)
- Modest clothing for religious sites
- Camera (check photography rules)
- Reusable water bottle
- Small daypack
- Notebook for reflections
- Museum guide apps
- Portable phone charger

CULTURAL LEARNING:
- Read about history before visiting
- Learn key dates and historical figures
- Understand artistic movements
- Recognize architectural styles
- Appreciate cultural evolution
- Connect past to present

RESPECT & AUTHENTICITY:
- Support authentic cultural experiences over tourist traps
- Buy from local artisans
- Attend genuine performances
- Eat at traditional establishments
- Learn from locals and guides
- Preserve and respect heritage sites

CRITICAL: Create EXACTLY ${durationDays} days with deep cultural immersion! Prioritize authentic experiences, historical education, and artistic appreciation. Include specific details about exhibits, historical context, and cultural significance.`;
}
