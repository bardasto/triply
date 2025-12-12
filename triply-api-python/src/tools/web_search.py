"""
Web Search Tool

LangChain tool for searching the web using Tavily API
Tavily is specifically designed for AI agents and provides high-quality search results
"""

import structlog
from langchain_core.tools import tool

from ..config import settings

logger = structlog.get_logger()

# Optional: Use Tavily if available
try:
    from tavily import TavilyClient

    TAVILY_AVAILABLE = bool(settings.tavily_api_key)
except ImportError:
    TAVILY_AVAILABLE = False


@tool
async def web_search(query: str, max_results: int = 5) -> str:
    """
    Search the web for information.

    Use this tool to find:
    - Current events, festivals, and seasonal activities in a city
    - Local tips and hidden gems that tourists might not know about
    - Best times to visit attractions
    - Cultural information and customs
    - Specific niche interests (anime spots, vegan restaurants, LGBTQ+ friendly places, etc.)
    - Recent reviews and recommendations

    Args:
        query: Search query like "best anime shops Tokyo 2024" or "vegan restaurants Berlin"
        max_results: Maximum number of results (1-10)

    Returns:
        Search results with titles, snippets, and URLs
    """
    logger.info("Web search", query=query, max_results=max_results)

    if not TAVILY_AVAILABLE:
        return (
            "Web search is not available. To enable it, install tavily-python "
            "and set TAVILY_API_KEY in your environment."
        )

    try:
        client = TavilyClient(api_key=settings.tavily_api_key)

        # Use search_context for more relevant AI-friendly results
        response = client.search(
            query=query,
            search_depth="advanced",  # More thorough search
            max_results=max_results,
            include_answer=True,  # Get AI-generated answer summary
        )

        # Format results
        results = []

        # Include AI answer if available
        if response.get("answer"):
            results.append(f"Summary: {response['answer']}\n")

        # Include search results
        for i, r in enumerate(response.get("results", []), 1):
            title = r.get("title", "No title")
            content = r.get("content", "")[:300]
            url = r.get("url", "")
            results.append(f"{i}. {title}\n   {content}\n   Source: {url}")

        if not results:
            return f"No results found for: {query}"

        return "\n\n".join(results)

    except Exception as e:
        logger.error("Web search failed", query=query, error=str(e))
        return f"Error performing web search: {str(e)}"


@tool
async def get_destination_info(city: str, country: str) -> str:
    """
    Get comprehensive information about a travel destination.

    Use this tool to learn about:
    - Best time to visit
    - Local culture and customs
    - Must-know tips for travelers
    - Popular neighborhoods
    - Transportation options

    Args:
        city: City name
        country: Country name

    Returns:
        Comprehensive destination information
    """
    logger.info("Getting destination info", city=city, country=country)

    if not TAVILY_AVAILABLE:
        return (
            f"Destination info search is not available. "
            f"Using basic info for {city}, {country}."
        )

    try:
        client = TavilyClient(api_key=settings.tavily_api_key)

        # Search for comprehensive travel info
        query = f"{city} {country} travel guide tips best things to do 2024"

        response = client.search(
            query=query,
            search_depth="advanced",
            max_results=5,
            include_answer=True,
        )

        results = []

        if response.get("answer"):
            results.append(f"Overview:\n{response['answer']}\n")

        # Add key points from search results
        results.append("Key Information:")
        for r in response.get("results", [])[:3]:
            content = r.get("content", "")[:400]
            if content:
                results.append(f"- {content}")

        return "\n".join(results) if results else f"Basic destination: {city}, {country}"

    except Exception as e:
        logger.error("Destination info failed", city=city, country=country, error=str(e))
        return f"Could not fetch destination info: {str(e)}"
