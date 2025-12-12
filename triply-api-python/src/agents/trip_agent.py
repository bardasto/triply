"""
Trip Planning ReAct Agent

Uses LangGraph's prebuilt ReAct agent with custom tools for trip planning.
This is a TRUE ReAct agent that can:
- Think about what it needs to do
- Use tools autonomously
- Observe results and adapt
- Handle ANY type of query (anime, romantic, vegan, adults-only, etc.)
"""

import uuid
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage, SystemMessage
from langgraph.prebuilt import create_react_agent
from langgraph.checkpoint.memory import MemorySaver

from ..config import settings
from ..tools import ALL_TOOLS
from ..schemas import Trip, TripIntent
from ..logging import get_logger
from ..logging.logger import AgentLogger

logger = get_logger("agent")

# System prompt that makes the agent a trip planning expert
TRIP_AGENT_SYSTEM_PROMPT = """You are a trip planning AI that creates STRICTLY THEMATIC trips.

CRITICAL RULES:
1. You MUST call search_places tool multiple times before generating any response
2. DO NOT generate place names from your knowledge - ONLY use results from search_places
3. EVERY place MUST match the trip theme - NO generic tourist attractions!

THEME ANALYSIS (do this first):
When user requests a themed trip (e.g., "anime trip", "biker trip", "romantic getaway"):
1. Identify the CORE THEME and related keywords
2. Search ONLY for places matching that theme
3. DO NOT include generic landmarks that don't fit the theme

THEME EXAMPLES:
- "anime trip to Paris" → search: "anime shop Paris", "manga store Paris", "japanese culture Paris", "cosplay Paris", "gaming cafe Paris", "japan expo Paris"
  DO NOT include: Eiffel Tower, Louvre, Notre Dame (unless they have anime connection)
- "biker trip" → search: "motorcycle shop", "biker bar", "scenic motorcycle route", "harley davidson", "motorcycle museum"
- "romantic trip" → search: "romantic restaurant", "couples spa", "sunset viewpoint", "wine tasting", "boutique hotel"
- "vegan food trip" → search: "vegan restaurant", "plant-based cafe", "organic market", "vegan bakery"

MANDATORY REQUIREMENTS:
- MINIMUM 3-4 places per day that ALL match the theme
- EXACTLY 3 restaurants per day (breakfast, lunch, dinner) - also matching theme when possible
- If theme-specific places are limited, search for RELATED themes (e.g., for anime: japanese culture, gaming, cosplay)
- NEVER fill gaps with unrelated tourist attractions

SEARCH STRATEGY:
1. FIRST: Identify 5-10 search queries related to the theme
2. Call search_places for EACH themed query (e.g., "anime shops [city]", "manga cafes [city]", "japanese bookstore [city]")
3. If results are few, expand to related themes (japanese → asian culture → pop culture → gaming)
4. NOTE the Location coordinates (lat,lng) from the search results
5. Use web_search to find ticket prices for attractions

RESTAURANT SEARCH (must also fit theme when possible):
- For anime trip: search "ramen restaurant", "japanese cafe", "maid cafe", "themed restaurant"
- For biker trip: search "biker bar", "steakhouse", "roadside diner"
- For romantic trip: search "romantic dinner", "candlelit restaurant", "rooftop bar"
- Use near_location parameter with coordinates from nearby attractions
- Example: search_places("ramen restaurant", near_location="48.8566,2.3522", radius_meters=1000)

PRICING STRATEGY:
- For PLACES: Use web_search to find REAL ticket prices. Include currency symbol (€, $, etc.)
  Examples: "€17", "$25", "Free", "€12-18" (for ranges)
- For RESTAURANTS: Use price_range like "$" (cheap), "$$" (moderate), "$$$" (expensive)
  This comes from Google Places price_level data

RESTAURANT SEARCH STRATEGY:
- Search "breakfast restaurants/cafes in [city]" near first attraction
- Search "lunch restaurants in [city]" near middle of day's route
- Search "dinner restaurants in [city]" near last attraction
- Match restaurant style to trip theme (e.g., ramen for anime trip, romantic bistro for couples)
- MUST include exactly 3 restaurants per day: breakfast, lunch, dinner

OUTPUT FORMAT after searching:
{
  "title": "Trip title",
  "description": "Brief description",
  "city": "City name",
  "country": "Country name",
  "durationDays": 3,
  "theme": "Trip theme",
  "days": [
    {
      "dayNumber": 1,
      "title": "Day title",
      "description": "Day description",
      "places": [
        {
          "name": "EXACT name from search_places result",
          "place_id": "ID from search_places result",
          "address": "EXACT address from search_places result",
          "type": "attraction|museum|park|landmark|shop",
          "category": "attraction",
          "description": "Why this place fits the trip theme",
          "duration_minutes": 60,
          "rating": 4.5,
          "latitude": 48.8566,
          "longitude": 2.3522,
          "price": "€15"
        }
      ],
      "restaurants": [
        {
          "name": "EXACT name from search_places result",
          "place_id": "ID from search_places result",
          "address": "EXACT address from search_places result",
          "type": "restaurant|cafe|bar",
          "category": "breakfast|lunch|dinner",
          "description": "Why this restaurant fits",
          "duration_minutes": 45,
          "rating": 4.2,
          "latitude": 48.8570,
          "longitude": 2.3525,
          "cuisine": "French|Japanese|Italian|etc",
          "price_range": "$$"
        }
      ]
    }
  ]
}

RULES:
- MUST call search_places before responding
- MUST use web_search to find REAL ticket prices for attractions
- Use ONLY names, addresses, place_ids, and coordinates from search_places results
- SEPARATE places and restaurants arrays - do NOT mix them
- EVERY day MUST have BOTH "places" array AND "restaurants" array
- The "restaurants" array MUST have EXACTLY 3 items per day (breakfast, lunch, dinner)
- Category for restaurants MUST be: breakfast, lunch, or dinner
- Include latitude/longitude from Location field in search results
- For places: "price" = real ticket price from web search (e.g., "€15", "Free")
- For restaurants: "price_range" = "$", "$$", or "$$$"
- Output valid JSON only, no markdown

VALIDATION CHECKLIST before outputting JSON:
✓ Each day has "places" array with 3-4+ items
✓ Each day has "restaurants" array with EXACTLY 3 items
✓ Each restaurant has category: "breakfast", "lunch", or "dinner"
✓ All places and restaurants have place_id, latitude, longitude from search_places
"""


