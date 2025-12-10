"use client";

import { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { Search } from "lucide-react";
import { motion, useSpring, useTransform } from "framer-motion";
import { Button } from "@/components/ui/button";
import { GeminiIcon } from "@/components/ui/gemini-icon";
import { DestinationPicker } from "./search/destination-picker";
import { DatePicker } from "./search/date-picker";
import { GuestsPicker } from "./search/guests-picker";
import { MobileSearchModal } from "./search/mobile-search-modal";
import { cn } from "@/lib/utils";
import { useAuth } from "@/contexts/auth-context";

// Spring config for Apple-style animations
const SPRING_CONFIG = {
  mass: 0.1,
  stiffness: 150,
  damping: 12,
};

type ActivePicker = "destination" | "date" | "guests" | null;

// AI Chat Button with dock-style magnification and sliding text
function AiChatButton({ onClick }: { onClick: () => void }) {
  const [isHovered, setIsHovered] = useState(false);
  const ref = useRef<HTMLButtonElement>(null);

  // Spring-animated scale
  const scale = useSpring(1, SPRING_CONFIG);

  // Width animation for expanding effect
  const width = useSpring(64, {
    stiffness: 300,
    damping: 25,
  });

  useEffect(() => {
    if (isHovered) {
      scale.set(1.08);
      width.set(180);
    } else {
      scale.set(1);
      width.set(64);
    }
  }, [isHovered, scale, width]);

  return (
    <motion.button
      ref={ref}
      onClick={onClick}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      style={{
        scale,
        width,
      }}
      className="relative h-16 rounded-full bg-background/80 backdrop-blur-sm border border-border shadow-lg hover:border-accent hover:bg-accent/5 transition-colors duration-200 overflow-hidden origin-center cursor-pointer"
    >
      <div className="absolute inset-0 flex items-center">
        {/* Icon container - fixed position on left */}
        <div className="w-16 h-16 flex items-center justify-center shrink-0">
          <motion.div
            animate={{
              rotate: isHovered ? 15 : 0,
            }}
            transition={{ type: "spring", stiffness: 300, damping: 20 }}
          >
            <GeminiIcon className="h-6 w-6 text-accent" />
          </motion.div>
        </div>

        {/* Text container - slides in from right */}
        <motion.span
          initial={{ opacity: 0, x: -10 }}
          animate={{
            opacity: isHovered ? 1 : 0,
            x: isHovered ? 0 : -10,
          }}
          transition={{
            type: "spring",
            stiffness: 300,
            damping: 25,
            delay: isHovered ? 0.05 : 0,
          }}
          className="text-sm font-medium text-accent whitespace-nowrap pr-5"
        >
          Open Chat
        </motion.span>
      </div>
    </motion.button>
  );
}

function useIsMobile() {
  const [isMobile, setIsMobile] = useState<boolean | null>(null);

  useEffect(() => {
    const checkMobile = () => setIsMobile(window.innerWidth < 640);
    checkMobile();
    window.addEventListener("resize", checkMobile);
    return () => window.removeEventListener("resize", checkMobile);
  }, []);

  return isMobile;
}

export function HeroSearch() {
  const router = useRouter();
  const isMobile = useIsMobile();
  const { user } = useAuth();
  const isLoggedIn = !!user;
  const [scrollProgress, setScrollProgress] = useState(0);
  const [activePicker, setActivePicker] = useState<ActivePicker>(null);
  const [mobileSearchOpen, setMobileSearchOpen] = useState(false);
  const [mobileSearchSticky, setMobileSearchSticky] = useState(false);
  const mobileSearchRef = useRef<HTMLDivElement>(null);

  // Search state
  const [destination, setDestination] = useState("");
  const [dateValue, setDateValue] = useState<{ startDate: Date | null; endDate: Date | null; flexible: boolean }>({
    startDate: null,
    endDate: null,
    flexible: false,
  });
  const [guests, setGuests] = useState({ adults: 0, children: 0, infants: 0 });

  useEffect(() => {
    const handleScroll = () => {
      // When logged in, start animation immediately and finish faster
      const start = isLoggedIn ? 0 : 50;
      const end = isLoggedIn ? 80 : 250;
      const current = window.scrollY;

      if (current <= start) {
        setScrollProgress(0);
      } else if (current >= end) {
        setScrollProgress(1);
      } else {
        setScrollProgress((current - start) / (end - start));
      }

      // Close any open picker when scrolling
      if (current > 0 && activePicker !== null) {
        setActivePicker(null);
      }

      // Check if mobile search bar should be sticky
      if (mobileSearchRef.current && isMobile) {
        const rect = mobileSearchRef.current.getBoundingClientRect();
        // When search bar top reaches 12px (to align with header content), make it sticky
        setMobileSearchSticky(rect.top <= 12);
      }
    };

    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, [isMobile, activePicker, isLoggedIn]);

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

  const handlePickerChange = (picker: ActivePicker) => {
    setActivePicker(picker);
  };

  // Interpolate values based on scroll
  const scale = 1 - scrollProgress * 0.15;
  const opacity = 1 - scrollProgress;
  const translateY = scrollProgress * -20;

  const hasAnyPickerOpen = activePicker !== null;

  return (
    <section className={cn("relative", hasAnyPickerOpen && "z-[50]")}>
      {/* Background gradient */}
      <div className="absolute inset-0 bg-gradient-to-b from-primary/5 via-background to-background" />

      {/* Decorative elements */}
      <div className="absolute top-10 left-0 w-[400px] h-[400px] bg-primary/10 rounded-full blur-3xl animate-pulse" />
      <div className="absolute top-20 right-0 w-[500px] h-[500px] bg-accent/10 rounded-full blur-3xl animate-pulse delay-1000" />

      <div className={cn(
        "relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8",
        isLoggedIn ? "pt-[84px] sm:pt-20 pb-0 sm:pb-4" : "pt-24 sm:pt-32 pb-0 sm:pb-8"
      )}>
        {/* Hero Content - hidden when logged in */}
        {!isLoggedIn && (
          <div
            className="text-center max-w-3xl mx-auto mb-8 sm:mb-12"
            style={isMobile === false ? {
              opacity: Math.max(0, 1 - scrollProgress * 1.5),
              transform: `translateY(${scrollProgress * -10}px)`,
            } : undefined}
          >
            <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold tracking-tight">
              <span className="text-foreground">Discover Your </span>
              <span className="text-gradient-accent">Perfect Trip</span>
            </h1>
            <p className="mt-4 sm:mt-6 text-base sm:text-lg text-muted-foreground max-w-2xl mx-auto leading-relaxed">
              Explore thousands of curated trips or let AI create your personalized itinerary in seconds
            </p>
          </div>
        )}

        {/* Search Bar */}
        <div
          className="max-w-4xl mx-auto relative z-[60]"
          style={isMobile === false ? {
            opacity,
            transform: `scale(${scale}) translateY(${translateY}px)`,
            transformOrigin: "top center",
          } : undefined}
        >
          {/* Desktop Layout */}
          {isMobile === false && (
            <div className="flex items-center gap-3">
              <div
                className={cn(
                  "flex-1 relative bg-background/80 backdrop-blur-sm border rounded-full transition-all duration-300",
                  hasAnyPickerOpen
                    ? "border-primary shadow-xl shadow-primary/10"
                    : "border-border shadow-lg"
                )}
              >
                <div className="flex items-center">
                  {/* Destination */}
                  <div className="flex-1">
                    <DestinationPicker
                      value={destination}
                      onChange={setDestination}
                      isOpen={activePicker === "destination"}
                      onOpenChange={(open) => handlePickerChange(open ? "destination" : null)}
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
                    />
                  </div>

                  <div className="h-6 w-px bg-border" />

                  {/* Guests */}
                  <div className="flex-shrink-0">
                    <GuestsPicker
                      value={guests}
                      onChange={setGuests}
                      isOpen={activePicker === "guests"}
                      onOpenChange={(open) => handlePickerChange(open ? "guests" : null)}
                    />
                  </div>

                  {/* Search Button */}
                  <div className="pr-2 py-2">
                    <Button
                      size="lg"
                      className="rounded-[22px] h-12 px-6 gap-2"
                      onClick={handleSearch}
                    >
                      <Search className="h-4 w-4" />
                      <span className="hidden lg:inline">Search</span>
                    </Button>
                  </div>
                </div>
              </div>

              {/* AI Trip Button with dock-style animation */}
              <AiChatButton onClick={() => router.push("/chat")} />
            </div>
          )}

          {/* Mobile Layout - Simple Search Bar (non-sticky version) */}
          {isMobile === true && !mobileSearchSticky && (
            <div ref={mobileSearchRef}>
              <div
                className="flex items-center gap-2 transition-all duration-200 ease-out"
                style={{
                  marginLeft: `${scrollProgress * 40}px`,
                  marginRight: `${scrollProgress * 40}px`,
                }}
              >
                <button
                  type="button"
                  onClick={() => setMobileSearchOpen(true)}
                  className="flex-1 bg-background border border-border rounded-full shadow-lg py-2.5 px-4 flex items-center gap-3 active:scale-[0.98] transition-all duration-200"
                >
                  <Search className="h-5 w-5 text-muted-foreground shrink-0" />
                  <span className={cn(
                    "text-sm",
                    destination ? "text-foreground" : "text-muted-foreground"
                  )}>
                    {destination || "Where to?"}
                  </span>
                </button>

                {/* AI Trip Button */}
                <Button
                  size="icon"
                  variant="outline"
                  className="rounded-full h-[44px] w-[44px] shrink-0 bg-background border-border shadow-lg hover:border-accent hover:bg-accent/10 transition-all duration-200"
                  onClick={() => router.push("/chat")}
                >
                  <GeminiIcon className="h-5 w-5 text-accent" />
                </Button>
              </div>
            </div>
          )}

          {/* Placeholder when mobile search is sticky */}
          {isMobile === true && mobileSearchSticky && (
            <div ref={mobileSearchRef} className="h-[48px]" />
          )}

        </div>
      </div>

      {/* Mobile Sticky Search Bar - rendered outside nested containers */}
      {isMobile === true && (
        <div
          className="fixed top-[10px] left-[60px] right-[60px] z-[101] flex items-center gap-2 transition-all duration-300 ease-out"
          style={{
            opacity: mobileSearchSticky ? 1 : 0,
            transform: mobileSearchSticky ? 'translateY(0)' : 'translateY(10px)',
            pointerEvents: mobileSearchSticky ? 'auto' : 'none',
          }}
        >
          <button
            type="button"
            onClick={() => setMobileSearchOpen(true)}
            className="flex-1 bg-background border border-border rounded-full shadow-lg py-2.5 px-4 flex items-center gap-3 active:scale-[0.98] transition-all duration-200"
          >
            <Search className="h-5 w-5 text-muted-foreground shrink-0" />
            <span className={cn(
              "text-sm",
              destination ? "text-foreground" : "text-muted-foreground"
            )}>
              {destination || "Where to?"}
            </span>
          </button>

          {/* AI Trip Button */}
          <Button
            size="icon"
            variant="outline"
            className="rounded-full h-[44px] w-[44px] shrink-0 bg-background border-border shadow-lg hover:border-accent hover:bg-accent/10 transition-all duration-200"
            onClick={() => router.push("/chat")}
          >
            <GeminiIcon className="h-5 w-5 text-accent" />
          </Button>
        </div>
      )}

      {/* Mobile Search Modal */}
      {isMobile === true && (
        <MobileSearchModal
          isOpen={mobileSearchOpen}
          onClose={() => setMobileSearchOpen(false)}
          destination={destination}
          onDestinationChange={setDestination}
          dateValue={dateValue}
          onDateChange={setDateValue}
          guests={guests}
          onGuestsChange={setGuests}
          onSearch={handleSearch}
        />
      )}
    </section>
  );
}
