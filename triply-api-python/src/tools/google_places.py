"""
Google Places Tool

LangChain tool for searching places using Google Places API (New)
"""

import httpx
import structlog
from langchain_core.tools import tool
from pydantic import BaseModel, Field

from ..config import settings

logger = structlog.get_logger()

# Google Places API (New) base URL
PLACES_API_URL = "https://places.googleapis.com/v1/places:searchText"


class PlaceSearchInput(BaseModel):
    """Input schema for place search"""

    query: str = Field(description="Search query, e.g. 'romantic restaurants in Paris'")
    max_results: int = Field(default=10, ge=1, le=20, description="Maximum number of results")


class PlaceResult(BaseModel):
    """Simplified place result from Google Places"""

    place_id: str
    name: str
    address: str | None = None
    rating: float | None = None
    user_ratings_total: int | None = None
    price_level: int | None = None
    types: list[str] = []
    location: dict | None = None
    photo_url: str | None = None
    opening_hours: list[str] | None = None
    website: str | None = None


async def search_places_api(query: str, max_results: int = 10) -> list[dict]:
    """
    Call Google Places API (New) Text Search

    Returns raw place data from Google
    """
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": settings.places_api_key,
        "X-Goog-FieldMask": ",".join([
            "places.id",
            "places.displayName",
            "places.formattedAddress",
            "places.rating",
            "places.userRatingCount",
            "places.priceLevel",
            "places.types",
            "places.location",
            "places.photos",
            "places.regularOpeningHours",
            "places.websiteUri",
            "places.reviews",
        ]),
    }

    body = {
        "textQuery": query,
        "maxResultCount": max_results,
        "languageCode": "en",
    }

    async with httpx.AsyncClient() as client:
        response = await client.post(PLACES_API_URL, json=body, headers=headers, timeout=30)
        response.raise_for_status()
        data = response.json()

    return data.get("places", [])


def get_photo_url(photo_name: str, max_width: int = 800) -> str:
    """Generate photo URL from Google Places photo reference"""
    return (
        f"https://places.googleapis.com/v1/{photo_name}/media"
        f"?maxWidthPx={max_width}&key={settings.places_api_key}"
    )


def convert_google_place(place: dict) -> PlaceResult:
    """Convert Google Places API response to our schema"""
    photos = place.get("photos", [])
    photo_url = get_photo_url(photos[0]["name"]) if photos else None

    opening_hours = None
    if "regularOpeningHours" in place:
        opening_hours = place["regularOpeningHours"].get("weekdayDescriptions", [])

    location = None
    if "location" in place:
        location = {
            "lat": place["location"].get("latitude"),
            "lng": place["location"].get("longitude"),
        }

    # Convert price level from PRICE_LEVEL_* enum to int
    price_level = None
    price_str = place.get("priceLevel", "")
    if price_str:
        price_map = {
            "PRICE_LEVEL_FREE": 0,
            "PRICE_LEVEL_INEXPENSIVE": 1,
            "PRICE_LEVEL_MODERATE": 2,
            "PRICE_LEVEL_EXPENSIVE": 3,
            "PRICE_LEVEL_VERY_EXPENSIVE": 4,
        }
        price_level = price_map.get(price_str)

    return PlaceResult(
        place_id=place.get("id", ""),
        name=place.get("displayName", {}).get("text", "Unknown"),
        address=place.get("formattedAddress"),
        rating=place.get("rating"),
        user_ratings_total=place.get("userRatingCount"),
        price_level=price_level,
        types=place.get("types", []),
        location=location,
        photo_url=photo_url,
        opening_hours=opening_hours,
        website=place.get("websiteUri"),
    )


@tool
async def search_places(query: str, max_results: int = 10) -> str:
    """
    Search for places using Google Places API.

    Use this tool to find restaurants, attractions, hotels, bars, cafes,
    museums, parks, and any other places in a specific city.

    Args:
        query: Search query like "romantic restaurants in Paris" or "anime shops in Tokyo"
        max_results: Maximum number of results (1-20)

    Returns:
        JSON string with list of places including name, address, rating, etc.
    """
    logger.info("Searching places", query=query, max_results=max_results)

    try:
        raw_places = await search_places_api(query, max_results)
        places = [convert_google_place(p) for p in raw_places]

        logger.info("Found places", count=len(places), query=query)

        # Format as readable string for the agent
        if not places:
            return f"No places found for query: {query}"

        results = []
        for i, p in enumerate(places, 1):
            rating_str = f"Rating: {p.rating}/5 ({p.user_ratings_total} reviews)" if p.rating else "No rating"
            price_str = "💰" * (p.price_level or 0) if p.price_level else ""
            results.append(
                f"{i}. {p.name}\n"
                f"   Address: {p.address or 'N/A'}\n"
                f"   {rating_str} {price_str}\n"
                f"   Types: {', '.join(p.types[:5])}\n"
                f"   ID: {p.place_id}"
            )

        return "\n\n".join(results)

    except httpx.HTTPStatusError as e:
        logger.error("Google Places API error", status=e.response.status_code, error=str(e))
        return f"Error searching places: {e.response.status_code}"
    except Exception as e:
        logger.error("Place search failed", error=str(e))
        return f"Error searching places: {str(e)}"


@tool
async def get_place_details(place_id: str) -> str:
    """
    Get detailed information about a specific place.

    Use this tool when you need more details about a place you found,
    such as reviews, photos, opening hours, etc.

    Args:
        place_id: The Google Place ID

    Returns:
        Detailed information about the place
    """
    logger.info("Getting place details", place_id=place_id)

    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": settings.places_api_key,
        "X-Goog-FieldMask": ",".join([
            "id",
            "displayName",
            "formattedAddress",
            "rating",
            "userRatingCount",
            "priceLevel",
            "types",
            "location",
            "photos",
            "regularOpeningHours",
            "websiteUri",
            "reviews",
            "editorialSummary",
        ]),
    }

    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"https://places.googleapis.com/v1/places/{place_id}",
                headers=headers,
                timeout=30,
            )
            response.raise_for_status()
            place = response.json()

        # Format response
        name = place.get("displayName", {}).get("text", "Unknown")
        address = place.get("formattedAddress", "N/A")
        rating = place.get("rating", "N/A")
        reviews_count = place.get("userRatingCount", 0)
        summary = place.get("editorialSummary", {}).get("text", "No description available")

        opening_hours = "N/A"
        if "regularOpeningHours" in place:
            hours = place["regularOpeningHours"].get("weekdayDescriptions", [])
            opening_hours = "\n   ".join(hours)

        reviews_text = ""
        reviews = place.get("reviews", [])
        if reviews:
            reviews_text = "\n\nTop Reviews:\n"
            for r in reviews[:3]:
                author = r.get("authorAttribution", {}).get("displayName", "Anonymous")
                text = r.get("text", {}).get("text", "")[:200]
                r_rating = r.get("rating", "?")
                reviews_text += f"- {author} ({r_rating}/5): {text}...\n"

        return (
            f"Name: {name}\n"
            f"Address: {address}\n"
            f"Rating: {rating}/5 ({reviews_count} reviews)\n"
            f"Summary: {summary}\n"
            f"Opening Hours:\n   {opening_hours}"
            f"{reviews_text}"
        )

    except Exception as e:
        logger.error("Failed to get place details", place_id=place_id, error=str(e))
        return f"Error getting place details: {str(e)}"
