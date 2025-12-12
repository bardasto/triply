"""
Agent Tools

Tools available for the ReAct agent to use during trip planning
"""

from .google_places import search_places, get_place_details
from .web_search import web_search, get_destination_info

# All tools available to the agent
ALL_TOOLS = [
    search_places,
    get_place_details,
    web_search,
    get_destination_info,
]

__all__ = [
    "search_places",
    "get_place_details",
    "web_search",
    "get_destination_info",
    "ALL_TOOLS",
]