def create_trip_agent(checkpointer: MemorySaver | None = None):
    """
    Create a ReAct agent for trip planning

    This uses LangGraph's prebuilt create_react_agent which implements
    the full ReAct loop: Think -> Act -> Observe -> Think...

    Args:
        checkpointer: Optional memory checkpointer for conversation persistence

    Returns:
        Compiled LangGraph agent
    """
    # Initialize Gemini model with tools bound
    model = ChatGoogleGenerativeAI(
        model="gemini-2.0-flash-exp",
        google_api_key=settings.google_api_key,
        temperature=0.7,
        max_output_tokens=8192,
    )

    # Bind tools to the model explicitly
    model_with_tools = model.bind_tools(ALL_TOOLS)

    # Create the ReAct agent
    agent = create_react_agent(
        model=model_with_tools,
        tools=ALL_TOOLS,
        prompt=TRIP_AGENT_SYSTEM_PROMPT,
        checkpointer=checkpointer,
    )

    # Add recursion limit to prevent infinite loops
    agent = agent.with_config({"recursion_limit": 25})

    return agent


async def generate_trip(
    query: str,
    thread_id: str | None = None,
    checkpointer: MemorySaver | None = None,
) -> dict:
    """
    Generate a trip using the ReAct agent

    Args:
        query: User's trip request
        thread_id: Optional thread ID for conversation memory
        checkpointer: Optional checkpointer for persistence

    Returns:
        Dictionary with trip data and metadata
    """
    from ..tools.google_places import clear_place_cache, get_cached_places

    execution_id = str(uuid.uuid4())
    effective_thread_id = thread_id or f"trip-{execution_id}"

    # Clear place cache at start of generation
    clear_place_cache()

    # Initialize agent logger
    agent_logger = AgentLogger(trip_id=execution_id, query=query)
    agent_logger.start(query)

    # Create agent
    agent = create_trip_agent(checkpointer)

    # Prepare input - explicitly require tool usage
    input_message = HumanMessage(content=f"""
Plan a trip: {query}

STEP 1 - THEME ANALYSIS:
First, identify the THEME of this trip. What specific type of experience is the user looking for?
Generate 5-10 search queries that match THIS SPECIFIC THEME.

STEP 2 - THEMED PLACE SEARCH:
Call search_places MULTIPLE TIMES with theme-specific queries.
DO NOT search for generic "attractions" or "landmarks" - search for places that match the THEME.
Example for "anime trip Paris": search "anime shop Paris", "manga store Paris", "japanese culture center Paris"

STEP 3 - PRICE RESEARCH:
Use web_search to find REAL ticket prices for each attraction.

STEP 4 - THEMED RESTAURANT SEARCH:
Search for restaurants that ALSO match the theme when possible.
Use near_location parameter with coordinates from nearby places.

STEP 5 - OUTPUT:
Generate JSON with SEPARATE "places" and "restaurants" arrays.

CRITICAL REQUIREMENTS:
- EVERY place MUST match the trip theme - no generic tourist spots!
- Each day MUST have "places" array with 3-4 themed attractions
- Each day MUST have "restaurants" array with EXACTLY 3 restaurants (breakfast, lunch, dinner)
- For places: include "price" with real ticket prices (e.g., "€15", "Free")
- For restaurants: include "price_range" ("$", "$$", "$$$") and "category" ("breakfast"/"lunch"/"dinner")

Start by analyzing the theme and generating themed search queries.
""")

    # Run the agent
    config = {"configurable": {"thread_id": effective_thread_id}}

    try:
        tool_calls = []

        # Use ainvoke for complete execution
        result = await agent.ainvoke(
            {"messages": [input_message]},
            config=config,
        )

        # Extract messages and tool calls
        messages = result.get("messages", [])

        # Find all tool calls from messages
        for msg in messages:
            if hasattr(msg, "tool_calls") and msg.tool_calls:
                for tc in msg.tool_calls:
                    tool_name = tc.get("name", "unknown")
                    tool_args = tc.get("args", {})
                    tool_calls.append({
                        "tool": tool_name,
                        "input": tool_args,
                    })
                    # Log each tool call
                    agent_logger.tool_call(tool_name, tool_args)

        # Get the final AI message (should be an AIMessage without tool_calls)
        final_message = ""
        from langchain_core.messages import AIMessage

        for msg in reversed(messages):
            # Find the last AI message that is not a tool call
            if isinstance(msg, AIMessage):
                if not msg.tool_calls and msg.content:
                    final_message = msg.content
                    break

        # If no clean AI response found, try to get any AI message with content
        if not final_message:
            for msg in reversed(messages):
                if isinstance(msg, AIMessage) and msg.content:
                    final_message = msg.content
                    break

        if not final_message:
            final_message = "Trip generation completed but no final response was produced."

        # Log successful completion
        agent_logger.complete(
            success=True,
            response_length=len(final_message),
        )

        # Get cached places for post-processing (photos, prices, etc.)
        place_cache = get_cached_places()

        return {
            "success": True,
            "execution_id": execution_id,
            "thread_id": effective_thread_id,
            "response": final_message,
            "tool_calls": tool_calls,
            "place_cache": place_cache,
        }

    except Exception as e:
        # Log failure
        agent_logger.complete(success=False, error=str(e))
        return {
            "success": False,
            "execution_id": execution_id,
            "error": str(e),
        }


