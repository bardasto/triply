# Flexible AI Trip Generation

## Overview

The new flexible AI trip generation system allows users to create personalized trips from **any free-form query** without templates or hardcoded cities.

### Key Features

✅ **ANY City** - Not limited to predefined cities. Works with any city worldwide.
✅ **ANY Activity** - No fixed activity categories. AI understands any interest or theme.
✅ **ANY Duration** - Automatically extracts or defaults to sensible trip length.
✅ **Personalized** - AI creates unique itineraries tailored to user's specific request.
✅ **Dynamic Places** - Searches Google Places API in real-time for relevant locations.

## Architecture

```
User Query → Query Analyzer → Place Search → AI Itinerary Generator → Trip
     ↓              ↓               ↓                  ↓               ↓
"romantic      Extract:        Find places:      Create unique      Final
 weekend       - Paris         - romantic         personalized      trip
 in Paris"     - 2 days        restaurants       itinerary with    object
               - romantic      - sunset spots     descriptions
                               - couple
                                 activities
```

## Example Queries

The system understands **any** travel request:

### Romantic Trips
- "romantic weekend in Paris"
- "honeymoon trip to Santorini for 5 days"
- "anniversary dinner and spa in Budapest"

### Themed Adventures
- "anime Tokyo-style trip but in Berlin"
- "street photography tour in Amsterdam for 3 days"
- "Viking-themed adventure in Oslo"

### Activity-Focused
- "foodie weekend in Rome with pasta and wine"
- "cycling tour around Munich for 2 days"
- "mountain hiking escape near Innsbruck"

### Cultural & Educational
- "medieval history tour in Prague"
- "architecture-focused 4 days in Copenhagen"
- "art museum journey in Madrid"

### Special Interests
- "Christmas market trip in Vienna"
- "underground techno weekend in Berlin"
- "wine tasting weekend in Porto"

### Budget & Style
- "budget student trip in Krakow for 3 days"
- "luxury spa weekend in Budapest"
- "solo backpacking trip in Lisbon"

## API Endpoints

### Generate Trip

**POST** `/api/trips/generate`

```json
{
  "query": "romantic weekend in Paris"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "title": "Romantic Parisian Escape",
    "description": "...",
    "city": "Paris",
    "country": "France",
    "duration": "2 days",
    "duration_days": 2,
    "itinerary": [...],
    "images": [...],
    "_meta": {
      "original_query": "romantic weekend in Paris",
      "extracted_intent": {
        "city": "Paris",
        "durationDays": 2,
        "activities": ["romantic", "city exploration"],
        "vibe": ["romantic", "relaxing"]
      }
    }
  }
}
```

### Health Check

**GET** `/health`

```json
{
  "status": "ok",
  "timestamp": "2024-11-23T12:00:00Z",
  "service": "triply-ai-api"
}
```

## Running the System

### 1. Environment Variables

Ensure you have these in `triply-workers/.env`:

```bash
# OpenAI API Key (required)
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4
OPENAI_TEMPERATURE=0.7

# Google Places API Key (required)
GOOGLE_PLACES_API_KEY=AIza...

# Supabase (optional - for caching)
SUPABASE_URL=https://...
SUPABASE_SERVICE_ROLE_KEY=...

# Server Port
PORT=3000
```

### 2. Start the Server

```bash
cd triply-workers
npm install
npm run server
```

You should see:
```
═══════════════════════════════════════════════════════
🚀 Triply AI API Server
═══════════════════════════════════════════════════════
✓ Server running on http://localhost:3000
✓ Health check: http://localhost:3000/health
✓ Generate trip: POST http://localhost:3000/api/trips/generate
═══════════════════════════════════════════════════════
```

### 3. Test with curl

```bash
# Test 1: Romantic Paris
curl -X POST http://localhost:3000/api/trips/generate \
  -H "Content-Type: application/json" \
  -d '{"query": "romantic weekend in Paris"}'

# Test 2: Anime Berlin
curl -X POST http://localhost:3000/api/trips/generate \
  -H "Content-Type: application/json" \
  -d '{"query": "anime Tokyo-style trip but in Berlin for 5 days"}'

# Test 3: Food Rome
curl -X POST http://localhost:3000/api/trips/generate \
  -H "Content-Type: application/json" \
  -d '{"query": "foodie weekend in Rome with pasta and wine"}'
```

