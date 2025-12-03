"use client";

import { useState } from "react";
import Link from "next/link";
import {
  PanelLeftClose,
  PanelLeft,
  Plus,
  MessageSquare,
  MoreHorizontal,
  Home,
  Compass,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

interface ChatHistory {
  id: string;
  title: string;
  createdAt: Date;
}

// Mock chat history
const mockChatHistory: ChatHistory[] = [
  { id: "1", title: "Weekend trip to Paris", createdAt: new Date() },
  { id: "2", title: "Bali beach vacation", createdAt: new Date(Date.now() - 86400000) },
  { id: "3", title: "Italy road trip planning", createdAt: new Date(Date.now() - 172800000) },
  { id: "4", title: "Tokyo food tour", createdAt: new Date(Date.now() - 259200000) },
];

interface ChatSidebarProps {
  isOpen: boolean;
  onToggle: () => void;
  currentChatId?: string;
}

export function ChatSidebar({ isOpen, onToggle, currentChatId }: ChatSidebarProps) {
  const [hoveredChat, setHoveredChat] = useState<string | null>(null);

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
          <Link href="/chat">
            <Button
              variant="outline"
              size="icon"
              className="h-10 w-10 border-dashed"
            >
              <Plus className="h-4 w-4" />
            </Button>
          </Link>
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
          <Link href="/chat" className="block">
            <Button
              variant="outline"
              className="w-full justify-start gap-2 border-dashed"
            >
              <Plus className="h-4 w-4" />
              <span>New Chat</span>
            </Button>
          </Link>
        </div>

        {/* Chat History */}
        <div className="flex-1 overflow-y-auto px-3 py-2">
          <div className="text-xs font-medium text-muted-foreground mb-2 px-2">
            Recent Chats
          </div>
          <div className="space-y-1">
            {mockChatHistory.map((chat) => (
              <div
                key={chat.id}
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
                <span className="truncate flex-1">{chat.title}</span>
                {hoveredChat === chat.id && (
                  <button className="shrink-0 p-1 rounded hover:bg-background">
                    <MoreHorizontal className="h-3.5 w-3.5" />
                  </button>
                )}
              </div>
            ))}
          </div>
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
