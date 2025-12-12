"""
Trip Schema

Represents a complete trip itinerary
"""

from pydantic import BaseModel, Field
from .place import Place


class ScheduledPlace(BaseModel):
    """A place scheduled in the itinerary with time slot"""

    place: Place
    start_time: str = Field(description="Start time in HH:MM format")
    end_time: str = Field(description="End time in HH:MM format")
    duration_minutes: int = Field(description="Duration in minutes")
    notes: str | None = Field(default=None, description="AI-generated notes for this visit")


class DayItinerary(BaseModel):
    """A single day's itinerary"""

    day_number: int = Field(ge=1, description="Day number starting from 1")
    date: str | None = Field(default=None, description="Date in YYYY-MM-DD format")
    title: str = Field(description="Day title/theme")
    places: list[ScheduledPlace] = Field(default_factory=list)
    total_places: int = Field(default=0)


class Trip(BaseModel):
    """Complete trip itinerary"""

    id: str = Field(description="Unique trip ID")
    title: str = Field(description="Trip title")
    description: str = Field(description="AI-generated trip description")
    city: str = Field(description="Destination city")
    country: str = Field(description="Destination country")
    duration_days: int = Field(ge=1, description="Number of days")
    theme: str | None = Field(default=None, description="Trip theme")
    days: list[DayItinerary] = Field(default_factory=list)

    # Metadata
    total_places: int = Field(default=0)
    highlights: list[str] = Field(default_factory=list, description="Trip highlights")
    tips: list[str] = Field(default_factory=list, description="Travel tips")


class TripIntent(BaseModel):
    """Parsed user intent from query"""

    city: str
    country: str
    duration_days: int = Field(ge=1, le=14)
    theme: str | None = None
    keywords: list[str] = Field(default_factory=list)
    constraints: list[str] = Field(default_factory=list)
    type: str = Field(default="general", description="Intent type: general, romantic, adventure, etc.")
