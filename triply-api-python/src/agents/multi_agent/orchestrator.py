"""
Trip Orchestrator

Main coordinator that runs the multi-agent pipeline:
1. Query Analyzer → Extract theme and generate search queries
2. Places Agent → Find themed attractions (parallel)
3. Restaurant Agent → Find themed restaurants (parallel with places)
4. Assembler → Build day-by-day itinerary
5. Validator → Quality check

Uses LangGraph for workflow orchestration.
"""

import uuid
import asyncio
from typing import Literal

from langgraph.graph import StateGraph, END

from ...logging import get_logger
from ...logging.logger import AgentLogger
from ...tools.google_places import clear_place_cache, get_cached_places

from .state import (
    MultiAgentState,
    ThemeAnalysis,
    PlaceData,
    RestaurantData,
    DayPlan,
    TripPlan,
    ValidationResult,
)
from .query_analyzer import analyze_query
from .places_agent import search_places_for_theme, get_place_prices
from .restaurant_agent import search_restaurants_parallel
from .validator_agent import validate_trip_plan, quick_validate

logger = get_logger("orchestrator")


class TripOrchestrator:
    """
    Multi-agent orchestrator for trip planning.

    Coordinates multiple specialized agents to create high-quality trips.
    """

    def __init__(self):
        self.graph = self._build_graph()

    def _build_graph(self) -> StateGraph:
        """Build the LangGraph workflow."""

        # Define the graph with our state
        workflow = StateGraph(MultiAgentState)

        # Add nodes for each phase
        workflow.add_node("analyze_query", self._analyze_query_node)
        workflow.add_node("search_places", self._search_places_node)
        workflow.add_node("search_restaurants", self._search_restaurants_node)
        workflow.add_node("assemble_trip", self._assemble_trip_node)
        workflow.add_node("validate", self._validate_node)
        workflow.add_node("finalize", self._finalize_node)

        # Define edges
        workflow.set_entry_point("analyze_query")

        # After analysis, search places and restaurants in parallel
        # LangGraph doesn't support true parallel, so we chain them
        # but the internal searches are parallel
        workflow.add_edge("analyze_query", "search_places")
        workflow.add_edge("search_places", "search_restaurants")
        workflow.add_edge("search_restaurants", "assemble_trip")
        workflow.add_edge("assemble_trip", "validate")

        # Conditional edge based on validation
        workflow.add_conditional_edges(
            "validate",
            self._should_retry,
            {
                "retry": "search_places",  # Retry if validation fails
                "finalize": "finalize",
            }
        )

        workflow.add_edge("finalize", END)

        return workflow.compile()

    def _should_retry(self, state: MultiAgentState) -> Literal["retry", "finalize"]:
        """Decide whether to retry based on validation."""
        validation = state.get("validation_result")

        if validation and not validation.is_valid:
            # Check if we've already retried
            retry_count = len([log for log in state.get("agent_logs", []) if log.get("action") == "retry"])
            if retry_count < 1:  # Only retry once
                logger.info("Validation failed, retrying search")
                return "retry"

        return "finalize"

    async def _analyze_query_node(self, state: MultiAgentState) -> dict:
        """Node: Analyze the user query."""
        logger.info("Node: analyze_query", query=state["query"])

        try:
            theme_analysis = await analyze_query(state["query"])

            return {
                "theme_analysis": theme_analysis,
                "current_phase": "analysis_complete",
                "progress": 0.15,
                "agent_logs": state.get("agent_logs", []) + [{
                    "agent": "query_analyzer",
                    "action": "analyze",
                    "result": f"Theme: {theme_analysis.theme}, City: {theme_analysis.city}",
                }],
            }

        except Exception as e:
            logger.error("Query analysis failed", error=str(e))
            return {
                "errors": state.get("errors", []) + [f"Query analysis failed: {e}"],
                "current_phase": "error",
            }

    async def _search_places_node(self, state: MultiAgentState) -> dict:
        """Node: Search for themed places."""
        logger.info("Node: search_places")

        theme_analysis = state.get("theme_analysis")
        if not theme_analysis:
            return {"errors": state.get("errors", []) + ["No theme analysis available"]}

        try:
            # Search for places
            places = await search_places_for_theme(theme_analysis)

            # Get prices for top places
            places = await get_place_prices(places, theme_analysis.city)

            return {
                "found_places": places,
                "current_phase": "places_found",
                "progress": 0.45,
                "agent_logs": state.get("agent_logs", []) + [{
                    "agent": "places_agent",
                    "action": "search",
                    "result": f"Found {len(places)} places",
                }],
            }

        except Exception as e:
            logger.error("Place search failed", error=str(e))
            return {
                "errors": state.get("errors", []) + [f"Place search failed: {e}"],
                "found_places": [],
            }

    async def _search_restaurants_node(self, state: MultiAgentState) -> dict:
        """Node: Search for themed restaurants."""
        logger.info("Node: search_restaurants")

        theme_analysis = state.get("theme_analysis")
        found_places = state.get("found_places", [])

        if not theme_analysis:
            return {"errors": state.get("errors", []) + ["No theme analysis available"]}

        try:
            # Group places by day for location-aware search
            places_per_day = theme_analysis.duration_days
            min_places_per_day = 3

            day_places = []
            for i in range(places_per_day):
                start_idx = i * min_places_per_day
                end_idx = start_idx + min_places_per_day
                day_places.append(found_places[start_idx:end_idx])

            # Search restaurants
            restaurants = await search_restaurants_parallel(theme_analysis, day_places)

            return {
                "found_restaurants": restaurants,
                "current_phase": "restaurants_found",
                "progress": 0.65,
                "agent_logs": state.get("agent_logs", []) + [{
                    "agent": "restaurant_agent",
                    "action": "search",
                    "result": f"Found {len(restaurants)} restaurants",
                }],
            }

        except Exception as e:
            logger.error("Restaurant search failed", error=str(e))
            return {
                "errors": state.get("errors", []) + [f"Restaurant search failed: {e}"],
                "found_restaurants": [],
            }

    async def _assemble_trip_node(self, state: MultiAgentState) -> dict:
        """Node: Assemble the final trip plan."""
        logger.info("Node: assemble_trip")

        theme_analysis = state.get("theme_analysis")
        found_places = state.get("found_places", [])
        found_restaurants = state.get("found_restaurants", [])

        if not theme_analysis:
            return {"errors": state.get("errors", []) + ["No theme analysis available"]}

        try:
            trip_plan = assemble_trip_plan(
                theme_analysis,
                found_places,
                found_restaurants,
            )

            return {
                "trip_plan": trip_plan,
                "current_phase": "assembled",
                "progress": 0.80,
                "agent_logs": state.get("agent_logs", []) + [{
                    "agent": "assembler",
                    "action": "assemble",
                    "result": f"Created {len(trip_plan.days)} day plan",
                }],
            }

        except Exception as e:
            logger.error("Trip assembly failed", error=str(e))
            return {
                "errors": state.get("errors", []) + [f"Assembly failed: {e}"],
            }

    async def _validate_node(self, state: MultiAgentState) -> dict:
        """Node: Validate the trip plan."""
        logger.info("Node: validate")

        trip_plan = state.get("trip_plan")
        if not trip_plan:
            return {
                "validation_result": ValidationResult(
                    is_valid=False,
                    issues=["No trip plan to validate"],
                    quality_score=0.0,
                )
            }

        try:
            validation_result = await validate_trip_plan(trip_plan)

            return {
                "validation_result": validation_result,
                "current_phase": "validated",
                "progress": 0.90,
                "agent_logs": state.get("agent_logs", []) + [{
                    "agent": "validator",
                    "action": "validate",
                    "result": f"Score: {validation_result.quality_score:.2f}, Valid: {validation_result.is_valid}",
                }],
            }

        except Exception as e:
            logger.error("Validation failed", error=str(e))
            return {
                "validation_result": ValidationResult(
                    is_valid=True,  # Pass through on error
                    issues=[f"Validation error: {e}"],
                    quality_score=0.5,
                ),
            }

    async def _finalize_node(self, state: MultiAgentState) -> dict:
        """Node: Finalize and format the trip."""
        logger.info("Node: finalize")

        trip_plan = state.get("trip_plan")
        if not trip_plan:
            return {"errors": state.get("errors", []) + ["No trip plan to finalize"]}

        # Convert to final JSON format
        final_trip = trip_plan_to_dict(trip_plan)

        return {
            "final_trip": final_trip,
            "current_phase": "complete",
            "progress": 1.0,
            "agent_logs": state.get("agent_logs", []) + [{
                "agent": "orchestrator",
                "action": "finalize",
                "result": "Trip finalized",
            }],
        }

    async def run(self, query: str, execution_id: str | None = None) -> dict:
        """
        Run the multi-agent pipeline.

        Args:
            query: User's trip request
            execution_id: Optional execution ID

        Returns:
            Final trip data
        """
        execution_id = execution_id or str(uuid.uuid4())

        # Clear place cache
        clear_place_cache()

        # Initialize state
        initial_state: MultiAgentState = {
            "query": query,
            "execution_id": execution_id,
            "messages": [],
            "theme_analysis": None,
            "found_places": [],
            "found_restaurants": [],
            "trip_plan": None,
            "validation_result": None,
            "final_trip": None,
            "current_phase": "starting",
            "progress": 0.0,
            "errors": [],
            "agent_logs": [],
        }

        logger.info("Starting multi-agent pipeline", query=query, execution_id=execution_id)

        try:
            # Run the graph
            result = await self.graph.ainvoke(initial_state)

            # Get cached places for photos
            place_cache = get_cached_places()

            return {
                "success": True,
                "execution_id": execution_id,
                "trip": result.get("final_trip"),
                "place_cache": place_cache,
                "validation": result.get("validation_result"),
                "agent_logs": result.get("agent_logs", []),
                "errors": result.get("errors", []),
            }

        except Exception as e:
            logger.error("Pipeline failed", error=str(e), execution_id=execution_id)
            return {
                "success": False,
                "execution_id": execution_id,
                "error": str(e),
            }


