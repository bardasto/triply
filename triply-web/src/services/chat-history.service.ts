"use server";

import { createClient } from "@/lib/supabase/server";
import type {
  ChatHistory,
  ChatMessage,
  DBChatHistory,
  CreateChatHistoryInput,
  UpdateChatHistoryInput,
  ChatHistoryFilters,
} from "@/types/chat-history";
import {
  dbHistoryToWeb,
  webMessagesToDB,
  webMessageToDB,
} from "@/types/chat-history";

/**
 * Fetch all chat histories for the current authenticated user
 */
export async function getChatHistories(filters?: ChatHistoryFilters): Promise<{
  histories: ChatHistory[];
  error: string | null;
}> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return { histories: [], error: "Not authenticated" };
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let query = (supabase as any)
    .from("chat_history")
    .select("*")
    .eq("user_id", user.id)
    .order("updated_at", { ascending: false });

  // Apply filters
  if (filters?.mode) {
    query = query.eq("mode", filters.mode);
  }

  if (filters?.search) {
    query = query.ilike("title", `%${filters.search}%`);
  }

  const { data, error } = await query;

  if (error) {
    console.error("Error fetching chat histories:", error);
    return { histories: [], error: error.message };
  }

  // Convert DB format (snake_case) to Web format (camelCase)
  const histories = (data as DBChatHistory[]).map(dbHistoryToWeb);
  return { histories, error: null };
}

/**
 * Get a single chat history by ID for the current user
 */
export async function getChatHistoryById(historyId: string): Promise<{
  history: ChatHistory | null;
  error: string | null;
}> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return { history: null, error: "Not authenticated" };
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { data, error } = await (supabase as any)
    .from("chat_history")
    .select("*")
    .eq("id", historyId)
    .eq("user_id", user.id)
    .single();

  if (error) {
    console.error("Error fetching chat history:", error);
    return { history: null, error: error.message };
  }

  // Convert DB format (snake_case) to Web format (camelCase)
  return { history: dbHistoryToWeb(data as DBChatHistory), error: null };
}

/**
 * Create a new chat history
 */
export async function createChatHistory(
  input: CreateChatHistoryInput
): Promise<{ history: ChatHistory | null; error: string | null }> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return { history: null, error: "Not authenticated" };
  }

  const now = new Date().toISOString();

  // Convert Web messages (camelCase) to DB format (snake_case)
  const dbMessages = input.messages ? webMessagesToDB(input.messages) : [];

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { data, error } = await (supabase as any)
    .from("chat_history")
    .insert({
      user_id: user.id,
      title: input.title,
      mode: input.mode,
      messages: dbMessages,
      created_at: now,
      updated_at: now,
    })
    .select()
    .single();

  if (error) {
    console.error("Error creating chat history:", error);
    return { history: null, error: error.message };
  }

  // Convert back to Web format
  return { history: dbHistoryToWeb(data as DBChatHistory), error: null };
}

/**
 * Update an existing chat history
 */
export async function updateChatHistory(
  historyId: string,
  input: UpdateChatHistoryInput
): Promise<{ success: boolean; error: string | null }> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return { success: false, error: "Not authenticated" };
  }

  const updateData: Record<string, unknown> = {
    updated_at: new Date().toISOString(),
  };

  if (input.title !== undefined) {
    updateData.title = input.title;
  }

  if (input.messages !== undefined) {
    // Convert Web messages (camelCase) to DB format (snake_case)
    updateData.messages = webMessagesToDB(input.messages);
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { error } = await (supabase as any)
    .from("chat_history")
    .update(updateData)
    .eq("id", historyId)
    .eq("user_id", user.id);

  if (error) {
    console.error("Error updating chat history:", error);
    return { success: false, error: error.message };
  }

  return { success: true, error: null };
}

/**
 * Add a message to an existing chat history
 */
export async function addMessageToChatHistory(
  historyId: string,
  message: ChatMessage
): Promise<{ success: boolean; error: string | null }> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return { success: false, error: "Not authenticated" };
  }

  // First, get current messages
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { data: current, error: fetchError } = await (supabase as any)
    .from("chat_history")
    .select("messages")
    .eq("id", historyId)
    .eq("user_id", user.id)
    .single();

  if (fetchError) {
    console.error("Error fetching chat history:", fetchError);
    return { success: false, error: fetchError.message };
  }

  // Messages from DB are in snake_case, append new message converted to snake_case
  const dbMessage = webMessageToDB(message);
  const messages = [...(current.messages || []), dbMessage];

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { error } = await (supabase as any)
    .from("chat_history")
    .update({
      messages,
      updated_at: new Date().toISOString(),
    })
    .eq("id", historyId)
    .eq("user_id", user.id);

  if (error) {
    console.error("Error adding message to chat history:", error);
    return { success: false, error: error.message };
  }

  return { success: true, error: null };
}

/**
 * Delete a chat history
 */
export async function deleteChatHistory(
  historyId: string
): Promise<{ success: boolean; error: string | null }> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return { success: false, error: "Not authenticated" };
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { error } = await (supabase as any)
    .from("chat_history")
    .delete()
    .eq("id", historyId)
    .eq("user_id", user.id);

  if (error) {
    console.error("Error deleting chat history:", error);
    return { success: false, error: error.message };
  }

  return { success: true, error: null };
}

/**
 * Get the most recent chat history for the user
 */
export async function getMostRecentChatHistory(): Promise<{
  history: ChatHistory | null;
  error: string | null;
}> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return { history: null, error: "Not authenticated" };
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { data, error } = await (supabase as any)
    .from("chat_history")
    .select("*")
    .eq("user_id", user.id)
    .order("updated_at", { ascending: false })
    .limit(1)
    .single();

  if (error) {
    if (error.code === "PGRST116") {
      // No rows found
      return { history: null, error: null };
    }
    console.error("Error fetching most recent chat history:", error);
    return { history: null, error: error.message };
  }

  // Convert DB format (snake_case) to Web format (camelCase)
  return { history: dbHistoryToWeb(data as DBChatHistory), error: null };
}
