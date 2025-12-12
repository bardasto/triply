"""
Restaurant Agent

Specialized agent for finding themed restaurants.
Finds breakfast, lunch, and dinner spots that match the trip theme.
Uses location-aware search to place restaurants near day's attractions.
"""

import asyncio
import json
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage

from ...config import settings
from ...logging import get_logger
from ...tools.google_places import search_places_api, convert_google_place
from .state import ThemeAnalysis, PlaceData, RestaurantData

logger = get_logger("restaurant_agent")

# Cuisine mapping for different themes
THEME_CUISINE_MAP = {
    "anime": ["japanese", "ramen", "sushi", "izakaya", "maid cafe", "themed cafe"],
    "manga": ["japanese", "ramen", "anime cafe", "themed restaurant"],
    "japanese": ["japanese", "ramen", "sushi", "izakaya", "tempura"],
    "romantic": ["french", "italian", "fine dining", "rooftop", "candlelit"],
    "couples": ["romantic", "intimate", "fine dining", "wine bar"],
    "biker": ["steakhouse", "bbq", "roadside diner", "pub", "bar"],
    "motorcycle": ["american", "steakhouse", "diner", "bar and grill"],
    "vegan": ["vegan", "plant-based", "vegetarian", "organic", "raw food"],
    "vegetarian": ["vegetarian", "vegan", "organic", "healthy"],
    "adventure": ["local cuisine", "street food", "traditional", "exotic"],
    "foodie": ["michelin", "fine dining", "local specialties", "street food"],
    "budget": ["street food", "local", "cheap eats", "fast food"],
    "luxury": ["fine dining", "michelin star", "gourmet", "exclusive"],
    "family": ["family restaurant", "kid-friendly", "casual dining"],
    "nightlife": ["bar", "club", "late night", "cocktail bar"],
}

# Default meal preferences by time
MEAL_PREFERENCES = {
    "breakfast": ["cafe", "breakfast", "brunch", "bakery", "coffee shop"],
    "lunch": ["restaurant", "bistro", "casual dining", "lunch spot"],
    "dinner": ["restaurant", "fine dining", "dinner", "evening dining"],
}


