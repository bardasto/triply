"""
Places Agent

Specialized agent for finding themed attractions and places.
Uses pre-generated search queries from Query Analyzer.
Searches in parallel and filters results by theme relevance.
"""

import asyncio
import json
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage, SystemMessage

from ...config import settings
from ...logging import get_logger
from ...tools.google_places import search_places_api, convert_google_place, get_cached_places
from ...tools.web_search import web_search
from .state import ThemeAnalysis, PlaceData

logger = get_logger("places_agent")

# Prompt for evaluating theme relevance
RELEVANCE_PROMPT = """You are evaluating places for a THEMED trip.

Theme: {theme}
Related themes: {related_themes}

For each place, score its relevance to the theme from 0.0 to 1.0:
- 1.0 = Perfectly matches the theme (e.g., anime shop for anime trip)
- 0.7-0.9 = Strongly related to theme
- 0.4-0.6 = Somewhat related
- 0.1-0.3 = Weakly related
- 0.0 = Not related at all (generic tourist spot)

Places to evaluate:
{places}

Return JSON array with place_id and relevance_score:
[{{"place_id": "xxx", "relevance_score": 0.9, "reason": "Direct anime merchandise shop"}}]

IMPORTANT: Be strict! Generic landmarks that don't match the theme should get LOW scores.
For example, if theme is "anime" and place is "Eiffel Tower", score should be 0.1 or less.

Return ONLY valid JSON array."""


async def search_places_for_theme(
    theme_analysis: ThemeAnalysis,
    min_places_per_day: int = 4,
) -> list[PlaceData]:
    """
    Search for places matching the theme.

    Executes multiple searches in parallel using pre-generated queries,
    then filters and ranks results by theme relevance.

    Args:
        theme_analysis: Analyzed query with search queries
        min_places_per_day: Minimum places needed per day

    Returns:
        List of PlaceData sorted by theme relevance
    """
    logger.info(
        "Searching places for theme",
        theme=theme_analysis.theme,
        city=theme_analysis.city,
        queries_count=len(theme_analysis.search_queries),
    )

    # Calculate how many places we need
    total_needed = theme_analysis.duration_days * min_places_per_day
    # Search for more than needed to filter
    search_limit = max(total_needed * 2, 20)

    # Execute all search queries in parallel
    async def search_single_query(query: str) -> list[dict]:
        try:
            results = await search_places_api(query, max_results=5)
            logger.debug(f"Query '{query}' returned {len(results)} results")
            return results
        except Exception as e:
            logger.error(f"Search failed for query '{query}'", error=str(e))
            return []

    # Run all searches in parallel
    all_results = await asyncio.gather(
        *[search_single_query(q) for q in theme_analysis.search_queries],
        return_exceptions=True
    )

    # Flatten and deduplicate results
    seen_ids = set()
    unique_places = []

    for result in all_results:
        if isinstance(result, Exception):
            continue
        for place in result:
            place_id = place.get("id", "")
            if place_id and place_id not in seen_ids:
                seen_ids.add(place_id)
                unique_places.append(place)

    logger.info(f"Found {len(unique_places)} unique places from {len(theme_analysis.search_queries)} queries")

    if not unique_places:
        logger.warning("No places found, trying related themes")
        # Try related themes
        for related_theme in theme_analysis.related_themes[:3]:
            query = f"{related_theme} {theme_analysis.city}"
            try:
                results = await search_places_api(query, max_results=10)
                for place in results:
                    place_id = place.get("id", "")
                    if place_id and place_id not in seen_ids:
                        seen_ids.add(place_id)
                        unique_places.append(place)
            except Exception as e:
                logger.error(f"Related theme search failed", error=str(e))

    # Types that indicate a restaurant/food establishment - MUST be excluded from places
    RESTAURANT_TYPES = {
        "restaurant",
        "food",
        "cafe",
        "bakery",
        "bar",
        "meal_delivery",
        "meal_takeaway",
        "night_club",
        "liquor_store",
        "coffee_shop",
    }

    # Convert to PlaceResult and then to PlaceData
    converted_places = []
    for raw_place in unique_places:
        try:
            place_result = convert_google_place(raw_place)

            # STRICT: Filter out restaurants - they should NEVER appear in places
            place_types_set = set(place_result.types)
            if place_types_set & RESTAURANT_TYPES:
                logger.debug(
                    f"Filtering out restaurant from places",
                    name=place_result.name,
                    types=place_result.types,
                )
                continue

            converted_places.append(PlaceData(
                place_id=place_result.place_id,
                name=place_result.name,
                address=place_result.address,
                rating=place_result.rating,
                price_level=place_result.price_level,
                types=place_result.types,
                latitude=place_result.location.get("lat") if place_result.location else None,
                longitude=place_result.location.get("lng") if place_result.location else None,
                photo_urls=place_result.photo_urls,
                opening_hours=place_result.opening_hours,
                description=place_result.description,
            ))
        except Exception as e:
            logger.error(f"Failed to convert place", error=str(e))

    # Evaluate theme relevance using LLM
    if converted_places:
        converted_places = await evaluate_theme_relevance(
            converted_places,
            theme_analysis.theme,
            theme_analysis.related_themes,
        )

    # Sort by relevance and take top results
    converted_places.sort(key=lambda x: x.theme_relevance, reverse=True)

    # Filter out low-relevance places
    min_relevance = 0.3
    filtered_places = [p for p in converted_places if p.theme_relevance >= min_relevance]

    # If we don't have enough, include some lower relevance ones
    if len(filtered_places) < total_needed:
        remaining = total_needed - len(filtered_places)
        low_relevance = [p for p in converted_places if p.theme_relevance < min_relevance]
        filtered_places.extend(low_relevance[:remaining])

    logger.info(
        "Places search complete",
        total_found=len(unique_places),
        after_filter=len(filtered_places),
        theme=theme_analysis.theme,
    )

    return filtered_places[:search_limit]


