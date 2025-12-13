"""
Modification Agent

Handles intelligent modifications to existing trips without full regeneration.
Supports:
- Budget filtering (cheaper, free, expensive)
- Type filtering (remove museums, only parks, etc.)
- Day operations (add/remove days)
- Place replacement (swap specific places)
- Semantic modifications (make more romantic, add adventure, etc.)
"""

import json
import re
from enum import Enum
from pydantic import BaseModel
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage

from ...config import settings
from ...logging import get_logger
from .state import ThemeAnalysis, PlaceData, RestaurantData
from .places_agent import search_places_for_theme
from .restaurant_agent import search_restaurants_parallel
from .query_analyzer import analyze_query

logger = get_logger("modification_agent")


class ModificationType(Enum):
    """Types of trip modifications"""
    FILTER_BUDGET_CHEAPER = "filter_budget_cheaper"  # Make cheaper, replace expensive
    FILTER_BUDGET_FREE = "filter_budget_free"        # Only free places
    FILTER_BUDGET_LUXURY = "filter_budget_luxury"    # More expensive/luxury
    FILTER_TYPE = "filter_type"                      # Remove/keep specific types
    ADD_DAY = "add_day"                              # Add one or more days
    REMOVE_DAY = "remove_day"                        # Remove one or more days
    REPLACE_PLACE = "replace_place"                  # Replace specific place
    REPLACE_RESTAURANT = "replace_restaurant"        # Replace specific restaurant
    REORDER_PLACES = "reorder_places"                # Change order of places
    SEMANTIC = "semantic"                            # Complex semantic changes
    NOT_MODIFICATION = "not_modification"            # Not a modification request


class ModificationAnalysis(BaseModel):
    """Result of analyzing a modification request"""
    type: ModificationType
    params: dict = {}
    confidence: float = 0.0
    requires_search: bool = False
    requires_llm: bool = False
    estimated_time_ms: int = 100
    description: str = ""


# Keywords for rule-based detection
BUDGET_CHEAPER_KEYWORDS = [
    "дешевле", "cheaper", "budget", "бюджет", "экономнее", "подешевле",
    "менее дорого", "less expensive", "affordable", "доступнее"
]

BUDGET_FREE_KEYWORDS = [
    "бесплатно", "free", "без денег", "даром", "no cost", "без оплаты",
    "бесплатные", "free entry", "free admission"
]

BUDGET_LUXURY_KEYWORDS = [
    "дороже", "люкс", "luxury", "премиум", "premium", "vip",
    "expensive", "high-end", "эксклюзив", "exclusive"
]

ADD_DAY_KEYWORDS = [
    "+1 день", "добавь день", "add day", "ещё день", "еще день",
    "добавить день", "another day", "one more day", "+1 day",
    "продли", "extend", "longer"
]

REMOVE_DAY_KEYWORDS = [
    "-1 день", "убери день", "remove day", "удали день", "короче",
    "меньше дней", "less days", "fewer days", "shorten", "сократи"
]

REMOVE_TYPE_PATTERNS = [
    (r"убери\s+(музе[йи]|парк[иа]?|рестораны?|пляж[иа]?)", "remove"),
    (r"без\s+(музе[йе]в|парков|ресторанов|пляжей)", "remove"),
    (r"remove\s+(museums?|parks?|restaurants?|beaches?)", "remove"),
    (r"no\s+(museums?|parks?|restaurants?|beaches?)", "remove"),
]

ONLY_TYPE_PATTERNS = [
    (r"только\s+(музе[йи]|парк[иа]?|пляж[иа]?)", "only"),
    (r"only\s+(museums?|parks?|beaches?)", "only"),
]

# Type mappings
TYPE_KEYWORDS_TO_GOOGLE_TYPES = {
    "музей": ["museum"],
    "музеи": ["museum"],
    "museums": ["museum"],
    "museum": ["museum"],
    "парк": ["park"],
    "парки": ["park"],
    "parks": ["park"],
    "park": ["park"],
    "пляж": ["beach"],
    "пляжи": ["beach"],
    "beaches": ["beach"],
    "beach": ["beach"],
    "ресторан": ["restaurant", "food", "cafe"],
    "рестораны": ["restaurant", "food", "cafe"],
    "restaurants": ["restaurant", "food", "cafe"],
    "restaurant": ["restaurant", "food", "cafe"],
}


