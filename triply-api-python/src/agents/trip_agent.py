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
import structlog
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage, SystemMessage
from langgraph.prebuilt import create_react_agent
from langgraph.checkpoint.memory import MemorySaver

from ..config import settings
from ..tools import ALL_TOOLS
from ..schemas import Trip, TripIntent

logger = structlog.get_logger()

# System prompt that makes the agent a trip planning expert
TRIP_AGENT_SYSTEM_PROMPT = """You are an expert travel planner AI that creates personalized trip itineraries.

YOUR CAPABILITIES:
1. You can search for ANY type of place using the search_places tool
2. You can get detailed information about specific places using get_place_details
3. You can search the web for current information, local tips, and niche interests using web_search
4. You can get comprehensive destination info using get_destination_info

YOUR MISSION:
Create a perfect trip itinerary that EXACTLY matches what the user wants. This includes:
- Niche interests (anime, K-pop, specific cuisines, etc.)
- Special requirements (vegan, wheelchair accessible, family-friendly, adults-only, etc.)
- Themes (romantic, adventure, relaxation, party, culture, etc.)
- Budget constraints
- Time constraints

PROCESS:
1. UNDERSTAND: Parse the user's query to understand what they really want
2. RESEARCH: Use web_search to find local tips, hidden gems, and current information
3. SEARCH: Use search_places multiple times with different queries to find relevant places
4. EVALUATE: Consider ratings, reviews, and relevance to the user's interests
5. PLAN: Create a day-by-day itinerary with proper timing and logistics

IMPORTANT RULES:
- ALWAYS search for the user's specific interests, not just generic tourist spots
- For niche themes, use web_search FIRST to understand what to look for
- Include a mix of attractions, restaurants, and experiences
- Consider travel time between places
- Make the trip feel authentic and tailored, not generic

OUTPUT FORMAT:
After gathering all information, create a structured trip with:
- A compelling title that reflects the theme
- Day-by-day breakdown with times
- Why each place was chosen for THIS specific trip
- Local tips and recommendations

Remember: The user wants a PERFECT trip for THEIR specific interests. Generic tourist itineraries are NOT acceptable.
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
    execution_id = str(uuid.uuid4())
    effective_thread_id = thread_id or f"trip-{execution_id}"

    logger.info(
        "Starting trip generation",
        query=query,
        execution_id=execution_id,
        thread_id=effective_thread_id,
    )

    # Create agent
    agent = create_trip_agent(checkpointer)

    # Prepare input - make it clear tools should be used
    input_message = HumanMessage(content=f"""
Create a detailed trip itinerary for: {query}

You MUST use the search_places tool to find real venues. Make multiple searches:
- Search for the main theme (e.g., "nightclubs in Bratislava", "bars in Bratislava")
- Search for restaurants
- Search for attractions if relevant

If web_search fails, continue with search_places - it's the primary tool for finding places.

After gathering places, create a structured day-by-day itinerary with:
- Specific venue names and addresses
- Time slots (morning, afternoon, evening, night)
- Brief description of each place

START by calling search_places with the main query.
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
                    tool_calls.append({
                        "tool": tc.get("name", "unknown"),
                        "input": tc.get("args", {}),
                    })

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

        logger.info(
            "Trip generation completed",
            execution_id=execution_id,
            tool_calls_count=len(tool_calls),
            messages_count=len(messages),
        )

        return {
            "success": True,
            "execution_id": execution_id,
            "thread_id": effective_thread_id,
            "response": final_message,
            "tool_calls": tool_calls,
        }

    except Exception as e:
        logger.error("Trip generation failed", error=str(e), execution_id=execution_id)
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
