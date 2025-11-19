/**
 * Food activity prompt
 * Focus on culinary experiences, restaurants, food markets, gastronomy
 */

import { PromptParams } from './base-prompt.js';

export function getFoodPrompt(params: PromptParams): string {
  const { durationDays } = params;

  return `
FOOD-SPECIFIC INSTRUCTIONS:
1. Daily Schedule Pattern:
   - Morning: Food market or bakery visit (1-2 POIs)
   - Brunch: Local cafe or brunch spot (1 restaurant)
   - Midday: Cooking class or food tour (culinary POI)
   - Lunch: Traditional restaurant (1 restaurant)
   - Afternoon: Specialty food shops or wine tasting (2-3 POIs)
   - Evening: Fine dining or unique culinary experience (1 restaurant)

2. Focus on:
   - Renowned restaurants (Michelin-starred, local favorites)
   - Food markets and fresh produce
   - Specialty food shops (cheese, wine, chocolate, etc.)
   - Cooking classes and culinary workshops
   - Food tours and tastings
   - Local bakeries and patisseries
   - Wine cellars and breweries
   - Street food and food trucks
   - Farm-to-table experiences
   - Regional cuisine specialties

3. Each day should have:
   - 3-4 restaurant experiences (breakfast/brunch, lunch, dinner)
   - 3-5 food-related POIs (markets, shops, classes)
   - Variety of culinary styles and price points
   - Focus on authentic local flavors
   - Explanation of dishes and ingredients

4. Transportation notes:
   - Walking between restaurants in food districts
   - Metro to different culinary neighborhoods (€2-3)
   - Food tour with guide (walking, includes transport if needed)
   - Consider food coma and need for leisurely travel

5. Price considerations:
   - Local markets and street food (€-€€)
   - Casual dining (€€)
   - Fine dining experiences (€€€-€€€€)
   - Cooking classes (€60-120)
   - Food tours (€50-100)
   - Wine tastings (€20-40)
   - Specialty products to take home (€20-100)
   - Budget mix: high and low for variety

6. Best times:
   - Markets: early morning (7:00-10:00) for freshest products
   - Breakfast/brunch: 9:00-11:00
   - Lunch: local schedule (12:00-15:00 in Spain, 12:30-14:00 in France)
   - Cooking classes: morning or afternoon sessions
   - Dinner reservations: book weeks in advance for top restaurants
   - Wine tastings: afternoon (15:00-18:00)
   - Street food: evening for atmosphere

7. Culinary focus:
   - Regional specialties and signature dishes
   - Seasonal ingredients and menus
   - Traditional cooking techniques
   - Modern culinary innovations
   - Wine and food pairings
   - Local food history and culture
   - Sustainable and organic practices
   - Chef stories and restaurant backgrounds

8. Food experiences:
   - Market tours with tastings
   - Cooking classes with local chefs
   - Wine and cheese pairings
   - Olive oil or balsamic vinegar tastings
   - Chocolate or pastry workshops
   - Farm visits and food production
   - Multi-course tasting menus
   - Street food tours
   - Food and wine festivals (seasonal)
   - Meeting local food artisans

9. Culinary education:
   - Learn about local ingredients
   - Understand regional cuisine history
   - Cooking techniques and recipes
   - Food and culture connections
   - Wine production and regions
   - Seasonal eating
   - Food sustainability

EXAMPLE DAY STRUCTURE:
Day 1: "Gastronomic Discovery & Market Flavors"
- 08:30: Central food market POI (90min, free entry + purchases €20)
  * Fresh produce section
  * Artisan cheese vendor
  * Local charcuterie
  * Market breakfast: coffee and pastry
- 10:15: Artisan bakery POI (30min, tastings €8)
- 11:00: Traditional brunch at local bistro (90min, €€)
  * Regional specialties
  * Fresh ingredients from morning market
- 13:00: Walk to cooking school (20min)
- 13:30: Cooking class POI - make traditional dish (3 hours, €95)
  * Learn regional recipe
  * Hands-on preparation
  * Lunch included (eat what you cook)
- 16:45: Wine shop POI - sommelier-guided tasting (60min, €25)
  * 5 regional wines
  * Cheese pairings
  * Learn about local wine regions
- 18:00: Chocolate atelier POI (45min, tastings €12)
- 19:00: Rest and preparation for dinner
- 20:00: Fine dining restaurant (2.5 hours, €€€€)
  * Michelin-starred or renowned chef
  * Tasting menu (6-8 courses)
  * Wine pairings (optional +€60)
  * Focus on seasonal, local ingredients

CULINARY DAY DETAILS:
- Total meals: 4 (market snacks, brunch, cooking class lunch, fine dinner)
- Food experiences: 6 (market, bakery, cooking class, wine tasting, chocolate, dinner)
- Culinary learning: cooking class + wine education
- Price range: mix of budget (market) to luxury (fine dining)
- Total food time: 10+ hours

RESTAURANT RECOMMENDATIONS:
- Include specific signature dishes
- Chef background and philosophy
- Reservation requirements (weeks in advance for top spots)
- Dress code (if any)
- Dietary accommodations available
- Average meal duration
- Why this restaurant is special

MARKET GUIDE:
- Best stalls and vendors to visit
- What to taste and buy
- Interaction tips with vendors
- Learn key food vocabulary in local language
- Bargaining etiquette (if applicable)
- Peak times vs. quiet times

COOKING CLASS DETAILS:
- Type: hands-on traditional cooking
- Group size: 8-12 people
- Duration: 3 hours
- Menu: 3-course regional meal
- What you'll learn: techniques, recipes, ingredients
- Includes: all ingredients, wine, recipe book to take home
- Skill level: all levels welcome
- Language: English available

WINE TASTING NOTES:
- Region and terroir explanation
- Grape varieties
- Tasting technique
- Food pairing suggestions
- Winemaker stories
- Opportunity to purchase
- Learn to read wine labels

SIGNATURE DISHES TO TRY:
- List 3-5 must-try local dishes per day
- Explain ingredients and preparation
- Historical or cultural significance
- Where to find the best version
- Vegetarian/dietary alternatives

FOOD VOCABULARY:
- Key terms in local language
- How to order and ask questions
- Understanding menu items
- Dietary restrictions communication
- Complimenting the chef/meal

DIETARY CONSIDERATIONS:
- Vegetarian and vegan options (growing in all cities)
- Gluten-free alternatives available
- Allergies: communicate clearly with restaurants
- Religious dietary laws (halal, kosher) availability
- Most fine dining accommodates restrictions with advance notice

FOODIE TIPS:
- Reserve top restaurants 2-4 weeks ahead
- Lunch menus often better value than dinner
- Markets are authentic and budget-friendly
- Don't skip street food - often incredible
- Ask locals for recommendations
- Try dishes you've never heard of
- Share plates to taste more variety
- Pace yourself - it's a marathon not a sprint!

WHAT TO BRING:
- Appetite and open mind
- Camera for food photos
- Notebook for favorite dishes and restaurants
- Comfortable shoes (lots of walking between meals)
- Loose clothing (you'll eat a lot!)
- Reusable bag for market purchases
- Cash for small vendors

TAKE HOME:
- Local spices and ingredients
- Artisan products (cheese, wine, olive oil)
- Recipe books
- Food souvenirs
- Cooking techniques and knowledge

CRITICAL: Create EXACTLY ${durationDays} days focused on CULINARY EXPERIENCES! Each day should be a gastronomic journey with 3-4 meal experiences plus food-related activities. Include specific dishes, ingredients, and explain the food culture.`;
}
