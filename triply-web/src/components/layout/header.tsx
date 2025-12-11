"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import Image from "next/image";
import { usePathname, useRouter } from "next/navigation";
import { Menu, LogOut } from "lucide-react";
import { LottieIcon, type HeaderIconName, type SearchIconName } from "@/components/ui/lottie-icon";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { DestinationPicker } from "@/components/features/home/search/destination-picker";
import { DatePicker } from "@/components/features/home/search/date-picker";
import { GuestsPicker } from "@/components/features/home/search/guests-picker";
import { AuthModal } from "@/components/features/auth/auth-modal";
import { useAuth } from "@/contexts/auth-context";
import { cn } from "@/lib/utils";

type ActivePicker = "destination" | "date" | "guests" | null;

const navItems = [
  { name: "Home", href: "/", lottieIcon: "home" as HeaderIconName },
  { name: "Explore", href: "/explore", lottieIcon: "explore" as HeaderIconName },
  { name: "AI Chat", href: "/chat", lottieIcon: "aiChat" as HeaderIconName },
  { name: "My Trips", href: "/trips", lottieIcon: "myTrips" as HeaderIconName },
];

export function Header() {
  const router = useRouter();
  const [scrollProgress, setScrollProgress] = useState(0);
  const [mobileNavProgress, setMobileNavProgress] = useState(0);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);
  const [hoveredNavItem, setHoveredNavItem] = useState<string | null>(null);
  const pathname = usePathname();
  const { user, isLoading: authLoading, signOut } = useAuth();

  // Search state
  const [activePicker, setActivePicker] = useState<ActivePicker>(null);
  const [destination, setDestination] = useState("");
  const [dateValue, setDateValue] = useState<{ startDate: Date | null; endDate: Date | null; flexible: boolean }>({
    startDate: null,
    endDate: null,
    flexible: false,
  });
  const [guests, setGuests] = useState({ adults: 0, children: 0, infants: 0 });

  // Pages with their own search bar - don't show header search on desktop
  const pagesWithOwnSearch = ['/trips', '/chat'];
  const hasOwnSearch = pagesWithOwnSearch.includes(pathname);

  const handlePickerChange = (picker: ActivePicker) => {
    setActivePicker(picker);
  };

  const handleSearch = () => {
    const params = new URLSearchParams();
    if (destination) params.set("destination", destination);
    if (dateValue.startDate) {
      params.set("startDate", dateValue.startDate.toISOString().split("T")[0]);
    }
    if (dateValue.endDate) {
      params.set("endDate", dateValue.endDate.toISOString().split("T")[0]);
    }
    if (dateValue.flexible) params.set("flexible", "true");
    const totalGuests = guests.adults + guests.children + guests.infants;
    if (totalGuests > 0) {
      params.set("adults", guests.adults.toString());
      params.set("children", guests.children.toString());
      params.set("infants", guests.infants.toString());
    }
    router.push(`/explore?${params.toString()}`);
  };

  const hasAnyPickerOpen = activePicker !== null;

  useEffect(() => {
    const handleScroll = () => {
      // For pages with their own search, use shorter thresholds
      // For home page with hero, use longer thresholds
      // When logged in on home page, use faster thresholds (no hero text)
      const isHomePage = pathname === '/';
      const isLoggedInHome = isHomePage && !!user;

      let start: number;
      let end: number;

      if (isLoggedInHome) {
        start = 0;
        end = 80;
      } else if (hasOwnSearch) {
        start = 50;
        end = 120;
      } else {
        start = 150;
        end = 350;
      }

      const current = window.scrollY;

      if (current <= start) {
        setScrollProgress(0);
      } else if (current >= end) {
        setScrollProgress(1);
      } else {
        setScrollProgress((current - start) / (end - start));
      }

      // Close any open picker when scrolling
      if (activePicker !== null) {
        setActivePicker(null);
      }

      // Mobile nav fades immediately from scroll start
      const mobileNavEnd = 30;
      if (current <= 0) {
        setMobileNavProgress(0);
      } else if (current >= mobileNavEnd) {
        setMobileNavProgress(1);
      } else {
        setMobileNavProgress(current / mobileNavEnd);
      }
    };

    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, [hasOwnSearch, activePicker, pathname, user]);

  // Interpolate values based on scroll progress
  // Nav disappears in first half of scroll, search appears in second half
  const navOpacity = 1 - Math.min(1, scrollProgress * 2);
  const navScale = 1 - (Math.min(1, scrollProgress * 2) * 0.1);
  const searchOpacity = Math.max(0, (scrollProgress - 0.5) * 2);
  const searchScale = 0.98 + (Math.max(0, (scrollProgress - 0.5) * 2) * 0.02);
  const searchWidth = 60 + (scrollProgress * 40); // 60% to 100%

  return (
    <header
      className="fixed top-0 left-0 right-0 z-[100] bg-background backdrop-blur-xl border-b border-border"
    >
      <nav className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="flex h-16 items-center justify-between gap-4">
          {/* Logo */}
          <Link
            href="/"
            className="flex items-center gap-2 transition-opacity hover:opacity-80 shrink-0"
          >
            <div className="relative h-8 w-8 rounded-lg bg-gradient-to-br from-primary to-accent flex items-center justify-center">
              <span className="text-white font-bold text-lg">T</span>
            </div>
            <span className="text-xl font-bold text-foreground hidden sm:block">
              Toogo
            </span>
          </Link>

          {/* Mobile Navigation - fades out on scroll */}
          <div
            className="flex-1 flex md:hidden items-center justify-around transition-all duration-100 mx-2"
            style={{
              opacity: 1 - mobileNavProgress,
              transform: `scale(${1 - mobileNavProgress * 0.1})`,
              pointerEvents: mobileNavProgress > 0.5 ? 'none' : 'auto',
            }}
          >
            {navItems.map((item) => {
              const isActive = pathname === item.href;
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  className={cn(
                    "flex flex-col items-center gap-0.5 transition-colors",
                    isActive
                      ? "text-primary"
                      : "text-muted-foreground"
                  )}
                >
                  <LottieIcon variant="header" name={item.lottieIcon} size={20} isActive={isActive} playOnHover />
                  <span className="text-[10px] font-medium">{item.name === "AI Chat" ? "AI" : item.name}</span>
                </Link>
              );
            })}
          </div>

          {/* Center area with morphing content */}
          <div className="hidden md:flex flex-1 justify-center items-center relative">
            {/* Navigation - fades out on scroll */}
            <div
              className="flex items-center gap-1 absolute"
              style={{
                opacity: navOpacity,
                transform: `scale(${navScale})`,
                pointerEvents: scrollProgress > 0.5 ? 'none' : 'auto',
                transition: 'opacity 0.1s ease-out, transform 0.1s ease-out',
              }}
            >
              {navItems.map((item) => {
                const isActive = pathname === item.href;
                const isHovered = hoveredNavItem === item.name;
                return (
                  <Link
                    key={item.name}
                    href={item.href}
                    onMouseEnter={() => setHoveredNavItem(item.name)}
                    onMouseLeave={() => setHoveredNavItem(null)}
                    className={cn(
                      "flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium transition-colors",
                      isActive
                        ? "text-primary"
                        : "text-muted-foreground hover:text-foreground"
                    )}
                  >
                    <LottieIcon variant="header" name={item.lottieIcon} size={16} isActive={isActive} isHovered={isHovered} playOnHover />
                    {item.name}
                  </Link>
                );
              })}
            </div>

            {/* Search Bar - fades in and grows on scroll */}
            <div
              className={cn(
                "absolute flex items-center gap-2",
                hasAnyPickerOpen && "z-[60]"
              )}
              style={{
                opacity: searchOpacity,
                transform: `scale(${searchScale})`,
                width: `${searchWidth}%`,
                maxWidth: '40rem',
                pointerEvents: scrollProgress < 0.5 ? 'none' : 'auto',
                transition: 'opacity 0.1s ease-out, transform 0.1s ease-out',
              }}
            >
              <div
                className={cn(
                  "flex-1 flex items-center bg-muted/50 border rounded-full h-12 transition-all duration-300",
                  hasAnyPickerOpen
                    ? "border-primary shadow-lg shadow-primary/10"
                    : "border-border"
                )}
              >
                {/* Destination */}
                <div className="flex-1 min-w-0">
                  <DestinationPicker
                    value={destination}
                    onChange={setDestination}
                    isOpen={activePicker === "destination"}
                    onOpenChange={(open) => handlePickerChange(open ? "destination" : null)}
                    compact
                  />
                </div>

                <div className="h-6 w-px bg-border" />

                {/* Date */}
                <div className="flex-shrink-0">
                  <DatePicker
                    value={dateValue}
                    onChange={setDateValue}
                    isOpen={activePicker === "date"}
                    onOpenChange={(open) => handlePickerChange(open ? "date" : null)}
                    compact
                  />
                </div>

                {/* Guests - hidden on /trips page */}
                {pathname !== '/trips' && (
                  <>
                    <div className="h-6 w-px bg-border" />
                    <div className="flex-shrink-0">
                      <GuestsPicker
                        value={guests}
                        onChange={setGuests}
                        isOpen={activePicker === "guests"}
                        onOpenChange={(open) => handlePickerChange(open ? "guests" : null)}
                        compact
                      />
                    </div>
                  </>
                )}

                {/* Search Button */}
                <div className="pr-1.5 py-1.5">
                  <Button size="icon" className="h-9 w-9 rounded-full" onClick={handleSearch}>
                    <LottieIcon variant="search" name="search" size={18} playOnHover />
                  </Button>
                </div>
              </div>

              {/* AI Trip Button */}
              <Link href="/chat">
                <Button
                  size="icon"
                  variant="outline"
                  className="rounded-full h-12 w-12 shrink-0 bg-background/80 border-border shadow-sm hover:border-accent hover:bg-accent/10"
                >
                  <LottieIcon variant="header" name="aiChat" size={22} playOnHover />
                </Button>
              </Link>
            </div>
          </div>

          {/* Right Side - Account */}
          <div className="flex items-center gap-2 shrink-0">
            {/* Desktop */}
            <div className="hidden md:flex items-center gap-2">
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
                    className="text-muted-foreground hover:text-foreground"
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

            {/* Mobile Menu Button */}
            <div className="flex md:hidden">
              <Sheet open={isMobileMenuOpen} onOpenChange={setIsMobileMenuOpen}>
                <SheetTrigger asChild>
                  <Button variant="ghost" size="icon" className="h-9 w-9">
                    <Menu className="h-5 w-5" />
                  </Button>
                </SheetTrigger>
                <SheetContent side="right" className="w-full max-w-xs p-0">
                  <div className="flex flex-col h-full">
                    {/* Mobile Header */}
                    <div className="flex items-center justify-between p-4 border-b border-border">
                      <Link
                        href="/"
                        className="flex items-center gap-2"
                        onClick={() => setIsMobileMenuOpen(false)}
                      >
                        <div className="h-8 w-8 rounded-lg bg-gradient-to-br from-primary to-accent flex items-center justify-center">
                          <span className="text-white font-bold text-lg">T</span>
                        </div>
                        <span className="text-xl font-bold">Toogo</span>
                      </Link>
                    </div>

                    {/* Mobile Navigation */}
                    <div className="flex-1 overflow-y-auto py-4">
                      <div className="space-y-1 px-3">
                        <Link
                          href="/explore"
                          onClick={() => setIsMobileMenuOpen(false)}
                          className="flex items-center gap-3 px-4 py-3 rounded-xl text-base font-medium text-muted-foreground hover:text-foreground hover:bg-muted transition-all"
                        >
                          Explore
                        </Link>
                        <Link
                          href="/chat"
                          onClick={() => setIsMobileMenuOpen(false)}
                          className="flex items-center gap-3 px-4 py-3 rounded-xl text-base font-medium text-muted-foreground hover:text-foreground hover:bg-muted transition-all"
                        >
                          AI Chat
                        </Link>
                        <Link
                          href="/trips"
                          onClick={() => setIsMobileMenuOpen(false)}
                          className="flex items-center gap-3 px-4 py-3 rounded-xl text-base font-medium text-muted-foreground hover:text-foreground hover:bg-muted transition-all"
                        >
                          My Trips
                        </Link>
                      </div>
                    </div>

                    {/* Mobile Footer Actions */}
                    <div className="p-4 border-t border-border space-y-3">
                      {user ? (
                        <>
                          <div className="flex items-center gap-3 px-2 py-2">
                            {user.user_metadata?.avatar_url ? (
                              <Image
                                src={user.user_metadata.avatar_url}
                                alt={user.user_metadata?.full_name || "User"}
                                width={40}
                                height={40}
                                className="rounded-full object-cover"
                              />
                            ) : (
                              <div className="h-10 w-10 rounded-full bg-primary/10 flex items-center justify-center">
                                <span className="text-base font-medium text-primary">
                                  {(user.user_metadata?.full_name || user.email || "U")[0].toUpperCase()}
                                </span>
                              </div>
                            )}
                            <div className="flex-1 min-w-0">
                              <p className="text-sm font-medium truncate">
                                {user.user_metadata?.full_name || "User"}
                              </p>
                              <p className="text-xs text-muted-foreground truncate">
                                {user.email}
                              </p>
                            </div>
                          </div>
                          <Button
                            variant="outline"
                            className="w-full justify-center"
                            onClick={() => {
                              signOut();
                              setIsMobileMenuOpen(false);
                            }}
                          >
                            <LogOut className="mr-2 h-4 w-4" />
                            Sign Out
                          </Button>
                        </>
                      ) : (
                        <>
                          <Button
                            variant="outline"
                            className="w-full justify-center"
                            onClick={() => {
                              setIsMobileMenuOpen(false);
                              setIsAuthModalOpen(true);
                            }}
                          >
                            Sign In
                          </Button>
                          <Button
                            className="w-full justify-center"
                            onClick={() => {
                              setIsMobileMenuOpen(false);
                              setIsAuthModalOpen(true);
                            }}
                          >
                            Get Started
                          </Button>
                        </>
                      )}
                    </div>
                  </div>
                </SheetContent>
              </Sheet>
            </div>
          </div>
        </div>
      </nav>

      {/* Auth Modal */}
      <AuthModal
        isOpen={isAuthModalOpen}
        onClose={() => setIsAuthModalOpen(false)}
      />

    </header>
  );
}
