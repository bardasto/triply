"use client";

import { useState, useEffect, useRef, useCallback, useMemo, Suspense } from "react";
import { useSearchParams } from "next/navigation";

// Hook to detect mobile
function useIsMobile() {
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    const checkMobile = () => setIsMobile(window.innerWidth < 768);
    checkMobile();
    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  return isMobile;
}

// Simulated progress bar component for desktop chat
function SimulatedProgressBar({ realProgress, phase }: { realProgress: number; phase: string }) {
  const [displayProgress, setDisplayProgress] = useState(realProgress);
  const lastRealProgressRef = useRef(realProgress);
  const lastUpdateTimeRef = useRef(Date.now());

  useEffect(() => {
    if (realProgress !== lastRealProgressRef.current) {
      lastRealProgressRef.current = realProgress;
      lastUpdateTimeRef.current = Date.now();
      setDisplayProgress(realProgress);
      return;
    }

    const interval = setInterval(() => {
      const timeSinceUpdate = Date.now() - lastUpdateTimeRef.current;
      if (timeSinceUpdate > 2000) {
        setDisplayProgress(prev => {
          let maxProgress = realProgress + 0.15;
          if (phase === 'skeleton' || phase === 'generating_skeleton') {
            maxProgress = Math.min(maxProgress, 0.45);
          } else if (phase === 'days' || phase === 'places' || phase === 'assigning_places') {
            maxProgress = Math.min(maxProgress, 0.75);
          } else if (phase === 'images' || phase === 'loading_images') {
            maxProgress = Math.min(maxProgress, 0.95);
          }
          return Math.min(prev + 0.005, maxProgress);
        });
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [realProgress, phase]);

  const statusText = phase === 'skeleton' || phase === 'generating_skeleton'
    ? 'Creating structure...'
    : phase === 'days' || phase === 'places' || phase === 'assigning_places'
    ? 'Finding places...'
    : phase === 'images' || phase === 'loading_images'
    ? 'Loading images...'
    : 'Generating trip...';

  return (
    <div className="bg-white/10 rounded-xl p-4 space-y-3">
      <div className="flex items-center gap-2">
        <div className="relative w-2 h-2 flex-shrink-0">
          <div className="absolute inset-0 bg-primary rounded-full" />
          <div className="absolute inset-0 bg-primary rounded-full animate-ping opacity-50" />
        </div>
        <span className="text-sm text-white/70">Generating trip...</span>
      </div>
      <div className="w-full h-1.5 bg-white/10 rounded-full overflow-hidden">
        <div
          className="h-full bg-primary rounded-full transition-all duration-500 ease-out"
          style={{ width: `${displayProgress * 100}%` }}
        />
      </div>
      <div className="flex items-center justify-between text-xs">
        <span className="text-white/50">{statusText}</span>
        <span className="font-medium text-primary">{Math.round(displayProgress * 100)}%</span>
      </div>
    </div>
  );
}

import { ChatSidebar } from "@/components/features/chat/chat-sidebar";
import { ChatHeader } from "@/components/features/chat/chat-header";
import { ChatMessage, type Message } from "@/components/features/chat/chat-message";
import { ChatInput } from "@/components/features/chat/chat-input";
import { ChatEmptyState } from "@/components/features/chat/chat-empty-state";
import { AuthModal } from "@/components/features/auth/auth-modal";
import { TripDetailsPanel } from "@/components/features/chat/panels/trip-details-panel";
import { PlaceDetailsPanel } from "@/components/features/chat/panels/place-details-panel";
import { StreamingTripDetailsPanel } from "@/components/features/chat/panels/streaming-trip-details-panel";
import { StreamingTripCard } from "@/components/features/chat/cards/streaming-trip-card";
import { cn } from "@/lib/utils";
import { useAuth } from "@/contexts/auth-context";
import { useChatHistory, useChatSession, useChatHistories } from "@/hooks/useChatHistory";
import { useStreamingTrip } from "@/hooks/useStreamingTrip";
import {
  generateFromQuery,
  buildConversationContext,
  extractResponseSummary,
  generateShortMessage,
  AIServiceError,
} from "@/services/ai-chat.service";
import { saveUserTrip } from "@/services/user-trips.service";
import type { ChatMessage as ChatHistoryMessage } from "@/types/chat-history";
import type {
  AITripResponse,
  AISinglePlaceResponse,
  ConversationMessage,
} from "@/types/ai-response";

// Convert chat history message to UI message
function toUIMessage(msg: ChatHistoryMessage): Message {
  return {
    id: msg.id,
    role: msg.isUser ? "user" : "assistant",
    content: msg.text,
    createdAt: new Date(msg.timestamp),
    tripData: msg.tripData || null,
    placeData: msg.placeData || null,
    savedTripId: msg.savedTripId || null,
  };
}

// Keywords to detect trip requests vs single place requests
const TRIP_KEYWORDS = [
  'trip', 'itinerary', 'travel', 'vacation', 'holiday', 'tour',
  'day trip', 'days', 'week', 'weekend', 'visit', 'explore',
  'plan', 'schedule', 'route', 'journey',
];

function isLikelyTripRequest(query: string): boolean {
  const lowerQuery = query.toLowerCase();
  return TRIP_KEYWORDS.some(keyword => lowerQuery.includes(keyword));
}

function ChatContent() {
  const searchParams = useSearchParams();
  const initialQuery = searchParams.get("q") || "";

  const { user } = useAuth();
  const [currentChatId, setCurrentChatId] = useState<string | null>(null);
  const [localMessages, setLocalMessages] = useState<Message[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [inputValue, setInputValue] = useState("");
  const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);

  // Streaming state
  const [showStreamingCard, setShowStreamingCard] = useState(false);
  const [introMessage, setIntroMessage] = useState<string | null>(null);
  const [displayedIntroText, setDisplayedIntroText] = useState("");
  const [introTypingComplete, setIntroTypingComplete] = useState(false);
  const [completionMessage, setCompletionMessage] = useState<string | null>(null);
  const [displayedCompletionText, setDisplayedCompletionText] = useState("");
  const [completionTypingComplete, setCompletionTypingComplete] = useState(false);
  const pendingQueryRef = useRef<string | null>(null);
  const pendingUserMessageRef = useRef<Message | null>(null);
  const aiMessageIdRef = useRef<string | null>(null);
  const pendingAiMessageRef = useRef<Message | null>(null);
  const pendingTripRef = useRef<AITripResponse | null>(null);

  // Side panel state
  const [selectedTrip, setSelectedTrip] = useState<AITripResponse | null>(null);
  const [selectedPlace, setSelectedPlace] = useState<AISinglePlaceResponse | null>(null);
  const [isTripPanelOpen, setIsTripPanelOpen] = useState(false);
  const [isPlacePanelOpen, setIsPlacePanelOpen] = useState(false);
  const [isStreamingPanelOpen, setIsStreamingPanelOpen] = useState(false);

  // Check if any details panel is open
  const isMobile = useIsMobile();
  // On mobile, panel is shown as overlay (sheet), so don't shift chat area
  const isDetailsPanelOpen = !isMobile && (isTripPanelOpen || isPlacePanelOpen || isStreamingPanelOpen);

  const messagesEndRef = useRef<HTMLDivElement>(null);
  const initialQueryProcessedRef = useRef(false);

  // Chat history hooks
  const { history, mutate: mutateHistory } = useChatHistory(currentChatId);
  const { startNewChat, addMessageToChat } = useChatSession();
  const { mutate: mutateHistories } = useChatHistories();

  // Streaming hook for trip generation
  const handleStreamingComplete = useCallback(async (tripData: unknown, message: string) => {
    console.log("[Chat] handleStreamingComplete called");
    console.log("[Chat] tripData:", tripData);
    console.log("[Chat] message:", message);

    const aiMessageId = aiMessageIdRef.current;
    const userMessage = pendingUserMessageRef.current;
    const query = pendingQueryRef.current;

    console.log("[Chat] aiMessageId:", aiMessageId);
    console.log("[Chat] userMessage:", userMessage);
    console.log("[Chat] query:", query);

    if (!aiMessageId || !userMessage || !query) {
      console.error("[Chat] Missing required refs!", { aiMessageId, userMessage, query });
      return;
    }

    // Cast tripData to AITripResponse
    const trip = tripData as AITripResponse;

    // Generate completion message
    const completionMsg = await generateShortMessage('completion', {
      query,
      city: trip.city,
      country: trip.country,
      tripTitle: trip.title,
      duration: trip.duration_days,
    });

    // Set completion message to trigger typewriter effect
    setCompletionMessage(completionMsg);

    // Save trip to user's trips first to get savedTripId
    let savedTripId: string | null = null;
    if (user) {
      const { tripId, error } = await saveUserTrip(trip, query);
      if (error) {
        console.error("Failed to save trip to user trips:", error);
      } else {
        console.log("Trip saved to user trips:", tripId);
        savedTripId = tripId;
      }
    }

    // Create the final AI message with completion text and savedTripId
    const aiMessage: Message = {
      id: aiMessageId,
      role: "assistant",
      content: completionMsg,
      createdAt: new Date(),
      isGenerating: false,
      tripData: trip,
      placeData: null,
      savedTripId,
    };

    // Store for use after typing animation completes
    pendingAiMessageRef.current = aiMessage;
    pendingTripRef.current = trip;

    // Hide streaming card immediately, show completion message typing
    setShowStreamingCard(false);
    setIntroMessage(null);
    setDisplayedIntroText("");
    setIntroTypingComplete(false);
    setIsLoading(false);

    // On desktop, close streaming panel and open the regular trip panel with complete data
    // Use window.innerWidth since we're inside a callback where isMobile hook may be stale
    if (window.innerWidth >= 768) {
      setIsStreamingPanelOpen(false);
      setSelectedTrip(trip);
      setIsTripPanelOpen(true);
    }

    // Save to chat history database
    if (!currentChatId) {
      const { historyId, error } = await startNewChat(query);
      if (historyId && !error) {
        setCurrentChatId(historyId);
        const currentMessages = history?.messages || [];
        await addMessageToChat(
          historyId,
          aiMessage.content,
          false,
          [
            ...currentMessages,
            {
              id: userMessage.id,
              text: query,
              isUser: true,
              timestamp: new Date().toISOString(),
              tripData: null,
              placeData: null,
            },
          ],
          { tripData: trip, placeData: null, savedTripId }
        );
        mutateHistory();
        mutateHistories();
      }
    } else {
      const currentMessages = history?.messages || [];
      await addMessageToChat(currentChatId, query, true, currentMessages);
      const updatedMessages = [
        ...currentMessages,
        {
          id: userMessage.id,
          text: query,
          isUser: true,
          timestamp: new Date().toISOString(),
          tripData: null,
          placeData: null,
        },
      ];
      await addMessageToChat(
        currentChatId,
        aiMessage.content,
        false,
        updatedMessages,
        { tripData: trip, placeData: null, savedTripId }
      );
      mutateHistory();
      mutateHistories();
    }

    // Clean up refs
    pendingUserMessageRef.current = null;
    aiMessageIdRef.current = null;
    pendingQueryRef.current = null;
  }, [user, currentChatId, history, startNewChat, addMessageToChat, mutateHistory, mutateHistories]);

  const handleStreamingError = useCallback((error: string) => {
    const aiMessageId = aiMessageIdRef.current;
    if (!aiMessageId) return;

    const errorMessage: Message = {
      id: aiMessageId,
      role: "assistant",
      content: `Sorry, I encountered an error: ${error}`,
      createdAt: new Date(),
      isGenerating: false,
    };

    setLocalMessages((prev) =>
      prev.map((msg) => (msg.id === aiMessageId ? errorMessage : msg))
    );
    setShowStreamingCard(false);
    setIntroMessage(null);
    setIsLoading(false);

    // Clean up refs
    pendingUserMessageRef.current = null;
    aiMessageIdRef.current = null;
    pendingQueryRef.current = null;
  }, []);

  const {
    state: streamingState,
    isStreaming,
    startStreaming,
    cancelStreaming,
    reset: resetStreaming,
  } = useStreamingTrip({
    onComplete: handleStreamingComplete,
    onError: handleStreamingError,
  });

  // Derive messages from history or use local messages
  const messages = useMemo(() => {
    if (history?.messages && history.messages.length > 0) {
      return history.messages.map(toUIMessage);
    }
    return localMessages;
  }, [history, localMessages]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  // Build conversation context for AI
  const buildContext = useCallback((): ConversationMessage[] => {
    if (!messages || messages.length === 0) {
      return [];
    }
    const contextMessages = messages
      .filter((msg) => msg && msg.role && msg.content)
      .map((msg) => ({
        role: msg.role,
        content: msg.content || '',
        tripData: msg.tripData || undefined,
        placeData: msg.placeData || undefined,
      }));
    return buildConversationContext(contextMessages);
  }, [messages]);

  const handleSendMessage = useCallback(
    async (content: string) => {
      // Check if user is logged in
      if (!user) {
        setIsAuthModalOpen(true);
        return;
      }

      const userMessage: Message = {
        id: Date.now().toString(),
        role: "user",
        content,
        createdAt: new Date(),
      };

      // Add user message to local state
      setLocalMessages((prev) => [...prev, userMessage]);
      setIsLoading(true);
      setInputValue("");

      // Create placeholder AI message with loading state
      const aiMessageId = (Date.now() + 1).toString();
      const loadingMessage: Message = {
        id: aiMessageId,
        role: "assistant",
        content: "",
        createdAt: new Date(),
        isGenerating: true,
      };
      setLocalMessages((prev) => [...prev, loadingMessage]);

      // Build conversation context
      const conversationContext = buildContext();

      // Check if this looks like a trip request - use streaming
      if (isLikelyTripRequest(content)) {
        // Store refs for completion handler
        pendingUserMessageRef.current = userMessage;
        aiMessageIdRef.current = aiMessageId;
        pendingQueryRef.current = content;
        resetStreaming();

        // Generate intro message first (don't await - show streaming card immediately)
        generateShortMessage('intro', { query: content }).then((intro) => {
          setIntroMessage(intro);
        });

        // Show streaming card (for mobile) or streaming panel (for desktop)
        setShowStreamingCard(true);

        // On desktop, open streaming details panel immediately
        if (!isMobile) {
          setIsStreamingPanelOpen(true);
          // Close other panels
          setIsTripPanelOpen(false);
          setIsPlacePanelOpen(false);
        }

        // Start streaming generation
        startStreaming(content, conversationContext);
        return;
      }

      // For non-trip requests, use regular API
      try {
        // Call AI API
        const response = await generateFromQuery({
          query: content,
          conversationContext,
        });

        // Validate response
        if (!response || !response.data) {
          throw new Error('Invalid response from AI API');
        }

        // Extract text summary for display
        const responseSummary = extractResponseSummary(response);

        // Save trip to user's trips if authenticated and it's a trip response
        let savedTripId: string | null = null;
        const tripData = response.type === 'trip' && response.data ? (response.data as AITripResponse) : null;
        if (user && tripData) {
          const { tripId, error } = await saveUserTrip(tripData, content);
          if (error) {
            console.error("Failed to save trip to user trips:", error);
          } else {
            console.log("Trip saved to user trips:", tripId);
            savedTripId = tripId;
          }
        }

        // Create AI message with data
        const aiMessage: Message = {
          id: aiMessageId,
          role: "assistant",
          content: responseSummary,
          createdAt: new Date(),
          isGenerating: false,
          tripData,
          placeData: response.type === 'single_place' && response.data ? (response.data as AISinglePlaceResponse) : null,
          savedTripId,
        };

        // Update local messages - replace loading message with real one
        setLocalMessages((prev) =>
          prev.map((msg) => (msg.id === aiMessageId ? aiMessage : msg))
        );

        // Save to database
        if (!currentChatId) {
          // Start new chat
          const { historyId, error } = await startNewChat(content);
          if (historyId && !error) {
            setCurrentChatId(historyId);

            // Save AI response to database with tripData/placeData
            const currentMessages = history?.messages || [];
            await addMessageToChat(
              historyId,
              responseSummary,
              false,
              [
                ...currentMessages,
                {
                  id: userMessage.id,
                  text: content,
                  isUser: true,
                  timestamp: new Date().toISOString(),
                  tripData: null,
                  placeData: null,
                },
              ],
              {
                tripData: aiMessage.tripData,
                placeData: aiMessage.placeData,
                savedTripId,
              }
            );
            mutateHistory();
            mutateHistories();
          }
        } else {
          // Add to existing chat
          const currentMessages = history?.messages || [];
          await addMessageToChat(currentChatId, content, true, currentMessages);

          // Save AI response with tripData/placeData
          const updatedMessages = [
            ...currentMessages,
            {
              id: userMessage.id,
              text: content,
              isUser: true,
              timestamp: new Date().toISOString(),
              tripData: null,
              placeData: null,
            },
          ];
          await addMessageToChat(
            currentChatId,
            responseSummary,
            false,
            updatedMessages,
            {
              tripData: aiMessage.tripData,
              placeData: aiMessage.placeData,
              savedTripId,
            }
          );
          mutateHistory();
          mutateHistories();
        }
      } catch (error) {
        console.error("AI generation failed:", error);

        // Create error message
        const errorContent =
          error instanceof AIServiceError
            ? `Sorry, I encountered an error: ${error.message}`
            : "Sorry, something went wrong. Please try again.";

        const errorMessage: Message = {
          id: aiMessageId,
          role: "assistant",
          content: errorContent,
          createdAt: new Date(),
          isGenerating: false,
        };

        setLocalMessages((prev) =>
          prev.map((msg) => (msg.id === aiMessageId ? errorMessage : msg))
        );
      } finally {
        setIsLoading(false);
      }
    },
    [user, currentChatId, history, startNewChat, addMessageToChat, buildContext, mutateHistory, mutateHistories, startStreaming, resetStreaming]
  );

  const handleSelectChat = useCallback((chatId: string) => {
    setCurrentChatId(chatId);
    setLocalMessages([]); // Clear local messages when selecting a saved chat
    // Close all panels when switching chats - they will reopen for the new chat's trip
    setIsTripPanelOpen(false);
    setIsPlacePanelOpen(false);
    setIsStreamingPanelOpen(false);
    setSelectedTrip(null);
    setSelectedPlace(null);
    // Close sidebar on mobile
    if (typeof window !== "undefined" && window.innerWidth < 768) {
      setSidebarOpen(false);
    }
  }, []);

  const handleNewChat = useCallback(() => {
    setCurrentChatId(null);
    setLocalMessages([]);
    setInputValue("");
    setShowStreamingCard(false);
    setIntroMessage(null);
    resetStreaming();
    // Close sidebar on mobile
    if (typeof window !== "undefined" && window.innerWidth < 768) {
      setSidebarOpen(false);
    }
  }, [resetStreaming]);

  // Handle trip expand
  const handleExpandTrip = useCallback((trip: AITripResponse) => {
    setSelectedTrip(trip);
    setSelectedPlace(null);
    setIsPlacePanelOpen(false);
    setIsTripPanelOpen(true);
  }, []);

  // Handle place expand
  const handleExpandPlace = useCallback((place: AISinglePlaceResponse) => {
    setSelectedPlace(place);
    setSelectedTrip(null);
    setIsTripPanelOpen(false);
    setIsPlacePanelOpen(true);
  }, []);

  // Handle close details panel
  const handleCloseDetailsPanel = useCallback(() => {
    setIsTripPanelOpen(false);
    setIsPlacePanelOpen(false);
    setSelectedTrip(null);
    setSelectedPlace(null);
  }, []);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  // Auto-open trip details when switching to a chat that has a trip (desktop only)
  useEffect(() => {
    // Only on desktop
    if (typeof window !== "undefined" && window.innerWidth < 768) return;
    // Only when history loads and we have messages
    if (!history?.messages || history.messages.length === 0) return;
    // Don't open if already streaming
    if (isStreaming || showStreamingCard) return;
    // Don't open if panel is already open with a trip
    if (isTripPanelOpen && selectedTrip) return;

    // Find the last message with tripData
    const lastTripMessage = [...history.messages].reverse().find(msg => msg.tripData);
    if (lastTripMessage?.tripData) {
      setSelectedTrip(lastTripMessage.tripData as AITripResponse);
      setIsTripPanelOpen(true);
    }
  }, [history?.messages, currentChatId]); // Re-run when chat changes or history loads

  // Typewriter effect for intro message
  useEffect(() => {
    if (!introMessage) {
      setDisplayedIntroText("");
      setIntroTypingComplete(false);
      return;
    }

    let index = 0;
    setDisplayedIntroText("");
    setIntroTypingComplete(false);

    const interval = setInterval(() => {
      if (index < introMessage.length) {
        setDisplayedIntroText(introMessage.substring(0, index + 1));
        index++;
      } else {
        clearInterval(interval);
        setIntroTypingComplete(true);
      }
    }, 8); // Very fast typing speed

    return () => clearInterval(interval);
  }, [introMessage]);

  // Typewriter effect for completion message
  useEffect(() => {
    if (!completionMessage) {
      setDisplayedCompletionText("");
      setCompletionTypingComplete(false);
      return;
    }

    let index = 0;
    setDisplayedCompletionText("");
    setCompletionTypingComplete(false);

    const interval = setInterval(() => {
      if (index < completionMessage.length) {
        setDisplayedCompletionText(completionMessage.substring(0, index + 1));
        index++;
      } else {
        clearInterval(interval);
        setCompletionTypingComplete(true);
      }
    }, 8); // Very fast typing speed

    return () => clearInterval(interval);
  }, [completionMessage]);

  // When completion typing finishes, wait a moment then show the final message with trip card
  useEffect(() => {
    if (completionTypingComplete && pendingAiMessageRef.current) {
      const aiMessage = pendingAiMessageRef.current;

      // Wait 800ms after typing completes so user can read the message
      const timer = setTimeout(() => {
        // Update messages with the final AI message (includes tripData)
        setLocalMessages((prev) =>
          prev.map((msg) => (msg.id === aiMessage.id ? aiMessage : msg))
        );

        // Clean up
        setCompletionMessage(null);
        setDisplayedCompletionText("");
        setCompletionTypingComplete(false);
        pendingAiMessageRef.current = null;
        pendingTripRef.current = null;
        pendingUserMessageRef.current = null;
        aiMessageIdRef.current = null;
        pendingQueryRef.current = null;
      }, 800);

      return () => clearTimeout(timer);
    }
  }, [completionTypingComplete]);

  // Handle initial query from URL - only run once on mount
  useEffect(() => {
    if (initialQuery && !initialQueryProcessedRef.current) {
      initialQueryProcessedRef.current = true;
      // Use setTimeout to avoid calling during render
      setTimeout(() => {
        handleSendMessage(initialQuery);
      }, 0);
    }
  }, [initialQuery, handleSendMessage]);

  return (
    <div className="flex flex-col h-screen bg-background">
      {/* Header */}
      <ChatHeader onMenuClick={() => setSidebarOpen(true)} />

      {/* Spacer for fixed header */}
      <div className="h-14 shrink-0" />

      <div className="flex flex-1 overflow-hidden">
        {/* Sidebar */}
        <ChatSidebar
          isOpen={sidebarOpen}
          onToggle={() => setSidebarOpen((prev) => !prev)}
          onClose={() => setSidebarOpen(false)}
          currentChatId={currentChatId}
          onSelectChat={handleSelectChat}
          onNewChat={handleNewChat}
        />

        {/* Main Chat Area - shifts left when details panel opens */}
        <main
          className={cn(
            "flex flex-col transition-all duration-300 relative overflow-hidden flex-1",
            "md:ml-[68px]" // Fixed margin for collapsed sidebar width
          )}
        >
          {/* Messages Area */}
          <div className="flex-1 overflow-y-auto">
            {messages.length === 0 && !isLoading && !inputValue.trim() ? (
              <ChatEmptyState />
            ) : messages.length > 0 || isLoading ? (
              <div className={cn(
                "mx-auto px-4 transition-all duration-300",
                isDetailsPanelOpen ? "max-w-md" : "max-w-3xl"
              )}>
                {messages.map((message) => {
                  // If this is the AI placeholder message and we're streaming, show streaming card
                  // Keep showing streaming card while showStreamingCard is true (until onComplete updates the message)
                  if (message.isGenerating && showStreamingCard) {
                    return (
                      <div key={message.id} className="py-3 space-y-4">
                        {/* Intro message with typewriter effect - no background like normal AI messages */}
                        {displayedIntroText && (
                          <div className="prose prose-sm dark:prose-invert max-w-none">
                            <p className="whitespace-pre-wrap text-foreground/90 leading-relaxed">
                              {displayedIntroText}
                              {!introTypingComplete && (
                                <span className="inline-block w-0.5 h-4 bg-primary/70 ml-0.5 animate-pulse" />
                              )}
                            </p>
                          </div>
                        )}
                        {/* On mobile: show streaming card after intro. On desktop: show simple progress bar */}
                        {introTypingComplete && (
                          <>
                            {/* Mobile: full streaming card */}
                            <div className="md:hidden">
                              <StreamingTripCard
                                state={streamingState}
                                onCancel={cancelStreaming}
                              />
                            </div>
                            {/* Desktop: simple progress bar with simulated progress (details are in right panel) */}
                            <div className="hidden md:block max-w-xs">
                              <SimulatedProgressBar
                                realProgress={streamingState.progress}
                                phase={streamingState.phase}
                              />
                            </div>
                          </>
                        )}
                      </div>
                    );
                  }

                  // Show completion message with typewriter while waiting for trip card
                  if (message.isGenerating && displayedCompletionText && !completionTypingComplete) {
                    return (
                      <div key={message.id} className="py-3">
                        <div className="prose prose-sm dark:prose-invert max-w-none">
                          <p className="whitespace-pre-wrap text-foreground/90 leading-relaxed">
                            {displayedCompletionText}
                            <span className="inline-block w-0.5 h-4 bg-primary/70 ml-0.5 animate-pulse" />
                          </p>
                        </div>
                      </div>
                    );
                  }

                  // Otherwise show normal message
                  return (
                    <ChatMessage
                      key={message.id}
                      message={message}
                      onExpandTrip={handleExpandTrip}
                      onExpandPlace={handleExpandPlace}
                    />
                  );
                })}
                <div ref={messagesEndRef} className="h-32" />
              </div>
            ) : null}
          </div>

          {/* Input Area - Fixed at bottom */}
          <div className={cn(
            "sticky bottom-0 z-10 transition-all duration-300",
            isDetailsPanelOpen ? "pr-4" : ""
          )}>
            <ChatInput
              onSubmit={handleSendMessage}
              isLoading={isLoading}
              showSuggestions={messages.length === 0 && !isLoading}
              value={inputValue}
              onChange={setInputValue}
              compact={isDetailsPanelOpen}
            />
          </div>
        </main>

        {/* Details Panel - Right side (Desktop only) */}
        {!isMobile && (
          <div
            className={cn(
              "transition-all duration-300 overflow-hidden shrink-0 border-l border-white/10",
              isDetailsPanelOpen ? "w-[600px]" : "w-0 border-l-0"
            )}
          >
            {/* Streaming Trip Details Panel - shows during generation */}
            <StreamingTripDetailsPanel
              streamingState={streamingState}
              isOpen={isStreamingPanelOpen}
              onClose={() => setIsStreamingPanelOpen(false)}
            />

            {/* Trip Details Panel - shows after generation complete */}
            <TripDetailsPanel
              trip={selectedTrip}
              isOpen={isTripPanelOpen && !isStreamingPanelOpen}
              onClose={handleCloseDetailsPanel}
            />

            {/* Place Details Panel */}
            <PlaceDetailsPanel
              placeResponse={selectedPlace}
              isOpen={isPlacePanelOpen && !isStreamingPanelOpen}
              onClose={handleCloseDetailsPanel}
            />
          </div>
        )}

        {/* Mobile: Panels are rendered as Sheets (handled internally by components) */}
        {isMobile && (
          <>
            <TripDetailsPanel
              trip={selectedTrip}
              isOpen={isTripPanelOpen}
              onClose={handleCloseDetailsPanel}
            />
            <PlaceDetailsPanel
              placeResponse={selectedPlace}
              isOpen={isPlacePanelOpen}
              onClose={handleCloseDetailsPanel}
            />
          </>
        )}
      </div>

      {/* Auth Modal */}
      <AuthModal
        isOpen={isAuthModalOpen}
        onClose={() => setIsAuthModalOpen(false)}
      />
    </div>
  );
}

export default function ChatPage() {
  return (
    <Suspense
      fallback={
        <div className="flex h-screen items-center justify-center bg-background">
          <div className="animate-pulse text-muted-foreground">Loading chat...</div>
        </div>
      }
    >
      <ChatContent />
    </Suspense>
  );
}
