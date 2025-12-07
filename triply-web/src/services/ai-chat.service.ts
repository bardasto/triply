/**
 * AI Chat Service
 * Handles communication with triply-workers AI generation API
 */

import type {
  AIGenerateRequest,
  AIGenerateResponse,
  ConversationMessage,
  AITripResponse,
  AISinglePlaceResponse,
} from '@/types/ai-response';

// API Configuration
const API_BASE_URL = process.env.NEXT_PUBLIC_AI_API_URL || 'http://localhost:3000';

/**
 * Custom error class for AI API errors
 */
export class AIServiceError extends Error {
  code: string;
  details?: string;

  constructor(message: string, code: string, details?: string) {
    super(message);
    this.name = 'AIServiceError';
    this.code = code;
    this.details = details;
  }
}

/**
 * Generate trip or place recommendation from user query
 * AI automatically determines the response type based on the query
 */
export async function generateFromQuery(
  request: AIGenerateRequest
): Promise<AIGenerateResponse> {
  try {
    const response = await fetch(`${API_BASE_URL}/api/trips/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(request),
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new AIServiceError(
        errorData.error?.message || `HTTP error ${response.status}`,
        errorData.error?.code || 'HTTP_ERROR',
        errorData.error?.details
      );
    }

    const data: AIGenerateResponse = await response.json();

    if (!data.success) {
      throw new AIServiceError(
        data.error?.message || 'Generation failed',
        data.error?.code || 'GENERATION_FAILED',
        data.error?.details
      );
    }

    return data;
  } catch (error) {
    if (error instanceof AIServiceError) {
      throw error;
    }

    // Network or other errors
    throw new AIServiceError(
      error instanceof Error ? error.message : 'Unknown error occurred',
      'NETWORK_ERROR'
    );
  }
}

/**
 * Build conversation context from chat history for context-aware generation
 */
export function buildConversationContext(
  messages: Array<{
    role: 'user' | 'assistant';
    content: string;
    tripData?: AITripResponse | null;
    placeData?: AISinglePlaceResponse | null;
  }> | null | undefined
): ConversationMessage[] {
  // Handle null/undefined messages
  if (!messages || !Array.isArray(messages)) {
    return [];
  }

  return messages
    .filter((msg) => msg && msg.role && msg.content)
    .map((msg) => {
      const contextMsg: ConversationMessage = {
        role: msg.role,
        content: msg.content || '',
      };

      if (msg.tripData) {
        contextMsg.type = 'trip';
        contextMsg.tripData = msg.tripData;
        contextMsg.city = msg.tripData.city;
        contextMsg.country = msg.tripData.country;
      } else if (msg.placeData) {
        contextMsg.type = 'places';
        contextMsg.placeData = msg.placeData;
        contextMsg.places = [msg.placeData.place, ...(msg.placeData.alternatives || [])];
        contextMsg.city = msg.placeData.place?.city;
        contextMsg.country = msg.placeData.place?.country;
      } else {
        contextMsg.type = 'text';
      }

      return contextMsg;
    });
}

/**
 * Health check for AI API
 */
export async function checkAPIHealth(): Promise<boolean> {
  try {
    const response = await fetch(`${API_BASE_URL}/health`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      return false;
    }

    const data = await response.json();
    return data.status === 'ok';
  } catch {
    return false;
  }
}

/**
 * Generate a short contextual message using AI
 * Used for intro messages before trip generation and completion messages after
 */
export async function generateShortMessage(
  type: 'intro' | 'completion',
  context: {
    query?: string;
    city?: string;
    country?: string;
    tripTitle?: string;
    duration?: number;
  }
): Promise<string> {
  try {
    const response = await fetch(`${API_BASE_URL}/api/chat/short-message`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ type, context }),
    });

    if (!response.ok) {
      // Return fallback message if API fails
      return getFallbackMessage(type, context);
    }

    const data = await response.json();
    return data.message || getFallbackMessage(type, context);
  } catch {
    // Return fallback message on error
    return getFallbackMessage(type, context);
  }
}

/**
 * Get fallback messages when AI generation fails
 */
function getFallbackMessage(
  type: 'intro' | 'completion',
  context: {
    query?: string;
    city?: string;
    country?: string;
    tripTitle?: string;
    duration?: number;
  }
): string {
  const city = context.city;
  const duration = context.duration || 3;

  if (type === 'intro') {
    // If we have a city, use city-specific messages
    if (city) {
      const introMessages = [
        `Alright, let me dive into ${city} and find the most amazing spots for you. I'm searching through local favorites, hidden gems, and must-see attractions to craft something special...`,
        `Great choice! I'm now exploring ${city} to put together the perfect itinerary. Give me a moment while I search for the best restaurants, attractions, and experiences...`,
        `${city} is an incredible destination! Let me search through hundreds of places to find the perfect mix of culture, food, and memorable experiences for your trip...`,
        `On it! I'm scanning through ${city}'s best spots right now — from iconic landmarks to those hidden places only locals know about. This is going to be good...`,
        `Let me work some magic here. I'm exploring ${city} to create a personalized adventure just for you. Searching for the perfect balance of activities, dining, and sightseeing...`,
        `Exciting! I'm now putting together your ${city} experience. Searching for the best places to eat, things to see, and moments you'll remember forever...`,
      ];
      return introMessages[Math.floor(Math.random() * introMessages.length)];
    }

    // Generic messages when city is not yet known
    const genericIntroMessages = [
      `Let me work on this for you. I'm analyzing your request and searching through thousands of places to find exactly what you're looking for...`,
      `Great request! Give me a moment while I search through local favorites, hidden gems, and must-see attractions to craft something special for you...`,
      `I'm on it! Searching through the best restaurants, attractions, and experiences to put together the perfect itinerary for you...`,
      `Let me dig into this. I'm exploring all the possibilities to create a personalized adventure tailored just to what you're looking for...`,
      `Working on your trip now! I'm scanning through iconic landmarks, local secrets, and amazing experiences to build something you'll love...`,
    ];
    return genericIntroMessages[Math.floor(Math.random() * genericIntroMessages.length)];
  }

  // Completion messages - city should always be known by this point
  const cityText = city || 'your destination';
  const completionMessages = [
    `And here we go! I've put together a ${duration}-day adventure in ${cityText} that I think you're going to love. Take a look and let me know if you'd like me to adjust anything!`,
    `Your ${cityText} trip is ready! I've curated a mix of must-see spots and some unique experiences. Feel free to ask if you want to swap anything or add more activities.`,
    `Done! Here's your personalized ${cityText} itinerary. I've balanced the days to give you a great mix of exploration and relaxation. What do you think?`,
    `All set! I've crafted a ${duration}-day journey through ${cityText} with carefully selected spots. Let me know if this looks good or if you'd like any changes!`,
    `Here's what I came up with for ${cityText}! Each day is packed with amazing experiences. Take a look and tell me if you want me to tweak anything.`,
  ];
  return completionMessages[Math.floor(Math.random() * completionMessages.length)];
}

/**
 * Extract a text summary from AI response for storing in chat history
 */
export function extractResponseSummary(
  response: AIGenerateResponse | null | undefined
): string {
  if (!response || !response.data) {
    return 'Here are my recommendations:';
  }

  try {
    if (response.type === 'trip') {
      const trip = response.data as AITripResponse;
      const duration = trip.duration_days || 'multi';
      const city = trip.city || 'your destination';
      const country = trip.country || '';
      const title = trip.title || 'Your Trip';
      const description = trip.description || '';
      return `Here's a ${duration}-day trip to ${city}${country ? `, ${country}` : ''}: **${title}**\n\n${description}`;
    }

    if (response.type === 'single_place') {
      const placeResponse = response.data as AISinglePlaceResponse;
      const place = placeResponse?.place;
      if (!place) {
        return 'Here is my recommendation:';
      }
      const ratingText = place.rating ? ` (${place.rating.toFixed(1)} rating)` : '';
      const priceText = place.estimatedPrice ? ` - ${place.estimatedPrice}` : '';
      return `I recommend **${place.name || 'this place'}**${ratingText}${priceText}\n\n${place.description || ''}`;
    }
  } catch (error) {
    console.error('Error extracting response summary:', error);
  }

  return 'Here are my recommendations:';
}
