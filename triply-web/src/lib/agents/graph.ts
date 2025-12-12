/**
 * LangGraph Trip Generation Graph
 *
 * This is the main orchestrator that connects all agents together.
 *
 * Graph Structure:
 * ┌─────────────────────────────────────────────────────────────────┐
 * │                         START                                   │
 * │                           │                                     │
 * │                           ▼                                     │
 * │                    ┌─────────────┐                              │
 * │                    │   Intent    │                              │
 * │                    │   Agent     │                              │
 * │                    └──────┬──────┘                              │
 * │                           │                                     │
 * │                           ▼                                     │
 * │                    ┌─────────────┐                              │
 * │                    │   Search    │                              │
 * │                    │   Agent     │                              │
 * │                    └──────┬──────┘                              │
 * │                           │                                     │
 * │                           ▼                                     │
 * │                    ┌─────────────┐                              │
 * │              ┌────▶│  Planner    │◀────┐                        │
 * │              │     │   Agent     │     │                        │
 * │              │     └──────┬──────┘     │                        │
 * │              │            │            │                        │
 * │              │            ▼            │                        │
 * │              │     ┌─────────────┐     │                        │
 * │              │     │  Validator  │     │                        │
 * │              │     │   Agent     │     │                        │
 * │              │     └──────┬──────┘     │                        │
 * │              │            │            │                        │
 * │              │     ┌──────┴──────┐     │                        │
 * │              │     │             │     │                        │
 * │              │     ▼             ▼     │                        │
 * │              │  [VALID]     [INVALID]──┘                        │
 * │              │     │         (retry)                            │
 * │              │     │                                            │
 * │              │     ▼                                            │
 * │              │   END                                            │
 * │              │                                                  │
 * │              └── (max retries reached) ──▶ END                  │
 * └─────────────────────────────────────────────────────────────────┘
 */

import { StateGraph, Annotation, END, START } from "@langchain/langgraph";
import type {
  TripGenerationState,
  IntentResult,
  Place,
  Trip,
  ValidationResult,
  GraphConfig,
} from "./types";
import { DEFAULT_GRAPH_CONFIG } from "./types";

// =============================================================================
// State Annotation (defines how state is updated)
// =============================================================================

/**
 * LangGraph Annotation defines how each field in state is updated
 * when nodes return partial state
 */
export const TripStateAnnotation = Annotation.Root({
  // Input fields
  query: Annotation<string>({
    reducer: (_, new_) => new_,
    default: () => "",
  }),
  conversationContext: Annotation<Array<{ role: "user" | "assistant"; content: string }>>({
    reducer: (_, new_) => new_ ?? [],
    default: () => [],
  }),

  // Agent outputs
  intent: Annotation<IntentResult | null>({
    reducer: (_, new_) => new_,
    default: () => null,
  }),
  places: Annotation<Place[] | null>({
    reducer: (_, new_) => new_,
    default: () => null,
  }),
  trip: Annotation<Trip | null>({
    reducer: (_, new_) => new_,
    default: () => null,
  }),
  validation: Annotation<ValidationResult | null>({
    reducer: (_, new_) => new_,
    default: () => null,
  }),

  // Meta fields
  currentPhase: Annotation<TripGenerationState["currentPhase"]>({
    reducer: (_, new_) => new_,
    default: () => "initializing" as const,
  }),
  progress: Annotation<number>({
    reducer: (_, new_) => new_,
    default: () => 0,
  }),
  retryCount: Annotation<number>({
    reducer: (old, new_) => old + new_,
    default: () => 0,
  }),
  maxRetries: Annotation<number>({
    reducer: (_, new_) => new_,
    default: () => 3,
  }),
  errors: Annotation<string[]>({
    reducer: (old, new_) => [...old, ...new_],
    default: () => [],
  }),
  timestamps: Annotation<TripGenerationState["timestamps"]>({
    reducer: (old, new_) => ({ ...old, ...new_ }),
    default: () => ({}),
  }),
});

// Type for the state
export type TripState = typeof TripStateAnnotation.State;

// =============================================================================
// Node Functions (Placeholder - will be replaced with actual agents)
// =============================================================================

/**
 * Intent Node - Analyzes the user query to understand intent
 */
async function intentNode(state: TripState): Promise<Partial<TripState>> {
  console.log("🎯 [Intent Agent] Analyzing query:", state.query);

  // TODO: Replace with actual IntentAgent
  // For now, return mock data
  const intent: IntentResult = {
    type: "thematic",
    theme: "massage",
    keywords: ["massage", "spa", "wellness", "relaxation"],
    city: "Bratislava",
    country: "Slovakia",
    duration: 2,
    strictMode: true,
    preferences: {
      budget: "moderate",
      pace: "relaxed",
    },
    confidence: 0.9,
  };

  return {
    intent,
    currentPhase: "analyzing_intent",
    progress: 20,
    timestamps: {
      intentCompleted: new Date().toISOString(),
    },
  };
}

/**
 * Search Node - Searches for relevant places
 */
