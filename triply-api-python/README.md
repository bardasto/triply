# Triply API v2.0 - ReAct Agent Trip Planner

Multi-Agent Trip Generation Service using LangGraph ReAct agents.

## Features

- **True ReAct Agent**: Autonomous reasoning with Think → Act → Observe loop
- **Any Theme Support**: Anime, romantic, vegan, adults-only, adventure - ANY theme works
- **Smart Tool Use**: Agent decides when to use Google Places, Web Search, etc.
- **SSE Streaming**: Real-time updates as the agent thinks and plans
- **Conversation Memory**: Continue conversations with thread_id

## Quick Start

```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
pip install -e .

# Copy env file and add your API keys
cp .env.example .env

# Run the server
python -m src.main
```

## API Endpoints

### POST /generate
Generate a trip (non-streaming)

```bash
curl -X POST http://localhost:3001/generate \
  -H "Content-Type: application/json" \
  -d '{"query": "3 days in Tokyo for anime lovers"}'
```

### POST /generate/stream
Generate with SSE streaming

```bash
curl -X POST http://localhost:3001/generate/stream \
  -H "Content-Type: application/json" \
  -d '{"query": "romantic weekend in Paris"}'
```

## How It Works

The ReAct agent follows this process:

1. **Think**: Parse user's request, understand destination, duration, theme
2. **Act**: Use tools (Google Places, Web Search) to gather information
3. **Observe**: Analyze results from tools
4. **Repeat**: Continue thinking and acting until enough info gathered
5. **Respond**: Create detailed day-by-day itinerary

## Available Tools

- `search_places`: Search Google Places for restaurants, attractions, etc.
- `get_place_details`: Get detailed info about a specific place
- `web_search`: Search web for local tips, current events, niche interests
- `get_destination_info`: Get comprehensive destination information

## Example Queries

- "3 days in Tokyo for anime lovers with maid cafes and Akihabara"
- "Romantic weekend in Paris with vegan restaurants and hidden gems"
- "5 day adventure in Iceland with hiking, hot springs, and northern lights"
- "Adults only nightlife trip to Bratislava with best clubs and bars"
- "Family friendly 4 days in Barcelona with kids activities"

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| GOOGLE_API_KEY | Yes | Google AI (Gemini) API key |
| GOOGLE_PLACES_API_KEY | No | Google Places API key (falls back to GOOGLE_API_KEY) |
| TAVILY_API_KEY | No | Tavily API key for web search (recommended) |
| PORT | No | Server port (default: 3001) |
| ENV | No | Environment: development/production |
