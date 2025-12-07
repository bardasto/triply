"use client";

import { useState, useRef, useEffect } from "react";
import { useRouter } from "next/navigation";
import {
  X,
  Send,
  Sparkles,
  Maximize2,
  Plane,
  MapPin,
  Calendar,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { GeminiIcon } from "@/components/ui/gemini-icon";
import { cn } from "@/lib/utils";

const quickSuggestions = [
  { label: "Plan a trip", icon: Plane },
  { label: "Find destinations", icon: MapPin },
  { label: "Create itinerary", icon: Calendar },
];

export function FloatingChat() {
  const [isOpen, setIsOpen] = useState(false);
  const [input, setInput] = useState("");
  const [isAnimating, setIsAnimating] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const router = useRouter();

  // Focus input when chat opens
  useEffect(() => {
    if (isOpen) {
      setTimeout(() => inputRef.current?.focus(), 100);
    }
  }, [isOpen]);

  const handleOpen = () => {
    setIsAnimating(true);
    setIsOpen(true);
  };

  const handleClose = () => {
    setIsAnimating(true);
    setIsOpen(false);
    setTimeout(() => setIsAnimating(false), 300);
  };

  const handleSubmit = (query: string) => {
    if (!query.trim()) return;
    const encodedQuery = encodeURIComponent(query.trim());
    router.push(`/chat?q=${encodedQuery}`);
  };

  const handleFormSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    handleSubmit(input);
  };

  const handleExpand = () => {
    router.push("/chat");
  };

  return (
    <>
      {/* Chat Window */}
      <div
        className={cn(
          "fixed bottom-24 right-6 z-50",
          "w-[360px] max-w-[calc(100vw-48px)]",
          "transition-all duration-300 ease-out",
          isOpen
            ? "opacity-100 translate-y-0 scale-100"
            : "opacity-0 translate-y-4 scale-95 pointer-events-none"
        )}
      >
        <div
          className={cn(
            "rounded-2xl overflow-hidden",
            "bg-background border border-border",
            "shadow-2xl shadow-black/20"
          )}
        >
          {/* Header */}
          <div className="flex items-center justify-between px-4 py-3 bg-gradient-to-r from-primary to-accent">
            <div className="flex items-center gap-2">
              <div className="h-8 w-8 rounded-full bg-white/20 flex items-center justify-center">
                <Sparkles className="h-4 w-4 text-white" />
              </div>
              <div>
                <h3 className="text-sm font-semibold text-white">Toogo AI</h3>
                <p className="text-xs text-white/70">Your travel assistant</p>
              </div>
            </div>
            <div className="flex items-center gap-1">
              <Button
                variant="ghost"
                size="icon"
                onClick={handleExpand}
                className="h-8 w-8 text-white/80 hover:text-white hover:bg-white/10"
              >
                <Maximize2 className="h-4 w-4" />
              </Button>
              <Button
                variant="ghost"
                size="icon"
                onClick={handleClose}
                className="h-8 w-8 text-white/80 hover:text-white hover:bg-white/10"
              >
                <X className="h-4 w-4" />
              </Button>
            </div>
          </div>

          {/* Content */}
          <div className="p-4">
            {/* Welcome Message */}
            <div className="mb-4">
              <div className="flex gap-3">
                <div className="shrink-0 h-8 w-8 rounded-full bg-gradient-to-br from-primary to-accent flex items-center justify-center">
                  <Sparkles className="h-4 w-4 text-white" />
                </div>
                <div className="flex-1">
                  <p className="text-sm text-foreground leading-relaxed">
                    Hi! I'm your AI travel assistant. Tell me about your dream
                    trip and I'll help you plan it.
                  </p>
                </div>
              </div>
            </div>

            {/* Quick Suggestions */}
            <div className="mb-4 space-y-2">
              <p className="text-xs text-muted-foreground">Quick actions:</p>
              <div className="flex flex-wrap gap-2">
                {quickSuggestions.map((suggestion) => {
                  const Icon = suggestion.icon;
                  return (
                    <button
                      key={suggestion.label}
                      onClick={() => handleSubmit(suggestion.label)}
                      className={cn(
                        "inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full",
                        "text-xs text-muted-foreground",
                        "bg-muted/50 border border-border",
                        "hover:bg-primary/10 hover:text-primary hover:border-primary/30",
                        "transition-all duration-200"
                      )}
                    >
                      <Icon className="h-3 w-3" />
                      {suggestion.label}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Input */}
            <form onSubmit={handleFormSubmit}>
              <div
                className={cn(
                  "flex items-center gap-2 px-3 py-2 rounded-xl",
                  "bg-muted/50 border border-border",
                  "focus-within:border-primary/50 focus-within:ring-2 focus-within:ring-primary/20",
                  "transition-all duration-200"
                )}
              >
                <input
                  ref={inputRef}
                  type="text"
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  placeholder="Ask about your next trip..."
                  className="flex-1 bg-transparent text-sm text-foreground placeholder:text-muted-foreground focus:outline-none"
                />
                <Button
                  type="submit"
                  size="icon"
                  disabled={!input.trim()}
                  className="h-8 w-8 rounded-lg shrink-0"
                >
                  <Send className="h-4 w-4" />
                </Button>
              </div>
            </form>
          </div>
        </div>
      </div>

      {/* Floating Button */}
      <button
        onClick={isOpen ? handleClose : handleOpen}
        className={cn(
          "fixed bottom-6 right-6 z-50",
          "h-14 w-14 rounded-full",
          "bg-gradient-to-br from-primary to-accent",
          "shadow-lg shadow-primary/30",
          "flex items-center justify-center",
          "transition-all duration-300",
          "hover:scale-110 hover:shadow-xl hover:shadow-primary/40",
          "active:scale-95"
        )}
      >
        <div
          className={cn(
            "transition-transform duration-300",
            isOpen ? "rotate-0" : "rotate-0"
          )}
        >
          {isOpen ? (
            <X className="h-6 w-6 text-white" />
          ) : (
            <GeminiIcon className="h-7 w-7 text-white" />
          )}
        </div>

        {/* Pulse animation when closed */}
        {!isOpen && (
          <span className="absolute inset-0 rounded-full bg-primary animate-ping opacity-20" />
        )}
      </button>
    </>
  );
}
