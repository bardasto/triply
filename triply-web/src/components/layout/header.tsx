"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { Menu, Search, User, Home, Compass, Map, Sparkles } from "lucide-react";
import { GeminiIcon } from "@/components/ui/gemini-icon";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";
import { DestinationPicker } from "@/components/features/home/search/destination-picker";
import { DatePicker } from "@/components/features/home/search/date-picker";
import { GuestsPicker } from "@/components/features/home/search/guests-picker";
import { cn } from "@/lib/utils";

type ActivePicker = "destination" | "date" | "guests" | null;

const navItems = [
  { name: "Home", href: "/", icon: Home },
  { name: "Explore", href: "/explore", icon: Compass },
  { name: "AI Chat", href: "/chat", icon: GeminiIcon, isCustom: true },
  { name: "My Trips", href: "/trips", icon: Map },
];

export function Header() {
  const router = useRouter();
  const [scrollProgress, setScrollProgress] = useState(0);
  const [mobileNavProgress, setMobileNavProgress] = useState(0);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const pathname = usePathname();

  // Search state
  const [activePicker, setActivePicker] = useState<ActivePicker>(null);
  const [destination, setDestination] = useState("");
  const [dateValue, setDateValue] = useState<{ startDate: Date | null; endDate: Date | null; flexible: boolean }>({
    startDate: null,
    endDate: null,
    flexible: false,
  });
  const [guests, setGuests] = useState({ adults: 0, children: 0, infants: 0 });

  // Pages with their own search bar - don't show header search
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
      const start = hasOwnSearch ? 20 : 150;
      const end = hasOwnSearch ? 80 : 350;
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
  }, [hasOwnSearch, activePicker]);

  // Interpolate values based on scroll progress
  const navOpacity = 1 - scrollProgress;
  const navScale = 1 - (scrollProgress * 0.1);
  const searchOpacity = scrollProgress;
  const searchScale = 0.9 + (scrollProgress * 0.1);
  const searchWidth = 60 + (scrollProgress * 40); // 60% to 100%

  return (
    <header
      className="fixed top-0 left-0 right-0 z-50 bg-background/95 backdrop-blur-xl border-b border-border/50"
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
              Triply
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
              const Icon = item.icon;
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
                  <Icon className="h-5 w-5" />
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
                const Icon = item.icon;
                const isActive = pathname === item.href;
                return (
                  <Link
                    key={item.name}
                    href={item.href}
                    className={cn(
                      "flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium transition-colors",
                      isActive
                        ? "text-primary"
                        : "text-muted-foreground hover:text-foreground"
                    )}
                  >
                    <Icon className="h-4 w-4" />
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
                    <Search className="h-4 w-4" />
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
                  <Sparkles className="h-5 w-5 text-accent" />
                </Button>
              </Link>
            </div>
          </div>

          {/* Right Side - Account */}
          <div className="flex items-center gap-2 shrink-0">
            {/* Desktop */}
            <div className="hidden md:flex items-center gap-2">
              <Button variant="ghost" size="sm" className="text-muted-foreground hover:text-foreground">
                Sign In
              </Button>
              <Button size="icon" variant="ghost" className="rounded-full h-9 w-9">
                <User className="h-5 w-5" />
              </Button>
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
                        <span className="text-xl font-bold">Triply</span>
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
                      <Button variant="outline" className="w-full justify-center">
                        Sign In
                      </Button>
                      <Button className="w-full justify-center">
                        Get Started
                      </Button>
                    </div>
                  </div>
                </SheetContent>
              </Sheet>
            </div>
          </div>
        </div>
      </nav>
    </header>
  );
}
