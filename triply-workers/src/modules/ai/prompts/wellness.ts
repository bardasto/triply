/**
 * Wellness activity prompt
 * Focus on relaxation, spa, yoga, mindfulness, health retreats
 */

import { PromptParams } from './base-prompt.js';

export function getWellnessPrompt(params: PromptParams): string {
  const { durationDays } = params;

  return `
WELLNESS-SPECIFIC INSTRUCTIONS:
1. Daily Schedule Pattern:
   - Morning: Yoga or meditation session (wellness center POI)
   - Late morning: Spa treatment or massage (spa POI)
   - Lunch: Healthy, organic restaurant (1 restaurant)
   - Afternoon: Relaxation activity (thermal baths, nature walk - 2 POIs)
   - Late afternoon: Wellness workshop or therapy (wellness POI)
   - Evening: Light, nutritious dinner (1 restaurant)
   - Night: Relaxation or early rest

2. Focus on:
   - Spa and wellness centers
   - Yoga and meditation studios
   - Thermal baths and hot springs
   - Massage and therapy centers
   - Wellness retreats
   - Peaceful gardens and parks
   - Healthy restaurants and cafes
   - Meditation and mindfulness spots
   - Fitness and wellness activities
   - Natural healing locations

3. Each day should have:
   - 2-3 wellness treatments or activities
   - 3-5 POIs (spas, gardens, quiet spaces)
   - 2 restaurants (healthy, organic, vegetarian-friendly)
   - Balance of active and passive wellness
   - Relaxation and rejuvenation focus

4. Transportation notes:
   - Slow, mindful travel between locations
   - Walking or gentle cycling preferred
   - Spa/wellness center shuttles (often free)
   - Taxi for comfort and relaxation
   - Minimize rushing and stress

5. Price considerations:
   - Spa day pass (€40-80)
   - Massage treatments (€60-120 per session)
   - Yoga class (€15-25)
   - Thermal bath entry (€25-45)
   - Wellness workshops (€30-60)
   - Healthy restaurants (€€-€€€)
   - Meditation retreat (€100-300 per day)

6. Best times:
   - Morning yoga: 7:00-8:30 AM (energizing)
   - Spa treatments: 10:00-12:00 (relaxing)
   - Thermal baths: 15:00-18:00 (afternoon relaxation)
   - Meditation: sunset or evening (calming)
   - Early dinners: 18:00-19:00 (for better digestion)
   - Early bedtime for rest and recovery

7. Wellness focus areas:
   - Physical relaxation (massage, spa, baths)
   - Mental clarity (meditation, mindfulness)
   - Body movement (yoga, tai chi, gentle walks)
   - Nutrition (healthy eating, detox)
   - Nature connection (gardens, parks, natural springs)
   - Sleep and rest (proper routines)
   - Stress reduction
   - Digital detox

8. Wellness activities:
   - Hatha or Vinyasa yoga classes
   - Guided meditation sessions
   - Swedish or Thai massage
   - Aromatherapy treatments
   - Thermal bath soaking
   - Sauna and steam room
   - Facial and beauty treatments
   - Reflexology
   - Acupuncture or acupressure
   - Sound healing
   - Breathwork workshops
   - Nature bathing (Shinrin-yoku)
   - Healthy cooking classes

9. Mindful experiences:
   - Silent walking in gardens
   - Journaling in peaceful spots
   - Tea ceremonies
   - Gentle stretching
   - Gratitude practices
   - Creative workshops (art, pottery)
   - Reading and rest
   - Digital-free time

EXAMPLE DAY STRUCTURE:
Day 1: "Relaxation & Renewal"
- 07:30: Morning yoga session at wellness center (60min, €20)
- 08:45: Healthy breakfast at organic cafe (60min, €€)
- 10:00: Full body massage at spa POI (90min, €85)
- 12:00: Thermal bath and sauna experience (2 hours, day pass €45)
- 14:00: Light vegetarian lunch at wellness restaurant (75min, €€)
- 15:30: Meditation walk in botanical garden POI (60min, free entry)
- 16:45: Guided meditation session at meditation center (45min, €15)
- 17:45: Rest time at accommodation or quiet cafe
- 19:00: Wholesome dinner with fresh ingredients (90min, €€€)
- 21:00: Evening relaxation, early rest

WELLNESS DAY DETAILS:
- Focus: deep relaxation and stress relief
- Treatments: yoga, massage, thermal baths, meditation
- Meals: organic, plant-based options
- Pace: slow and mindful
- Total wellness time: 6+ hours
- Screen-free time: recommended throughout day

SPA & WELLNESS CENTER INFO:
- Name: Serenity Spa & Wellness
- Services: massage, facials, body treatments, thermal pools
- Day pass: €45 (includes thermal baths, sauna, relaxation area)
- Treatments: book in advance, 15min arrival before appointment
- Facilities: indoor/outdoor pools, steam room, sauna, meditation room
- Amenities: robes, slippers, towels provided
- Age: 16+ only (quiet environment)
- Etiquette: silence in relaxation areas

HEALTHY EATING FOCUS:
- Emphasize fresh, local, organic ingredients
- Plant-based or vegetarian options
- Mindful eating practices
- Smaller, lighter portions
- Hydration (water, herbal teas)
- Avoid heavy, processed foods
- Timing: eat earlier in evening

WELLNESS BENEFITS TO HIGHLIGHT:
- Stress reduction and mental clarity
- Physical tension release
- Improved sleep quality
- Enhanced mindfulness
- Body detoxification
- Renewed energy
- Emotional balance
- Connection with self and nature

WHAT TO BRING:
- Comfortable, loose clothing for yoga
- Swimsuit for thermal baths
- Journal for reflections
- Reusable water bottle
- Meditation cushion or mat (if personal preference)
- Light reading material
- Minimal makeup and natural products
- Open mind and willingness to relax

WELLNESS TIPS:
- Arrive early to treatments (15min before)
- Stay hydrated throughout the day
- Communicate with therapists about preferences
- Respect quiet zones and other guests
- Turn phone to silent or off
- Take time between activities (don't over-schedule)
- Listen to your body's needs
- Practice gratitude

CRITICAL: Create EXACTLY ${durationDays} days with balanced wellness experiences! Prioritize relaxation, mindfulness, and rejuvenation over tourist attractions.`;
}