async def evaluate_theme_relevance(
    places: list[PlaceData],
    theme: str,
    related_themes: list[str],
) -> list[PlaceData]:
    """
    Use LLM to evaluate how relevant each place is to the theme.

    Args:
        places: List of places to evaluate
        theme: Main theme
        related_themes: Related themes

    Returns:
        Places with updated theme_relevance scores
    """
    if not places:
        return places

    # Prepare places info for LLM
    places_info = []
    for p in places[:30]:  # Limit to avoid token limits
        places_info.append({
            "place_id": p.place_id,
            "name": p.name,
            "types": p.types[:5],
            "address": p.address,
        })

    model = ChatGoogleGenerativeAI(
        model="gemini-2.0-flash-exp",
        google_api_key=settings.google_api_key,
        temperature=0.1,
    )

    prompt = RELEVANCE_PROMPT.format(
        theme=theme,
        related_themes=", ".join(related_themes),
        places=json.dumps(places_info, indent=2),
    )

    try:
        response = await model.ainvoke([HumanMessage(content=prompt)])
        content = response.content

        # Parse response
        if isinstance(content, str):
            # Clean markdown
            if "```" in content:
                import re
                match = re.search(r'```(?:json)?\s*([\s\S]*?)\s*```', content)
                if match:
                    content = match.group(1)

            scores = json.loads(content)

            # Create lookup
            score_map = {s["place_id"]: s["relevance_score"] for s in scores}

            # Update places
            for place in places:
                if place.place_id in score_map:
                    place.theme_relevance = score_map[place.place_id]

    except Exception as e:
        logger.error("Failed to evaluate theme relevance", error=str(e))
        # Keep default relevance

    return places


async def get_place_prices(places: list[PlaceData], city: str) -> list[PlaceData]:
    """
    Search for real ticket prices for attractions.

    Args:
        places: Places to get prices for
        city: City name for search context

    Returns:
        Places with updated price information
    """
    logger.info(f"Getting prices for {len(places)} places")

    async def get_price_for_place(place: PlaceData) -> tuple[str, str | None]:
        try:
            # Use web search to find ticket price
            query = f"{place.name} {city} entrance fee ticket price 2024"
            result = await web_search.ainvoke({"query": query, "max_results": 3})

            # Simple extraction - look for price patterns
            if isinstance(result, str):
                import re
                # Look for common price patterns
                patterns = [
                    r'[€$£]\s*\d+(?:\.\d{2})?',
                    r'\d+(?:\.\d{2})?\s*[€$£]',
                    r'(?:EUR|USD|GBP)\s*\d+',
                ]
                for pattern in patterns:
                    match = re.search(pattern, result)
                    if match:
                        return (place.place_id, match.group(0))

                # Check for "free" mentions
                if "free" in result.lower() and "admission" in result.lower():
                    return (place.place_id, "Free")

            return (place.place_id, None)

        except Exception as e:
            logger.error(f"Price search failed for {place.name}", error=str(e))
            return (place.place_id, None)

    # Get prices in parallel (limit concurrency)
    semaphore = asyncio.Semaphore(5)

    async def limited_get_price(place):
        async with semaphore:
            return await get_price_for_place(place)

    # Only get prices for top places (to save API calls)
    top_places = places[:15]
    price_results = await asyncio.gather(
        *[limited_get_price(p) for p in top_places],
        return_exceptions=True
    )

    # Update places with prices
    price_map = {}
    for result in price_results:
        if isinstance(result, tuple):
            place_id, price = result
            if price:
                price_map[place_id] = price

    for place in places:
        if place.place_id in price_map:
            place.price = price_map[place.place_id]

    logger.info(f"Found prices for {len(price_map)} places")
    return places
