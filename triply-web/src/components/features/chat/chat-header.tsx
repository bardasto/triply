"use client";

import { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { Menu, LogOut } from "lucide-react";
import { LottieIcon, type HeaderIconName } from "@/components/ui/lottie-icon";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { AuthModal } from "@/components/features/auth/auth-modal";
import { useAuth } from "@/contexts/auth-context";
import { cn } from "@/lib/utils";

const navItems = [
  { name: "Home", href: "/", lottieIcon: "home" as HeaderIconName },
  { name: "Explore", href: "/explore", lottieIcon: "explore" as HeaderIconName },
  { name: "AI Chat", href: "/chat", lottieIcon: "aiChat" as HeaderIconName },
  { name: "My Trips", href: "/trips", lottieIcon: "myTrips" as HeaderIconName },
];

// NavLink component with hover state for icon animation
function NavLink({
  item,
  isActive,
  isMobile = false
}: {
  item: { name: string; href: string; lottieIcon: HeaderIconName };
  isActive: boolean;
  isMobile?: boolean;
}) {
  const [isHovered, setIsHovered] = useState(false);

  if (isMobile) {
    return (
      <Link
        href={item.href}
        className={cn(
          "flex flex-col items-center gap-0.5 transition-colors",
          isActive ? "text-primary" : "text-muted-foreground"
        )}
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
      >
        <LottieIcon variant="header" name={item.lottieIcon} size={24} isActive={isActive} isHovered={isHovered} playOnHover />
        <span className="text-[10px] font-medium">{item.name === "AI Chat" ? "AI" : item.name}</span>
      </Link>
    );
  }

  return (
    <Link
      href={item.href}
      className={cn(
        "flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium transition-colors",
        isActive ? "text-primary" : "text-muted-foreground hover:text-foreground"
      )}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      <LottieIcon variant="header" name={item.lottieIcon} size={20} isActive={isActive} isHovered={isHovered} playOnHover />
      {item.name}
    </Link>
  );
}

interface ChatHeaderProps {
  onMenuClick?: () => void;
}

export function ChatHeader({ onMenuClick }: ChatHeaderProps) {
  const pathname = usePathname();
  const { user, isLoading: authLoading, signOut } = useAuth();
  const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);

  return (
    <>
      <header className="fixed top-0 left-0 right-0 z-50 h-14 md:h-16 bg-background/95 backdrop-blur-xl border-b border-border/50">
        <div className="flex h-full items-center justify-between px-4">
          {/* Left side - Menu button (mobile) + Logo (desktop) */}
          <div className="flex items-center gap-3">
            {/* Mobile menu button */}
            <Button
              variant="ghost"
              size="icon"
              className="md:hidden h-9 w-9"
              onClick={onMenuClick}
            >
              <Menu className="h-5 w-5" />
            </Button>

            {/* Logo - desktop only */}
            <Link
              href="/"
              className="hidden md:flex items-center gap-2 transition-opacity hover:opacity-80"
            >
              <div className="relative h-8 w-8 rounded-lg bg-gradient-to-br from-primary to-accent flex items-center justify-center">
                <span className="text-white font-bold text-lg">T</span>
              </div>
              <span className="text-xl font-bold text-foreground">
                Toogo
              </span>
            </Link>
          </div>

          {/* Mobile Navigation - same style as main header */}
          <div className="flex-1 flex md:hidden items-center justify-around mx-2">
            {navItems.map((item) => {
              const isActive = pathname === item.href;
              return (
                <NavLink key={item.name} item={item} isActive={isActive} isMobile />
              );
            })}
          </div>

          {/* Desktop Navigation */}
          <nav className="hidden md:flex items-center gap-1">
            {navItems.map((item) => {
              const isActive = pathname === item.href;
              return (
                <NavLink key={item.name} item={item} isActive={isActive} />
              );
            })}
          </nav>

          {/* Right side - Account */}
          <div className="flex items-center gap-2">
            {authLoading ? (
              <div className="h-9 w-9 rounded-full bg-muted animate-pulse" />
            ) : user ? (
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" size="icon" className="rounded-full h-9 w-9 overflow-hidden">
                    {user.user_metadata?.avatar_url ? (
                      <Image
                        src={user.user_metadata.avatar_url}
                        alt={user.user_metadata?.full_name || "User"}
                        width={36}
                        height={36}
                        className="rounded-full object-cover"
                      />
                    ) : (
                      <div className="h-9 w-9 rounded-full bg-primary/10 flex items-center justify-center">
                        <span className="text-sm font-medium text-primary">
                          {(user.user_metadata?.full_name || user.email || "U")[0].toUpperCase()}
                        </span>
                      </div>
                    )}
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="w-56">
                  <div className="px-3 py-2">
                    <p className="text-sm font-medium truncate">
                      {user.user_metadata?.full_name || "User"}
                    </p>
                    <p className="text-xs text-muted-foreground truncate">
                      {user.email}
                    </p>
                  </div>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem asChild>
                    <Link href="/trips" className="cursor-pointer flex items-center">
                      <LottieIcon variant="header" name="myTrips" size={16} className="mr-2" playOnHover />
                      My Trips
                    </Link>
                  </DropdownMenuItem>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem
                    onClick={() => signOut()}
                    className="cursor-pointer text-destructive focus:text-destructive"
                  >
                    <LogOut className="mr-2 h-4 w-4" />
                    Sign Out
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            ) : (
              <>
                <Button
                  variant="ghost"
                  size="sm"
                  className="hidden md:flex text-muted-foreground hover:text-foreground"
                  onClick={() => setIsAuthModalOpen(true)}
                >
                  Sign In
                </Button>
                <Button
                  size="icon"
                  variant="ghost"
                  className="rounded-full h-9 w-9"
                  onClick={() => setIsAuthModalOpen(true)}
                >
                  <LottieIcon variant="header" name="profile" size={20} playOnHover />
                </Button>
              </>
            )}
          </div>
        </div>
      </header>

      {/* Auth Modal */}
      <AuthModal
        isOpen={isAuthModalOpen}
        onClose={() => setIsAuthModalOpen(false)}
      />
    </>
  );
}
