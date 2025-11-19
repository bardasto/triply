/**
 * Shopping activity prompt
 * Focus on retail therapy, markets, boutiques, shopping districts
 */

import { PromptParams } from './base-prompt.js';

export function getShoppingPrompt(params: PromptParams): string {
  const { durationDays } = params;

  return `
SHOPPING-SPECIFIC INSTRUCTIONS:
1. Daily Schedule Pattern:
   - Morning: Main shopping street or mall (2-3 shopping POIs)
   - Lunch: Cafe or restaurant in shopping district (1 restaurant)
   - Afternoon: Specialty boutiques or local markets (2-3 POIs)
   - Late afternoon: Department store or outlet (1-2 POIs)
   - Evening: Dinner near shopping area (1 restaurant)
   - Optional: Evening shopping (if stores open late)

2. Focus on:
   - Famous shopping streets and avenues
   - Luxury boutiques and designer stores
   - Local markets (flea markets, craft markets)
   - Department stores and shopping malls
   - Vintage and second-hand shops
   - Artisan workshops and studios
   - Outlet villages and factory stores
   - Specialty shops (books, music, crafts)
   - Souvenir shops (authentic, not touristy)
   - Fashion districts and trendy areas

3. Each day should have:
   - 5-7 shopping POIs (mix of streets, stores, markets)
   - 2 restaurants (shopping breaks)
   - Variety of shopping experiences (luxury, local, markets)
   - Balance of window shopping and actual purchases
   - Cultural shopping insights

4. Transportation notes:
   - Walking between shops in same district (best way to discover)
   - Metro to different shopping areas (€2-3)
   - Shopping bags - plan for carrying purchases
   - Delivery services to hotel (available at major stores)
   - Consider shopping tour (€40-60 with stylist)

5. Price considerations:
   - Luxury brands (€€€€)
   - Mid-range fashion (€€-€€€)
   - Local markets (€-€€)
   - Vintage/second-hand (€-€€)
   - Artisan crafts (€€)
   - Souvenirs (€-€€)
   - VAT refund for non-EU visitors (save 10-20%)
   - Sales seasons (January-February, July-August)

6. Best times:
   - Stores open: typically 10:00-20:00 (varies by country)
   - Markets: morning for best selection (8:00-14:00)
   - Lunch: 13:00-15:00 (avoid peak shopping time)
   - Late shopping: Thursdays often extended hours
   - Sunday: many shops closed (Europe) or open (US)
   - Sales periods: winter and summer
   - Avoid Saturday afternoons (most crowded)

7. Shopping tips:
   - Try before you buy
   - Know your sizes in local measurements
   - Check return policies
   - Keep receipts for VAT refund
   - Bargaining appropriate at markets (not boutiques)
   - Ask about student/senior discounts
   - Sign up for store cards at major retailers (discounts)
   - Bring reusable shopping bag

8. Shopping experiences:
   - Personal shopping services
   - Fashion district tours
   - Antique market browsing
   - Local craft workshops (make and buy)
   - Outlet shopping trips
   - Designer flagship stores
   - Independent boutiques
   - Concept stores
   - Pop-up shops and markets
   - Shopping with a local stylist

9. What to shop for:
   - Local fashion and designers
   - Artisan crafts and handmade items
   - Regional specialties (food, wine)
   - Antiques and vintage finds
   - Books and music (local)
   - Jewelry and accessories
   - Home decor and textiles
   - Art and prints
   - Beauty and cosmetics (local brands)
   - Souvenirs with meaning

EXAMPLE DAY STRUCTURE:
Day 1: "Chic Streets & Market Treasures"
- 10:00: Famous shopping avenue POI (2 hours, window shopping + purchases)
  * Luxury brand flagship stores
  * International fashion retailers
  * People watching and cafe culture
- 12:15: Designer concept store POI (45min, €€€)
  * Curated fashion selection
  * Unique pieces
- 13:00: Lunch at trendy shopping district cafe (90min, €€)
  * Fashion crowd-watching
  * Light, energizing meal
- 14:45: Local designer boutique district POI (90min, €€-€€€)
  * 3-4 independent boutiques
  * Emerging designers
  * Unique finds
- 16:30: Historic covered market POI (75min, €-€€)
  * Artisan crafts
  * Vintage items
  * Local food products
  * Bargaining opportunities
- 18:00: Department store POI (90min, €€-€€€)
  * Multiple brands under one roof
  * Beauty and cosmetics floor
  * Home goods section
- 19:45: Dinner at restaurant near shopping area (90min, €€€)
- 21:30: Evening stroll through lit-up shopping streets (optional, 45min)

SHOPPING DAY DETAILS:
- Districts visited: 3 (luxury avenue, designer area, historic market)
- Store types: luxury, mid-range, local, market, department
- Shopping style: mix of browsing and buying
- Total shopping time: 8+ hours
- Purchases: fashion, crafts, souvenirs, local products

SHOPPING DISTRICTS TO COVER:
- Main luxury shopping street (Champs-Élysées, Via Montenapoleone, Fifth Avenue style)
- Local designer neighborhoods (emerging fashion)
- Vintage and second-hand areas
- Artisan craft districts
- Market areas (flea markets, food markets, craft markets)

FEATURED STORES:
- Name and specialty
- What makes it unique
- Price range
- Must-see items or sections
- Celebrity designer connections
- Architectural or historical significance of store

MARKET GUIDE:
- Type: flea market, craft market, food market
- Days and hours of operation
- What to look for
- Bargaining tips (start at 60-70% of asking price)
- Cash vs. card acceptance
- Best time to visit for selection vs. deals
- Hidden gems and stalls to check

LOCAL DESIGNERS TO DISCOVER:
- Mention 2-3 local fashion designers or brands
- Where to find their boutiques
- Style and specialty
- Price point
- Why they're notable

VAT REFUND PROCESS:
- Available for non-EU visitors
- Minimum purchase: €100-175 (varies by country)
- Ask for tax-free forms at stores
- Get stamped at airport customs before check-in
- Refund options: cash, credit card, or mail
- Saves 10-20% on purchases

SALES AND DISCOUNTS:
- Winter sales: January-February
- Summer sales: July-August
- Outlet villages: 30-70% off year-round
- Student discounts: ask with ID
- Loyalty programs: free to join at major stores
- Newsletter sign-ups: often give first-purchase discount

WHAT TO BUY AS SOUVENIRS:
- Authentic local crafts (not mass-produced)
- Regional food products (olive oil, wine, cheese)
- Fashion from local designers
- Vintage finds from markets
- Art from local artists
- Books by local authors
- Traditional textiles or clothing items
- Handmade jewelry
- Beauty products (local brands)

FASHION SIZES CONVERSION:
- Provide clothing size chart for local country
- Shoe size conversions
- Jewelry sizing differences
- When in doubt, try it on

SHIPPING OPTIONS:
- Large items: many stores ship internationally
- Cost: varies, often 10-15% of purchase price
- Time: 1-3 weeks
- Insurance recommended for valuable items
- Or: buy foldable bag for extra luggage

SHOPPING ETIQUETTE:
- Greet staff when entering shops
- Ask before touching in boutiques
- Try-on policies (some limit number of items)
- Photography rules (ask permission)
- Tipping not expected in most countries
- Be respectful even if not buying

BUDGET SHOPPING OPTIONS:
- Outlet villages (30min outside city)
- Chain stores (H&M, Zara, Mango)
- Department store sales sections
- Flea markets for vintage
- Second-hand designer shops
- End-of-season clearance

LUXURY SHOPPING EXPERIENCE:
- Flagship stores of major brands
- Personal shopping services (often free)
- Private styling sessions
- Champagne and canapés
- Tax-free shopping facilitated
- Delivery to hotel
- VIP treatment

SUSTAINABLE SHOPPING:
- Support local artisans and designers
- Vintage and second-hand shops
- Eco-friendly brands
- Quality over quantity
- Timeless pieces vs. fast fashion
- Ethical production practices

WHAT TO BRING:
- Comfortable walking shoes (lots of standing/walking)
- Reusable shopping bags
- Passport (for VAT refund)
- Credit cards (often better exchange rates than cash)
- Photos of sizes or items you're looking for
- Measurements written down
- Empty suitcase space or foldable bag

SHOPPING STRATEGY:
- Scout in morning (note items and prices)
- Decide over lunch
- Return to purchase in afternoon
- Compare prices between stores
- Don't rush major purchases
- Try everything on
- Check for defects before buying
- Ask about return policies

POST-SHOPPING:
- Organize receipts for VAT refund
- Store purchases safely at hotel
- Consider shipping bulky items home
- Take photos of items for customs declaration (if needed)
- Update budget and spending tracker

CRITICAL: Create EXACTLY ${durationDays} days with varied SHOPPING experiences! Balance luxury, local, and market shopping. Include practical tips, local designers, and authentic purchases. Make it about discovery and cultural shopping, not just buying.`;
}
