"""
Query Analyzer Agent

Analyzes user queries to extract:
- Theme and related themes
- City/Country
- Duration
- Special requirements
- Pre-generates search queries for other agents
"""

import json
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage, SystemMessage

from ...config import settings
from ...logging import get_logger
from .state import ThemeAnalysis

logger = get_logger("query_analyzer")

ANALYZER_SYSTEM_PROMPT = """You are a query analyzer for a trip planning system.
Your job is to parse user requests and extract structured information.

Given a trip request, extract:
1. THEME: The main theme/interest (e.g., "anime", "romantic", "biker", "vegan", "adventure")
2. RELATED_THEMES: 3-5 related themes to expand search if needed
3. SEARCH_QUERIES: 8-12 specific search queries to find themed places
4. RESTAURANT_QUERIES: 4-6 search queries for themed restaurants
5. CITY: Destination city
6. COUNTRY: Destination country
7. DURATION_DAYS: Trip duration in days
8. SPECIAL_REQUIREMENTS: Any special needs (accessibility, dietary, etc.)

IMPORTANT for SEARCH_QUERIES:
- Generate queries that will find places MATCHING THE THEME
- DO NOT include generic queries like "attractions in X" or "landmarks in X"
- Be specific to the theme

Examples:

Query: "3 day anime trip to Tokyo"
{
  "theme": "anime",
  "related_themes": ["manga", "japanese pop culture", "gaming", "cosplay", "otaku"],
  "search_queries": [
    "anime shops Tokyo",
    "manga stores Akihabara",
    "anime figure shops Tokyo",
    "cosplay shops Tokyo",
    "gaming arcades Tokyo",
    "anime cafes Tokyo",
    "Studio Ghibli museum Tokyo",
    "Pokemon center Tokyo",
    "anime goods Nakano Broadway",
    "maid cafes Akihabara"
  ],
  "restaurant_queries": [
    "anime themed cafe Tokyo",
    "ramen restaurant Tokyo",
    "maid cafe Akihabara",
    "japanese izakaya Tokyo"
  ],
  "city": "Tokyo",
  "country": "Japan",
  "duration_days": 3,
  "special_requirements": []
}

Query: "romantic weekend in Paris for couples"
{
  "theme": "romantic",
  "related_themes": ["couples", "love", "intimate", "scenic", "wine"],
  "search_queries": [
    "romantic spots Paris",
    "couples activities Paris",
    "scenic viewpoints Paris",
    "wine tasting Paris",
    "couples spa Paris",
    "sunset spots Paris",
    "love locks bridge Paris",
    "romantic gardens Paris",
    "boat cruise Seine",
    "intimate bars Paris"
  ],
  "restaurant_queries": [
    "romantic restaurant Paris",
    "candlelit dinner Paris",
    "rooftop restaurant Paris view",
    "intimate bistro Paris"
  ],
  "city": "Paris",
  "country": "France",
  "duration_days": 2,
  "special_requirements": []
}

Query: "5 day vegan food trip to Berlin"
{
  "theme": "vegan",
  "related_themes": ["plant-based", "vegetarian", "organic", "health food", "sustainable"],
  "search_queries": [
    "vegan restaurant Berlin",
    "plant-based cafe Berlin",
    "vegan bakery Berlin",
    "organic food market Berlin",
    "vegan ice cream Berlin",
    "vegan supermarket Berlin",
    "raw food restaurant Berlin",
    "vegan cooking class Berlin"
  ],
  "restaurant_queries": [
    "vegan breakfast Berlin",
    "vegan brunch Berlin",
    "vegan fine dining Berlin",
    "plant-based restaurant Berlin"
  ],
  "city": "Berlin",
  "country": "Germany",
  "duration_days": 5,
  "special_requirements": ["vegan food only"]
}

Return ONLY valid JSON, no markdown or explanation."""


async def analyze_query(query: str) -> ThemeAnalysis:
    """
    Analyze user query and extract theme, city, duration, and search queries.

    Args:
        query: User's trip request

    Returns:
        ThemeAnalysis with extracted information
    """
    logger.info("Analyzing query", query=query)

    model = ChatGoogleGenerativeAI(
        model="gemini-2.0-flash-exp",
        google_api_key=settings.google_api_key,
        temperature=0.3,  # Lower temperature for more consistent parsing
    )

    messages = [
        SystemMessage(content=ANALYZER_SYSTEM_PROMPT),
        HumanMessage(content=f"Analyze this trip request:\n\n{query}")
    ]

    try:
        response = await model.ainvoke(messages)
        content = response.content

        # Clean up response
        if isinstance(content, str):
            # Remove markdown code blocks if present
            if content.startswith("```"):
                import re
                match = re.search(r'```(?:json)?\s*([\s\S]*?)\s*```', content)
                if match:
                    content = match.group(1)

            # Parse JSON
            data = json.loads(content)

            analysis = ThemeAnalysis(
                theme=data.get("theme", "general"),
                related_themes=data.get("related_themes", []),
                search_queries=data.get("search_queries", []),
                restaurant_queries=data.get("restaurant_queries", []),
                city=data.get("city", "Unknown"),
                country=data.get("country", "Unknown"),
                duration_days=data.get("duration_days", 3),
                special_requirements=data.get("special_requirements", []),
            )

            logger.info(
                "Query analyzed",
                theme=analysis.theme,
                city=analysis.city,
                duration=analysis.duration_days,
                search_queries_count=len(analysis.search_queries),
            )

            return analysis

    except json.JSONDecodeError as e:
        logger.error("Failed to parse analyzer response", error=str(e), content=content[:500])
        # Return default analysis
        return ThemeAnalysis(
            theme="general",
            related_themes=[],
            search_queries=[f"attractions in {query}"],
            restaurant_queries=[f"restaurants in {query}"],
            city="Unknown",
            country="Unknown",
            duration_days=3,
            special_requirements=[],
        )
    except Exception as e:
        logger.error("Query analysis failed", error=str(e))
        raise
