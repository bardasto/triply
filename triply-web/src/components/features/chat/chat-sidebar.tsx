"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import {
  PanelLeftClose,
  PanelLeft,
  Plus,
  MessageSquare,
  MoreHorizontal,
  Home,
  Compass,
  Trash2,
  Loader2,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { cn } from "@/lib/utils";
import { useAuth } from "@/contexts/auth-context";
import { useChatHistories, useChatHistoryActions, useChatHistoryRealtime } from "@/hooks/useChatHistory";
import type { ChatHistoryCard } from "@/types/chat-history";

interface ChatSidebarProps {
  isOpen: boolean;
  onToggle: () => void;
  currentChatId?: string | null;
  onSelectChat?: (chatId: string) => void;
  onNewChat?: () => void;
}

export function ChatSidebar({
  isOpen,
  onToggle,
  currentChatId,
  onSelectChat,
  onNewChat,
}: ChatSidebarProps) {
  const { user } = useAuth();
  const { historyCards, isLoading, mutate } = useChatHistories();
  const { deleteHistory } = useChatHistoryActions();
  const { subscribe } = useChatHistoryRealtime();
  const [hoveredChat, setHoveredChat] = useState<string | null>(null);

  // Subscribe to real-time updates
  useEffect(() => {
    const unsubscribe = subscribe();
    return unsubscribe;
  }, [subscribe]);

  const handleSelectChat = (chat: ChatHistoryCard) => {
    if (onSelectChat) {
      onSelectChat(chat.id);
    }
  };

  const handleNewChat = () => {
    if (onNewChat) {
      onNewChat();
    }
  };

  const handleDeleteChat = async (chatId: string, e: React.MouseEvent) => {
    e.stopPropagation();

    if (!window.confirm("Are you sure you want to delete this chat?")) {
      return;
    }

    // Optimistic update
    mutate(
      (current) => current?.filter((h) => h.id !== chatId),
      false
    );

    const { success } = await deleteHistory(chatId);
    if (!success) {
      // Revert on error
      mutate();
    } else if (currentChatId === chatId && onNewChat) {
      // If deleting current chat, start a new one
      onNewChat();
    }
  };

  // Format date for display
  const formatDate = (date: Date) => {
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));

    if (days === 0) return "Today";
    if (days === 1) return "Yesterday";
    if (days < 7) return `${days} days ago`;
    return date.toLocaleDateString();
  };

  // Collapsed sidebar (icons only)
  if (!isOpen) {
    return (
      <aside className="fixed top-14 bottom-0 left-0 z-40 hidden md:flex flex-col w-16 bg-muted/30 border-r border-border">
        {/* Toggle button */}
        <div className="flex items-center justify-center py-3">
          <Button
            variant="ghost"
            size="icon"
            onClick={onToggle}
            className="h-8 w-8"
          >
            <PanelLeft className="h-4 w-4" />
          </Button>
        </div>

        {/* New Chat Button */}
        <div className="flex justify-center p-3">
          <Button
            variant="outline"
            size="icon"
            className="h-10 w-10 border-dashed"
            onClick={handleNewChat}
          >
            <Plus className="h-4 w-4" />
          </Button>
        </div>

        {/* Spacer */}
        <div className="flex-1" />

        {/* Bottom Navigation */}
        <div className="flex flex-col items-center gap-1 p-3 border-t border-border">
          <Link href="/">
            <Button
              variant="ghost"
              size="icon"
              className="h-10 w-10 text-muted-foreground hover:text-foreground"
            >
              <Home className="h-4 w-4" />
            </Button>
          </Link>
          <Link href="/explore">
            <Button
              variant="ghost"
              size="icon"
              className="h-10 w-10 text-muted-foreground hover:text-foreground"
            >
              <Compass className="h-4 w-4" />
            </Button>
          </Link>
        </div>
      </aside>
    );
  }

  // Expanded sidebar (full width)
  return (
    <>
      <aside className="fixed top-14 bottom-0 left-0 z-40 flex flex-col w-64 bg-background md:bg-muted/30 border-r border-border">
        {/* Toggle button */}
        <div className="flex items-center justify-end px-3 py-2">
          <Button
            variant="ghost"
            size="icon"
            onClick={onToggle}
            className="h-8 w-8"
          >
            <PanelLeftClose className="h-4 w-4" />
          </Button>
        </div>

        {/* New Chat Button */}
        <div className="px-3 pb-3">
          <Button
            variant="outline"
            className="w-full justify-start gap-2 border-dashed"
            onClick={handleNewChat}
          >
            <Plus className="h-4 w-4" />
            <span>New Chat</span>
          </Button>
        </div>

        {/* Chat History */}
        <div className="flex-1 overflow-y-auto px-3 py-2">
          <div className="text-xs font-medium text-muted-foreground mb-2 px-2">
            Recent Chats
          </div>

          {!user ? (
            <div className="text-sm text-muted-foreground text-center py-4 px-2">
              Sign in to see your chat history
            </div>
          ) : isLoading ? (
            <div className="flex items-center justify-center py-4">
              <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
            </div>
          ) : historyCards.length === 0 ? (
            <div className="text-sm text-muted-foreground text-center py-4 px-2">
              No chats yet. Start a new conversation!
            </div>
          ) : (
            <div className="space-y-1">
              {historyCards.map((chat) => (
                <div
                  key={chat.id}
                  onClick={() => handleSelectChat(chat)}
                  onMouseEnter={() => setHoveredChat(chat.id)}
                  onMouseLeave={() => setHoveredChat(null)}
                  className={cn(
                    "group relative flex items-center gap-2 px-2 py-2 rounded-lg",
                    "text-sm text-muted-foreground",
                    "hover:bg-muted hover:text-foreground",
                    "transition-colors cursor-pointer",
                    currentChatId === chat.id && "bg-muted text-foreground"
                  )}
                >
                  <MessageSquare className="h-4 w-4 shrink-0" />
                  <div className="flex-1 min-w-0">
                    <span className="block truncate">{chat.title}</span>
                    <span className="block text-xs text-muted-foreground/60">
                      {formatDate(chat.updatedAt)}
                    </span>
                  </div>
                  {hoveredChat === chat.id && (
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <button
                          className="shrink-0 p-1 rounded hover:bg-background"
                          onClick={(e) => e.stopPropagation()}
                        >
                          <MoreHorizontal className="h-3.5 w-3.5" />
                        </button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem
                          onClick={(e) => handleDeleteChat(chat.id, e as unknown as React.MouseEvent)}
                          className="text-destructive focus:text-destructive"
                        >
                          <Trash2 className="h-4 w-4 mr-2" />
                          Delete
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Bottom Navigation */}
        <div className="border-t border-border p-3 space-y-1">
          <Link href="/" className="block">
            <Button
              variant="ghost"
              className="w-full justify-start gap-2 text-muted-foreground hover:text-foreground"
            >
              <Home className="h-4 w-4" />
              <span>Home</span>
            </Button>
          </Link>
          <Link href="/explore" className="block">
            <Button
              variant="ghost"
              className="w-full justify-start gap-2 text-muted-foreground hover:text-foreground"
            >
              <Compass className="h-4 w-4" />
              <span>Explore</span>
            </Button>
          </Link>
        </div>
      </aside>

      {/* Mobile Overlay */}
      <div
        className="fixed top-14 inset-x-0 bottom-0 z-30 bg-black/50 md:hidden"
        onClick={onToggle}
      />
    </>
  );
}
