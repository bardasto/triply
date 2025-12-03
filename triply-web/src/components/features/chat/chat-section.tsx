"use client";

import { useState, useRef } from "react";
import { useRouter } from "next/navigation";
import { Send, Sparkles, MapPin, Calendar, Plane, Utensils, Camera } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

const suggestionChips = [
  { label: "Weekend in Paris", icon: Plane },
  { label: "Best beaches in Bali", icon: MapPin },
  { label: "7-day Italy road trip", icon: Calendar },
  { label: "Hidden gems in Tokyo", icon: Camera },
  { label: "Romantic dinner spots", icon: Utensils },
];

export function ChatSection() {
  const [input, setInput] = useState("");
  const inputRef = useRef<HTMLInputElement>(null);
  const router = useRouter();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim()) return;

    // Redirect to chat page with the query
    const encodedQuery = encodeURIComponent(input.trim());
    router.push(`/chat?q=${encodedQuery}`);
  };

  const handleSuggestionClick = (suggestion: string) => {
    const encodedQuery = encodeURIComponent(suggestion);
    router.push(`/chat?q=${encodedQuery}`);
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter") {
      e.preventDefault();
      handleSubmit(e);
    }
  };

  return (
    <section className="py-8 sm:py-12">
      <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
        {/* Chat Container */}
        <div
          className={cn(
            "relative overflow-hidden rounded-3xl",
            "bg-gradient-to-br from-primary/15 via-primary/5 to-accent/15",
            "border border-primary/20",
            "shadow-2xl shadow-primary/10"
          )}
        >
          {/* Decorative Elements */}
          <div className="absolute top-0 right-0 w-64 h-64 bg-primary/20 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2" />
          <div className="absolute bottom-0 left-0 w-64 h-64 bg-accent/20 rounded-full blur-3xl translate-y-1/2 -translate-x-1/2" />
          <div className="absolute top-1/2 left-1/2 w-32 h-32 bg-primary/10 rounded-full blur-2xl -translate-x-1/2 -translate-y-1/2" />

          <div className="relative z-10 p-6 sm:p-8">
            {/* Header */}
            <div className="text-center mb-6">
              <h2 className="text-2xl sm:text-3xl font-bold text-foreground mb-2">
                Where do you want to go?
              </h2>
              <p className="text-muted-foreground max-w-lg mx-auto">
                Tell me about your dream trip and I'll create a personalized itinerary just for you
              </p>
            </div>

            {/* Suggestion Chips */}
            <div className="mb-4 flex flex-wrap justify-center gap-2">
              {suggestionChips.map((chip) => {
                const Icon = chip.icon;
                return (
                  <button
                    key={chip.label}
                    onClick={() => handleSuggestionClick(chip.label)}
                    className={cn(
                      "inline-flex items-center gap-2 px-4 py-2 rounded-full",
                      "bg-background/80 backdrop-blur-sm",
                      "border border-border/50",
                      "text-sm text-muted-foreground",
                      "hover:bg-primary/20 hover:text-primary hover:border-primary/40",
                      "transition-all duration-200"
                    )}
                  >
                    <Icon className="h-3.5 w-3.5" />
                    {chip.label}
                  </button>
                );
              })}
            </div>

            {/* Input Form */}
            <form onSubmit={handleSubmit} className="relative flex justify-center">
              <div
                className={cn(
                  "relative flex items-center gap-2 px-4 py-2 rounded-full w-full max-w-2xl",
                  "bg-background/90 backdrop-blur-sm",
                  "border border-border/50",
                  "focus-within:border-primary/50 focus-within:ring-2 focus-within:ring-primary/20",
                  "transition-all duration-200"
                )}
              >
                <Sparkles className="h-4 w-4 text-primary/60 shrink-0" />
                <input
                  ref={inputRef}
                  type="text"
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyDown={handleKeyDown}
                  placeholder="Ask me anything about your next trip..."
                  className={cn(
                    "flex-1 bg-transparent py-1",
                    "text-foreground placeholder:text-muted-foreground",
                    "focus:outline-none text-sm"
                  )}
                />
                <Button
                  type="submit"
                  size="icon"
                  disabled={!input.trim()}
                  className="h-8 w-8 rounded-full shrink-0"
                >
                  <Send className="h-4 w-4" />
                </Button>
              </div>
            </form>
          </div>
        </div>

        {/* Helper Text */}
        <p className="text-center text-xs text-muted-foreground mt-4">
          Powered by AI. Your conversations help us improve your travel experience.
        </p>
      </div>
    </section>
  );
}
