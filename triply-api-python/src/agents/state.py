"""
Agent State

Defines the state that flows through the LangGraph
"""

from typing import Annotated, Sequence
from typing_extensions import TypedDict

from langchain_core.messages import BaseMessage
from langgraph.graph.message import add_messages

from ..schemas import Place, Trip, TripIntent


class AgentState(TypedDict):
    """
    State for the Trip Planning Agent

    This state flows through all nodes in the graph.
    Messages are accumulated using the add_messages reducer.
    """

    # Core request
    query: str
    execution_id: str

    # Messages for ReAct reasoning (accumulated)
    messages: Annotated[Sequence[BaseMessage], add_messages]

    # Parsed intent
    intent: TripIntent | None

    # Discovered places
    places: list[Place]

    # Final trip
    trip: Trip | None

    # Progress tracking
    current_phase: str
    progress: int

    # Error handling
    errors: list[str]

    # Metadata
    reasoning_steps: list[str]  # Track agent's thinking
    tool_calls: list[dict]  # Track tool usage
