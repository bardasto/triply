"use client";

import useSWR from "swr";
import { useCallback, useMemo } from "react";
import { useAuth } from "@/contexts/auth-context";
import { getSupabaseBrowserClient } from "@/lib/supabase/client";
import type {
  ChatHistory,
  ChatMessage,
  DBChatHistory,
  ChatHistoryCard,
  ChatHistoryFilters,
  CreateChatHistoryInput,
  ChatMode,
} from "@/types/chat-history";
import type { AITripResponse, AISinglePlaceResponse } from "@/types/ai-response";
import {
  toChatHistoryCard,
  createChatMessage,
  generateChatTitle,
  dbHistoryToWeb,
  webMessagesToDB,
} from "@/types/chat-history";

// Fetcher for chat histories
async function fetchChatHistories(
  userId: string,
  filters?: ChatHistoryFilters
): Promise<ChatHistory[]> {
  const supabase = getSupabaseBrowserClient();
  let query = supabase
    .from("chat_history")
    .select("*")
    .eq("user_id", userId)
    .order("updated_at", { ascending: false });

  if (filters?.mode) {
    query = query.eq("mode", filters.mode);
  }

  if (filters?.search) {
    query = query.ilike("title", `%${filters.search}%`);
  }

  const { data, error } = await query;

  if (error) {
    throw new Error(error.message);
  }

  // Convert DB format (snake_case) to Web format (camelCase)
  return (data as DBChatHistory[]).map(dbHistoryToWeb);
}

// Fetcher for single chat history
async function fetchChatHistory(
  userId: string,
  historyId: string
): Promise<ChatHistory | null> {
  const supabase = getSupabaseBrowserClient();
  const { data, error } = await supabase
    .from("chat_history")
    .select("*")
    .eq("id", historyId)
    .eq("user_id", userId)
    .single();

  if (error) {
    if (error.code === "PGRST116") {
      return null; // Not found
    }
    throw new Error(error.message);
  }

  // Convert DB format (snake_case) to Web format (camelCase)
  return dbHistoryToWeb(data as DBChatHistory);
}

/**
 * Hook to fetch all chat histories for the current user
 */
export function useChatHistories(filters?: ChatHistoryFilters) {
  const { user } = useAuth();

  const { data, error, isLoading, mutate } = useSWR(
    user ? ["chat-histories", user.id, filters] : null,
    () => fetchChatHistories(user!.id, filters),
    {
      revalidateOnFocus: false,
      revalidateIfStale: true,
      dedupingInterval: 30000,
    }
  );

  const histories = data || [];
  const historyCards: ChatHistoryCard[] = useMemo(
    () => histories.map(toChatHistoryCard),
    [histories]
  );

  return {
    histories,
    historyCards,
    isLoading,
    error: error?.message || null,
    mutate,
  };
}

/**
 * Hook to fetch a single chat history by ID
 */
export function useChatHistory(historyId: string | null) {
  const { user } = useAuth();

  const { data, error, isLoading, mutate } = useSWR(
    user && historyId ? ["chat-history", user.id, historyId] : null,
    () => fetchChatHistory(user!.id, historyId!),
    {
      revalidateOnFocus: false,
    }
  );

  return {
    history: data || null,
    isLoading,
    error: error?.message || null,
    mutate,
  };
}

/**
 * Hook for chat history actions (create, update, delete, add message)
 */
