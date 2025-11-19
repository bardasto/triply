/**
 * Skiing activity prompt
 * Focus on ski resorts, winter sports, alpine skiing
 */

import { PromptParams } from './base-prompt.js';

export function getSkiingPrompt(params: PromptParams): string {
  const { durationDays } = params;

  return `
SKIING-SPECIFIC INSTRUCTIONS:
1. Daily Schedule Pattern:
   - Early morning: Ski resort arrival and lift pass (resort base POI)
   - Morning: Ski runs on main slopes (2-3 slope areas)
   - Lunch: Mountain restaurant or ski lodge (1 restaurant)
   - Afternoon: More skiing or alternative winter activity (2-3 runs/areas)
   - Late afternoon: Après-ski location or spa (1 POI)
   - Evening: Resort village dinner (1 restaurant)

2. Focus on:
   - Ski resort slopes and lift systems
   - Beginner, intermediate, and advanced runs
   - Ski schools and equipment rental
   - Ski lifts (gondolas, chairlifts, T-bars)
   - Mountain restaurants and warming huts
   - Après-ski bars and entertainment
   - Alternative winter activities (snowboarding, sledding)
   - Spa and wellness facilities
   - Snow conditions and grooming

3. Each day should have:
   - 4-6 different ski runs or areas
   - 2 restaurants (mountain lunch and evening dinner)
   - Variety of run difficulties (green, blue, red, black)
   - Alternative activities for non-skiing times
   - Lift connections and resort layout

4. Transportation notes:
   - Hotel to ski resort shuttle (free or €5-10)
   - Ski lifts between areas (included in pass)
   - Gondola access to mountain (included in pass)
   - Walk between nearby slopes
   - Ski-in/ski-out options if available

5. Price considerations:
   - Daily lift pass (€45-65)
   - Multi-day pass discount (€200-300 for 5 days)
   - Ski equipment rental (€30-50 per day)
   - Ski lessons (€60-150 per session)
   - Mountain restaurant meals (€€-€€€)
   - Après-ski drinks (€10-20)
   - Locker rental (€5-10 per day)

6. Best times:
   - First tracks: 8:00-9:00 AM for fresh groomed snow
   - Morning: best snow conditions (9:00-12:00)
   - Lunch: 12:00-14:00 at mountain restaurant
   - Afternoon: 14:00-16:00 (watch for icy conditions)
   - Last run: 16:00-17:00 (lifts close around 16:30-17:00)
   - Après-ski: 16:30-19:00

7. Safety and equipment:
   - Helmet mandatory for beginners
   - Ski insurance recommended
   - Check avalanche warnings
   - Stay on marked runs
   - Ski level assessment (beginner/intermediate/advanced)
   - Weather and visibility conditions
   - Sunscreen and goggles essential

8. Run details to include:
   - Slope name and number
   - Difficulty: Green (easiest), Blue (easy), Red (intermediate), Black (advanced)
   - Length in km
   - Vertical drop in meters
   - Lift type and duration
   - Crowding level and best times

9. Alternative winter activities:
   - Snowboarding areas
   - Cross-country skiing trails
   - Snowshoeing routes
   - Sledding/tobogganing runs
   - Winter hiking trails
   - Ice skating rink
   - Spa and thermal baths
   - Snow park for tricks

EXAMPLE DAY STRUCTURE:
Day 1: "First Tracks & Mountain Discovery"
- 08:00: Resort base - lift pass and equipment (60min, day pass €55, rental €40)
- 09:00: Gondola to mid-station (15min, included in pass)
- 09:30: Blue run "Morning Glory" (2.5km, 20min, easy intermediate)
- 10:00: Chairlift to upper station (10min, included)
- 10:15: Red run "Alpine View" (3km, 25min, intermediate with views)
- 11:00: Same lift return + Green run "Beginner's Dream" (1.5km, 15min)
- 11:30: Ski school meeting point POI (if needed)
- 12:30: Mountain restaurant lunch with terrace (90min, €€€)
- 14:00: Explore different sector via connecting lift (15min)
- 14:30: Blue run "Forest Trail" (2km, 20min through trees)
- 15:15: Red run "Powder Bowl" (2.5km, 25min, more challenging)
- 16:00: Last run down to base - Blue "Sunset Run" (4km, 30min)
- 16:45: Après-ski bar at slope base POI (90min, drinks €15)
- 18:30: Return to accommodation (shuttle, 15min)
- 19:30: Traditional mountain restaurant dinner in village (90min, €€)

SKI DAY SUMMARY:
- Total skiing: 15.5 km across 6 runs
- Vertical descent: approximately 3,500m
- Lifts used: 5 different lifts
- Difficulty mix: 3 blue, 2 red, 1 green
- Suitable for: Intermediate skiers
- Ski time: approximately 4.5 hours

WEATHER CONDITIONS:
- Temperature: -5°C to 2°C
- Snow: fresh grooming overnight
- Visibility: excellent
- Wind: light
- Recommendation: perfect conditions for all levels

CRITICAL: Create EXACTLY ${durationDays} days with varied skiing experiences! Include different slopes, abilities, and après-ski activities.`;
}
