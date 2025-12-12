"""
Place Schema

Represents a place/venue in the trip itinerary
"""

from pydantic import BaseModel, Field


class PlaceReview(BaseModel):
    """A review for a place"""

    author: str
    rating: float
    text: str
    time: str | None = None


class Place(BaseModel):
    """A place/venue that can be added to the trip"""

    place_id: str = Field(description="Unique identifier from Google Places")
    name: str = Field(description="Name of the place")
    category: str = Field(description="Category: attraction, restaurant, cafe, bar, nightlife, etc.")
    description: str | None = Field(default=None, description="AI-generated description")
    address: str | None = Field(default=None, description="Full address")
    location: dict | None = Field(default=None, description="Lat/lng coordinates")
    rating: float | None = Field(default=None, ge=0, le=5, description="Google rating 0-5")
    user_ratings_total: int | None = Field(default=None, description="Number of ratings")
    price_level: int | None = Field(default=None, ge=0, le=4, description="Price level 0-4")
    opening_hours: list[str] | None = Field(default=None, description="Opening hours")
    phone: str | None = Field(default=None, description="Phone number")
    website: str | None = Field(default=None, description="Website URL")
    image_url: str | None = Field(default=None, description="Primary photo URL")
    images: list[str] | None = Field(default=None, description="Additional photo URLs")
    reviews: list[PlaceReview] | None = Field(default=None, description="User reviews")
    types: list[str] | None = Field(default=None, description="Google place types")

    # AI-computed fields
    theme_relevance: float = Field(default=0.5, ge=0, le=1, description="How relevant to user's theme")
    visit_duration: int = Field(default=60, description="Suggested visit duration in minutes")
