"use client";

import { useState, useRef, useEffect } from "react";
import { Send, Loader2, Mic, Plane, Palmtree, Calendar } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

const suggestions = [
  {
    label: "Plan a trip to Japan",
    icon: Plane,
  },
  {
    label: "Best beaches in Europe",
    icon: Palmtree,
  },
  {
    label: "Paris itinerary",
    icon: Calendar,
  },
];

interface ChatInputProps {
  onSubmit: (message: string) => void;
  isLoading?: boolean;
  placeholder?: string;
  initialValue?: string;
  showSuggestions?: boolean;
  value?: string;
  onChange?: (value: string) => void;
  compact?: boolean;
}

export function ChatInput({
  onSubmit,
  isLoading = false,
  placeholder = "Message Toogo AI...",
  initialValue = "",
  showSuggestions = false,
  value,
  onChange,
  compact = false,
}: ChatInputProps) {
  const [internalInput, setInternalInput] = useState(initialValue);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  // Use controlled or uncontrolled input
  const input = value !== undefined ? value : internalInput;
  const setInput = (newValue: string) => {
    if (onChange) {
      onChange(newValue);
    } else {
      setInternalInput(newValue);
    }
  };

  // Auto-focus and set initial value
  useEffect(() => {
    if (initialValue && !value) {
      setInternalInput(initialValue);
    }
    textareaRef.current?.focus();
  }, [initialValue, value]);

  // Auto-resize textarea
  useEffect(() => {
    const textarea = textareaRef.current;
    if (textarea) {
      textarea.style.height = "auto";
      textarea.style.height = `${Math.min(textarea.scrollHeight, 200)}px`;
    }
  }, [input]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || isLoading) return;

    onSubmit(input.trim());
    setInput("");

    // Reset textarea height
    if (textareaRef.current) {
      textareaRef.current.style.height = "auto";
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSubmit(e);
    }
  };

  const handleSuggestionClick = (suggestion: string) => {
    onSubmit(suggestion);
  };

  // Show suggestions only if enabled and input is empty
  const shouldShowSuggestions = showSuggestions && !input.trim();

  return (
    <div className="bg-linear-to-t from-background via-background to-transparent pt-6">
      {/* Suggestions - above input, hidden when typing */}
      {shouldShowSuggestions && !compact && (
        <div className="mx-auto max-w-3xl px-4 pb-4">
          <div className="flex flex-wrap gap-2 justify-center">
            {suggestions.map((suggestion) => {
              const Icon = suggestion.icon;
              return (
                <button
                  key={suggestion.label}
                  onClick={() => handleSuggestionClick(suggestion.label)}
                  className={cn(
                    "inline-flex items-center gap-2 px-4 py-2 rounded-full",
                    "text-sm text-muted-foreground",
                    "bg-muted/50 border border-border",
                    "hover:bg-primary/10 hover:text-primary hover:border-primary/30",
                    "transition-all duration-200"
                  )}
                >
                  <Icon className="h-4 w-4" />
                  {suggestion.label}
                </button>
              );
            })}
          </div>
        </div>
      )}

      <form
        onSubmit={handleSubmit}
        className={cn(
          "mx-auto px-4 pb-4 transition-all duration-300",
          compact ? "max-w-md" : "max-w-3xl"
        )}
      >
        <div
          className={cn(
            "relative flex items-end gap-3 rounded-2xl px-4",
            "bg-muted/50 border border-border",
            "focus-within:border-primary/50 focus-within:ring-2 focus-within:ring-primary/20",
            "transition-all duration-200"
          )}
        >
          <textarea
            ref={textareaRef}
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder={placeholder}
            rows={1}
            disabled={isLoading}
            className={cn(
              "flex-1 resize-none bg-transparent py-3",
              "text-foreground placeholder:text-muted-foreground",
              "focus:outline-none",
              "min-h-12 max-h-[200px]",
              "disabled:opacity-50"
            )}
          />

          <div className="flex items-center gap-2 self-center">
            {/* Microphone button */}
            <Button
              type="button"
              size="icon"
              variant="ghost"
              className="h-10 w-10 rounded-xl shrink-0 text-muted-foreground hover:text-foreground"
            >
              <Mic className="h-5 w-5" />
            </Button>

            {/* Send button */}
            <Button
              type="submit"
              size="icon"
              disabled={!input.trim() || isLoading}
              className={cn(
                "h-10 w-10 rounded-xl shrink-0",
                "transition-all duration-200",
                input.trim() && !isLoading
                  ? "bg-primary hover:bg-primary/90"
                  : "bg-muted text-muted-foreground"
              )}
            >
              {isLoading ? (
                <Loader2 className="h-5 w-5 animate-spin" />
              ) : (
                <Send className="h-5 w-5" />
              )}
            </Button>
          </div>
        </div>

        <p className="text-center text-xs text-muted-foreground mt-2">
          Toogo AI can make mistakes. Consider checking important information.
        </p>
      </form>
    </div>
  );
}
