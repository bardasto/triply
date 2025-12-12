/**
 * LangGraph Multi-Agent System Types
 *
 * This file defines all types for the trip generation multi-agent system.
 */

// =============================================================================
// Intent Types
// =============================================================================

/**
 * Trip intent classification
 * - sightseeing: Standard tourist trip (attractions, landmarks)
 * - thematic: Focused on specific theme (massage, anime, wine, etc.)
 * - activity: Active experiences (hiking, cycling, surfing)
 * - culinary: Food-focused trip (restaurants, food tours)
 * - relaxation: Spa, wellness, beaches
 */
export type TripIntentType =
  | "sightseeing"
  | "thematic"
  | "activity"
  | "culinary"
  | "relaxation";

/**
 * Result from Intent Agent
 */
export interface IntentResult {
  /** Type of trip the user wants */
  type: TripIntentType;

  /** Specific theme if thematic (e.g., "massage", "anime", "wine tasting") */
  theme: string | null;

  /** Related keywords for search */
  keywords: string[];

  /** Target city */
  city: string;

  /** Target country */
  country: string;

  /** Trip duration in days */
  duration: number;

  /**
   * Strict mode: if true, ONLY include places matching the theme
   * If false, can mix in general attractions
   */
  strictMode: boolean;

  /** User's specific preferences extracted from query */
  preferences: {
    budget?: "budget" | "moderate" | "luxury";
    pace?: "relaxed" | "moderate" | "intensive";
    interests?: string[];
  };

  /** Confidence score 0-1 */
  confidence: number;
}

// =============================================================================
// Place Types
// =============================================================================

export interface PlacePhoto {
  url: string;
  attribution?: string;
}

export interface PlaceOpeningHours {
  weekday_text?: string[];
  open_now?: boolean;
}

export interface Place {
  id: string;
  placeId: string;
  name: string;
  category: "breakfast" | "lunch" | "dinner" | "attraction" | "activity" | "cafe" | "bar";
  description: string;
  address: string;
  location: {
    lat: number;
    lng: number;
  };
  rating?: number;
  reviewCount?: number;
  priceLevel?: number;
  photos: PlacePhoto[];
  openingHours?: PlaceOpeningHours;
  types: string[];

  /** Relevance score to the theme (0-1) */
  themeRelevance?: number;
}

// =============================================================================
// Trip Types
// =============================================================================

export interface TripPlace {
  placeId: string;
  name: string;
  category: string;
  description: string;
  duration_minutes: number;
  price: string;
  price_value: number;
  best_time: string;
  photos: PlacePhoto[];
  location: {
    lat: number;
    lng: number;
  };
  address: string;
  rating?: number;
  transportation: {
    from_previous: string;
    method: string;
    duration_minutes: number;
  };
}

export interface TripDay {
  day: number;
  title: string;
  description: string;
  places: TripPlace[];
}

export interface Trip {
  id: string;
  title: string;
  description: string;
  city: string;
  country: string;
  duration_days: number;
  best_season: string;
  daily_budget: {
    min: number;
    max: number;
    currency: string;
  };
  total_budget: {
    min: number;
    max: number;
    currency: string;
  };
  trip_highlights: string[];
  local_tips: string[];
  days: TripDay[];
  cover_image?: string;
  created_at: string;
}

// =============================================================================
// Validation Types
// =============================================================================

export interface ValidationIssue {
  type: "theme_mismatch" | "missing_category" | "poor_route" | "timing_issue" | "quality";
  severity: "error" | "warning" | "info";
  message: string;
  dayIndex?: number;
  placeIndex?: number;
}

export interface ValidationResult {
  /** Overall validity */
  isValid: boolean;

  /** Quality score 0-100 */
  score: number;

  /** Theme match percentage (0-100) */
  themeMatchPercent: number;

  /** List of issues found */
  issues: ValidationIssue[];

  /** Suggestions for improvement */
  suggestions: string[];

  /** Should retry with different approach */
  shouldRetry: boolean;
}

// =============================================================================
// Graph State
// =============================================================================

/**
 * The state object that flows through the entire LangGraph
 */
export interface TripGenerationState {
  // ─────────────────────────────────────────────────────────────────────────
  // Input
  // ─────────────────────────────────────────────────────────────────────────

  /** Original user query */
  query: string;

  /** Conversation context (previous messages) */
  conversationContext?: Array<{
    role: "user" | "assistant";
    content: string;
  }>;

  // ─────────────────────────────────────────────────────────────────────────
  // Agent Outputs
  // ─────────────────────────────────────────────────────────────────────────

  /** Result from Intent Agent */
  intent: IntentResult | null;

  /** Result from Search Agent */
  places: Place[] | null;

  /** Result from Planner Agent */
  trip: Trip | null;

  /** Result from Validator Agent */
  validation: ValidationResult | null;

  // ─────────────────────────────────────────────────────────────────────────
  // Meta / Control
  // ─────────────────────────────────────────────────────────────────────────

  /** Current phase for progress tracking */
  currentPhase:
    | "initializing"
    | "analyzing_intent"
    | "searching_places"
    | "planning_trip"
    | "validating"
    | "retrying"
    | "complete"
    | "error";

  /** Progress percentage 0-100 */
  progress: number;

  /** Number of retry attempts */
  retryCount: number;

  /** Maximum retries allowed */
  maxRetries: number;

  /** Accumulated errors */
  errors: string[];

  /** Timestamps for debugging */
  timestamps: {
    started?: string;
    intentCompleted?: string;
    searchCompleted?: string;
    planningCompleted?: string;
    validationCompleted?: string;
    finished?: string;
  };
}

// =============================================================================
// Agent Interface
// =============================================================================

/**
 * Base interface for all agents
 */
export interface Agent<TInput = TripGenerationState, TOutput = Partial<TripGenerationState>> {
  /** Agent name for logging/debugging */
  name: string;

  /** Agent description */
  description: string;

  /** Execute the agent */
  execute(state: TInput): Promise<TOutput>;
}

// =============================================================================
// Graph Configuration
// =============================================================================

export interface GraphConfig {
  /** Enable detailed logging */
  debug: boolean;

  /** Maximum retry attempts */
  maxRetries: number;

  /** Minimum theme match percentage to pass validation */
  minThemeMatchPercent: number;

  /** Minimum quality score to pass validation */
  minQualityScore: number;

  /** Enable streaming updates */
  streaming: boolean;
}

export const DEFAULT_GRAPH_CONFIG: GraphConfig = {
  debug: true,
  maxRetries: 3,
  minThemeMatchPercent: 70,
  minQualityScore: 60,
  streaming: true,
};