async def search_restaurants_for_theme(
    theme_analysis: ThemeAnalysis,
    day_places: list[list[PlaceData]],  # Places grouped by day
) -> list[RestaurantData]:
    """
    Search for restaurants matching the theme.

    For each day, finds:
    - Breakfast near first attraction
    - Lunch near middle attractions
    - Dinner near last attraction

    Args:
        theme_analysis: Analyzed query with restaurant queries
        day_places: Places grouped by day for location-aware search

    Returns:
        List of RestaurantData with meal category assigned
    """
    logger.info(
        "Searching restaurants for theme",
        theme=theme_analysis.theme,
        city=theme_analysis.city,
        days=len(day_places),
    )

    all_restaurants: list[RestaurantData] = []

    # Get theme-specific cuisines
    theme_cuisines = THEME_CUISINE_MAP.get(
        theme_analysis.theme.lower(),
        THEME_CUISINE_MAP.get("foodie", ["local cuisine"])
    )

    # Search for each day
    for day_num, places in enumerate(day_places, 1):
        if not places:
            continue

        # Get coordinates for location-aware search
        first_place = places[0] if places else None
        middle_place = places[len(places) // 2] if len(places) > 1 else first_place
        last_place = places[-1] if places else first_place

        # Search for breakfast, lunch, dinner
        meal_searches = [
            ("breakfast", first_place, theme_cuisines + MEAL_PREFERENCES["breakfast"]),
            ("lunch", middle_place, theme_cuisines + MEAL_PREFERENCES["lunch"]),
            ("dinner", last_place, theme_cuisines + MEAL_PREFERENCES["dinner"]),
        ]

        for meal_type, near_place, cuisines in meal_searches:
            # Build location-aware query
            location = None
            if near_place and near_place.latitude and near_place.longitude:
                location = {"lat": near_place.latitude, "lng": near_place.longitude}

            # Try themed search first
            restaurant = await search_single_restaurant(
                theme_analysis.city,
                meal_type,
                cuisines[:3],  # Top cuisines
                location,
            )

            if restaurant:
                restaurant.category = meal_type
                all_restaurants.append(restaurant)
            else:
                # Fallback to general search
                restaurant = await search_single_restaurant(
                    theme_analysis.city,
                    meal_type,
                    MEAL_PREFERENCES[meal_type],
                    location,
                )
                if restaurant:
                    restaurant.category = meal_type
                    all_restaurants.append(restaurant)

    logger.info(
        "Restaurant search complete",
        total_found=len(all_restaurants),
        theme=theme_analysis.theme,
    )

    return all_restaurants


async def search_single_restaurant(
    city: str,
    meal_type: str,
    cuisines: list[str],
    location: dict | None = None,
) -> RestaurantData | None:
    """
    Search for a single restaurant matching criteria.

    Args:
        city: City to search in
        meal_type: breakfast, lunch, or dinner
        cuisines: List of cuisine types to try
        location: Optional location to search near

    Returns:
        Best matching RestaurantData or None
    """
    # Try each cuisine type
    for cuisine in cuisines:
        query = f"{cuisine} {meal_type} restaurant {city}"

        try:
            results = await search_places_api(
                query,
                max_results=3,
                location=location,
                radius=1500,
            )

            if results:
                # Take the highest rated one
                best = max(results, key=lambda x: x.get("rating", 0))
                place = convert_google_place(best)

                # Determine price range
                price_range = None
                if place.price_level is not None:
                    price_symbols = ["Free", "$", "$$", "$$$", "$$$$"]
                    price_range = price_symbols[min(place.price_level, 4)]

                return RestaurantData(
                    place_id=place.place_id,
                    name=place.name,
                    address=place.address,
                    rating=place.rating,
                    price_range=price_range,
                    price_level=place.price_level,
                    cuisine=cuisine,
                    latitude=place.location.get("lat") if place.location else None,
                    longitude=place.location.get("lng") if place.location else None,
                    photo_urls=place.photo_urls,
                    category=meal_type,
                    opening_hours=place.opening_hours,
                )

        except Exception as e:
            logger.error(f"Restaurant search failed", query=query, error=str(e))
            continue

    return None


async def search_restaurants_parallel(
    theme_analysis: ThemeAnalysis,
    day_places: list[list[PlaceData]],
) -> list[RestaurantData]:
    """
    Search for all restaurants in parallel.

    More efficient version that batches searches.

    Args:
        theme_analysis: Query analysis
        day_places: Places by day

    Returns:
        All found restaurants
    """
    logger.info("Searching restaurants in parallel")

    # Get theme cuisines
    theme_cuisines = THEME_CUISINE_MAP.get(
        theme_analysis.theme.lower(),
        ["local cuisine", "popular restaurant"]
    )

    async def search_day_restaurants(day_num: int, places: list[PlaceData]) -> list[RestaurantData]:
        """Search restaurants for a single day"""
        restaurants = []

        if not places:
            return restaurants

        first_place = places[0]
        middle_place = places[len(places) // 2]
        last_place = places[-1]

        # Parallel search for all three meals
        tasks = []

        for meal_type, near_place in [
            ("breakfast", first_place),
            ("lunch", middle_place),
            ("dinner", last_place),
        ]:
            location = None
            if near_place.latitude and near_place.longitude:
                location = {"lat": near_place.latitude, "lng": near_place.longitude}

            # Build query
            cuisine = theme_cuisines[0] if theme_cuisines else "restaurant"
            query = f"{cuisine} {meal_type} {theme_analysis.city}"

            tasks.append((meal_type, query, location))

        # Execute searches
        for meal_type, query, location in tasks:
            try:
                results = await search_places_api(query, max_results=3, location=location, radius=1500)

                if results:
                    best = max(results, key=lambda x: x.get("rating", 0))
                    place = convert_google_place(best)

                    price_range = None
                    if place.price_level is not None:
                        price_symbols = ["Free", "$", "$$", "$$$", "$$$$"]
                        price_range = price_symbols[min(place.price_level, 4)]

                    restaurants.append(RestaurantData(
                        place_id=place.place_id,
                        name=place.name,
                        address=place.address,
                        rating=place.rating,
                        price_range=price_range,
                        price_level=place.price_level,
                        cuisine=theme_cuisines[0] if theme_cuisines else "local",
                        latitude=place.location.get("lat") if place.location else None,
                        longitude=place.location.get("lng") if place.location else None,
                        photo_urls=place.photo_urls,
                        category=meal_type,
                        opening_hours=place.opening_hours,
                    ))

            except Exception as e:
                logger.error(f"Restaurant search failed for day {day_num}", error=str(e))

        return restaurants

    # Search all days in parallel
    all_results = await asyncio.gather(
        *[search_day_restaurants(i, places) for i, places in enumerate(day_places, 1)],
        return_exceptions=True
    )

    # Flatten results
    all_restaurants = []
    for result in all_results:
        if isinstance(result, list):
            all_restaurants.extend(result)

    logger.info(f"Found {len(all_restaurants)} restaurants total")
    return all_restaurants