async function searchNode(state: TripState): Promise<Partial<TripState>> {
  console.log("🔍 [Search Agent] Searching for places...");
  console.log("   Theme:", state.intent?.theme);
  console.log("   City:", state.intent?.city);
  console.log("   Strict mode:", state.intent?.strictMode);

  // TODO: Replace with actual SearchAgent
  const places: Place[] = [];

  return {
    places,
    currentPhase: "searching_places",
    progress: 40,
    timestamps: {
      searchCompleted: new Date().toISOString(),
    },
  };
}

/**
 * Planner Node - Creates the trip itinerary
 */
async function plannerNode(state: TripState): Promise<Partial<TripState>> {
  console.log("📋 [Planner Agent] Creating itinerary...");
  console.log("   Available places:", state.places?.length ?? 0);
  console.log("   Duration:", state.intent?.duration, "days");

  // TODO: Replace with actual PlannerAgent
  const trip: Trip = {
    id: crypto.randomUUID(),
    title: "Mock Trip",
    description: "This is a placeholder trip",
    city: state.intent?.city ?? "Unknown",
    country: state.intent?.country ?? "Unknown",
    duration_days: state.intent?.duration ?? 1,
    best_season: "Any",
    daily_budget: { min: 50, max: 100, currency: "EUR" },
    total_budget: { min: 100, max: 200, currency: "EUR" },
    trip_highlights: [],
    local_tips: [],
    days: [],
    created_at: new Date().toISOString(),
  };

  return {
    trip,
    currentPhase: "planning_trip",
    progress: 70,
    timestamps: {
      planningCompleted: new Date().toISOString(),
    },
  };
}

/**
 * Validator Node - Validates the generated trip
 */
async function validatorNode(state: TripState): Promise<Partial<TripState>> {
  console.log("✅ [Validator Agent] Validating trip...");
  console.log("   Trip title:", state.trip?.title);
  console.log("   Retry count:", state.retryCount);

  // TODO: Replace with actual ValidatorAgent
  const validation: ValidationResult = {
    isValid: true,
    score: 85,
    themeMatchPercent: 80,
    issues: [],
    suggestions: [],
    shouldRetry: false,
  };

  return {
    validation,
    currentPhase: "validating",
    progress: 90,
    timestamps: {
      validationCompleted: new Date().toISOString(),
    },
  };
}

/**
 * Retry Node - Prepares for retry
 */
async function retryNode(state: TripState): Promise<Partial<TripState>> {
  console.log("🔄 [Retry] Attempting retry #", state.retryCount + 1);

  return {
    retryCount: 1, // Will be added to existing count
    currentPhase: "retrying",
    validation: null, // Clear previous validation
  };
}

/**
 * Complete Node - Finalizes the trip
 */
async function completeNode(_state: TripState): Promise<Partial<TripState>> {
  console.log("🎉 [Complete] Trip generation finished!");

  return {
    currentPhase: "complete",
    progress: 100,
    timestamps: {
      finished: new Date().toISOString(),
    },
  };
}

// =============================================================================
// Conditional Edge Functions
// =============================================================================

/**
 * Decides what to do after validation
 */
function shouldRetryOrComplete(state: TripState): "retry" | "complete" {
  const { validation, retryCount, maxRetries } = state;

  // If valid, complete
  if (validation?.isValid) {
    console.log("✓ Validation passed, completing...");
    return "complete";
  }

  // If max retries reached, complete anyway
  if (retryCount >= maxRetries) {
    console.log("⚠ Max retries reached, completing with current result...");
    return "complete";
  }

  // Otherwise, retry
  console.log("✗ Validation failed, retrying...");
  return "retry";
}

// =============================================================================
// Graph Builder
// =============================================================================

/**
 * Creates the trip generation graph
 */
export function createTripGraph(_config: GraphConfig = DEFAULT_GRAPH_CONFIG) {
  // Create the graph with our state annotation
  const graph = new StateGraph(TripStateAnnotation);

  // ─────────────────────────────────────────────────────────────────────────
  // Add nodes (using _agent suffix to avoid conflict with state fields)
  // ─────────────────────────────────────────────────────────────────────────
  graph.addNode("intent_agent", intentNode);
  graph.addNode("search_agent", searchNode);
  graph.addNode("planner_agent", plannerNode);
  graph.addNode("validator_agent", validatorNode);
  graph.addNode("retry_node", retryNode);
  graph.addNode("complete_node", completeNode);

  // ─────────────────────────────────────────────────────────────────────────
  // Add edges
  // ─────────────────────────────────────────────────────────────────────────

  // Start -> Intent
  graph.addEdge(START, "intent_agent");

  // Intent -> Search
  graph.addEdge("intent_agent", "search_agent");

  // Search -> Planner
  graph.addEdge("search_agent", "planner_agent");

  // Planner -> Validator
  graph.addEdge("planner_agent", "validator_agent");

  // Validator -> (Retry OR Complete)
  graph.addConditionalEdges("validator_agent", shouldRetryOrComplete, {
    retry: "retry_node",
    complete: "complete_node",
  });

  // Retry -> Planner (try again)
  graph.addEdge("retry_node", "planner_agent");

  // Complete -> END
  graph.addEdge("complete_node", END);

  // ─────────────────────────────────────────────────────────────────────────
  // Compile and return
  // ─────────────────────────────────────────────────────────────────────────
  return graph.compile();
}

