"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { motion, AnimatePresence } from "framer-motion";
import {
  Plus,
  MessageSquare,
  MoreHorizontal,
  Home,
  Compass,
  Trash2,
  Loader2,
  X,
} from "lucide-react";
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

// iOS-style spring animation
const springTransition = {
  type: "spring" as const,
  stiffness: 400,
  damping: 30,
};

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
  const [desktopOpen, setDesktopOpen] = useState(false);

  // For mobile, use isOpen prop (controlled by header menu button)
  // For desktop, use internal desktopOpen state (hover-based)

  useEffect(() => {
    const unsubscribe = subscribe();
    return unsubscribe;
  }, [subscribe]);

  const handleSelectChat = (chat: ChatHistoryCard) => {
    onSelectChat?.(chat.id);
    onToggle(); // Close mobile sidebar
  };

  const handleNewChat = () => {
    onNewChat?.();
    onToggle(); // Close mobile sidebar
  };

  const handleDeleteChat = async (chatId: string, e: React.MouseEvent) => {
    e.stopPropagation();
    if (!window.confirm("Are you sure you want to delete this chat?")) return;

    mutate((current) => current?.filter((h) => h.id !== chatId), false);

    const { success } = await deleteHistory(chatId);
    if (!success) {
      mutate();
    } else if (currentChatId === chatId) {
      onNewChat?.();
    }
  };

  const formatDate = (date: Date) => {
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));

    if (days === 0) return "Today";
    if (days === 1) return "Yesterday";
    if (days < 7) return `${days} days ago`;
    return date.toLocaleDateString();
  };

  // Sidebar item component with optimized animations
  const SidebarItem = ({
    icon,
    label,
    sublabel,
    onClick,
    active,
    showMenu,
    onMouseEnter,
    onMouseLeave,
    menuContent,
  }: {
    icon: React.ReactNode;
    label: string;
    sublabel?: string;
    onClick?: () => void;
    active?: boolean;
    showMenu?: boolean;
    onMouseEnter?: () => void;
    onMouseLeave?: () => void;
    menuContent?: React.ReactNode;
  }) => (
    <div
      onClick={onClick}
      onMouseEnter={onMouseEnter}
      onMouseLeave={onMouseLeave}
      className={cn(
        "flex items-center gap-3 px-3 py-2.5 rounded-xl cursor-pointer",
        "transition-colors duration-200",
        "hover:bg-white/10",
        active && "bg-white/10"
      )}
    >
      <div className="shrink-0 w-5 h-5 flex items-center justify-center">
        {icon}
      </div>
      <div
        className={cn(
          "flex-1 min-w-0 overflow-hidden",
          "transition-all duration-300 ease-out",
          desktopOpen ? "opacity-100 translate-x-0" : "opacity-0 -translate-x-2 w-0"
        )}
        style={{ willChange: "opacity, transform" }}
      >
        <span className="block truncate text-sm">{label}</span>
        {sublabel && (
          <span className="block text-xs text-muted-foreground/60 truncate">
            {sublabel}
          </span>
        )}
      </div>
      {desktopOpen && showMenu && menuContent}
    </div>
  );

  return (
    <>
      {/* Desktop Sidebar */}
      <aside
        className={cn(
          "fixed top-14 bottom-0 left-0 z-40",
          "hidden md:flex flex-col",
          "bg-muted/30 backdrop-blur-xl border-r border-white/5",
          "transition-[width] duration-300 ease-out",
          "will-change-[width]",
          desktopOpen ? "w-64" : "w-[68px]"
        )}
        onMouseEnter={() => setDesktopOpen(true)}
        onMouseLeave={() => setDesktopOpen(false)}
      >
        <div className="flex flex-col h-full px-3 py-3">
          {/* New Chat Button */}
          <div className="mb-4">
            <button
              onClick={handleNewChat}
              className={cn(
                "flex items-center gap-3 w-full px-3 py-2.5 rounded-xl",
                "border border-dashed border-white/20",
                "hover:border-primary/50 hover:bg-primary/5",
                "transition-colors duration-200"
              )}
            >
              <Plus className="h-5 w-5 shrink-0" />
              <span
                className={cn(
                  "text-sm transition-all duration-300 ease-out whitespace-nowrap",
                  desktopOpen ? "opacity-100 translate-x-0" : "opacity-0 -translate-x-2 w-0 overflow-hidden"
                )}
                style={{ willChange: "opacity, transform" }}
              >
                New Chat
              </span>
            </button>
          </div>

          {/* Label */}
          <div
            className={cn(
              "px-3 mb-2 transition-all duration-300 ease-out",
              desktopOpen ? "opacity-100" : "opacity-0 h-0 overflow-hidden"
            )}
          >
            <span className="text-xs font-medium text-muted-foreground">
              Recent Chats
            </span>
          </div>

          {/* Chat History */}
          <div className="flex-1 overflow-y-auto overflow-x-hidden scrollbar-hide">
            {!user ? (
              <div
                className={cn(
                  "text-sm text-muted-foreground text-center py-4 px-2",
                  "transition-opacity duration-300",
                  desktopOpen ? "opacity-100" : "opacity-0"
                )}
              >
                Sign in to see history
              </div>
            ) : isLoading ? (
              <div className="flex justify-center py-4">
                <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
              </div>
            ) : historyCards.length === 0 ? (
              <div
                className={cn(
                  "text-sm text-muted-foreground text-center py-4 px-2",
                  "transition-opacity duration-300",
                  desktopOpen ? "opacity-100" : "opacity-0"
                )}
              >
                No chats yet
              </div>
            ) : (
              <div className="space-y-1">
                {historyCards.map((chat) => (
                  <SidebarItem
                    key={chat.id}
                    icon={<MessageSquare className="h-4 w-4" />}
                    label={chat.title}
                    sublabel={formatDate(chat.updatedAt)}
                    onClick={() => handleSelectChat(chat)}
                    active={currentChatId === chat.id}
                    showMenu={hoveredChat === chat.id}
                    onMouseEnter={() => setHoveredChat(chat.id)}
                    onMouseLeave={() => setHoveredChat(null)}
                    menuContent={
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <button
                            className="shrink-0 p-1 rounded-lg hover:bg-white/10"
                            onClick={(e) => e.stopPropagation()}
                          >
                            <MoreHorizontal className="h-4 w-4" />
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
                    }
                  />
                ))}
              </div>
            )}
          </div>

          {/* Bottom Navigation */}
          <div className="border-t border-white/5 pt-3 mt-3 space-y-1">
            <Link href="/">
              <SidebarItem
                icon={<Home className="h-4 w-4" />}
                label="Home"
              />
            </Link>
            <Link href="/explore">
              <SidebarItem
                icon={<Compass className="h-4 w-4" />}
                label="Explore"
              />
            </Link>
          </div>
        </div>
      </aside>

      {/* Mobile Sidebar */}
      <AnimatePresence>
        {isOpen && (
          <>
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.2 }}
              className="fixed inset-0 bg-black/60 backdrop-blur-sm z-[100] md:hidden"
              onClick={onToggle}
            />

            {/* Panel */}
            <motion.aside
              initial={{ x: "-100%" }}
              animate={{ x: 0 }}
              exit={{ x: "-100%" }}
              transition={springTransition}
              className="fixed top-0 bottom-0 left-0 z-[101] w-80 bg-background/95 backdrop-blur-xl flex flex-col md:hidden"
              style={{ willChange: "transform" }}
            >
              {/* Header */}
              <div className="flex items-center justify-between p-4 border-b border-white/5">
                <h2 className="text-lg font-semibold">Menu</h2>
                <button
                  onClick={onToggle}
                  className="p-2 rounded-xl hover:bg-white/10 transition-colors"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>

              {/* Content */}
              <div className="flex-1 flex flex-col p-3 overflow-hidden">
                {/* New Chat */}
                <button
                  onClick={handleNewChat}
                  className="flex items-center gap-3 w-full px-3 py-2.5 mb-4 rounded-xl border border-dashed border-white/20 hover:border-primary/50 hover:bg-primary/5 transition-colors"
                >
                  <Plus className="h-5 w-5" />
                  <span className="text-sm">New Chat</span>
                </button>

                {/* Label */}
                <span className="text-xs font-medium text-muted-foreground px-3 mb-2">
                  Recent Chats
                </span>

                {/* History */}
                <div className="flex-1 overflow-y-auto scrollbar-hide">
                  {!user ? (
                    <div className="text-sm text-muted-foreground text-center py-4">
                      Sign in to see history
                    </div>
                  ) : isLoading ? (
                    <div className="flex justify-center py-4">
                      <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
                    </div>
                  ) : historyCards.length === 0 ? (
                    <div className="text-sm text-muted-foreground text-center py-4">
                      No chats yet
                    </div>
                  ) : (
                    <div className="space-y-1">
                      {historyCards.map((chat) => (
                        <div
                          key={chat.id}
                          onClick={() => handleSelectChat(chat)}
                          className={cn(
                            "flex items-center gap-3 px-3 py-2.5 rounded-xl cursor-pointer",
                            "hover:bg-white/10 transition-colors",
                            currentChatId === chat.id && "bg-white/10"
                          )}
                        >
                          <MessageSquare className="h-4 w-4 shrink-0" />
                          <div className="flex-1 min-w-0">
                            <span className="block truncate text-sm">{chat.title}</span>
                            <span className="block text-xs text-muted-foreground/60">
                              {formatDate(chat.updatedAt)}
                            </span>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                {/* Bottom Nav */}
                <div className="border-t border-white/5 pt-3 mt-3 space-y-1">
                  <Link
                    href="/"
                    onClick={onToggle}
                    className="flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-white/10 transition-colors"
                  >
                    <Home className="h-4 w-4" />
                    <span className="text-sm">Home</span>
                  </Link>
                  <Link
                    href="/explore"
                    onClick={onToggle}
                    className="flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-white/10 transition-colors"
                  >
                    <Compass className="h-4 w-4" />
                    <span className="text-sm">Explore</span>
                  </Link>
                </div>
              </div>
            </motion.aside>
          </>
        )}
      </AnimatePresence>
    </>
  );
}