def assemble_trip_plan(
    theme_analysis: ThemeAnalysis,
    places: list[PlaceData],
    restaurants: list[RestaurantData],
) -> TripPlan:
    """
    Assemble places and restaurants into a day-by-day trip plan.

    Args:
        theme_analysis: Query analysis with theme and duration
        places: Found places sorted by relevance
        restaurants: Found restaurants with meal categories

    Returns:
        Complete TripPlan
    """
    logger.info(
        "Assembling trip",
        days=theme_analysis.duration_days,
        places=len(places),
        restaurants=len(restaurants),
    )

    days = []
    places_per_day = max(3, len(places) // theme_analysis.duration_days)

    for day_num in range(1, theme_analysis.duration_days + 1):
        # Get places for this day
        start_idx = (day_num - 1) * places_per_day
        end_idx = start_idx + places_per_day
        day_places = places[start_idx:end_idx]

        # Get restaurants for this day
        day_restaurants = []
        restaurants_per_day = len(restaurants) // theme_analysis.duration_days
        r_start = (day_num - 1) * restaurants_per_day
        r_end = r_start + restaurants_per_day

        # Try to get one of each meal type
        for category in ["breakfast", "lunch", "dinner"]:
            matching = [r for r in restaurants[r_start:r_end] if r.category == category]
            if matching:
                day_restaurants.append(matching[0])
            else:
                # Find any restaurant with this category
                all_matching = [r for r in restaurants if r.category == category]
                if all_matching:
                    day_restaurants.append(all_matching[0])

        # Generate day title based on places
        day_title = generate_day_title(day_num, day_places, theme_analysis.theme)

        days.append(DayPlan(
            day_number=day_num,
            title=day_title,
            description=f"Day {day_num} of your {theme_analysis.theme} adventure in {theme_analysis.city}",
            places=day_places,
            restaurants=day_restaurants,
        ))

    # Generate trip title
    trip_title = f"{theme_analysis.theme.title()} Trip to {theme_analysis.city}"

    return TripPlan(
        title=trip_title,
        description=f"A {theme_analysis.duration_days}-day {theme_analysis.theme} experience in {theme_analysis.city}, {theme_analysis.country}",
        city=theme_analysis.city,
        country=theme_analysis.country,
        duration_days=theme_analysis.duration_days,
        theme=theme_analysis.theme,
        days=days,
    )


def generate_day_title(day_num: int, places: list[PlaceData], theme: str) -> str:
    """Generate a title for a day based on its places."""
    if not places:
        return f"Day {day_num}"

    # Get unique types
    types = set()
    for p in places:
        types.update(p.types[:2])

    # Map types to friendly names
    type_names = {
        "museum": "Museums",
        "art_gallery": "Art",
        "park": "Nature",
        "shopping_mall": "Shopping",
        "restaurant": "Dining",
        "tourist_attraction": "Sightseeing",
        "store": "Shopping",
        "cafe": "Cafes",
    }

    friendly_types = [type_names.get(t, t.replace("_", " ").title()) for t in list(types)[:2]]

    if friendly_types:
        return f"Day {day_num}: {' & '.join(friendly_types)}"

    return f"Day {day_num}: Exploring {theme.title()}"


def trip_plan_to_dict(trip_plan: TripPlan) -> dict:
    """Convert TripPlan to dictionary format for API response."""
    return {
        "title": trip_plan.title,
        "description": trip_plan.description,
        "city": trip_plan.city,
        "country": trip_plan.country,
        "durationDays": trip_plan.duration_days,
        "theme": trip_plan.theme,
        "days": [
            {
                "dayNumber": day.day_number,
                "title": day.title,
                "description": day.description,
                "places": [
                    {
                        "place_id": p.place_id,
                        "name": p.name,
                        "address": p.address,
                        "rating": p.rating,
                        "price": p.price,
                        "price_level": p.price_level,
                        "type": p.types[0] if p.types else "attraction",
                        "category": "attraction",
                        "description": p.description or f"A great {trip_plan.theme} spot",
                        "duration_minutes": p.duration_minutes,
                        "latitude": p.latitude,
                        "longitude": p.longitude,
                        "images": [{"url": url, "source": "google_places"} for url in p.photo_urls],
                        "opening_hours": p.opening_hours,
                    }
                    for p in day.places
                ],
                "restaurants": [
                    {
                        "place_id": r.place_id,
                        "name": r.name,
                        "address": r.address,
                        "rating": r.rating,
                        "price_range": r.price_range,
                        "type": "restaurant",
                        "category": r.category,
                        "description": r.description or f"Great {r.cuisine or 'local'} cuisine",
                        "duration_minutes": r.duration_minutes,
                        "latitude": r.latitude,
                        "longitude": r.longitude,
                        "cuisine": r.cuisine,
                        "images": [{"url": url, "source": "google_places"} for url in r.photo_urls],
                        "opening_hours": r.opening_hours,
                    }
                    for r in day.restaurants
                ],
            }
            for day in trip_plan.days
        ],
    }


async def generate_trip_multi_agent(
    query: str,
    thread_id: str | None = None,
) -> dict:
    """
    Generate a trip using the multi-agent system.

    This is the main entry point for the new architecture.

    Args:
        query: User's trip request
        thread_id: Optional thread ID

    Returns:
        Trip generation result
    """
    execution_id = str(uuid.uuid4())
    effective_thread_id = thread_id or f"trip-{execution_id}"

    # Initialize agent logger
    agent_logger = AgentLogger(trip_id=execution_id, query=query)
    agent_logger.start(query)

    try:
        orchestrator = TripOrchestrator()
        result = await orchestrator.run(query, execution_id)

        if result.get("success"):
            agent_logger.complete(success=True)
        else:
            agent_logger.complete(success=False, error=result.get("error"))

        return {
            **result,
            "thread_id": effective_thread_id,
        }

    except Exception as e:
        agent_logger.complete(success=False, error=str(e))
        return {
            "success": False,
            "execution_id": execution_id,
            "error": str(e),
        }
