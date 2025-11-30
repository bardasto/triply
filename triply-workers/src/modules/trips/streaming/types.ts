/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Trip Streaming Types
 * Type definitions for real-time trip generation pipeline
 * ═══════════════════════════════════════════════════════════════════════════
 */

// ═══════════════════════════════════════════════════════════════════════════
// Event Types
// ═══════════════════════════════════════════════════════════════════════════

export type TripEventType =
  | 'init'
  | 'skeleton'
  | 'day'
  | 'place'
  | 'image'
  | 'prices'
  | 'complete'
  | 'error';

export interface BaseTripEvent {
  type: TripEventType;
  tripId: string;
  timestamp: number;
  sequence: number;
}

export interface InitEvent extends BaseTripEvent {
  type: 'init';
  data: {
    status: 'generating';
    estimatedDuration: number; // seconds
  };
}

export interface SkeletonEvent extends BaseTripEvent {
  type: 'skeleton';
  data: {
    title: string;
    description: string;
    theme: string | null;
    thematicKeywords: string[];
    city: string;
    country: string;
    duration: string;
    durationDays: number;
    vibe: string[];
    estimatedBudget: {
      min: number;
      max: number;
      currency: string;
    };
  };
}

export interface DayEvent extends BaseTripEvent {
  type: 'day';
  data: {
    day: number;
    title: string;
    description: string;
    placeholders: PlacePlaceholder[];
  };
}

export interface PlacePlaceholder {
  slot: 'breakfast' | 'lunch' | 'dinner' | 'attraction';
  index: number;
  hint: string;
}

export interface PlaceEvent extends BaseTripEvent {
  type: 'place';
  data: {
    day: number;
    slot: string;
    index: number;
    place: StreamingPlace;
  };
}

export interface StreamingPlace {
  id: string;
  placeId: string;
  name: string;
  category: string;
  description: string;
  duration_minutes: number;
  price: string;
  price_value: number;
  rating: number;
  address: string;
  latitude: number;
  longitude: number;
  best_time: string;
  opening_hours: string | null;
  image_url: string | null;
  transportation: {
    from_previous: string;
    method: string;
    duration_minutes: number;
    cost: string;
  };
}

export interface ImageEvent extends BaseTripEvent {
  type: 'image';
  data: {
    imageType: 'hero' | 'day' | 'place';
    url: string;
    day?: number;
    placeId?: string;
    placeName?: string;
    blurhash?: string;
  };
}

export interface PricesEvent extends BaseTripEvent {
  type: 'prices';
  data: {
    totalMin: number;
    totalMax: number;
    currency: string;
    breakdown: {
      accommodation: { min: number; max: number };
      food: { min: number; max: number };
      activities: { min: number; max: number };
      transport: { min: number; max: number };
    };
  };
}

export interface CompleteEvent extends BaseTripEvent {
  type: 'complete';
  data: {
    tripId: string;
    generatedAt: string;
    generationTimeMs: number;
    totalPlaces: number;
    totalImages: number;
  };
}

export interface ErrorEvent extends BaseTripEvent {
  type: 'error';
  data: {
    code: string;
    message: string;
    recoverable: boolean;
    phase: string;
  };
}

export type TripEvent =
  | InitEvent
  | SkeletonEvent
  | DayEvent
  | PlaceEvent
  | ImageEvent
  | PricesEvent
  | CompleteEvent
  | ErrorEvent;

// ═══════════════════════════════════════════════════════════════════════════
// Generation State
// ═══════════════════════════════════════════════════════════════════════════

export type GenerationPhase =
  | 'initializing'
  | 'analyzing'
  | 'generating_skeleton'
  | 'searching_places'
  | 'assigning_places'
  | 'loading_images'
  | 'finalizing'
  | 'complete'
  | 'error';

export interface GenerationState {
  tripId: string;
  phase: GenerationPhase;
  progress: number; // 0-100
  startTime: number;
  skeleton: SkeletonEvent['data'] | null;
  days: Map<number, DayEvent['data']>;
  places: Map<string, PlaceEvent['data']>; // key: `${day}-${slot}-${index}`
  images: Map<string, ImageEvent['data']>;
  errors: ErrorEvent['data'][];
}

// ═══════════════════════════════════════════════════════════════════════════
// Pipeline Types
// ═══════════════════════════════════════════════════════════════════════════

export interface GenerationRequest {
  tripId: string;
  userQuery: string;
  conversationContext?: any[];
  preferences?: {
    budget?: 'budget' | 'mid-range' | 'luxury';
    travelers?: number;
    accessibility?: boolean;
  };
}

export interface PipelineResult<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
  durationMs: number;
}

// ═══════════════════════════════════════════════════════════════════════════
// SSE Types
// ═══════════════════════════════════════════════════════════════════════════

export interface SSEClient {
  id: string;
  tripId: string;
  response: any; // Express Response
  connected: boolean;
  connectedAt: number;
}

export interface SSEMessage {
  event: TripEventType;
  data: string; // JSON stringified
  id?: string;
  retry?: number;
}
