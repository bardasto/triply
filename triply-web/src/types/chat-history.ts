/**
 * Chat History Types
 * Based on mobile app implementation for cross-platform sync
 *
 * IMPORTANT: Database stores messages in snake_case format (matching Flutter).
 * Web uses camelCase internally but converts when reading/writing to DB.
 */

import type { AITripResponse, AISinglePlaceResponse } from "./ai-response";

// Chat mode types matching the mobile app
export type ChatMode = "trip_generation" | "hotel_selection" | "flight_tickets";

// Message format stored in the database (snake_case - matches Flutter)
export interface DBChatMessage {
  id: string;
  text: string;
  is_user: boolean;
  timestamp: string; // ISO string
  trip_data?: AITripResponse | null;
  place_data?: AISinglePlaceResponse | null;
  can_create_trip?: boolean;
  is_trip_creation_prompt?: boolean;
  saved_trip_id?: string | null;
}

// Message format used in Web app (camelCase)
export interface ChatMessage {
  id: string;
  text: string;
  isUser: boolean;
  timestamp: string; // ISO string
  tripData?: AITripResponse | null;
  placeData?: AISinglePlaceResponse | null;
  canCreateTrip?: boolean;
  isTripCreationPrompt?: boolean;
  savedTripId?: string | null;
}

/**
 * Convert DB message (snake_case) to Web message (camelCase)
 */
export function dbMessageToWeb(dbMsg: DBChatMessage): ChatMessage {
  return {
    id: dbMsg.id,
    text: dbMsg.text,
    isUser: dbMsg.is_user,
    timestamp: dbMsg.timestamp,
    tripData: dbMsg.trip_data,
    placeData: dbMsg.place_data,
    canCreateTrip: dbMsg.can_create_trip,
    isTripCreationPrompt: dbMsg.is_trip_creation_prompt,
    savedTripId: dbMsg.saved_trip_id,
  };
}

/**
 * Convert Web message (camelCase) to DB message (snake_case)
 */
export function webMessageToDB(webMsg: ChatMessage): DBChatMessage {
  return {
    id: webMsg.id,
    text: webMsg.text,
    is_user: webMsg.isUser,
    timestamp: webMsg.timestamp,
    trip_data: webMsg.tripData,
    place_data: webMsg.placeData,
    can_create_trip: webMsg.canCreateTrip,
    is_trip_creation_prompt: webMsg.isTripCreationPrompt,
    saved_trip_id: webMsg.savedTripId,
  };
}

/**
 * Convert array of DB messages to Web messages
 */
export function dbMessagesToWeb(dbMessages: DBChatMessage[]): ChatMessage[] {
  return dbMessages.map(dbMessageToWeb);
}

/**
 * Convert array of Web messages to DB messages
 */
export function webMessagesToDB(webMessages: ChatMessage[]): DBChatMessage[] {
  return webMessages.map(webMessageToDB);
}

// Simplified trip data for backwards compatibility
export interface TripData {
  tripId: string;
  title: string;
  city: string;
  country: string;
  imageUrl?: string;
}

// Simplified place data for backwards compatibility
export interface PlaceData {
  placeId: string;
  name: string;
  type: string;
  imageUrl?: string;
}

// Database chat history record (snake_case messages)
export interface DBChatHistory {
  id: string;
  user_id: string;
  title: string;
  mode: ChatMode;
  messages: DBChatMessage[];
  created_at: string;
  updated_at: string;
}

// Full chat history record for Web app (camelCase messages)
export interface ChatHistory {
  id: string;
  user_id: string;
  title: string;
  mode: ChatMode;
  messages: ChatMessage[];
  created_at: string;
  updated_at: string;
}

/**
 * Convert DB chat history to Web format
 */
export function dbHistoryToWeb(dbHistory: DBChatHistory): ChatHistory {
  return {
    ...dbHistory,
    messages: dbMessagesToWeb(dbHistory.messages || []),
  };
}

/**
 * Convert Web chat history to DB format
 */
export function webHistoryToDB(webHistory: ChatHistory): DBChatHistory {
  return {
    ...webHistory,
    messages: webMessagesToDB(webHistory.messages || []),
  };
}

// Chat history card for display in sidebar
export interface ChatHistoryCard {
  id: string;
  title: string;
  mode: ChatMode;
  lastMessage: string;
  messageCount: number;
  createdAt: Date;
  updatedAt: Date;
}

// Input for creating a new chat history
export interface CreateChatHistoryInput {
  title: string;
  mode: ChatMode;
  messages?: ChatMessage[];
}

// Input for updating chat history
export interface UpdateChatHistoryInput {
  title?: string;
  messages?: ChatMessage[];
}

// Filters for querying chat history
export interface ChatHistoryFilters {
  mode?: ChatMode;
  search?: string;
}

/**
 * Convert ChatHistory to ChatHistoryCard for sidebar display
 */
export function toChatHistoryCard(history: ChatHistory): ChatHistoryCard {
  const lastMessage = history.messages.length > 0
    ? history.messages[history.messages.length - 1].text
    : "";

  return {
    id: history.id,
    title: history.title,
    mode: history.mode,
    lastMessage: lastMessage.length > 50 ? lastMessage.slice(0, 50) + "..." : lastMessage,
    messageCount: history.messages.length,
    createdAt: new Date(history.created_at),
    updatedAt: new Date(history.updated_at),
  };
}

/**
 * Create a new ChatMessage
 */
export function createChatMessage(
  text: string,
  isUser: boolean,
  options?: {
    tripData?: AITripResponse | null;
    placeData?: AISinglePlaceResponse | null;
    savedTripId?: string | null;
  }
): ChatMessage {
  return {
    id: crypto.randomUUID(),
    text,
    isUser,
    timestamp: new Date().toISOString(),
    tripData: options?.tripData || null,
    placeData: options?.placeData || null,
    savedTripId: options?.savedTripId || null,
  };
}

/**
 * Generate chat title from first user message
 */
export function generateChatTitle(firstMessage: string): string {
  // Truncate and clean up the message for a title
  const cleaned = firstMessage.trim().replace(/\n+/g, " ");
  if (cleaned.length <= 40) {
    return cleaned;
  }
  return cleaned.slice(0, 37) + "...";
}
