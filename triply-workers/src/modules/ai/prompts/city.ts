/**
 * City activity prompt
 * Focus on urban exploration, landmarks, museums, city culture
 */

import { PromptParams } from './base-prompt.js';

export function getCityPrompt(params: PromptParams): string {
  const { durationDays } = params;

  return `
CITY-SPECIFIC INSTRUCTIONS:
1. Daily Schedule Pattern:
   - Morning: Major landmark or museum (1-2 POIs)
   - Late morning: Historic district walk with monuments (2-3 POIs)
   - Lunch: City center restaurant (1 restaurant)
   - Afternoon: Cultural attractions or shopping district (2-3 POIs)
   - Late afternoon: Park or riverside walk (1 POI)
   - Evening: Trendy neighborhood dinner (1 restaurant)

2. Focus on:
   - Iconic landmarks and monuments
   - Museums and art galleries
   - Historic neighborhoods and architecture
   - City squares and public spaces
   - Shopping streets and markets
   - Parks and green spaces
   - Viewpoints and observation decks
   - Public transportation hubs and routes

3. Each day should have:
   - 5-7 POIs (mix of museums, landmarks, neighborhoods)
   - 2 restaurants (lunch and dinner in different areas)
   - Variety: culture, history, shopping, relaxation
   - Efficient routing through city districts

4. Transportation notes:
   - Metro/subway between major areas (€2-3 per trip)
   - Walking within neighborhoods (5-15 min)
   - Tram or bus for scenic routes
   - Bicycle sharing for short distances
   - Consider day pass for unlimited transport (€8-12)

5. Price considerations:
   - Museum tickets (€10-20)
   - Landmark entry fees (€8-25)
   - Free attractions (parks, squares, street markets)
   - Mid-range to upscale restaurants (€€-€€€)
   - Public transport costs

6. Best times:
   - Museums: morning opening to avoid crowds
   - Landmarks: early or late to avoid tour groups
   - Shopping: afternoon when stores are fully open
   - Parks: late afternoon for golden hour
   - Restaurants: book ahead for dinner (19:00-21:00)

7. City exploration tips:
   - Walking tours of historic centers
   - Architecture and photo opportunities
   - Local markets and food halls
   - Street art and cultural districts
   - Rooftop bars or observation decks for views
   - Public transport experience

8. Cultural experiences:
   - Museum highlights and must-see exhibits
   - Historic storytelling at monuments
   - Local neighborhoods and lifestyle
   - Street performances and public art
   - Shopping from local boutiques to markets

EXAMPLE DAY STRUCTURE:
Day 1: "Historic Heart & Cultural Treasures"
- 09:00: Major museum POI (2 hours, €18)
- 11:30: Walk to historic square (15min walk)
- 11:45: Cathedral or monument POI (45min, €8)
- 12:45: Old town lunch at traditional restaurant (90min, €€)
- 14:30: Shopping street or market POI (60min, free)
- 15:45: Metro to modern district (15min, €2.50)
- 16:00: Contemporary art museum POI (90min, €15)
- 17:45: Walk to riverside park (10min)
- 18:00: River or park walk POI (45min, free)
- 19:00: Trendy neighborhood dinner (90min, €€€)

ROUTING TIPS:
- Group nearby attractions together
- Use efficient metro connections between districts
- Include walking time and transport costs
- Plan logical circular routes (return near accommodation)

CRITICAL: Create EXACTLY ${durationDays} days with diverse city exploration activities!`;
}
