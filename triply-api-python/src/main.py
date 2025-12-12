"""
Triply API - Multi-Agent Trip Generation Service

FastAPI application with ReAct agent for intelligent trip planning.
"""

import json
import uuid
import re
import random
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from langgraph.checkpoint.memory import MemorySaver

from .config import settings
from .agents import generate_trip, stream_trip_generation
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
    description="Multi-Agent Trip Generation Service with ReAct Agents",
    version="2.0.0",
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
        "version": "2.0.0",
        "status": "running",
        "description": "Multi-Agent Trip Generation Service with ReAct Agents",
        "endpoints": {
            "health": "GET /",
            "generate": "POST /generate",
            "stream": "POST /generate/stream",
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


def parse_trip_from_response(response: str, query: str) -> dict:
    """
    Parse the agent's response into structured trip data.
    First tries to parse as JSON, falls back to markdown parsing.
    """
    trip_id = str(uuid.uuid4())

    # Try to parse JSON first
    try:
        # Try to extract JSON from response (may be wrapped in ```json ... ```)
        json_match = re.search(r'```json\s*([\s\S]*?)\s*```', response)
        if json_match:
            json_str = json_match.group(1)
        else:
            # Try to find raw JSON object
            json_match = re.search(r'\{[\s\S]*"days"[\s\S]*\}', response)
            if json_match:
                json_str = json_match.group(0)
            else:
                json_str = response.strip()

        parsed_json = json.loads(json_str)

        # Validate required fields
        if "days" in parsed_json and isinstance(parsed_json["days"], list):
            logger.info("trip_parsed_json", success=True, days_count=len(parsed_json["days"]))
            return {
                "tripId": trip_id,
                "title": parsed_json.get("title", f"Trip to {parsed_json.get('city', 'Unknown')}"),
                "description": parsed_json.get("description", ""),
                "city": parsed_json.get("city", "Unknown"),
                "country": parsed_json.get("country", "Unknown"),
                "durationDays": parsed_json.get("durationDays", len(parsed_json["days"])),
                "theme": parsed_json.get("theme"),
                "days": parsed_json["days"],
                "rawResponse": response,
            }
    except (json.JSONDecodeError, KeyError, TypeError) as e:
        logger.warning("json_parse_failed", error=str(e), falling_back="markdown")

    # Fallback to markdown parsing
    logger.info("parsing_markdown_fallback")

    # Extract city and country from query
    city = "Unknown"
    country = "Unknown"
    duration_days = 3

    # Try to extract city from query
    city_patterns = [
        r"(?:in|to|visit)\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)",
        r"([A-Za-z]+(?:\s+[A-Za-z]+)?)\s+(?:trip|vacation|holiday)",
        r"(\d+)\s*days?\s+(?:in\s+)?([A-Za-z]+)",
    ]
    for pattern in city_patterns:
        match = re.search(pattern, query, re.IGNORECASE)
        if match:
            city = match.group(match.lastindex).strip().title()
            break

    # Try to extract duration
    duration_match = re.search(r"(\d+)\s*(?:day|days)", query.lower())
    if duration_match:
        duration_days = int(duration_match.group(1))

    # Parse days from response
    days = []
    current_day = None
    places = []

    lines = response.split("\n")
    for line in lines:
        line = line.strip()
        if not line:
            continue

        # Match day headers
        day_match = re.match(
            r"(?:\*\*)?(?:##\s*)?Day\s*(\d+)[:\s]*([^*\n]*?)(?:\*\*)?$",
            line, re.IGNORECASE
        )
        if day_match:
            if current_day is not None and places:
                days.append({
                    "dayNumber": current_day["number"],
                    "title": current_day["title"],
                    "description": "",
                    "places": places,
                })
            current_day = {
                "number": int(day_match.group(1)),
                "title": day_match.group(2).strip() or f"Day {day_match.group(1)}",
            }
            places = []
            continue

        # Match place entries - look for bold place names
        if current_day is not None and (line.startswith("*") or line.startswith("-")):
            bold_matches = re.findall(r"\*\*([^*]+)\*\*", line)

            # Find address in parentheses
            address_match = re.search(r"\(([^)]+)\)", line)
            address = address_match.group(1) if address_match else None

            place_name = None
            for bold in bold_matches:
                # Skip time indicators and common words
                if re.match(r"^(Morning|Afternoon|Evening|Night|Late|Lunch|Dinner|Breakfast|Why|Time|Duration)", bold, re.IGNORECASE):
                    continue
                if len(bold) > 3 and not bold.endswith(":"):
                    place_name = bold.strip()
                    break

            if place_name:
                place_type = "attraction"
                line_lower = line.lower()
                if any(word in line_lower for word in ["restaurant", "dinner", "lunch", "food", "eat"]):
                    place_type = "restaurant"
                elif any(word in line_lower for word in ["bar", "drink", "cocktail", "pub"]):
                    place_type = "bar"
                elif any(word in line_lower for word in ["cafe", "coffee"]):
                    place_type = "cafe"
                elif any(word in line_lower for word in ["club", "nightclub"]):
                    place_type = "nightclub"
                elif any(word in line_lower for word in ["museum", "gallery"]):
                    place_type = "museum"

                places.append({
                    "name": place_name,
                    "address": address,
                    "type": place_type,
                    "description": "",
                    "duration_minutes": 60,
                    "rating": 4.5,
                })

    # Add last day
    if current_day is not None and places:
        days.append({
            "dayNumber": current_day["number"],
            "title": current_day["title"],
            "description": "",
            "places": places,
        })

    # Extract title from response
    title = f"Trip to {city}"
    for line in lines[:10]:
        line = line.strip()
        for pattern in [r"^##\s*(.+?)$", r"^\*\*(.+?)\*\*$", r"^#\s*(.+?)$"]:
            match = re.match(pattern, line)
            if match:
                potential_title = match.group(1).strip()
                if not potential_title.lower().startswith("day"):
                    title = potential_title
                    break
        if title != f"Trip to {city}":
            break

    return {
        "tripId": trip_id,
        "title": title,
        "description": f"A {duration_days}-day trip to {city}",
        "city": city,
        "country": country,
        "durationDays": duration_days,
        "theme": None,
        "days": days,
        "rawResponse": response,
    }


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


@app.post("/api/trips/generate/stream")
async def frontend_generate_stream(request: FrontendGenerateRequest):
    """
    Frontend-compatible endpoint that starts trip generation.
    Returns tripId and streamUrl for SSE connection.
    """
    if not request.query or len(request.query.strip()) < 3:
        raise HTTPException(status_code=400, detail="Query must be at least 3 characters")

    trip_id = str(uuid.uuid4())

    # Store the pending request
    pending_trips[trip_id] = {
        "query": request.query,
        "status": "pending",
    }

    logger.info("Frontend stream request", trip_id=trip_id, query=request.query)

    return {
        "success": True,
        "data": {
            "tripId": trip_id,
            "streamUrl": f"/api/trips/{trip_id}/stream",
        }
    }


@app.get("/api/trips/{trip_id}/stream")
async def frontend_trip_stream(trip_id: str):
    """
    SSE stream for trip generation progress.
    Emits events compatible with triply-web frontend.
    """
    if trip_id not in pending_trips:
        raise HTTPException(status_code=404, detail="Trip not found")

    trip_data = pending_trips[trip_id]
    query = trip_data["query"]

    async def event_generator():
        # Initialize SSE logger
        sse_logger = SSELogger(trip_id)
        sse_logger.stream_start()

        try:
            # Send init event
            init_event = {"phase": "init", "progress": 0.05}
            sse_logger.event("init")
            yield f"event: init\ndata: {json.dumps(init_event)}\n\n"

            # Generate the trip
            logger.info("trip_generation_start", trip_id=trip_id, query=query[:100])
            result = await generate_trip(
                query=query,
                checkpointer=checkpointer,
            )

            if not result.get("success"):
                error_msg = result.get("error", "Unknown error")
                logger.error("trip_generation_failed", trip_id=trip_id, error=error_msg)
                error_event = {"error": error_msg}
                sse_logger.event("error", error_msg)
                yield f"event: error\ndata: {json.dumps(error_event)}\n\n"
                sse_logger.stream_end(success=False, error=error_msg)
                return

            response = result.get("response", "")
            logger.info("trip_generation_success", trip_id=trip_id, response_length=len(response))

            # Parse the response into structured data
            parsed = parse_trip_from_response(response, query)
            logger.info(
                "trip_parsed",
                trip_id=trip_id,
                city=parsed["city"],
                days_count=len(parsed["days"]),
                total_places=sum(len(d["places"]) for d in parsed["days"]),
            )

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
                day_data = {
                    "dayNumber": day["dayNumber"],
                    "title": day["title"],
                    "description": day.get("description", ""),
                    "slotsCount": len(day["places"]),
                }
                day_event = {"phase": "days", "progress": progress, "data": day_data}
                sse_logger.event("day", f"Day {day['dayNumber']}: {day['title']}")
                yield f"event: day\ndata: {json.dumps(day_event)}\n\n"
                progress += 0.05

            # Send place events
            for day in parsed["days"]:
                for idx, place in enumerate(day["places"]):
                    place_data = {
                        "dayNumber": day["dayNumber"],
                        "slotIndex": idx,
                        "place": {
                            "id": str(uuid.uuid4()),
                            "name": place["name"],
                            "address": place.get("address"),
                            "type": place.get("type", "attraction"),
                            "category": place.get("type", "attraction"),
                            "description": place.get("description", ""),
                            "duration_minutes": place.get("duration_minutes", 60),
                            "rating": place.get("rating", 4.5),
                        }
                    }
                    place_event = {"phase": "places", "progress": progress, "data": place_data}
                    sse_logger.event("place", place["name"])
                    yield f"event: place\ndata: {json.dumps(place_event)}\n\n"
                    progress = min(progress + 0.02, 0.9)

            # Send complete event
            complete_data = {
                "tripId": trip_id,
                "message": "Trip generated successfully!",
            }
            complete_event = {"phase": "complete", "progress": 1.0, "data": complete_data}
            sse_logger.event("complete")
            yield f"event: complete\ndata: {json.dumps(complete_event)}\n\n"

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

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


# ─────────────────────────────────────────────────────────────────────────────
# Run with uvicorn
# ─────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import uvicorn

    banner = f"""
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║   🚀 TRIPLY API v2.0 - ReAct Agent Trip Planner                      ║
║                                                                      ║
║   Server: http://localhost:{settings.port}                                  ║
║   Docs:   http://localhost:{settings.port}/docs                             ║
║   Environment: {settings.env:<11}                                      ║
║                                                                      ║
║   Features:                                                          ║
║   ├─ ReAct Agent with autonomous reasoning                           ║
║   ├─ Google Places integration                                       ║
║   ├─ Web search for local tips                                       ║
║   └─ SSE streaming for real-time updates                             ║
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
