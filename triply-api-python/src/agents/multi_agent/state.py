"""
Multi-Agent State

Defines the state that flows through the multi-agent graph.
Each agent reads from and writes to this shared state.
"""

from typing import Annotated, Any
from typing_extensions import TypedDict
from pydantic import BaseModel
from langgraph.graph.message import add_messages
from langchain_core.messages import BaseMessage


class ThemeAnalysis(BaseModel):
    """Result of analyzing the user's query for theme"""
    theme: str  # Main theme (e.g., "anime", "romantic", "biker")
    related_themes: list[str]  # Related themes to expand search
    search_queries: list[str]  # Pre-generated search queries
    restaurant_queries: list[str]  # Restaurant search queries
    city: str
    country: str
    duration_days: int
    special_requirements: list[str]  # e.g., "vegan", "wheelchair accessible"


class PlaceData(BaseModel):
    """Place data from search"""
    place_id: str
    name: str
    address: str | None = None
    rating: float | None = None
    price: str | None = None  # Real ticket price from web search
    price_level: int | None = None
    types: list[str] = []
    latitude: float | None = None
    longitude: float | None = None
    photo_urls: list[str] = []
    description: str | None = None
    duration_minutes: int = 60
    opening_hours: list[str] | None = None
    theme_relevance: float = 1.0  # How relevant to the theme (0-1)


class RestaurantData(BaseModel):
    """Restaurant data from search"""
    place_id: str
    name: str
    address: str | None = None
    rating: float | None = None
    price_range: str | None = None  # $, $$, $$$
    price_level: int | None = None
    cuisine: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    photo_urls: list[str] = []
    category: str  # breakfast, lunch, dinner
    description: str | None = None
    duration_minutes: int = 45
    opening_hours: list[str] | None = None


class DayPlan(BaseModel):
    """Plan for a single day"""
    day_number: int
    title: str
    description: str
    places: list[PlaceData] = []
    restaurants: list[RestaurantData] = []


class TripPlan(BaseModel):
    """Complete trip plan"""
    title: str
    description: str
    city: str
    country: str
    duration_days: int
    theme: str
    days: list[DayPlan] = []


class ValidationResult(BaseModel):
    """Result of validation"""
    is_valid: bool
    issues: list[str] = []
    suggestions: list[str] = []
    quality_score: float = 0.0  # 0-1


class MultiAgentState(TypedDict):
    """
    Shared state for the multi-agent trip planning system.

    This state flows through all agents in the graph.
    Each agent reads what it needs and writes its results.
    """

    # Input
    query: str
    execution_id: str

    # Messages for agent communication
    messages: Annotated[list[BaseMessage], add_messages]

    # Phase 1: Query Analysis
    theme_analysis: ThemeAnalysis | None

    # Phase 2: Place Search (parallel)
    found_places: list[PlaceData]
    found_restaurants: list[RestaurantData]

    # Phase 3: Trip Assembly
    trip_plan: TripPlan | None

    # Phase 4: Validation
    validation_result: ValidationResult | None

    # Final Output
    final_trip: dict | None

    # Progress tracking
    current_phase: str
    progress: float  # 0.0 - 1.0

    # Error handling
    errors: list[str]

    # Agent execution log
    agent_logs: list[dict]