async def stream_trip_generation(
    query: str,
    thread_id: str | None = None,
    checkpointer: MemorySaver | None = None,
):
    """
    Stream trip generation events for SSE

    Yields events as the agent thinks and uses tools

    Args:
        query: User's trip request
        thread_id: Optional thread ID
        checkpointer: Optional checkpointer

    Yields:
        Event dictionaries for SSE streaming
    """
    execution_id = str(uuid.uuid4())
    effective_thread_id = thread_id or f"trip-{execution_id}"

    logger.info("Starting streaming trip generation", query=query)

    agent = create_trip_agent(checkpointer)

    input_message = HumanMessage(content=f"""
Please create a trip itinerary for the following request:

{query}

Follow these steps:
1. First, parse the request to understand: destination, duration, theme/interests, and any special requirements
2. Use web_search to find local tips and recommendations for the specific interests
3. Use search_places multiple times with different queries to find:
   - Places matching the specific theme/interests
   - Restaurants (consider the theme - e.g., themed cafes for anime trips)
   - Must-see attractions
   - Hidden gems
4. Create a detailed day-by-day itinerary

Start by telling me what you understood from the request, then proceed with research and planning.
""")

    config = {"configurable": {"thread_id": effective_thread_id}}

    # Yield initial event
    yield {
        "event": "start",
        "execution_id": execution_id,
        "phase": "starting",
        "progress": 0,
    }

    try:
        current_phase = "thinking"
        progress = 10

        async for event in agent.astream_events(
            {"messages": [input_message]},
            config=config,
            version="v2",
        ):
            kind = event["event"]

            if kind == "on_chat_model_stream":
                content = event["data"]["chunk"].content
                if content:
                    yield {
                        "event": "thinking",
                        "execution_id": execution_id,
                        "phase": current_phase,
                        "content": content,
                    }

            elif kind == "on_tool_start":
                tool_name = event["name"]
                tool_input = event["data"].get("input", {})
                progress = min(progress + 10, 80)
                current_phase = f"using_{tool_name}"

                yield {
                    "event": "tool_start",
                    "execution_id": execution_id,
                    "phase": current_phase,
                    "progress": progress,
                    "tool": tool_name,
                    "input": tool_input,
                }

            elif kind == "on_tool_end":
                tool_name = event["name"]
                output = event["data"].get("output", "")

                yield {
                    "event": "tool_end",
                    "execution_id": execution_id,
                    "phase": current_phase,
                    "tool": tool_name,
                    "output_preview": str(output)[:500],
                }

            elif kind == "on_chain_end":
                if event["name"] == "LangGraph":
                    final_response = event["data"].get("output", {})
                    if final_response and "messages" in final_response:
                        messages = final_response["messages"]
                        final_message = messages[-1].content if messages else ""

                        yield {
                            "event": "complete",
                            "execution_id": execution_id,
                            "phase": "completed",
                            "progress": 100,
                            "response": final_message,
                        }

    except Exception as e:
        logger.error("Streaming failed", error=str(e))
        yield {
            "event": "error",
            "execution_id": execution_id,
            "error": str(e),
        }