### 4. Run Flutter App

```bash
# Make sure backend is running on localhost:3000
flutter run
```

Then in the app:
1. Tap the AI chat icon
2. Type any query (e.g., "romantic weekend in Paris")
3. Wait for AI to generate your personalized trip!

## How It Works

### 1. Query Analysis

The `QueryAnalyzerService` uses GPT-4 to extract structured data from free-form text:

**Input:** `"anime Tokyo-style trip but in Berlin for 5 days"`

**Output:**
```json
{
  "city": "Berlin",
  "country": "Germany",
  "durationDays": 5,
  "activities": ["anime", "manga", "Japanese culture"],
  "vibe": ["pop culture", "alternative"],
  "specificInterests": ["anime", "manga", "cosplay"]
}
```

### 2. Dynamic Place Search

Based on extracted interests, the system searches Google Places:

For "anime" in Berlin, it searches:
- "anime shops in Berlin"
- "manga stores in Berlin"
- "Japanese restaurants in Berlin"
- "cosplay cafes in Berlin"
- "Japanese culture in Berlin"

### 3. AI Itinerary Generation

GPT-4 creates a personalized itinerary using:
- User's original query for context
- Extracted intent (city, activities, vibe)
- Real places from Google Places API
- Creative descriptions explaining why each place fits the request

### 4. Image Enhancement

System fetches:
- Hero image from Unsplash
- Photos for each place from Google Places
- City gallery images

## Benefits vs Template System

| Feature | Old (Template) | New (Flexible AI) |
|---------|---------------|-------------------|
| **Cities** | 30 hardcoded European cities | ANY city worldwide |
| **Activities** | 15 predefined templates | ANY activity/theme |
| **Duration** | Fixed 3 days | ANY duration |
| **Places** | Pre-seeded database | Real-time Google search |
| **Personalization** | Generic templates | Unique per query |
| **Creativity** | Limited by templates | Unlimited |

## Limitations & Future Improvements

### Current Limitations
- Google Places API rate limits (500ms delay between searches)
- Limited to 10 search queries per trip generation
- No caching of search results
- Images may be missing for some places

### Future Improvements
- [ ] Cache Google Places search results
- [ ] Support multi-city trips ("Paris and Rome in 7 days")
- [ ] Add user preferences (dietary restrictions, accessibility)
- [ ] Optimize search queries to reduce API calls
- [ ] Add conversation context (multi-turn refinement)
- [ ] Support itinerary editing and regeneration

## Troubleshooting

### "City not found"
- Make sure city name is spelled correctly
- AI will try to normalize (e.g., "Barselona" → "Barcelona")
- If it fails, try rephrasing with country name

### "Empty response from OpenAI"
- Check OPENAI_API_KEY is valid
- Check OpenAI API quota/billing
- Reduce query complexity

### "Google Places API error"
- Check GOOGLE_PLACES_API_KEY is valid
- Check Google Cloud billing is enabled
- Check API quota limits

### Server not starting
- Check all environment variables are set
- Run `npm install` to install dependencies
- Check port 3000 is not in use

## Development

### Adding New Features

The system is highly modular:

1. **Query Analysis** - Modify `query-analyzer.service.ts`
2. **Place Search** - Modify `flexible-trip-generator.service.ts` → `searchRelevantPlaces`
3. **Itinerary Generation** - Modify `flexible-trip-generator.service.ts` → `generateFlexibleItinerary`
4. **API Endpoints** - Modify `src/api/server.ts`

### Testing

```bash
# Run backend tests
cd triply-workers
npm test

# Test specific query
curl -X POST http://localhost:3000/api/trips/generate \
  -H "Content-Type: application/json" \
  -d '{"query": "YOUR_QUERY_HERE"}' | jq
```

## License

MIT