export function useChatHistoryActions() {
  const { user } = useAuth();

  const createHistory = useCallback(
    async (input: CreateChatHistoryInput) => {
      if (!user) {
        return { history: null, error: "Not authenticated" };
      }

      const supabase = getSupabaseBrowserClient();
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
        return { history: null, error: error.message };
      }

      // Convert back to Web format
      return { history: dbHistoryToWeb(data as DBChatHistory), error: null };
    },
    [user]
  );

  const updateHistory = useCallback(
    async (historyId: string, updates: { title?: string; messages?: ChatMessage[] }) => {
      if (!user) {
        return { success: false, error: "Not authenticated" };
      }

      const supabase = getSupabaseBrowserClient();
      const updateData: Record<string, unknown> = {
        updated_at: new Date().toISOString(),
      };

      if (updates.title !== undefined) {
        updateData.title = updates.title;
      }

      if (updates.messages !== undefined) {
        // Convert Web messages (camelCase) to DB format (snake_case)
        updateData.messages = webMessagesToDB(updates.messages);
      }

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const { error } = await (supabase as any)
        .from("chat_history")
        .update(updateData)
        .eq("id", historyId)
        .eq("user_id", user.id);

      if (error) {
        return { success: false, error: error.message };
      }

      return { success: true, error: null };
    },
    [user]
  );

  const addMessage = useCallback(
    async (historyId: string, text: string, isUser: boolean, currentMessages: ChatMessage[]) => {
      if (!user) {
        return { success: false, error: "Not authenticated" };
      }

      const message = createChatMessage(text, isUser);
      const messages = [...currentMessages, message];

      // Convert Web messages (camelCase) to DB format (snake_case)
      const dbMessages = webMessagesToDB(messages);

      const supabase = getSupabaseBrowserClient();
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const { error } = await (supabase as any)
        .from("chat_history")
        .update({
          messages: dbMessages,
          updated_at: new Date().toISOString(),
        })
        .eq("id", historyId)
        .eq("user_id", user.id);

      if (error) {
        return { success: false, message: null, error: error.message };
      }

      return { success: true, message, error: null };
    },
    [user]
  );

  const deleteHistory = useCallback(
    async (historyId: string) => {
      if (!user) {
        return { success: false, error: "Not authenticated" };
      }

      const supabase = getSupabaseBrowserClient();
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const { error } = await (supabase as any)
        .from("chat_history")
        .delete()
        .eq("id", historyId)
        .eq("user_id", user.id);

      if (error) {
        return { success: false, error: error.message };
      }

      return { success: true, error: null };
    },
    [user]
  );

  return {
    createHistory,
    updateHistory,
    addMessage,
    deleteHistory,
  };
}

/**
 * Hook for managing a single chat session with auto-sync
 */
export function useChatSession(mode: ChatMode = "trip_generation") {
  const { user } = useAuth();
  const { createHistory, updateHistory } = useChatHistoryActions();
  const { mutate: mutateList } = useChatHistories();

  const startNewChat = useCallback(
    async (firstMessage: string) => {
      if (!user) {
        return { historyId: null, error: "Not authenticated" };
      }

      const title = generateChatTitle(firstMessage);
      const userMessage = createChatMessage(firstMessage, true);

      const { history, error } = await createHistory({
        title,
        mode,
        messages: [userMessage],
      });

      if (error) {
        return { historyId: null, error };
      }

      // Revalidate the list
      mutateList();

      return { historyId: history?.id || null, error: null };
    },
    [user, mode, createHistory, mutateList]
  );

  const addMessageToChat = useCallback(
    async (
      historyId: string,
      text: string,
      isUser: boolean,
      currentMessages: ChatMessage[],
      options?: {
        tripData?: AITripResponse | null;
        placeData?: AISinglePlaceResponse | null;
      }
    ) => {
      if (!user) {
        return { message: null, error: "Not authenticated" };
      }

      const message = createChatMessage(text, isUser, options);
      const messages = [...currentMessages, message];

      const { success, error } = await updateHistory(historyId, { messages });

      if (!success) {
        return { message: null, error };
      }

      return { message, error: null };
    },
    [user, updateHistory]
  );

  return {
    startNewChat,
    addMessageToChat,
  };
}

/**
 * Hook for real-time chat history updates
 */
export function useChatHistoryRealtime() {
  const { user } = useAuth();
  const { mutate } = useChatHistories();

  const subscribe = useCallback(() => {
    if (!user) return () => {};

    const supabase = getSupabaseBrowserClient();
    const channel = supabase
      .channel(`chat_history_${user.id}`)
      .on(
        "postgres_changes",
        {
          event: "*",
          schema: "public",
          table: "chat_history",
          filter: `user_id=eq.${user.id}`,
        },
        () => {
          // Revalidate the chat histories data
          mutate();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [user, mutate]);

  return { subscribe };
}
