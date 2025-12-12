"""
Multi-Agent Trip Planning System

A production-ready multi-agent architecture for trip planning:
- Orchestrator: Coordinates all agents
- Query Analyzer: Parses user intent and theme
- Places Agent: Finds themed attractions
- Restaurant Agent: Finds themed restaurants
- Validator: Quality checks the final output
"""

from .orchestrator import TripOrchestrator, generate_trip_multi_agent
from .state import MultiAgentState

__all__ = [
    "TripOrchestrator",
    "generate_trip_multi_agent",
    "MultiAgentState",
]
