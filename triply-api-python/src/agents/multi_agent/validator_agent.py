"""
Validator Agent

Quality control agent that validates the final trip plan.
Checks for:
- Theme consistency
- Minimum places/restaurants per day
- Geographic logic (places not too far apart)
- Data completeness
"""

import json
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage, SystemMessage

from ...config import settings
from ...logging import get_logger
from .state import TripPlan, ValidationResult, DayPlan

logger = get_logger("validator_agent")

VALIDATOR_PROMPT = """You are a trip plan quality validator.

Analyze this trip plan and check for issues:

Trip Theme: {theme}
City: {city}
Duration: {duration_days} days

Trip Plan:
{trip_plan}

Validate:
1. THEME CONSISTENCY: Do all places match the theme "{theme}"?
   - Flag any generic tourist spots that don't fit the theme
   - Example: Eiffel Tower for an "anime" trip = BAD

2. QUANTITY: Each day should have:
   - At least 3 places (attractions/activities)
   - Exactly 3 restaurants (breakfast, lunch, dinner)

3. GEOGRAPHIC LOGIC:
   - Places within same day should be reasonably close
   - No jumping across city for no reason

4. DATA COMPLETENESS:
   - Each place should have name, address, coordinates
   - Each restaurant should have name and category

5. VARIETY:
   - Not too many similar places in one day
   - Good mix of activities

Return JSON:
{{
  "is_valid": true/false,
  "quality_score": 0.0-1.0,
  "issues": ["list of problems found"],
  "suggestions": ["list of improvements"]
}}

Be strict but fair. A good trip should score 0.7+.
Return ONLY valid JSON."""


async def validate_trip_plan(trip_plan: TripPlan) -> ValidationResult:
    """
    Validate the trip plan for quality and completeness.

    Args:
        trip_plan: The assembled trip plan

    Returns:
        ValidationResult with issues and suggestions
    """
    logger.info("Validating trip plan", title=trip_plan.title, days=len(trip_plan.days))

    issues = []
    suggestions = []
    quality_score = 1.0

    # Basic validation
    for day in trip_plan.days:
        day_num = day.day_number

        # Check minimum places
        if len(day.places) < 3:
            issues.append(f"Day {day_num}: Only {len(day.places)} places (minimum 3 required)")
            quality_score -= 0.1

        # Check restaurants
        if len(day.restaurants) < 3:
            issues.append(f"Day {day_num}: Only {len(day.restaurants)} restaurants (need breakfast, lunch, dinner)")
            quality_score -= 0.1

        # Check restaurant categories
        categories = {r.category for r in day.restaurants}
        for required in ["breakfast", "lunch", "dinner"]:
            if required not in categories:
                issues.append(f"Day {day_num}: Missing {required} restaurant")
                quality_score -= 0.05

        # Check data completeness
        for place in day.places:
            if not place.latitude or not place.longitude:
                issues.append(f"Day {day_num}: Place '{place.name}' missing coordinates")
                quality_score -= 0.02

        for restaurant in day.restaurants:
            if not restaurant.category:
                issues.append(f"Day {day_num}: Restaurant '{restaurant.name}' missing category")
                quality_score -= 0.02

    # LLM validation for theme consistency
    try:
        llm_result = await validate_with_llm(trip_plan)
        issues.extend(llm_result.get("issues", []))
        suggestions.extend(llm_result.get("suggestions", []))

        # Adjust quality score based on LLM assessment
        llm_score = llm_result.get("quality_score", 0.7)
        quality_score = (quality_score + llm_score) / 2

    except Exception as e:
        logger.error("LLM validation failed", error=str(e))
        suggestions.append("Could not perform deep theme validation")

    # Ensure score is in range
    quality_score = max(0.0, min(1.0, quality_score))

    is_valid = quality_score >= 0.5 and len([i for i in issues if "Only" in i]) == 0

    result = ValidationResult(
        is_valid=is_valid,
        issues=issues,
        suggestions=suggestions,
        quality_score=quality_score,
    )

    logger.info(
        "Validation complete",
        is_valid=result.is_valid,
        quality_score=result.quality_score,
        issues_count=len(result.issues),
    )

    return result


async def validate_with_llm(trip_plan: TripPlan) -> dict:
    """
    Use LLM to validate theme consistency and quality.

    Args:
        trip_plan: Trip plan to validate

    Returns:
        Dict with issues, suggestions, and quality_score
    """
    # Prepare trip summary for LLM
    trip_summary = {
        "title": trip_plan.title,
        "theme": trip_plan.theme,
        "city": trip_plan.city,
        "days": []
    }

    for day in trip_plan.days:
        day_summary = {
            "day": day.day_number,
            "title": day.title,
            "places": [{"name": p.name, "types": p.types[:3]} for p in day.places],
            "restaurants": [{"name": r.name, "cuisine": r.cuisine, "category": r.category} for r in day.restaurants],
        }
        trip_summary["days"].append(day_summary)

    model = ChatGoogleGenerativeAI(
        model="gemini-2.0-flash-exp",
        google_api_key=settings.google_api_key,
        temperature=0.1,
    )

    prompt = VALIDATOR_PROMPT.format(
        theme=trip_plan.theme,
        city=trip_plan.city,
        duration_days=trip_plan.duration_days,
        trip_plan=json.dumps(trip_summary, indent=2),
    )

    try:
        response = await model.ainvoke([HumanMessage(content=prompt)])
        content = response.content

        if isinstance(content, str):
            # Clean markdown
            if "```" in content:
                import re
                match = re.search(r'```(?:json)?\s*([\s\S]*?)\s*```', content)
                if match:
                    content = match.group(1)

            return json.loads(content)

    except Exception as e:
        logger.error("LLM validation parsing failed", error=str(e))

    return {"issues": [], "suggestions": [], "quality_score": 0.7}


def quick_validate(trip_plan: TripPlan) -> tuple[bool, list[str]]:
    """
    Quick synchronous validation without LLM.
    Used for fast feedback during assembly.

    Args:
        trip_plan: Trip plan to validate

    Returns:
        Tuple of (is_valid, list of issues)
    """
    issues = []

    for day in trip_plan.days:
        if len(day.places) < 3:
            issues.append(f"Day {day.day_number}: Need more places ({len(day.places)}/3)")
        if len(day.restaurants) < 3:
            issues.append(f"Day {day.day_number}: Need more restaurants ({len(day.restaurants)}/3)")

    return len(issues) == 0, issues
