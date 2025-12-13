"use client";

import { Copy, Check, Zap, ChevronDown, MapPin, Clock, DollarSign, Utensils, Calendar } from "lucide-react";
import { cn } from "@/lib/utils";
import { useState, useRef, useCallback } from "react";
import { ChatTripCard } from "./cards/chat-trip-card";
import { ChatPlaceCard } from "./cards/chat-place-card";
import { Button } from "@/components/ui/button";
import type { AITripResponse, AISinglePlaceResponse } from "@/types/ai-response";

// Quick action options for trip modifications
// These map to modification agent queries
const tripQuickActions = [
  { id: "add-day", label: "Add one more day", icon: Calendar, query: "Add one more day to this trip" },
  { id: "more-food", label: "More restaurants", icon: Utensils, query: "Add more restaurants to this trip" },
  { id: "budget", label: "Make it cheaper", icon: DollarSign, query: "Make this trip cheaper with free or budget-friendly alternatives" },
  { id: "shorter", label: "Make it shorter", icon: Clock, query: "Make this trip shorter by removing one day" },
  { id: "more-places", label: "Add more places", icon: MapPin, query: "Add more places to visit in this trip" },
];

// Quick action options for place modifications
const placeQuickActions = [
  { id: "alternatives", label: "Show alternatives", icon: MapPin },
  { id: "nearby", label: "What's nearby?", icon: MapPin },
  { id: "cheaper", label: "Cheaper option", icon: DollarSign },
  { id: "hours", label: "Opening hours", icon: Clock },
];

export interface Message {
  id: string;
  role: "user" | "assistant";
  content: string;
  createdAt?: Date;
  // AI response data
  tripData?: AITripResponse | null;
  placeData?: AISinglePlaceResponse | null;
  isGenerating?: boolean;
  // Saved trip ID from database (for navigation to /trips/[id])
  savedTripId?: string | null;
}

interface ChatMessageProps {
  message: Message;
  onExpandTrip?: (trip: AITripResponse, savedTripId?: string | null) => void;
  onExpandPlace?: (place: AISinglePlaceResponse) => void;
  onQuickAction?: (query: string, tripData: AITripResponse) => void;
}