// =============================================================================
// Graph Visualization
// =============================================================================

/**
 * Returns a Mermaid diagram of the graph structure
 */
export function getGraphMermaidDiagram(): string {
  return `
graph TD
    START((Start)) --> INTENT[🎯 Intent Agent]
    INTENT --> SEARCH[🔍 Search Agent]
    SEARCH --> PLANNER[📋 Planner Agent]
    PLANNER --> VALIDATOR[✅ Validator Agent]
    VALIDATOR --> DECISION{Valid?}
    DECISION -->|Yes| COMPLETE[🎉 Complete]
    DECISION -->|No & retries < 3| RETRY[🔄 Retry]
    DECISION -->|No & retries >= 3| COMPLETE
    RETRY --> PLANNER
    COMPLETE --> END((End))

    style INTENT fill:#e1f5fe
    style SEARCH fill:#f3e5f5
    style PLANNER fill:#e8f5e9
    style VALIDATOR fill:#fff3e0
    style COMPLETE fill:#e8f5e9
    style RETRY fill:#ffebee
`;
}

/**
 * Returns an ASCII visualization of the graph
 */
export function getGraphASCII(): string {
  return `
╔══════════════════════════════════════════════════════════════════╗
║                    TRIP GENERATION GRAPH                          ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║                          ┌─────────┐                              ║
║                          │  START  │                              ║
║                          └────┬────┘                              ║
║                               │                                   ║
║                               ▼                                   ║
║                    ┌─────────────────────┐                        ║
║                    │   🎯 Intent Agent   │                        ║
║                    │  ─────────────────  │                        ║
║                    │  • Classify intent  │                        ║
║                    │  • Extract theme    │                        ║
║                    │  • Get constraints  │                        ║
║                    └──────────┬──────────┘                        ║
║                               │                                   ║
║                               ▼                                   ║
║                    ┌─────────────────────┐                        ║
║                    │   🔍 Search Agent   │                        ║
║                    │  ─────────────────  │                        ║
║                    │  • Search places    │                        ║
║                    │  • Filter by theme  │                        ║
║                    │  • Score relevance  │                        ║
║                    └──────────┬──────────┘                        ║
║                               │                                   ║
║                               ▼                                   ║
║           ┌──────────────────────────────────────┐                ║
║           │                                      │                ║
║           ▼                                      │                ║
║  ┌─────────────────────┐                        │                ║
║  │  📋 Planner Agent   │◀───────────────────────┤                ║
║  │  ─────────────────  │                        │                ║
║  │  • Build itinerary  │                        │                ║
║  │  • Optimize route   │                        │                ║
║  │  • Add timings      │                        │                ║
║  └──────────┬──────────┘                        │                ║
║             │                                    │                ║
║             ▼                                    │                ║
║  ┌─────────────────────┐                        │                ║
║  │  ✅ Validator Agent │                        │                ║
║  │  ─────────────────  │                        │                ║
║  │  • Check theme %    │                        │                ║
║  │  • Validate route   │                        │                ║
║  │  • Score quality    │                        │                ║
║  └──────────┬──────────┘                        │                ║
║             │                                    │                ║
║       ┌─────┴─────┐                             │                ║
║       │           │                             │                ║
║       ▼           ▼                             │                ║
║   ┌───────┐   ┌───────┐                        │                ║
║   │ Valid │   │Invalid│─────────────────────────┘                ║
║   └───┬───┘   └───────┘     (retry if < 3 attempts)              ║
║       │                                                           ║
║       ▼                                                           ║
║  ┌─────────────────────┐                                          ║
║  │   🎉 Complete       │                                          ║
║  └──────────┬──────────┘                                          ║
║             │                                                     ║
║             ▼                                                     ║
║         ┌───────┐                                                 ║
║         │  END  │                                                 ║
║         └───────┘                                                 ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝
`;
}

/**
 * Prints graph info to console
 */
export function printGraphInfo(): void {
  console.log("\n" + "=".repeat(70));
  console.log("LANGGRAPH TRIP GENERATION PIPELINE");
  console.log("=".repeat(70));
  console.log(getGraphASCII());
  console.log("\nNodes:");
  console.log("  1. Intent Agent   - Understands what user wants");
  console.log("  2. Search Agent   - Finds relevant places");
  console.log("  3. Planner Agent  - Creates the itinerary");
  console.log("  4. Validator Agent - Ensures quality");
  console.log("\nFeatures:");
  console.log("  • Automatic retry on validation failure (max 3)");
  console.log("  • Theme-aware search (strict mode)");
  console.log("  • Quality scoring and feedback");
  console.log("=".repeat(70) + "\n");
}

// =============================================================================
// Export compiled graph
// =============================================================================

export const tripGraph = createTripGraph();
