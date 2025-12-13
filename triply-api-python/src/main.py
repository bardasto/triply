"""
Triply API - Multi-Agent Trip Generation Service

FastAPI application with ReAct agent for intelligent trip planning.
"""

import json
import uuid
import re
import random
import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from langgraph.checkpoint.memory import MemorySaver

from .config import settings
from .agents import generate_trip, stream_trip_generation
from .agents.multi_agent import generate_trip_multi_agent
from .agents.multi_agent.places_agent import get_place_prices
from .agents.multi_agent.state import PlaceData
from .agents.multi_agent.modification_agent import (
    ModificationAgent,
    ModificationAnalysis,
    ModificationType,
)
from .logging import setup_logging, get_logger, RequestLoggingMiddleware
from .logging.logger import SSELogger

# Initialize logging
setup_logging()
logger = get_logger("main")

# In-memory storage for pending trips (for SSE streaming)
pending_trips: dict[str, dict] = {}

# Global checkpointer for conversation memory
checkpointer = MemorySaver()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler"""
    logger.info("Starting Triply API", port=settings.port, env=settings.env)
    yield
    logger.info("Shutting down Triply API")


app = FastAPI(
    title="Triply API",
    description="Multi-Agent Trip Generation Service - Production-Ready Architecture",
    version="3.0.0",
    lifespan=lifespan,
)

# Request logging middleware (must be added before CORS)
app.add_middleware(RequestLoggingMiddleware)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:3001",
        "http://localhost:5173",
        "https://toogo.travel",
        "https://www.toogo.travel",
        "https://toogo-web.vercel.app",
        "https://triply-web.vercel.app",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─────────────────────────────────────────────────────────────────────────────
# Request/Response Models
# ─────────────────────────────────────────────────────────────────────────────


class GenerateRequest(BaseModel):
    """Request body for trip generation"""

    query: str = Field(description="User's trip request in natural language")
    thread_id: str | None = Field(default=None, description="Optional thread ID for conversation memory")


class GenerateResponse(BaseModel):
    """Response for trip generation"""

    success: bool
    execution_id: str
    thread_id: str | None = None
    response: str | None = None
    error: str | None = None
    tool_calls: list[dict] = []


class HealthResponse(BaseModel):
    """Health check response"""

    name: str
    version: str
    status: str
    description: str
    endpoints: dict


# ─────────────────────────────────────────────────────────────────────────────
# Health & Info Endpoints
# ─────────────────────────────────────────────────────────────────────────────


@app.get("/", response_model=HealthResponse)
async def health_check():
    """Health check and API info"""
    return {
        "name": "Triply API",
        "version": "3.1.0",
        "status": "running",
        "description": "Multi-Agent Trip Generation Service with Smart Modifications",
        "endpoints": {
            "health": "GET /",
            "generate": "POST /generate",
            "stream": "POST /generate/stream",
            "frontend_stream": "POST /api/trips/generate/stream",
            "modify": "POST /api/trips/modify",
            "analyze": "POST /api/trips/analyze-request",
            "docs": "GET /docs",
        },
    }


# ─────────────────────────────────────────────────────────────────────────────
# Trip Generation Endpoints
# ─────────────────────────────────────────────────────────────────────────────


@app.post("/generate", response_model=GenerateResponse)
async def generate_trip_endpoint(request: GenerateRequest):
    """
    Generate a trip itinerary using the ReAct agent.

    The agent will:
    1. Parse your request to understand destination, duration, and preferences
    2. Search the web for local tips and recommendations
    3. Find relevant places using Google Places
    4. Create a personalized day-by-day itinerary

    Examples:
    - "3 days in Tokyo for anime lovers"
    - "Romantic weekend in Paris with vegan restaurants"
    - "5 day adventure trip in Iceland with hiking and hot springs"
    - "Adults only nightlife trip to Bratislava"
    """
    if not request.query or len(request.query.strip()) < 3:
        raise HTTPException(status_code=400, detail="Query must be at least 3 characters")

    logger.info("Generate request received", query=request.query)

    result = await generate_trip(
        query=request.query,
        thread_id=request.thread_id,
        checkpointer=checkpointer,
    )

    return GenerateResponse(
        success=result.get("success", False),
        execution_id=result.get("execution_id", ""),
        thread_id=result.get("thread_id"),
        response=result.get("response"),
        error=result.get("error"),
        tool_calls=result.get("tool_calls", []),
    )


@app.post("/generate/stream")
async def generate_trip_stream(request: GenerateRequest):
    """
    Generate a trip with SSE streaming.

    Events are streamed as the agent thinks and uses tools:
    - start: Generation started
    - thinking: Agent reasoning
    - tool_start: Tool invocation started
    - tool_end: Tool invocation completed
    - complete: Final response ready
    - error: Error occurred
    """
    if not request.query or len(request.query.strip()) < 3:
        raise HTTPException(status_code=400, detail="Query must be at least 3 characters")

    logger.info("Stream request received", query=request.query)

    async def event_generator():
        async for event in stream_trip_generation(
            query=request.query,
            thread_id=request.thread_id,
            checkpointer=checkpointer,
        ):
            yield f"data: {json.dumps(event)}\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
        },
    )


# ─────────────────────────────────────────────────────────────────────────────
# Frontend-Compatible Streaming Endpoints
# ─────────────────────────────────────────────────────────────────────────────


class FrontendGenerateRequest(BaseModel):
    """Request body compatible with triply-web frontend"""
    query: str
    conversationContext: list[dict] | None = None
    currentTrip: dict | None = None  # For modification detection


class ModifyTripRequest(BaseModel):
    """Request body for trip modification"""
    query: str
    trip: dict
    conversationContext: list[dict] | None = None


class ModifyTripResponse(BaseModel):
    """Response for trip modification"""
    success: bool
    data: dict | None = None
    error: str | None = None
    modificationType: str | None = None
    estimatedTimeMs: int = 0


def enhance_place_with_cached_data(place: dict, place_cache: dict, is_restaurant: bool = False) -> dict:
    """
    Enhance a place from agent response with cached Google Places data.
    Adds photos and coordinates from the cache.

    For restaurants: also adds price_range from Google's price_level
    For places: keeps the agent's price (real ticket price from web search)
    """
    place_id = place.get("place_id")
    if not place_id or place_id not in place_cache:
        return place

    cached = place_cache[place_id]

    # Add photo URLs (up to 7)
    if cached.photo_urls:
        place["images"] = [{"url": url, "source": "google_places"} for url in cached.photo_urls]
        place["image_url"] = cached.photo_urls[0] if cached.photo_urls else None

    # For restaurants: add price_range from Google's price_level
    # For places: keep the agent's "price" (real ticket prices from web search)
    if is_restaurant and cached.price_level is not None:
        place["price_value"] = cached.price_level
        price_symbols = ["Free", "$", "$$", "$$$", "$$$$"]
        # Only set price_range if not already set by agent
        if not place.get("price_range"):
            place["price_range"] = price_symbols[cached.price_level] if cached.price_level < len(price_symbols) else "$$"

    # Ensure coordinates are present
    if cached.location:
        place["latitude"] = place.get("latitude") or cached.location.get("lat")
        place["longitude"] = place.get("longitude") or cached.location.get("lng")

    # Add opening hours
    if cached.opening_hours:
        place["opening_hours"] = cached.opening_hours

    # Add additional data
    if cached.website:
        place["website"] = cached.website
    if cached.user_ratings_total:
        place["reviews"] = cached.user_ratings_total

    return place


def parse_trip_from_response(response: str, query: str, place_cache: dict = None) -> dict:
    """
    Parse the agent's JSON response into structured trip data.
    Enhances places with cached Google Places data (photos, prices, etc.)
    Agent MUST return valid JSON - no fallback parsing.
    """
    place_cache = place_cache or {}
    trip_id = str(uuid.uuid4())

    # Clean up response - remove any markdown code blocks if present
    json_str = response.strip()

    # Remove ```json wrapper if present
    if json_str.startswith("```"):
        json_match = re.search(r'```(?:json)?\s*([\s\S]*?)\s*```', json_str)
        if json_match:
            json_str = json_match.group(1)

    # Try to extract JSON object if there's text around it
    if not json_str.startswith("{"):
        json_match = re.search(r'(\{[\s\S]*\})', json_str)
        if json_match:
            json_str = json_match.group(1)

    try:
        parsed = json.loads(json_str)

        # Validate required fields
        if "days" not in parsed or not isinstance(parsed["days"], list):
            raise ValueError("Missing or invalid 'days' field")

        # Enhance places and restaurants with cached data (photos, coordinates)
        for day in parsed.get("days", []):
            # Enhance places (keep agent's price - real ticket prices)
            day["places"] = [
                enhance_place_with_cached_data(p, place_cache, is_restaurant=False)
                for p in day.get("places", [])
            ]
            # Enhance restaurants (add price_range from Google's price_level)
            day["restaurants"] = [
                enhance_place_with_cached_data(r, place_cache, is_restaurant=True)
                for r in day.get("restaurants", [])
            ]

        total_places = sum(len(d.get("places", [])) for d in parsed["days"])
        total_restaurants = sum(len(d.get("restaurants", [])) for d in parsed["days"])

        logger.info(
            "trip_parsed",
            success=True,
            city=parsed.get("city"),
            days_count=len(parsed["days"]),
            total_places=total_places,
            total_restaurants=total_restaurants,
            cached_places_used=len(place_cache),
        )

        return {
            "tripId": trip_id,
            "title": parsed.get("title", f"Trip to {parsed.get('city', 'Unknown')}"),
            "description": parsed.get("description", ""),
            "city": parsed.get("city", "Unknown"),
            "country": parsed.get("country", "Unknown"),
            "durationDays": parsed.get("durationDays", len(parsed["days"])),
            "theme": parsed.get("theme"),
            "days": parsed["days"],
            "rawResponse": response,
        }

    except (json.JSONDecodeError, ValueError, KeyError, TypeError) as e:
        logger.error(
            "trip_parse_failed",
            error=str(e),
            response_preview=response[:500] if response else "empty",
        )
        # Return error structure instead of failing silently
        raise ValueError(f"Failed to parse trip JSON: {e}")


class ShortMessageContext(BaseModel):
    """Context for short message generation"""
    query: str | None = None
    city: str | None = None
    country: str | None = None
    tripTitle: str | None = None
    duration: int | None = None


class ShortMessageRequest(BaseModel):
    """Request for short message generation"""
    type: str  # 'intro' or 'completion'
    context: ShortMessageContext


@app.post("/api/chat/short-message")
async def short_message(request: ShortMessageRequest):
    """Generate a short message for the chat - used by frontend for intro and completion messages"""
    city = request.context.city or "your destination"
    duration = request.context.duration or 3

    if request.type == "intro":
        # Intro messages when trip generation starts
        if city and city != "your destination":
            messages = [
                f"Alright, let me dive into {city} and find the most amazing spots for you. I'm searching through local favorites, hidden gems, and must-see attractions to craft something special...",
                f"Great choice! I'm now exploring {city} to put together the perfect itinerary. Give me a moment while I search for the best restaurants, attractions, and experiences...",
                f"{city} is an incredible destination! Let me search through hundreds of places to find the perfect mix of culture, food, and memorable experiences for your trip...",
                f"On it! I'm scanning through {city}'s best spots right now — from iconic landmarks to those hidden places only locals know about. This is going to be good...",
            ]
        else:
            messages = [
                "Let me work on this for you. I'm analyzing your request and searching through thousands of places to find exactly what you're looking for...",
                "Great request! Give me a moment while I search through local favorites, hidden gems, and must-see attractions to craft something special for you...",
                "I'm on it! Searching through the best restaurants, attractions, and experiences to put together the perfect itinerary for you...",
            ]
    else:
        # Completion messages when trip is ready
        messages = [
            f"And here we go! I've put together a {duration}-day adventure in {city} that I think you're going to love. Take a look and let me know if you'd like me to adjust anything!",
            f"Your {city} trip is ready! I've curated a mix of must-see spots and some unique experiences. Feel free to ask if you want to swap anything or add more activities.",
            f"Done! Here's your personalized {city} itinerary. I've balanced the days to give you a great mix of exploration and relaxation. What do you think?",
            f"All set! I've crafted a {duration}-day journey through {city} with carefully selected spots. Let me know if this looks good or if you'd like any changes!",
        ]

    message = random.choice(messages)

    return {
        "success": True,
        "data": {
            "message": message
        }
    }


# Initialize modification agent
modification_agent = ModificationAgent()


@app.post("/api/trips/modify", response_model=ModifyTripResponse)
async def modify_trip(request: ModifyTripRequest):
    """
    Modify an existing trip without full regeneration.

    Supports:
    - Budget modifications (cheaper, free, luxury)
    - Type filtering (remove/keep specific types)
    - Day operations (add/remove days)
    - Place/restaurant replacement
    - Semantic modifications (more romantic, family-friendly, etc.)
    """
    if not request.query:
        raise HTTPException(status_code=400, detail="Query is required")

    if not request.trip or not request.trip.get("days"):
        raise HTTPException(status_code=400, detail="Valid trip data is required")

    logger.info(
        "Modification request received",
        query=request.query[:100],
        trip_city=request.trip.get("city"),
        days_count=len(request.trip.get("days", [])),
    )

    try:
        # Analyze the modification request
        analysis = await modification_agent.analyze_request(
            request=request.query,
            current_trip=request.trip,
            conversation_context=request.conversationContext,
        )

        logger.info(
            "Modification analysis complete",
            type=analysis.type.value,
            confidence=analysis.confidence,
            requires_search=analysis.requires_search,
        )

        # If not a modification, return appropriate response
        if analysis.type == ModificationType.NOT_MODIFICATION:
            return ModifyTripResponse(
                success=False,
                error="This request appears to be for a new trip, not a modification",
                modificationType=analysis.type.value,
            )

        # Apply the modification
        modified_trip = await modification_agent.apply_modification(
            trip=request.trip,
            analysis=analysis,
        )

        return ModifyTripResponse(
            success=True,
            data={
                "trip": modified_trip,
                "message": f"Trip modified successfully: {analysis.description}",
            },
            modificationType=analysis.type.value,
            estimatedTimeMs=analysis.estimated_time_ms,
        )

    except Exception as e:
        logger.error("Modification failed", error=str(e))
        return ModifyTripResponse(
            success=False,
            error=str(e),
        )


@app.post("/api/trips/analyze-request")
async def analyze_request(request: ModifyTripRequest):
    """
    Analyze a user request to determine if it's a modification or new trip.
    Frontend can use this to decide which endpoint to call.
    """
    if not request.query:
        raise HTTPException(status_code=400, detail="Query is required")

    try:
        analysis = await modification_agent.analyze_request(
            request=request.query,
            current_trip=request.trip,
            conversation_context=request.conversationContext,
        )

        return {
            "success": True,
            "data": {
                "isModification": analysis.type != ModificationType.NOT_MODIFICATION,
                "modificationType": analysis.type.value,
                "confidence": analysis.confidence,
                "requiresSearch": analysis.requires_search,
                "estimatedTimeMs": analysis.estimated_time_ms,
                "description": analysis.description,
            }
        }

    except Exception as e:
        logger.error("Analysis failed", error=str(e))
        return {
            "success": False,
            "error": str(e),
        }


@app.post("/api/trips/generate")
async def frontend_generate_non_streaming(request: FrontendGenerateRequest):
    """
    Non-streaming trip generation endpoint.
    Used by chat for non-trip queries or when streaming is not needed.
    """
    if not request.query or len(request.query.strip()) < 3:
        raise HTTPException(status_code=400, detail="Query must be at least 3 characters")

    try:
        # Generate trip using multi-agent system
        result = await generate_trip_multi_agent(query=request.query)

        if not result.get("success"):
            return {
                "success": False,
                "error": {
                    "message": result.get("error", "Unknown error"),
                    "code": "GENERATION_FAILED",
                }
            }

        # Get trip data
        trip_data = result.get("trip", {})

        # Build response in expected format
        return {
            "success": True,
            "type": "trip",
            "data": {
                "id": str(uuid.uuid4()),
                "type": "trip",
                "title": trip_data.get("title", "Your Trip"),
                "description": trip_data.get("description", ""),
                "city": trip_data.get("city", ""),
                "country": trip_data.get("country", ""),
                "duration": f"{trip_data.get('durationDays', 3)} days",
                "duration_days": trip_data.get("durationDays", 3),
                "itinerary": [
                    {
                        "day": day.get("dayNumber"),
                        "title": day.get("title", f"Day {day.get('dayNumber')}"),
                        "description": day.get("description", ""),
                        "places": day.get("places", []),
                        "restaurants": day.get("restaurants", []),
                    }
                    for day in trip_data.get("days", [])
                ],
                "images": [],
                "hero_image_url": None,
            }
        }

    except Exception as e:
        logger.error("Non-streaming generation failed", error=str(e))
        return {
            "success": False,
            "error": {
                "message": str(e),
                "code": "GENERATION_ERROR",
            }
        }


@app.post("/api/trips/generate/stream")
async def frontend_generate_stream(request: FrontendGenerateRequest):
    """
    Frontend-compatible endpoint that starts trip generation.
    Returns tripId and streamUrl for SSE connection.

    If currentTrip is provided, automatically detects if this is a modification
    request and routes appropriately.
    """
    if not request.query or len(request.query.strip()) < 3:
        raise HTTPException(status_code=400, detail="Query must be at least 3 characters")

    trip_id = str(uuid.uuid4())

    # Check if this might be a modification request
    is_modification = False
    modification_analysis = None

    if request.currentTrip and request.currentTrip.get("days"):
        # Analyze the request to determine if it's a modification
        try:
            modification_analysis = await modification_agent.analyze_request(
                request=request.query,
                current_trip=request.currentTrip,
                conversation_context=request.conversationContext,
            )

            if (modification_analysis.type != ModificationType.NOT_MODIFICATION
                and modification_analysis.confidence >= 0.7):
                is_modification = True
                logger.info(
                    "Modification detected in stream request",
                    type=modification_analysis.type.value,
                    confidence=modification_analysis.confidence,
                )
        except Exception as e:
            logger.error("Modification detection failed", error=str(e))

    # Store the pending request with modification info
    pending_trips[trip_id] = {
        "query": request.query,
        "status": "pending",
        "is_modification": is_modification,
        "modification_analysis": modification_analysis,
        "current_trip": request.currentTrip if is_modification else None,
    }

    logger.info(
        "Frontend stream request",
        trip_id=trip_id,
        query=request.query,
        is_modification=is_modification,
    )

    return {
        "success": True,
        "data": {
            "tripId": trip_id,
            "streamUrl": f"/api/trips/{trip_id}/stream",
            "isModification": is_modification,
            "modificationType": modification_analysis.type.value if modification_analysis else None,
            "estimatedTimeMs": modification_analysis.estimated_time_ms if modification_analysis else None,
        }
    }


@app.get("/api/trips/{trip_id}/stream")
async def frontend_trip_stream(trip_id: str):
    """
    SSE stream for trip generation progress.
    Emits events compatible with triply-web frontend.

    Handles both new trip generation and modifications based on
    the pending_trips data.
    """
    if trip_id not in pending_trips:
        raise HTTPException(status_code=404, detail="Trip not found")

    trip_data = pending_trips[trip_id]
    query = trip_data["query"]
    is_modification = trip_data.get("is_modification", False)
    modification_analysis = trip_data.get("modification_analysis")
    current_trip = trip_data.get("current_trip")

    async def event_generator():
        # Handle modification path
        if is_modification and modification_analysis and current_trip:
            async for event in _stream_modification(
                trip_id, query, modification_analysis, current_trip
            ):
                yield event
            return

        # Handle new trip generation
        async for event in _stream_new_trip(trip_id, query):
            yield event

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


async def _stream_modification(
    trip_id: str,
    query: str,
    analysis: ModificationAnalysis,
    current_trip: dict,
):
    """
    Stream granular modification events for smooth UI animations.

    Instead of re-streaming the entire trip, we send:
    - modification_start: Signals modification beginning
    - place_remove: Animated removal of a place
    - place_add: Animated addition of a new place
    - restaurant_remove: Animated removal of a restaurant
    - restaurant_add: Animated addition of a restaurant
    - day_remove: Animated removal of a day
    - day_add: Animated addition of a day
    - modification_complete: Final state with full trip
    """
    sse_logger = SSELogger(trip_id)
    sse_logger.stream_start()

    try:
        # Send modification_start event
        # Note: Frontend expects data in a nested "data" field
        start_event = {
            "phase": "modification_start",
            "progress": 0.1,
            "data": {
                "isModification": True,
                "modificationType": analysis.type.value,
                "description": analysis.description,
            },
        }
        sse_logger.event("modification_start", f"Modification: {analysis.type.value}")
        yield f"event: modification_start\ndata: {json.dumps(start_event)}\n\n"

        # Capture original state for diff calculation
        original_places_by_day = {}
        original_restaurants_by_day = {}
        original_day_numbers = set()

        for day in current_trip.get("days", []):
            day_num = day.get("dayNumber")
            original_day_numbers.add(day_num)
            original_places_by_day[day_num] = {
                p.get("place_id") or p.get("poi_id") or f"{day_num}-{i}"
                for i, p in enumerate(day.get("places", []))
            }
            original_restaurants_by_day[day_num] = {
                r.get("place_id") or r.get("poi_id") or f"{day_num}-r-{i}"
                for i, r in enumerate(day.get("restaurants", []))
            }

        # Apply the modification
        logger.info(
            "Applying modification in stream",
            trip_id=trip_id,
            type=analysis.type.value,
        )

        modified_trip = await modification_agent.apply_modification(
            trip=current_trip.copy(),  # Work on copy
            analysis=analysis,
        )

        progress = 0.2

        # Calculate diffs and stream granular events
        new_day_numbers = {d.get("dayNumber") for d in modified_trip.get("days", [])}

        # Stream day removals (animate out)
        removed_days = original_day_numbers - new_day_numbers
        for day_num in sorted(removed_days, reverse=True):
            remove_event = {
                "phase": "day_remove",
                "progress": progress,
                "data": {"dayNumber": day_num},
            }
            sse_logger.event("day_remove", f"Removing Day {day_num}")
            yield f"event: day_remove\ndata: {json.dumps(remove_event)}\n\n"
            progress = min(progress + 0.05, 0.9)
            # Small delay for animation
            await asyncio.sleep(0.3)

        # Stream place/restaurant changes per day
        for day in modified_trip.get("days", []):
            day_num = day.get("dayNumber")

            # Get current places/restaurants with IDs
            current_places = {
                p.get("place_id") or p.get("poi_id") or f"{day_num}-{i}": (i, p)
                for i, p in enumerate(day.get("places", []))
            }
            current_restaurants = {
                r.get("place_id") or r.get("poi_id") or f"{day_num}-r-{i}": (i, r)
                for i, r in enumerate(day.get("restaurants", []))
            }

            original_place_ids = original_places_by_day.get(day_num, set())
            original_restaurant_ids = original_restaurants_by_day.get(day_num, set())

            # Stream place removals (animate out first)
            removed_place_ids = original_place_ids - set(current_places.keys())
            for place_id in removed_place_ids:
                remove_event = {
                    "phase": "place_remove",
                    "progress": progress,
                    "data": {
                        "dayNumber": day_num,
                        "placeId": place_id,
                    },
                }
                sse_logger.event("place_remove", f"Removing place {place_id}")
                yield f"event: place_remove\ndata: {json.dumps(remove_event)}\n\n"
                progress = min(progress + 0.02, 0.9)
                await asyncio.sleep(0.2)  # Stagger animations

            # Stream restaurant removals
            removed_restaurant_ids = original_restaurant_ids - set(current_restaurants.keys())
            for restaurant_id in removed_restaurant_ids:
                remove_event = {
                    "phase": "restaurant_remove",
                    "progress": progress,
                    "data": {
                        "dayNumber": day_num,
                        "restaurantId": restaurant_id,
                    },
                }
                sse_logger.event("restaurant_remove", f"Removing restaurant {restaurant_id}")
                yield f"event: restaurant_remove\ndata: {json.dumps(remove_event)}\n\n"
                progress = min(progress + 0.02, 0.9)
                await asyncio.sleep(0.2)

            # Stream new place additions (animate in after removals)
            added_place_ids = set(current_places.keys()) - original_place_ids
            for place_id in added_place_ids:
                idx, place = current_places[place_id]
                images = place.get("images", [])
                image_url = images[0].get("url") if images else place.get("image_url")

                add_event = {
                    "phase": "place_add",
                    "progress": progress,
                    "data": {
                        "dayNumber": day_num,
                        "slotIndex": idx,
                        "place": {
                            "id": place.get("place_id") or str(uuid.uuid4()),
                            "poi_id": place.get("place_id"),
                            "name": place.get("name", ""),
                            "address": place.get("address"),
                            "type": place.get("type", "attraction"),
                            "category": place.get("category", "attraction"),
                            "description": place.get("description", ""),
                            "duration_minutes": place.get("duration_minutes", 60),
                            "rating": place.get("rating", 4.5),
                            "latitude": place.get("latitude"),
                            "longitude": place.get("longitude"),
                            "image_url": image_url,
                            "images": images,
                            "price": place.get("price"),
                            "price_value": place.get("price_value") or place.get("price_level"),
                            "opening_hours": place.get("opening_hours"),
                        },
                    },
                }
                sse_logger.event("place_add", f"Adding {place.get('name', 'place')}")
                yield f"event: place_add\ndata: {json.dumps(add_event)}\n\n"
                progress = min(progress + 0.02, 0.9)
                await asyncio.sleep(0.3)  # Stagger for smooth animation

            # Stream new restaurant additions
            added_restaurant_ids = set(current_restaurants.keys()) - original_restaurant_ids
            for restaurant_id in added_restaurant_ids:
                idx, restaurant = current_restaurants[restaurant_id]
                r_images = restaurant.get("images", [])
                r_image_url = r_images[0].get("url") if r_images else restaurant.get("image_url")

                add_event = {
                    "phase": "restaurant_add",
                    "progress": progress,
                    "data": {
                        "dayNumber": day_num,
                        "slotIndex": idx,
                        "restaurant": {
                            "id": restaurant.get("place_id") or str(uuid.uuid4()),
                            "poi_id": restaurant.get("place_id"),
                            "name": restaurant.get("name", ""),
                            "address": restaurant.get("address"),
                            "type": restaurant.get("type", "restaurant"),
                            "category": restaurant.get("category", "lunch"),
                            "description": restaurant.get("description", ""),
                            "duration_minutes": restaurant.get("duration_minutes", 45),
                            "rating": restaurant.get("rating", 4.0),
                            "latitude": restaurant.get("latitude"),
                            "longitude": restaurant.get("longitude"),
                            "image_url": r_image_url,
                            "images": r_images,
                            "price_range": restaurant.get("price_range"),
                            "price_value": restaurant.get("price_value") or restaurant.get("price_level"),
                            "cuisine": restaurant.get("cuisine"),
                            "opening_hours": restaurant.get("opening_hours"),
                        },
                    },
                }
                sse_logger.event("restaurant_add", f"Adding {restaurant.get('name', 'restaurant')}")
                yield f"event: restaurant_add\ndata: {json.dumps(add_event)}\n\n"
                progress = min(progress + 0.02, 0.9)
                await asyncio.sleep(0.3)

        # Stream day additions (new days)
        added_days = new_day_numbers - original_day_numbers
        for day in modified_trip.get("days", []):
            if day.get("dayNumber") in added_days:
                day_num = day.get("dayNumber")
                add_day_event = {
                    "phase": "day_add",
                    "progress": progress,
                    "data": {
                        "dayNumber": day_num,
                        "title": day.get("title", f"Day {day_num}"),
                        "description": day.get("description", ""),
                        "placesCount": len(day.get("places", [])),
                        "restaurantsCount": len(day.get("restaurants", [])),
                    },
                }
                sse_logger.event("day_add", f"Adding Day {day_num}")
                yield f"event: day_add\ndata: {json.dumps(add_day_event)}\n\n"
                progress = min(progress + 0.05, 0.95)

                # Stream places for new day
                for idx, place in enumerate(day.get("places", [])):
                    images = place.get("images", [])
                    image_url = images[0].get("url") if images else place.get("image_url")
                    place_event = {
                        "phase": "place_add",
                        "progress": progress,
                        "data": {
                            "dayNumber": day_num,
                            "slotIndex": idx,
                            "place": {
                                "id": place.get("place_id") or str(uuid.uuid4()),
                                "poi_id": place.get("place_id"),
                                "name": place.get("name", ""),
                                "address": place.get("address"),
                                "type": place.get("type", "attraction"),
                                "category": place.get("category", "attraction"),
                                "description": place.get("description", ""),
                                "duration_minutes": place.get("duration_minutes", 60),
                                "rating": place.get("rating", 4.5),
                                "latitude": place.get("latitude"),
                                "longitude": place.get("longitude"),
                                "image_url": image_url,
                                "images": images,
                                "price": place.get("price"),
                                "price_value": place.get("price_value"),
                                "opening_hours": place.get("opening_hours"),
                            },
                        },
                    }
                    yield f"event: place_add\ndata: {json.dumps(place_event)}\n\n"
                    await asyncio.sleep(0.15)

                # Stream restaurants for new day
                for idx, restaurant in enumerate(day.get("restaurants", [])):
                    r_images = restaurant.get("images", [])
                    r_image_url = r_images[0].get("url") if r_images else restaurant.get("image_url")
                    restaurant_event = {
                        "phase": "restaurant_add",
                        "progress": progress,
                        "data": {
                            "dayNumber": day_num,
                            "slotIndex": idx,
                            "restaurant": {
                                "id": restaurant.get("place_id") or str(uuid.uuid4()),
                                "poi_id": restaurant.get("place_id"),
                                "name": restaurant.get("name", ""),
                                "address": restaurant.get("address"),
                                "type": restaurant.get("type", "restaurant"),
                                "category": restaurant.get("category", "lunch"),
                                "description": restaurant.get("description", ""),
                                "duration_minutes": restaurant.get("duration_minutes", 45),
                                "rating": restaurant.get("rating", 4.0),
                                "latitude": restaurant.get("latitude"),
                                "longitude": restaurant.get("longitude"),
                                "image_url": r_image_url,
                                "images": r_images,
                                "price_range": restaurant.get("price_range"),
                                "price_value": restaurant.get("price_value"),
                                "cuisine": restaurant.get("cuisine"),
                                "opening_hours": restaurant.get("opening_hours"),
                            },
                        },
                    }
                    yield f"event: restaurant_add\ndata: {json.dumps(restaurant_event)}\n\n"
                    await asyncio.sleep(0.15)

        # Sync 'itinerary' with 'days' for frontend compatibility
        # Frontend uses 'itinerary' (with 'day') but backend uses 'days' (with 'dayNumber')
        if "days" in modified_trip:
            modified_trip["itinerary"] = [
                {
                    "day": day.get("dayNumber"),
                    "title": day.get("title", ""),
                    "description": day.get("description", ""),
                    "places": day.get("places", []),
                    "restaurants": day.get("restaurants", []),
                }
                for day in modified_trip["days"]
            ]
            # Also sync duration_days
            modified_trip["duration_days"] = len(modified_trip["days"])

        # Send modification_complete with final trip state
        complete_data = {
            "tripId": trip_id,
            "message": f"Trip modified: {analysis.description}",
            "isModification": True,
            "modificationType": analysis.type.value,
            "trip": modified_trip,  # Include full trip for state sync
        }
        complete_event = {"phase": "modification_complete", "progress": 1.0, "data": complete_data}
        sse_logger.event("modification_complete")
        yield f"event: modification_complete\ndata: {json.dumps(complete_event)}\n\n"

        # Cleanup
        if trip_id in pending_trips:
            del pending_trips[trip_id]

        sse_logger.stream_end(success=True)

    except Exception as e:
        logger.error("Modification stream error", trip_id=trip_id, error=str(e))
        error_event = {"error": str(e)}
        sse_logger.event("error", str(e))
        yield f"event: error\ndata: {json.dumps(error_event)}\n\n"
        sse_logger.stream_end(success=False, error=str(e))


async def _stream_new_trip(trip_id: str, query: str):
    """Stream new trip generation events"""
    # Initialize SSE logger
    sse_logger = SSELogger(trip_id)
    sse_logger.stream_start()

    try:
        # Send init event
        init_event = {"phase": "init", "progress": 0.05}
        sse_logger.event("init")
        yield f"event: init\ndata: {json.dumps(init_event)}\n\n"

        # Generate the trip using MULTI-AGENT system
        logger.info("trip_generation_start_multi_agent", trip_id=trip_id, query=query[:100])
        result = await generate_trip_multi_agent(query=query)

        if not result.get("success"):
            error_msg = result.get("error", "Unknown error")
            logger.error("trip_generation_failed", trip_id=trip_id, error=error_msg)
            error_event = {"error": error_msg}
            sse_logger.event("error", error_msg)
            yield f"event: error\ndata: {json.dumps(error_event)}\n\n"
            sse_logger.stream_end(success=False, error=error_msg)
            return

        # Multi-agent returns structured data directly
        parsed = result.get("trip", {})
        place_cache = result.get("place_cache", {})
        validation = result.get("validation")
        agent_logs = result.get("agent_logs", [])

        # Count restaurants in parsed data for debugging
        total_restaurants = sum(
            len(day.get("restaurants", [])) for day in parsed.get("days", [])
        )
        total_places = sum(
            len(day.get("places", [])) for day in parsed.get("days", [])
        )

        logger.info(
            "trip_generation_success_multi_agent",
            trip_id=trip_id,
            days=len(parsed.get("days", [])),
            total_places=total_places,
            total_restaurants=total_restaurants,
            cached_places=len(place_cache),
            quality_score=validation.quality_score if validation else "N/A",
            agent_count=len(agent_logs),
        )

        if not parsed or not parsed.get("days"):
            error_msg = "Trip generation produced no results"
            logger.error("trip_empty", trip_id=trip_id)
            error_event = {"error": error_msg}
            sse_logger.event("error", error_msg)
            yield f"event: error\ndata: {json.dumps(error_event)}\n\n"
            sse_logger.stream_end(success=False, error=error_msg)
            return

        # Send skeleton event - data field contains the skeleton data
        skeleton_data = {
            "title": parsed["title"],
            "description": parsed["description"],
            "city": parsed["city"],
            "country": parsed["country"],
            "durationDays": parsed["durationDays"],
            "theme": parsed.get("theme"),
            "thematicKeywords": [],
            "vibe": [],
        }
        skeleton_event = {"phase": "skeleton", "progress": 0.2, "data": skeleton_data}
        sse_logger.event("skeleton", parsed["title"])
        yield f"event: skeleton\ndata: {json.dumps(skeleton_event)}\n\n"

        # Send day events
        progress = 0.3
        for day in parsed["days"]:
            places_count = len(day.get("places", []))
            restaurants_count = len(day.get("restaurants", []))
            day_data = {
                "dayNumber": day["dayNumber"],
                "title": day["title"],
                "description": day.get("description", ""),
                "slotsCount": places_count,
                "restaurantsCount": restaurants_count,
            }
            day_event = {"phase": "days", "progress": progress, "data": day_data}
            sse_logger.event("day", f"Day {day['dayNumber']}: {day['title']}")
            yield f"event: day\ndata: {json.dumps(day_event)}\n\n"
            progress += 0.05

        # Send place events (attractions)
        for day in parsed["days"]:
            for idx, place in enumerate(day.get("places", [])):
                images = place.get("images", [])
                image_url = images[0].get("url") if images else place.get("image_url")
                place_data = {
                    "dayNumber": day["dayNumber"],
                    "slotIndex": idx,
                    "place": {
                        "id": place.get("place_id") or str(uuid.uuid4()),
                        "poi_id": place.get("place_id"),
                        "name": place["name"],
                        "address": place.get("address"),
                        "type": place.get("type", "attraction"),
                        "category": place.get("category", "attraction"),
                        "description": place.get("description", ""),
                        "duration_minutes": place.get("duration_minutes", 60),
                        "rating": place.get("rating", 4.5),
                        "latitude": place.get("latitude"),
                        "longitude": place.get("longitude"),
                        "image_url": image_url,
                        "images": images,
                        "price": place.get("price"),
                        "price_value": place.get("price_value"),
                        "opening_hours": place.get("opening_hours"),
                    }
                }
                place_event = {"phase": "places", "progress": progress, "data": place_data}
                sse_logger.event("place", place["name"])
                yield f"event: place\ndata: {json.dumps(place_event)}\n\n"
                progress = min(progress + 0.02, 0.85)

        # Send restaurant events
        restaurant_events_sent = 0
        for day in parsed["days"]:
            day_restaurants = day.get("restaurants", [])
            logger.debug(
                "processing_day_restaurants",
                day_number=day["dayNumber"],
                restaurant_count=len(day_restaurants),
            )
            for idx, restaurant in enumerate(day_restaurants):
                r_images = restaurant.get("images", [])
                r_image_url = r_images[0].get("url") if r_images else restaurant.get("image_url")
                restaurant_data = {
                    "dayNumber": day["dayNumber"],
                    "slotIndex": idx,
                    "restaurant": {
                        "id": restaurant.get("place_id") or str(uuid.uuid4()),
                        "poi_id": restaurant.get("place_id"),
                        "name": restaurant["name"],
                        "address": restaurant.get("address"),
                        "type": restaurant.get("type", "restaurant"),
                        "category": restaurant.get("category", "lunch"),  # breakfast/lunch/dinner
                        "description": restaurant.get("description", ""),
                        "duration_minutes": restaurant.get("duration_minutes", 45),
                        "rating": restaurant.get("rating", 4.0),
                        "latitude": restaurant.get("latitude"),
                        "longitude": restaurant.get("longitude"),
                        "image_url": r_image_url,
                        "images": r_images,
                        "price_range": restaurant.get("price_range"),
                        "price_value": restaurant.get("price_value"),
                        "cuisine": restaurant.get("cuisine"),
                        "opening_hours": restaurant.get("opening_hours"),
                    }
                }
                restaurant_event = {"phase": "restaurants", "progress": progress, "data": restaurant_data}
                sse_logger.event("restaurant", restaurant["name"])
                yield f"event: restaurant\ndata: {json.dumps(restaurant_event)}\n\n"
                restaurant_events_sent += 1
                progress = min(progress + 0.02, 0.95)

        logger.info(
            "restaurant_events_sent",
            trip_id=trip_id,
            count=restaurant_events_sent,
        )

        # Send complete event FIRST (user sees the trip immediately)
        complete_data = {
            "tripId": trip_id,
            "message": "Trip generated successfully!",
        }
        complete_event = {"phase": "complete", "progress": 1.0, "data": complete_data}
        sse_logger.event("complete")
        yield f"event: complete\ndata: {json.dumps(complete_event)}\n\n"

        # Now search for prices in background and stream updates
        # Collect all places that need prices
        places_for_price_search: list[PlaceData] = []
        place_id_to_location: dict[str, tuple[int, int]] = {}  # place_id -> (dayNumber, slotIndex)

        for day in parsed["days"]:
            for idx, place in enumerate(day.get("places", [])):
                place_id = place.get("place_id")
                if place_id and not place.get("price"):
                    # Create PlaceData for price search
                    places_for_price_search.append(PlaceData(
                        place_id=place_id,
                        name=place.get("name", ""),
                        address=place.get("address"),
                        types=place.get("types", []),
                    ))
                    place_id_to_location[place_id] = (day["dayNumber"], idx)

        # Search prices in parallel and yield updates as they come
        if places_for_price_search:
            city = parsed.get("city", "")
            logger.info(
                "starting_price_search",
                trip_id=trip_id,
                places_count=len(places_for_price_search),
            )

            # Search prices for all places
            places_with_prices = await get_place_prices(places_for_price_search, city)

            # Send price_update events for each place that got a price
            for place in places_with_prices:
                if place.price:
                    location = place_id_to_location.get(place.place_id)
                    if location:
                        day_num, slot_idx = location
                        price_update_data = {
                            "dayNumber": day_num,
                            "slotIndex": slot_idx,
                            "placeId": place.place_id,
                            "price": place.price,
                        }
                        price_event = {"phase": "price_update", "data": price_update_data}
                        sse_logger.event("price_update", f"{place.name}: {place.price}")
                        yield f"event: price_update\ndata: {json.dumps(price_event)}\n\n"

            prices_found = sum(1 for p in places_with_prices if p.price)
            logger.info(
                "price_search_complete",
                trip_id=trip_id,
                prices_found=prices_found,
            )

            # Send prices_complete event to signal frontend that price loading is done
            prices_complete_event = {
                "phase": "prices_complete",
                "data": {"pricesFound": prices_found, "totalPlaces": len(places_for_price_search)},
            }
            sse_logger.event("prices_complete", f"Found {prices_found} prices")
            yield f"event: prices_complete\ndata: {json.dumps(prices_complete_event)}\n\n"

        # Cleanup
        if trip_id in pending_trips:
            del pending_trips[trip_id]

        sse_logger.stream_end(success=True)

    except Exception as e:
        logger.error("stream_error", trip_id=trip_id, error=str(e))
        error_event = {"error": str(e)}
        sse_logger.event("error", str(e))
        yield f"event: error\ndata: {json.dumps(error_event)}\n\n"
        sse_logger.stream_end(success=False, error=str(e))


# ─────────────────────────────────────────────────────────────────────────────
# Run with uvicorn
# ─────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import uvicorn

    banner = f"""
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║   TRIPLY API v3.1 - Multi-Agent Trip Planner                         ║
║                                                                      ║
║   Server: http://localhost:{settings.port}                                  ║
║   Docs:   http://localhost:{settings.port}/docs                             ║
║   Environment: {settings.env:<11}                                      ║
║                                                                      ║
║   Multi-Agent Architecture:                                          ║
║   ├─ Query Analyzer      → Theme extraction & search queries         ║
║   ├─ Places Agent        → Themed attractions search                 ║
║   ├─ Restaurant Agent    → Location-aware restaurant search          ║
║   ├─ Validator Agent     → Quality control & theme consistency       ║
║   ├─ Modification Agent  → Smart trip modifications                  ║
║   └─ Orchestrator        → Coordinates all agents                    ║
║                                                                      ║
║   Features:                                                          ║
║   ├─ Strict theme matching (no generic tourist spots)                ║
║   ├─ Parallel search execution                                       ║
║   ├─ Google Places + Tavily Web Search                               ║
║   ├─ SSE streaming for real-time updates                             ║
║   └─ Smart modifications (budget, days, places)                      ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
"""
    print(banner)

    uvicorn.run(
        "src.main:app",
        host="0.0.0.0",
        port=settings.port,
        reload=settings.is_dev,
    )