export function ChatMessage({ message, onExpandTrip, onExpandPlace, onQuickAction }: ChatMessageProps) {
  const [copied, setCopied] = useState(false);
  const [showQuickActions, setShowQuickActions] = useState(false);
  const quickActionsRef = useRef<HTMLDivElement>(null);
  const scrollPositionRef = useRef<number>(0);

  // Handle fast action toggle with auto-scroll on mobile
  const handleToggleQuickActions = useCallback(() => {
    const newState = !showQuickActions;

    // Auto-scroll on mobile
    if (window.innerWidth < 768) {
      if (newState) {
        // Save current scroll position before opening
        scrollPositionRef.current = window.scrollY;
        setShowQuickActions(newState);
        setTimeout(() => {
          if (quickActionsRef.current) {
            // Scroll to show dropdown when opening
            quickActionsRef.current.scrollIntoView({ behavior: 'smooth', block: 'end' });
          }
        }, 100);
      } else {
        // Restore scroll position when closing
        setShowQuickActions(newState);
        setTimeout(() => {
          window.scrollTo({ top: scrollPositionRef.current, behavior: 'smooth' });
        }, 100);
      }
    } else {
      setShowQuickActions(newState);
    }
  }, [showQuickActions]);

  // Guard against undefined message
  if (!message) {
    return null;
  }

  const isUser = message.role === "user";

  const handleQuickAction = (actionId: string) => {
    // Find the action and get its query
    const action = tripQuickActions.find(a => a.id === actionId);
    if (action && message.tripData && onQuickAction) {
      onQuickAction(action.query, message.tripData);
    }
    setShowQuickActions(false);
  };

  const handleCopy = async () => {
    await navigator.clipboard.writeText(message.content);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  // Check if message has AI data
  const hasTrip = message.tripData && !message.isGenerating;
  const hasPlace = message.placeData && !message.isGenerating;
  const isGenerating = message.isGenerating;

  // User message - right aligned with purple box
  if (isUser) {
    return (
      <div className="flex justify-end py-3">
        <div className="max-w-[85%] px-4 py-2.5 bg-primary/20 rounded-2xl rounded-br-md">
          <p className="text-foreground whitespace-pre-wrap leading-relaxed">
            {message.content}
          </p>
        </div>
      </div>
    );
  }

  // AI message - left aligned
  return (
    <div className="group py-3">
      {/* Text content */}
      {message.content && !isGenerating && (
        <div className="prose prose-sm dark:prose-invert max-w-none">
          <p className="whitespace-pre-wrap text-foreground/90 leading-relaxed">
            {message.content}
          </p>
        </div>
      )}

      {/* Generation loading indicator - simple text */}
      {isGenerating && (
        <div className="flex items-center gap-2 text-white/60">
          <div className="w-2 h-2 bg-primary rounded-full animate-pulse" />
          <span className="text-sm">Generating...</span>
        </div>
      )}

      {/* Trip card with Fast Action button */}
      {hasTrip && message.tripData && (
        <>
          {/* Mobile: vertical layout with full width card */}
          <div className="md:hidden mt-3 max-w-full">
            <ChatTripCard
              trip={message.tripData}
              savedTripId={message.savedTripId}
              onExpand={() => onExpandTrip?.(message.tripData!, message.savedTripId)}
            />
            {/* Fast Action Button - below card on mobile */}
            <div className="relative mt-2">
              <Button
                variant="ghost"
                size="sm"
                className={cn(
                  "w-full h-9 px-3 gap-1.5 rounded-full",
                  "bg-primary/10 hover:bg-primary/20 text-primary border border-primary/20",
                  "transition-all duration-200",
                  showQuickActions && "bg-primary/20"
                )}
                onClick={handleToggleQuickActions}
              >
                <Zap className="h-4 w-4" />
                <span className="text-sm font-medium">Fast Action</span>
                <ChevronDown className={cn(
                  "h-3.5 w-3.5 transition-transform duration-200",
                  showQuickActions && "rotate-180"
                )} />
              </Button>

              {/* Dropdown Menu */}
              {showQuickActions && (
                <div
                  ref={quickActionsRef}
                  className="absolute top-full left-0 right-0 mt-2 bg-background/95 backdrop-blur-xl border border-white/10 rounded-xl shadow-xl z-50 overflow-hidden animate-in fade-in slide-in-from-top-2 duration-200"
                >
                  {tripQuickActions.map((action, index) => {
                    const Icon = action.icon;
                    return (
                      <button
                        key={action.id}
                        className={cn(
                          "w-full flex items-center gap-2.5 px-3 py-2.5 text-sm text-white/80 hover:text-white hover:bg-white/10 transition-colors",
                          index === 0 && "rounded-t-xl",
                          index === tripQuickActions.length - 1 && "rounded-b-xl"
                        )}
                        onClick={() => handleQuickAction(action.id)}
                      >
                        <Icon className="h-4 w-4 text-primary" />
                        {action.label}
                      </button>
                    );
                  })}
                </div>
              )}
            </div>
          </div>

          {/* Desktop: horizontal layout */}
          <div className="hidden md:flex items-start gap-2 mt-3 max-w-full overflow-hidden">
            <div className="w-[280px] flex-shrink-0">
              <ChatTripCard
                trip={message.tripData}
                savedTripId={message.savedTripId}
                onExpand={() => onExpandTrip?.(message.tripData!, message.savedTripId)}
              />
            </div>

            {/* Fast Action Button */}
            <div className="relative flex-shrink-0">
              <Button
                variant="ghost"
                size="sm"
                className={cn(
                  "h-9 px-3 gap-1.5 rounded-full",
                  "bg-primary/10 hover:bg-primary/20 text-primary border border-primary/20",
                  "transition-all duration-200",
                  showQuickActions && "bg-primary/20"
                )}
                onClick={handleToggleQuickActions}
              >
                <Zap className="h-4 w-4" />
                <span className="text-sm font-medium">Fast Action</span>
                <ChevronDown className={cn(
                  "h-3.5 w-3.5 transition-transform duration-200",
                  showQuickActions && "rotate-180"
                )} />
              </Button>

              {/* Dropdown Menu */}
              {showQuickActions && (
                <div className="absolute top-full left-0 mt-2 w-48 bg-background/95 backdrop-blur-xl border border-white/10 rounded-xl shadow-xl z-50 overflow-hidden animate-in fade-in slide-in-from-top-2 duration-200">
                  {tripQuickActions.map((action, index) => {
                    const Icon = action.icon;
                    return (
                      <button
                        key={action.id}
                        className={cn(
                          "w-full flex items-center gap-2.5 px-3 py-2.5 text-sm text-white/80 hover:text-white hover:bg-white/10 transition-colors",
                          index === 0 && "rounded-t-xl",
                          index === tripQuickActions.length - 1 && "rounded-b-xl"
                        )}
                        onClick={() => handleQuickAction(action.id)}
                      >
                        <Icon className="h-4 w-4 text-primary" />
                        {action.label}
                      </button>
                    );
                  })}
                </div>
              )}
            </div>
          </div>
        </>
      )}

      {/* Place card with Fast Action button */}
      {hasPlace && message.placeData && (
        <div className="flex items-start gap-1.5 sm:gap-2 mt-3 max-w-full overflow-hidden">
          <div className="w-[220px] sm:w-[280px] flex-shrink-0">
            <ChatPlaceCard
              placeResponse={message.placeData}
              onExpand={() => onExpandPlace?.(message.placeData!)}
            />
          </div>

          {/* Fast Action Button */}
          <div className="relative flex-shrink-0">
            <Button
              variant="ghost"
              size="sm"
              className={cn(
                "h-8 sm:h-9 px-2 sm:px-3 gap-1 sm:gap-1.5 rounded-full",
                "bg-primary/10 hover:bg-primary/20 text-primary border border-primary/20",
                "transition-all duration-200",
                showQuickActions && "bg-primary/20"
              )}
              onClick={() => setShowQuickActions(!showQuickActions)}
            >
              <Zap className="h-3.5 w-3.5 sm:h-4 sm:w-4" />
              <span className="text-xs sm:text-sm font-medium hidden xs:inline">Fast Action</span>
              <span className="text-xs font-medium xs:hidden">Action</span>
              <ChevronDown className={cn(
                "h-3 w-3 sm:h-3.5 sm:w-3.5 transition-transform duration-200",
                showQuickActions && "rotate-180"
              )} />
            </Button>

            {/* Dropdown Menu */}
            {showQuickActions && (
              <div className="absolute top-full left-0 mt-2 w-48 bg-background/95 backdrop-blur-xl border border-white/10 rounded-xl shadow-xl z-50 overflow-hidden animate-in fade-in slide-in-from-top-2 duration-200">
                {placeQuickActions.map((action, index) => {
                  const Icon = action.icon;
                  return (
                    <button
                      key={action.id}
                      className={cn(
                        "w-full flex items-center gap-2.5 px-3 py-2.5 text-sm text-white/80 hover:text-white hover:bg-white/10 transition-colors",
                        index === 0 && "rounded-t-xl",
                        index === placeQuickActions.length - 1 && "rounded-b-xl"
                      )}
                      onClick={() => handleQuickAction(action.id)}
                    >
                      <Icon className="h-4 w-4 text-primary" />
                      {action.label}
                    </button>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      )}

      {/* Actions */}
      {!isGenerating && message.content && (
        <div className="flex items-center gap-2 mt-2 opacity-0 group-hover:opacity-100 transition-opacity">
          <button
            onClick={handleCopy}
            className="flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground transition-colors"
          >
            {copied ? (
              <>
                <Check className="h-3.5 w-3.5" />
                Copied
              </>
            ) : (
              <>
                <Copy className="h-3.5 w-3.5" />
                Copy
              </>
            )}
          </button>
        </div>
      )}
    </div>
  );
}

export function ChatMessageSkeleton() {
  return (
    <div className="py-3 animate-pulse">
      <div className="space-y-2">
        <div className="h-4 w-full bg-muted rounded" />
        <div className="h-4 w-4/5 bg-muted rounded" />
        <div className="h-4 w-3/5 bg-muted rounded" />
      </div>
    </div>
  );
}
