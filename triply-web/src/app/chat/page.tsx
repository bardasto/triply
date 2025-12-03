"use client";

import { useState, useEffect, useRef, Suspense } from "react";
import { useSearchParams } from "next/navigation";
import { ChatSidebar } from "@/components/features/chat/chat-sidebar";
import { ChatHeader } from "@/components/features/chat/chat-header";
import { ChatMessage, ChatMessageSkeleton, type Message } from "@/components/features/chat/chat-message";
import { ChatInput } from "@/components/features/chat/chat-input";
import { ChatEmptyState } from "@/components/features/chat/chat-empty-state";
import { cn } from "@/lib/utils";

function ChatContent() {
  const searchParams = useSearchParams();
  const initialQuery = searchParams.get("q") || "";

  const [messages, setMessages] = useState<Message[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(() => {
    // Start with sidebar closed on mobile
    if (typeof window !== 'undefined') {
      return window.innerWidth >= 768;
    }
    return true;
  });
  const [hasProcessedInitialQuery, setHasProcessedInitialQuery] = useState(false);
  const [inputValue, setInputValue] = useState("");
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  const handleSendMessage = (content: string) => {
    const userMessage: Message = {
      id: Date.now().toString(),
      role: "user",
      content,
      createdAt: new Date(),
    };

    setMessages((prev) => [...prev, userMessage]);
    setIsLoading(true);
    setInputValue("");

    // Simulate AI response (replace with actual API call)
    setTimeout(() => {
      const aiResponses: Record<string, string> = {
        default: `I'd be happy to help you with "${content}"!\n\nHere's what I can do for you:\n\n**Trip Planning**\nI can create detailed day-by-day itineraries tailored to your interests, budget, and travel style.\n\n**Destination Insights**\nGet insider tips on the best times to visit, local customs, and hidden gems that most tourists miss.\n\n**Practical Information**\nI'll provide useful info about transportation, accommodation options, and estimated costs.\n\nWhat would you like me to focus on first?`,
        paris: `**Weekend in Paris - Your Perfect Itinerary**\n\n**Day 1: Classic Paris**\n- Morning: Eiffel Tower (book tickets in advance!)\n- Lunch: Café near Champ de Mars\n- Afternoon: Seine River cruise\n- Evening: Dinner in Le Marais\n\n**Day 2: Art & Culture**\n- Morning: Louvre Museum (go early!)\n- Lunch: Angelina for hot chocolate\n- Afternoon: Montmartre & Sacré-Cœur\n- Evening: Sunset at Arc de Triomphe\n\n**Pro Tips:**\n- Get a Paris Museum Pass\n- Metro is the best way to get around\n- Book restaurants in advance\n\nWould you like me to elaborate on any part of this itinerary?`,
        bali: `**Best Beaches in Bali - Complete Guide**\n\n**For Relaxation:**\n- Nusa Dua - Crystal clear waters, luxury resorts\n- Sanur - Calm waters, great for swimming\n- Jimbaran - Famous sunset views\n\n**For Surfing:**\n- Kuta - Great for beginners\n- Uluwatu - World-class waves for experts\n- Canggu - Trendy beach with good surf\n\n**Hidden Gems:**\n- Bias Tugel Beach - Secluded paradise\n- Green Bowl Beach - Pristine and quiet\n- Padang Padang - Beautiful cove\n\n**Best Time to Visit:** April-October (dry season)\n\nWould you like specific hotel recommendations or a day-by-day beach-hopping itinerary?`,
      };

      let responseContent = aiResponses.default;
      const lowerContent = content.toLowerCase();

      if (lowerContent.includes("paris")) {
        responseContent = aiResponses.paris;
      } else if (lowerContent.includes("bali") || lowerContent.includes("beach")) {
        responseContent = aiResponses.bali;
      }

      const aiMessage: Message = {
        id: (Date.now() + 1).toString(),
        role: "assistant",
        content: responseContent,
        createdAt: new Date(),
      };

      setMessages((prev) => [...prev, aiMessage]);
      setIsLoading(false);
    }, 1500);
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  // Handle initial query from URL
  useEffect(() => {
    if (initialQuery && !hasProcessedInitialQuery) {
      setHasProcessedInitialQuery(true);
      handleSendMessage(initialQuery);
    }
  }, [initialQuery, hasProcessedInitialQuery]);

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
          onToggle={() => setSidebarOpen(!sidebarOpen)}
        />

        {/* Main Chat Area */}
        <main
          className={cn(
            "flex-1 flex flex-col transition-all duration-300 relative overflow-hidden",
            sidebarOpen ? "md:ml-64" : "md:ml-16"
          )}
        >
          {/* Messages Area */}
          <div className="flex-1 overflow-y-auto">
            {messages.length === 0 && !isLoading && !inputValue.trim() ? (
              <ChatEmptyState />
            ) : messages.length > 0 || isLoading ? (
              <div className="max-w-3xl mx-auto px-4">
                {messages.map((message) => (
                  <ChatMessage key={message.id} message={message} />
                ))}
                {isLoading && <ChatMessageSkeleton />}
                <div ref={messagesEndRef} className="h-32" />
              </div>
            ) : null}
          </div>

          {/* Input Area - Fixed at bottom */}
          <div className="sticky bottom-0 z-10">
            <ChatInput
              onSubmit={handleSendMessage}
              isLoading={isLoading}
              showSuggestions={messages.length === 0 && !isLoading}
              value={inputValue}
              onChange={setInputValue}
            />
          </div>
        </main>
      </div>
    </div>
  );
}

export default function ChatPage() {
  return (
    <Suspense fallback={
      <div className="flex h-screen items-center justify-center bg-background">
        <div className="animate-pulse text-muted-foreground">Loading chat...</div>
      </div>
    }>
      <ChatContent />
    </Suspense>
  );
}