class ModificationAgent:
    """
    Agent for modifying existing trips without full regeneration.

    Uses rule-based detection for common operations and falls back
    to LLM for complex semantic modifications.
    """

    def __init__(self):
        self.model = ChatGoogleGenerativeAI(
            model="gemini-2.0-flash-exp",
            google_api_key=settings.google_api_key,
            temperature=0.1,
        )

    async def analyze_request(
        self,
        request: str,
        current_trip: dict,
        conversation_context: list[dict] | None = None
    ) -> ModificationAnalysis:
        """
        Analyze a user request to determine if it's a modification
        and what type of modification is needed.

        Args:
            request: User's message
            current_trip: Current trip data (if exists)
            conversation_context: Previous messages for context

        Returns:
            ModificationAnalysis with type and parameters
        """
        logger.info("Analyzing modification request", request=request[:100])

        # If no current trip, it's not a modification
        if not current_trip or not current_trip.get("days"):
            return ModificationAnalysis(
                type=ModificationType.NOT_MODIFICATION,
                confidence=1.0,
                description="No existing trip to modify"
            )

        # Try rule-based analysis first (fast)
        analysis = self._rule_based_analysis(request, current_trip)
        if analysis and analysis.confidence >= 0.8:
            logger.info(
                "Rule-based analysis succeeded",
                type=analysis.type.value,
                confidence=analysis.confidence
            )
            return analysis

        # Fall back to LLM analysis for complex cases
        return await self._llm_analysis(request, current_trip, conversation_context)

    def _rule_based_analysis(
        self,
        request: str,
        current_trip: dict
    ) -> ModificationAnalysis | None:
        """
        Fast rule-based analysis without LLM.
        Returns None if unsure.
        """
        request_lower = request.lower().strip()

        # Budget: Free
        if any(kw in request_lower for kw in BUDGET_FREE_KEYWORDS):
            return ModificationAnalysis(
                type=ModificationType.FILTER_BUDGET_FREE,
                params={"max_price_level": 0, "replace_with_free": True},
                confidence=0.95,
                requires_search=True,  # Need to find free alternatives
                estimated_time_ms=5000,
                description="Replace paid places with free alternatives"
            )

        # Budget: Cheaper
        if any(kw in request_lower for kw in BUDGET_CHEAPER_KEYWORDS):
            return ModificationAnalysis(
                type=ModificationType.FILTER_BUDGET_CHEAPER,
                params={"max_price_level": 2, "replace_expensive": True},
                confidence=0.9,
                requires_search=True,  # Need to find cheaper alternatives
                estimated_time_ms=5000,
                description="Replace expensive places with cheaper alternatives"
            )

        # Budget: Luxury
        if any(kw in request_lower for kw in BUDGET_LUXURY_KEYWORDS):
            return ModificationAnalysis(
                type=ModificationType.FILTER_BUDGET_LUXURY,
                params={"min_price_level": 3, "replace_cheap": True},
                confidence=0.9,
                requires_search=True,
                estimated_time_ms=5000,
                description="Replace budget places with luxury alternatives"
            )

        # Add day
        if any(kw in request_lower for kw in ADD_DAY_KEYWORDS):
            # Check for specific number
            days_to_add = 1
            match = re.search(r'\+(\d+)\s*(?:день|дня|дней|day)', request_lower)
            if match:
                days_to_add = int(match.group(1))

            return ModificationAnalysis(
                type=ModificationType.ADD_DAY,
                params={"days_to_add": days_to_add},
                confidence=0.9,
                requires_search=True,
                estimated_time_ms=8000 * days_to_add,
                description=f"Add {days_to_add} day(s) to the trip"
            )

        # Remove day
        if any(kw in request_lower for kw in REMOVE_DAY_KEYWORDS):
            days_to_remove = 1
            match = re.search(r'-(\d+)\s*(?:день|дня|дней|day)', request_lower)
            if match:
                days_to_remove = int(match.group(1))

            # Check if we can remove that many days
            current_days = len(current_trip.get("days", []))
            if days_to_remove >= current_days:
                days_to_remove = max(1, current_days - 1)

            return ModificationAnalysis(
                type=ModificationType.REMOVE_DAY,
                params={"days_to_remove": days_to_remove},
                confidence=0.9,
                requires_search=False,
                estimated_time_ms=100,
                description=f"Remove {days_to_remove} day(s) from the trip"
            )

        # Remove specific type
        for pattern, action in REMOVE_TYPE_PATTERNS:
            match = re.search(pattern, request_lower)
            if match:
                type_word = match.group(1)
                google_types = self._keyword_to_google_types(type_word)
                return ModificationAnalysis(
                    type=ModificationType.FILTER_TYPE,
                    params={
                        "action": "remove",
                        "types": google_types,
                        "replace": True
                    },
                    confidence=0.85,
                    requires_search=True,  # Need replacements
                    estimated_time_ms=5000,
                    description=f"Remove {type_word} and find alternatives"
                )

        # Only specific type
        for pattern, action in ONLY_TYPE_PATTERNS:
            match = re.search(pattern, request_lower)
            if match:
                type_word = match.group(1)
                google_types = self._keyword_to_google_types(type_word)
                return ModificationAnalysis(
                    type=ModificationType.FILTER_TYPE,
                    params={
                        "action": "only",
                        "types": google_types,
                        "replace": True
                    },
                    confidence=0.85,
                    requires_search=True,
                    estimated_time_ms=5000,
                    description=f"Keep only {type_word}, find alternatives for others"
                )

        return None

    def _keyword_to_google_types(self, keyword: str) -> list[str]:
        """Convert a keyword to Google Places types"""
        keyword_lower = keyword.lower()
        for kw, types in TYPE_KEYWORDS_TO_GOOGLE_TYPES.items():
            if kw in keyword_lower:
                return types
        return []

    async def _llm_analysis(
        self,
        request: str,
        current_trip: dict,
        conversation_context: list[dict] | None = None
    ) -> ModificationAnalysis:
        """
        Use LLM to analyze complex modification requests.
        """
        # Build context summary
        trip_summary = f"""
        Current trip: {current_trip.get('title', 'Trip')}
        City: {current_trip.get('city', 'Unknown')}
        Days: {len(current_trip.get('days', []))}
        """

        prompt = f"""Analyze if this is a request to MODIFY an existing trip or a request for a NEW trip.

EXISTING TRIP:
{trip_summary}

USER REQUEST: "{request}"

If this is a MODIFICATION request, determine the type:
1. FILTER_BUDGET_CHEAPER - make trip cheaper/more affordable
2. FILTER_BUDGET_FREE - only free places
3. FILTER_BUDGET_LUXURY - make trip more luxurious
4. FILTER_TYPE - remove or keep only specific place types
5. ADD_DAY - add more days to trip
6. REMOVE_DAY - remove days from trip
7. REPLACE_PLACE - replace a specific place
8. REPLACE_RESTAURANT - replace a specific restaurant
9. SEMANTIC - complex changes (more romantic, more active, family-friendly, etc.)
10. NOT_MODIFICATION - this is a request for a completely new trip

Return JSON:
{{
    "type": "one of the types above",
    "is_modification": true/false,
    "confidence": 0.0-1.0,
    "params": {{...}},
    "description": "what the user wants"
}}

For SEMANTIC type, include in params:
- "semantic_intent": description of the change
- "aspects_to_change": ["activities", "atmosphere", "audience", etc.]

Return ONLY valid JSON."""

        try:
            response = await self.model.ainvoke([HumanMessage(content=prompt)])
            content = response.content

            # Parse JSON
            if isinstance(content, str):
                if "```" in content:
                    match = re.search(r'```(?:json)?\s*([\s\S]*?)\s*```', content)
                    if match:
                        content = match.group(1)

                result = json.loads(content)

                mod_type = ModificationType(result.get("type", "NOT_MODIFICATION"))

                return ModificationAnalysis(
                    type=mod_type,
                    params=result.get("params", {}),
                    confidence=result.get("confidence", 0.7),
                    requires_search=mod_type in [
                        ModificationType.FILTER_BUDGET_CHEAPER,
                        ModificationType.FILTER_BUDGET_FREE,
                        ModificationType.FILTER_BUDGET_LUXURY,
                        ModificationType.FILTER_TYPE,
                        ModificationType.ADD_DAY,
                        ModificationType.REPLACE_PLACE,
                        ModificationType.REPLACE_RESTAURANT,
                        ModificationType.SEMANTIC,
                    ],
                    requires_llm=mod_type == ModificationType.SEMANTIC,
                    estimated_time_ms=self._estimate_time(mod_type),
                    description=result.get("description", "")
                )

        except Exception as e:
            logger.error("LLM analysis failed", error=str(e))

        # Default: not a modification
        return ModificationAnalysis(
            type=ModificationType.NOT_MODIFICATION,
            confidence=0.5,
            description="Could not determine modification type"
        )

    def _estimate_time(self, mod_type: ModificationType) -> int:
        """Estimate time in ms for a modification type"""
        estimates = {
            ModificationType.FILTER_BUDGET_CHEAPER: 5000,
            ModificationType.FILTER_BUDGET_FREE: 5000,
            ModificationType.FILTER_BUDGET_LUXURY: 5000,
            ModificationType.FILTER_TYPE: 5000,
            ModificationType.ADD_DAY: 8000,
            ModificationType.REMOVE_DAY: 100,
            ModificationType.REPLACE_PLACE: 3000,
            ModificationType.REPLACE_RESTAURANT: 3000,
            ModificationType.REORDER_PLACES: 100,
            ModificationType.SEMANTIC: 10000,
            ModificationType.NOT_MODIFICATION: 0,
        }
        return estimates.get(mod_type, 5000)

    async def apply_modification(
        self,
        trip: dict,
        analysis: ModificationAnalysis,
    ) -> dict:
        """
        Apply a modification to an existing trip.

        Args:
            trip: Current trip data
            analysis: Analysis result with modification type and params

        Returns:
            Modified trip data
        """
        logger.info(
            "Applying modification",
            type=analysis.type.value,
            params=analysis.params
        )

        # Get theme analysis for searches
        theme_analysis = None
        if analysis.requires_search:
            # Handle both camelCase and snake_case field names (frontend inconsistency)
            duration_days = trip.get('durationDays') or trip.get('duration_days') or len(trip.get('days', [])) or 2
            city = trip.get('city', 'Unknown')
            # Theme can be in various fields
            theme = trip.get('theme') or trip.get('activity_type') or ''

            theme_analysis = await analyze_query(
                f"{duration_days} days in {city} {theme}"
            )

        match analysis.type:
            case ModificationType.FILTER_BUDGET_FREE:
                return await self._apply_budget_filter(
                    trip, theme_analysis,
                    max_price_level=0,
                    replace=True
                )

            case ModificationType.FILTER_BUDGET_CHEAPER:
                return await self._apply_budget_filter(
                    trip, theme_analysis,
                    max_price_level=2,
                    replace=True
                )

            case ModificationType.FILTER_BUDGET_LUXURY:
                return await self._apply_budget_filter(
                    trip, theme_analysis,
                    min_price_level=3,
                    replace=True
                )

            case ModificationType.FILTER_TYPE:
                return await self._apply_type_filter(
                    trip, theme_analysis,
                    analysis.params.get("action", "remove"),
                    analysis.params.get("types", []),
                    analysis.params.get("replace", True)
                )

            case ModificationType.ADD_DAY:
                return await self._add_days(
                    trip, theme_analysis,
                    analysis.params.get("days_to_add", 1)
                )

            case ModificationType.REMOVE_DAY:
                return self._remove_days(
                    trip,
                    analysis.params.get("days_to_remove", 1),
                    analysis.params.get("day_numbers")
                )

            case ModificationType.REPLACE_PLACE:
                return await self._replace_place(
                    trip, theme_analysis,
                    analysis.params.get("day_number"),
                    analysis.params.get("place_index"),
                    analysis.params.get("criteria")
                )

            case ModificationType.REPLACE_RESTAURANT:
                return await self._replace_restaurant(
                    trip, theme_analysis,
                    analysis.params.get("day_number"),
                    analysis.params.get("restaurant_index"),
                    analysis.params.get("criteria")
                )

            case ModificationType.SEMANTIC:
                return await self._apply_semantic_modification(
                    trip, theme_analysis,
                    analysis.params
                )

            case _:
                logger.warning("Unknown modification type", type=analysis.type.value)
                return trip

    async def _apply_budget_filter(
        self,
        trip: dict,
        theme_analysis: ThemeAnalysis | None,
        max_price_level: int | None = None,
        min_price_level: int | None = None,
        replace: bool = True
    ) -> dict:
        """
        Filter places by budget and optionally replace filtered ones.
        """
        places_to_replace = []

        for day_idx, day in enumerate(trip.get("days", [])):
            filtered_places = []

            for place_idx, place in enumerate(day.get("places", [])):
                price_level = place.get("price_level") or place.get("price_value") or 2

                keep = True
                if max_price_level is not None and price_level > max_price_level:
                    keep = False
                if min_price_level is not None and price_level < min_price_level:
                    keep = False

                if keep:
                    filtered_places.append(place)
                else:
                    places_to_replace.append({
                        "day_idx": day_idx,
                        "place_idx": place_idx,
                        "original": place
                    })

            day["places"] = filtered_places

        # Find replacements if needed
        if replace and places_to_replace and theme_analysis:
            await self._find_replacements(
                trip, theme_analysis, places_to_replace,
                max_price_level=max_price_level,
                min_price_level=min_price_level
            )

        logger.info(
            "Budget filter applied",
            places_removed=len(places_to_replace),
            max_price_level=max_price_level,
            min_price_level=min_price_level
        )

        return trip

    async def _apply_type_filter(
        self,
        trip: dict,
        theme_analysis: ThemeAnalysis | None,
        action: str,
        types: list[str],
        replace: bool = True
    ) -> dict:
        """
        Filter places by type (remove specific types or keep only specific types).
        """
        places_to_replace = []

        for day_idx, day in enumerate(trip.get("days", [])):
            filtered_places = []

            for place_idx, place in enumerate(day.get("places", [])):
                place_types = place.get("types", [])
                if isinstance(place_types, str):
                    place_types = [place_types]
                place_type = place.get("type", "")
                all_types = set(place_types + [place_type])

                has_type = bool(all_types & set(types))

                if action == "remove":
                    keep = not has_type
                elif action == "only":
                    keep = has_type
                else:
                    keep = True

                if keep:
                    filtered_places.append(place)
                else:
                    places_to_replace.append({
                        "day_idx": day_idx,
                        "place_idx": place_idx,
                        "original": place
                    })

            day["places"] = filtered_places

        # Find replacements
        if replace and places_to_replace and theme_analysis:
            await self._find_replacements(
                trip, theme_analysis, places_to_replace,
                exclude_types=types if action == "remove" else None,
                only_types=types if action == "only" else None
            )

        logger.info(
            "Type filter applied",
            action=action,
            types=types,
            places_removed=len(places_to_replace)
        )

        return trip

    async def _find_replacements(
        self,
        trip: dict,
        theme_analysis: ThemeAnalysis,
        places_to_replace: list[dict],
        max_price_level: int | None = None,
        min_price_level: int | None = None,
        exclude_types: list[str] | None = None,
        only_types: list[str] | None = None
    ) -> None:
        """
        Find replacement places for filtered ones.
        Modifies trip in place.
        """
        if not places_to_replace:
            return

        # Collect existing place IDs
        existing_ids = set()
        for day in trip.get("days", []):
            for place in day.get("places", []):
                if place.get("place_id"):
                    existing_ids.add(place["place_id"])

        # Search for new places
        new_places = await search_places_for_theme(
            theme_analysis,
            min_places_per_day=len(places_to_replace) + 5  # Extra buffer
        )

        # Filter new places by criteria
        valid_replacements = []
        for place in new_places:
            if place.place_id in existing_ids:
                continue

            # Price filter
            price = place.price_level or 2
            if max_price_level is not None and price > max_price_level:
                continue
            if min_price_level is not None and price < min_price_level:
                continue

            # Type filter
            place_types = set(place.types)
            if exclude_types and (place_types & set(exclude_types)):
                continue
            if only_types and not (place_types & set(only_types)):
                continue

            valid_replacements.append(place)
            existing_ids.add(place.place_id)

        # Assign replacements to days
        replacement_idx = 0
        for item in places_to_replace:
            if replacement_idx >= len(valid_replacements):
                break

            replacement = valid_replacements[replacement_idx]
            replacement_idx += 1

            # Convert PlaceData to dict format
            new_place_dict = {
                "place_id": replacement.place_id,
                "name": replacement.name,
                "address": replacement.address,
                "rating": replacement.rating,
                "price_level": replacement.price_level,
                "price_value": replacement.price_level,
                "price": self._price_level_to_string(replacement.price_level),
                "type": replacement.types[0] if replacement.types else "attraction",
                "types": replacement.types,
                "category": "attraction",
                "description": replacement.description or f"A great spot in {trip.get('city', '')}",
                "duration_minutes": replacement.duration_minutes,
                "latitude": replacement.latitude,
                "longitude": replacement.longitude,
                "images": [{"url": url, "source": "google_places"} for url in replacement.photo_urls],
                "opening_hours": replacement.opening_hours,
            }

            # Add to day
            day_idx = item["day_idx"]
            trip["days"][day_idx]["places"].append(new_place_dict)

        logger.info(
            "Replacements found",
            requested=len(places_to_replace),
            found=replacement_idx
        )

    def _price_level_to_string(self, price_level: int | None) -> str:
        """Convert price level to display string"""
        if price_level is None:
            return ""
        symbols = {0: "Free", 1: "$", 2: "$$", 3: "$$$", 4: "$$$$"}
        return symbols.get(price_level, "")

    async def _add_days(
        self,
        trip: dict,
        theme_analysis: ThemeAnalysis,
        days_to_add: int = 1
    ) -> dict:
        """
        Add new days to the trip with new places and restaurants.
        """
        # Collect existing place IDs
        existing_ids = set()
        for day in trip.get("days", []):
            for place in day.get("places", []):
                if place.get("place_id"):
                    existing_ids.add(place["place_id"])
            for rest in day.get("restaurants", []):
                if rest.get("place_id"):
                    existing_ids.add(rest["place_id"])

        # Modify theme analysis to search for more places
        new_places = await search_places_for_theme(
            theme_analysis,
            min_places_per_day=5 * days_to_add
        )

        # Filter out existing places
        new_places = [p for p in new_places if p.place_id not in existing_ids]

        # Get restaurants for new days
        day_places_for_restaurants = []
        for i in range(days_to_add):
            start_idx = i * 5
            end_idx = start_idx + 5
            day_places_for_restaurants.append(new_places[start_idx:end_idx])

        new_restaurants = await search_restaurants_parallel(
            theme_analysis,
            day_places_for_restaurants
        )

        # Create new days
        current_day_count = len(trip.get("days", []))
        restaurants_per_day = len(new_restaurants) // days_to_add if new_restaurants else 0

        for i in range(days_to_add):
            new_day_num = current_day_count + i + 1
            start_idx = i * 5
            end_idx = start_idx + 5
            day_places = new_places[start_idx:end_idx]

            # Get restaurants for this day
            r_start = i * restaurants_per_day
            r_end = r_start + restaurants_per_day
            day_restaurants = new_restaurants[r_start:r_end] if new_restaurants else []

            new_day = {
                "dayNumber": new_day_num,
                "title": f"Day {new_day_num}: More {theme_analysis.theme}",
                "description": f"Additional day exploring {theme_analysis.city}",
                "places": [
                    {
                        "place_id": p.place_id,
                        "name": p.name,
                        "address": p.address,
                        "rating": p.rating,
                        "price_level": p.price_level,
                        "price_value": p.price_level,
                        "price": self._price_level_to_string(p.price_level),
                        "type": p.types[0] if p.types else "attraction",
                        "category": "attraction",
                        "description": p.description or "",
                        "duration_minutes": p.duration_minutes,
                        "latitude": p.latitude,
                        "longitude": p.longitude,
                        "images": [{"url": url, "source": "google_places"} for url in p.photo_urls],
                        "opening_hours": p.opening_hours,
                    }
                    for p in day_places
                ],
                "restaurants": [
                    {
                        "place_id": r.place_id,
                        "name": r.name,
                        "address": r.address,
                        "rating": r.rating,
                        "price_range": r.price_range,
                        "price_level": r.price_level,
                        "type": "restaurant",
                        "category": r.category,
                        "description": r.description or "",
                        "duration_minutes": r.duration_minutes,
                        "latitude": r.latitude,
                        "longitude": r.longitude,
                        "cuisine": r.cuisine,
                        "images": [{"url": url, "source": "google_places"} for url in r.photo_urls],
                        "opening_hours": r.opening_hours,
                    }
                    for r in day_restaurants
                ],
            }

            trip["days"].append(new_day)

        trip["durationDays"] = len(trip["days"])

        logger.info("Days added", days_added=days_to_add, total_days=trip["durationDays"])

        return trip

    def _remove_days(
        self,
        trip: dict,
        days_to_remove: int = 1,
        day_numbers: list[int] | None = None
    ) -> dict:
        """
        Remove days from the trip.
        If day_numbers specified, remove those specific days.
        Otherwise, remove from the end.
        """
        current_days = trip.get("days", [])

        if not current_days:
            return trip

        if day_numbers:
            # Remove specific days
            trip["days"] = [d for d in current_days if d.get("dayNumber") not in day_numbers]
        else:
            # Remove from the end
            days_to_keep = max(1, len(current_days) - days_to_remove)
            trip["days"] = current_days[:days_to_keep]

        # Renumber days
        for i, day in enumerate(trip["days"]):
            day["dayNumber"] = i + 1

        trip["durationDays"] = len(trip["days"])

        logger.info(
            "Days removed",
            removed=days_to_remove,
            remaining=trip["durationDays"]
        )

        return trip

    async def _replace_place(
        self,
        trip: dict,
        theme_analysis: ThemeAnalysis | None,
        day_number: int | None,
        place_index: int | None,
        criteria: str | None = None
    ) -> dict:
        """
        Replace a specific place with an alternative.
        """
        if day_number is None or place_index is None:
            return trip

        day_idx = day_number - 1
        if day_idx < 0 or day_idx >= len(trip.get("days", [])):
            return trip

        day = trip["days"][day_idx]
        places = day.get("places", [])

        if place_index < 0 or place_index >= len(places):
            return trip

        old_place = places[place_index]

        # Find alternative
        if theme_analysis:
            # Collect existing IDs
            existing_ids = set()
            for d in trip.get("days", []):
                for p in d.get("places", []):
                    if p.get("place_id"):
                        existing_ids.add(p["place_id"])

            new_places = await search_places_for_theme(
                theme_analysis,
                min_places_per_day=5
            )

            # Find first valid replacement
            for place in new_places:
                if place.place_id not in existing_ids:
                    places[place_index] = {
                        "place_id": place.place_id,
                        "name": place.name,
                        "address": place.address,
                        "rating": place.rating,
                        "price_level": place.price_level,
                        "price_value": place.price_level,
                        "type": place.types[0] if place.types else "attraction",
                        "category": "attraction",
                        "description": place.description or "",
                        "duration_minutes": place.duration_minutes,
                        "latitude": place.latitude,
                        "longitude": place.longitude,
                        "images": [{"url": url, "source": "google_places"} for url in place.photo_urls],
                        "opening_hours": place.opening_hours,
                    }
                    break

        logger.info(
            "Place replaced",
            day=day_number,
            old_place=old_place.get("name"),
            new_place=places[place_index].get("name")
        )

        return trip

    async def _replace_restaurant(
        self,
        trip: dict,
        theme_analysis: ThemeAnalysis | None,
        day_number: int | None,
        restaurant_index: int | None,
        criteria: str | None = None
    ) -> dict:
        """
        Replace a specific restaurant with an alternative.
        """
        if day_number is None or restaurant_index is None:
            return trip

        day_idx = day_number - 1
        if day_idx < 0 or day_idx >= len(trip.get("days", [])):
            return trip

        day = trip["days"][day_idx]
        restaurants = day.get("restaurants", [])

        if restaurant_index < 0 or restaurant_index >= len(restaurants):
            return trip

        old_restaurant = restaurants[restaurant_index]
        category = old_restaurant.get("category", "lunch")

        # Find alternative
        if theme_analysis:
            day_places = [
                PlaceData(
                    place_id=p.get("place_id", ""),
                    name=p.get("name", ""),
                    latitude=p.get("latitude"),
                    longitude=p.get("longitude"),
                )
                for p in day.get("places", [])
            ]

            new_restaurants = await search_restaurants_parallel(
                theme_analysis,
                [day_places]
            )

            # Find restaurant with same category
            for rest in new_restaurants:
                if rest.category == category and rest.place_id != old_restaurant.get("place_id"):
                    restaurants[restaurant_index] = {
                        "place_id": rest.place_id,
                        "name": rest.name,
                        "address": rest.address,
                        "rating": rest.rating,
                        "price_range": rest.price_range,
                        "price_level": rest.price_level,
                        "type": "restaurant",
                        "category": rest.category,
                        "description": rest.description or "",
                        "duration_minutes": rest.duration_minutes,
                        "latitude": rest.latitude,
                        "longitude": rest.longitude,
                        "cuisine": rest.cuisine,
                        "images": [{"url": url, "source": "google_places"} for url in rest.photo_urls],
                        "opening_hours": rest.opening_hours,
                    }
                    break

        logger.info(
            "Restaurant replaced",
            day=day_number,
            old=old_restaurant.get("name"),
            new=restaurants[restaurant_index].get("name")
        )

        return trip

    async def _apply_semantic_modification(
        self,
        trip: dict,
        theme_analysis: ThemeAnalysis | None,
        params: dict
    ) -> dict:
        """
        Apply complex semantic modifications using LLM.
        """
        semantic_intent = params.get("semantic_intent", "")

        # Use LLM to determine what changes to make
        prompt = f"""Analyze this trip and determine what changes to make for: "{semantic_intent}"

CURRENT TRIP:
{json.dumps(trip, indent=2, ensure_ascii=False)[:3000]}

Return JSON with specific changes:
{{
    "places_to_remove": [
        {{"day_number": 1, "place_index": 0, "reason": "..."}}
    ],
    "search_queries_for_new_places": ["query1", "query2"],
    "restaurants_to_change": [
        {{"day_number": 1, "criteria": "romantic dinner"}}
    ],
    "title_suggestion": "New title if needed",
    "description_update": "Updated description if needed"
}}

Be conservative - only change what's necessary for the semantic modification.
Return ONLY valid JSON."""

        try:
            response = await self.model.ainvoke([HumanMessage(content=prompt)])
            content = response.content

            if isinstance(content, str):
                if "```" in content:
                    match = re.search(r'```(?:json)?\s*([\s\S]*?)\s*```', content)
                    if match:
                        content = match.group(1)

                changes = json.loads(content)

                # Apply changes
                # Remove places
                for removal in changes.get("places_to_remove", []):
                    day_num = removal.get("day_number", 1)
                    place_idx = removal.get("place_index", 0)
                    if 0 < day_num <= len(trip["days"]):
                        day = trip["days"][day_num - 1]
                        if 0 <= place_idx < len(day.get("places", [])):
                            day["places"].pop(place_idx)

                # Search for new places
                if changes.get("search_queries_for_new_places") and theme_analysis:
                    for query in changes["search_queries_for_new_places"][:3]:
                        # Add query to theme analysis
                        modified_theme = ThemeAnalysis(
                            theme=query,
                            related_themes=theme_analysis.related_themes,
                            search_queries=[f"{query} {trip.get('city', '')}"],
                            restaurant_queries=theme_analysis.restaurant_queries,
                            city=theme_analysis.city,
                            country=theme_analysis.country,
                            duration_days=theme_analysis.duration_days,
                            special_requirements=theme_analysis.special_requirements,
                        )

                        new_places = await search_places_for_theme(
                            modified_theme,
                            min_places_per_day=2
                        )

                        # Add to days that need more places
                        for day in trip["days"]:
                            if len(day.get("places", [])) < 3 and new_places:
                                place = new_places.pop(0)
                                day["places"].append({
                                    "place_id": place.place_id,
                                    "name": place.name,
                                    "address": place.address,
                                    "rating": place.rating,
                                    "price_level": place.price_level,
                                    "type": place.types[0] if place.types else "attraction",
                                    "category": "attraction",
                                    "description": place.description or "",
                                    "duration_minutes": place.duration_minutes,
                                    "latitude": place.latitude,
                                    "longitude": place.longitude,
                                    "images": [{"url": url, "source": "google_places"} for url in place.photo_urls],
                                })

                # Update title/description
                if changes.get("title_suggestion"):
                    trip["title"] = changes["title_suggestion"]
                if changes.get("description_update"):
                    trip["description"] = changes["description_update"]

                logger.info("Semantic modification applied", intent=semantic_intent)

        except Exception as e:
            logger.error("Semantic modification failed", error=str(e))

        return trip


# Export for use in orchestrator
__all__ = [
    "ModificationAgent",
    "ModificationAnalysis",
    "ModificationType",
]
