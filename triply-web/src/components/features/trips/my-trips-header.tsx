"use client";

import { useState, useEffect, useRef } from "react";
import { createPortal } from "react-dom";
import { Search, SlidersHorizontal, LayoutGrid, LayoutList, MapPin, Calendar, X, ChevronRight, ChevronLeft, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { LottieIcon } from "@/components/ui/lottie-icon";
import { SegmentToggle } from "./segment-toggle";
import { DestinationPicker } from "../home/search/destination-picker";
import { DatePicker } from "../home/search/date-picker";
import { cn } from "@/lib/utils";

type ActivePicker = "destination" | "date" | null;

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

interface MyTripsHeaderProps {
  activeTab: number;
  onTabChange: (index: number) => void;
  tripsCount: number;
  placesCount: number;
  viewMode: "list" | "grid";
  onViewModeChange: (mode: "list" | "grid") => void;
  searchQuery: string;
  onSearchChange: (query: string) => void;
  onFilterClick?: () => void;
  hasActiveFilters?: boolean;
}

// Mobile Search Modal for My Trips
function MobileTripsSearchModal({
  isOpen,
  onClose,
  searchQuery,
  onSearchChange,
  dateValue,
  onDateChange,
}: {
  isOpen: boolean;
  onClose: () => void;
  searchQuery: string;
  onSearchChange: (value: string) => void;
  dateValue: { startDate: Date | null; endDate: Date | null; flexible: boolean };
  onDateChange: (value: { startDate: Date | null; endDate: Date | null; flexible: boolean }) => void;
}) {
  const [mounted, setMounted] = useState(false);
  const [activeSection, setActiveSection] = useState<"destination" | "date" | null>("destination");
  const [localQuery, setLocalQuery] = useState(searchQuery);
  const [currentMonth, setCurrentMonth] = useState(new Date().getMonth());
  const [currentYear, setCurrentYear] = useState(new Date().getFullYear());
  const [selecting, setSelecting] = useState<"start" | "end">("start");

  const today = new Date();
  const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
  const weekDays = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"];

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = "hidden";
      setLocalQuery(searchQuery);
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [isOpen, searchQuery]);

  const getDaysInMonth = (year: number, month: number) => new Date(year, month + 1, 0).getDate();
  const getFirstDayOfMonth = (year: number, month: number) => {
    const day = new Date(year, month, 1).getDay();
    return day === 0 ? 6 : day - 1;
  };

  const handleDateClick = (day: number) => {
    const clickedDate = new Date(currentYear, currentMonth, day);
    if (dateValue.flexible) {
      onDateChange({ startDate: clickedDate, endDate: null, flexible: false });
      setSelecting("end");
      return;
    }
    if (selecting === "start" || !dateValue.startDate) {
      onDateChange({ startDate: clickedDate, endDate: null, flexible: false });
      setSelecting("end");
    } else {
      if (clickedDate < dateValue.startDate) {
        onDateChange({ startDate: clickedDate, endDate: dateValue.startDate, flexible: false });
      } else {
        onDateChange({ ...dateValue, endDate: clickedDate });
      }
      setSelecting("start");
    }
  };

  const isDateDisabled = (day: number) => {
    const date = new Date(currentYear, currentMonth, day);
    const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    return date < todayStart;
  };

  const isDateSelected = (day: number) => {
    if (!dateValue.startDate) return false;
    const date = new Date(currentYear, currentMonth, day);
    if (dateValue.startDate && date.getTime() === dateValue.startDate.getTime()) return "start";
    if (dateValue.endDate && date.getTime() === dateValue.endDate.getTime()) return "end";
    return false;
  };

  const isDateInRange = (day: number) => {
    if (!dateValue.startDate || !dateValue.endDate) return false;
    const date = new Date(currentYear, currentMonth, day);
    return date > dateValue.startDate && date < dateValue.endDate;
  };

  const canGoPrev = !(currentYear === today.getFullYear() && currentMonth === today.getMonth());

  const renderCalendar = () => {
    const daysInMonth = getDaysInMonth(currentYear, currentMonth);
    const firstDay = getFirstDayOfMonth(currentYear, currentMonth);
    const days = [];
    for (let i = 0; i < firstDay; i++) {
      days.push(<div key={`empty-${i}`} className="h-10 w-10" />);
    }
    for (let day = 1; day <= daysInMonth; day++) {
      const disabled = isDateDisabled(day);
      const selected = isDateSelected(day);
      const inRange = isDateInRange(day);
      days.push(
        <button
          key={day}
          type="button"
          onClick={() => !disabled && handleDateClick(day)}
          disabled={disabled}
          className={cn(
            "h-10 w-10 rounded-full text-sm font-medium transition-all flex items-center justify-center",
            disabled && "opacity-30 cursor-not-allowed",
            selected === "start" && "bg-primary text-white",
            selected === "end" && "bg-primary text-white",
            inRange && "bg-primary/20",
            !selected && !inRange && !disabled && "hover:bg-muted"
          )}
        >
          {day}
        </button>
      );
    }
    return days;
  };

  const handleSearch = () => {
    onSearchChange(localQuery);
    onClose();
  };

  const handleClear = () => {
    setLocalQuery("");
    onSearchChange("");
    onDateChange({ startDate: null, endDate: null, flexible: false });
  };

  const getDateDisplayText = () => {
    if (dateValue.flexible) return "I'm flexible";
    if (dateValue.startDate && dateValue.endDate) {
      const start = dateValue.startDate.toLocaleDateString("en-US", { month: "short", day: "numeric" });
      const end = dateValue.endDate.toLocaleDateString("en-US", { month: "short", day: "numeric" });
      return `${start} - ${end}`;
    }
    if (dateValue.startDate) {
      return dateValue.startDate.toLocaleDateString("en-US", { month: "short", day: "numeric" });
    }
    return "Add dates";
  };

  const [isAnimating, setIsAnimating] = useState(false);

  useEffect(() => {
    if (isOpen) {
      setIsAnimating(true);
    }
  }, [isOpen]);

  const handleClose = () => {
    setIsAnimating(false);
    setTimeout(onClose, 300);
  };

  if (!mounted || !isOpen) return null;

  return createPortal(
    <div className="fixed inset-0 z-[9999] flex flex-col">
      {/* Backdrop */}
      <div
        className={cn(
          "absolute inset-0 bg-black/50 transition-opacity duration-300",
          isAnimating ? "opacity-100" : "opacity-0"
        )}
        onClick={handleClose}
      />

      {/* Modal */}
      <div
        className={cn(
          "absolute inset-x-0 bottom-0 top-12 bg-background rounded-t-3xl flex flex-col transition-transform duration-300 ease-out",
          isAnimating ? "translate-y-0" : "translate-y-full"
        )}
      >
        <div className="flex items-center justify-between p-4 border-b border-border">
          <button type="button" onClick={handleClose} className="p-2 -ml-2 rounded-full hover:bg-muted transition-colors">
            <X className="h-5 w-5" />
          </button>
          <span className="font-semibold">Search trips</span>
          <div className="w-9" />
        </div>

        <div className="flex-1 overflow-y-auto p-4 space-y-3">
          {/* Where Section Card */}
          <div
            className={cn(
              "bg-background rounded-2xl border shadow-sm overflow-hidden transition-all duration-300",
              activeSection === "destination" ? "border-primary shadow-lg" : "border-border"
            )}
          >
            <button
              type="button"
              onClick={() => setActiveSection(activeSection === "destination" ? null : "destination")}
              className="w-full p-4 flex items-center justify-between"
            >
              <div className="text-left">
                <div className="text-xs font-medium text-muted-foreground">Where</div>
                <div className={cn("text-base font-medium", localQuery ? "text-foreground" : "text-muted-foreground")}>
                  {localQuery || "Search trips, cities..."}
                </div>
              </div>
            </button>

            <div className={cn(
              "overflow-hidden transition-all duration-300",
              activeSection === "destination" ? "max-h-[200px] opacity-100" : "max-h-0 opacity-0"
            )}>
              <div className="px-4 pb-4">
                <div className="relative">
                  <div className="absolute left-3 top-1/2 -translate-y-1/2">
                    <LottieIcon name="search" size={16} playOnHover />
                  </div>
                  <Input
                    type="text"
                    placeholder="Search trips, cities..."
                    value={localQuery}
                    onChange={(e) => setLocalQuery(e.target.value)}
                    className="pl-10 h-12 rounded-xl"
                  />
                </div>
              </div>
            </div>
          </div>

          {/* When Section Card */}
          <div
            className={cn(
              "bg-background rounded-2xl border shadow-sm overflow-hidden transition-all duration-300",
              activeSection === "date" ? "border-primary shadow-lg" : "border-border"
            )}
          >
            <button
              type="button"
              onClick={() => setActiveSection(activeSection === "date" ? null : "date")}
              className="w-full p-4 flex items-center justify-between"
            >
              <div className="text-left">
                <div className="text-xs font-medium text-muted-foreground">When</div>
                <div className={cn("text-base font-medium", dateValue.startDate || dateValue.flexible ? "text-foreground" : "text-muted-foreground")}>
                  {getDateDisplayText()}
                </div>
              </div>
            </button>

            <div className={cn(
              "overflow-hidden transition-all duration-300",
              activeSection === "date" ? "max-h-[500px] opacity-100" : "max-h-0 opacity-0"
            )}>
              <div className="px-4 pb-4 space-y-4">
                <button
                  type="button"
                  onClick={() => onDateChange({ startDate: null, endDate: null, flexible: true })}
                  className={cn(
                    "w-full flex items-center justify-center gap-2 py-3 px-4 rounded-xl border-2 transition-all",
                    dateValue.flexible
                      ? "border-primary bg-primary/10 text-primary"
                      : "border-border hover:border-primary/50 text-muted-foreground hover:text-foreground"
                  )}
                >
                  <Sparkles className="h-4 w-4" />
                  <span className="font-medium">I'm flexible</span>
                </button>

                <div>
                  <div className="flex items-center justify-between mb-4">
                    <Button variant="ghost" size="icon" className="h-8 w-8 rounded-full" onClick={() => {
                      if (currentMonth === 0) { setCurrentMonth(11); setCurrentYear(currentYear - 1); }
                      else setCurrentMonth(currentMonth - 1);
                    }} disabled={!canGoPrev}>
                      <ChevronLeft className="h-4 w-4" />
                    </Button>
                    <span className="font-semibold">{months[currentMonth]} {currentYear}</span>
                    <Button variant="ghost" size="icon" className="h-8 w-8 rounded-full" onClick={() => {
                      if (currentMonth === 11) { setCurrentMonth(0); setCurrentYear(currentYear + 1); }
                      else setCurrentMonth(currentMonth + 1);
                    }}>
                      <ChevronRight className="h-4 w-4" />
                    </Button>
                  </div>
                  <div className="grid grid-cols-7 gap-1 mb-2">
                    {weekDays.map((day) => (
                      <div key={day} className="h-10 w-10 flex items-center justify-center text-xs text-muted-foreground font-medium">{day}</div>
                    ))}
                  </div>
                  <div className="grid grid-cols-7 gap-1">{renderCalendar()}</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className="p-4 border-t border-border flex items-center justify-between gap-4 bg-background">
          <button type="button" onClick={handleClear} className="text-sm font-medium text-foreground underline underline-offset-2">
            Clear all
          </button>
          <Button onClick={handleSearch} className="h-12 px-6 gap-2">
            <LottieIcon name="search" size={20} playOnHover />
            Search
          </Button>
        </div>
      </div>
    </div>,
    document.body
  );
}

export function MyTripsHeader({
  activeTab,
  onTabChange,
  tripsCount,
  placesCount,
  viewMode,
  onViewModeChange,
  searchQuery,
  onSearchChange,
  onFilterClick,
  hasActiveFilters = false,
}: MyTripsHeaderProps) {
  const isMobile = useIsMobile();
  const [activePicker, setActivePicker] = useState<ActivePicker>(null);
  const [mobileSearchOpen, setMobileSearchOpen] = useState(false);
  const [mobileSearchSticky, setMobileSearchSticky] = useState(false);
  const [scrollProgress, setScrollProgress] = useState(0);
  const mobileSearchRef = useRef<HTMLDivElement>(null);
  const [dateValue, setDateValue] = useState<{ startDate: Date | null; endDate: Date | null; flexible: boolean }>({
    startDate: null,
    endDate: null,
    flexible: false,
  });

  // Scroll handler for search bar shrinking
  useEffect(() => {
    const handleScroll = () => {
      // Different thresholds for mobile vs desktop
      // Desktop has shorter distance so shrinks faster
      const start = isMobile ? 0 : 0;
      const end = isMobile ? 80 : 60;
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

      // Mobile sticky behavior
      if (mobileSearchRef.current && isMobile) {
        const rect = mobileSearchRef.current.getBoundingClientRect();
        setMobileSearchSticky(rect.top <= 12);
      }
    };

    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, [isMobile, activePicker]);

  const handlePickerChange = (picker: ActivePicker) => {
    setActivePicker(picker);
  };

  const hasAnyPickerOpen = activePicker !== null;

  // Interpolate values for desktop search bar shrinking
  const scale = 1 - scrollProgress * 0.15;
  const opacity = 1 - scrollProgress;
  const translateY = scrollProgress * -20;

  const getDateDisplayText = () => {
    if (dateValue.flexible) return "Flexible";
    if (dateValue.startDate && dateValue.endDate) {
      const start = dateValue.startDate.toLocaleDateString("en-US", { month: "short", day: "numeric" });
      const end = dateValue.endDate.toLocaleDateString("en-US", { month: "short", day: "numeric" });
      return `${start} - ${end}`;
    }
    if (dateValue.startDate) {
      return dateValue.startDate.toLocaleDateString("en-US", { month: "short", day: "numeric" });
    }
    return "Any dates";
  };

  return (
    <div className={cn("relative", hasAnyPickerOpen && "z-[50]")}>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 space-y-4">
        {/* Title, Search bar and controls row */}
        <div className="flex items-center gap-4">
          {/* Title */}
          <h1 className="text-2xl font-bold text-foreground whitespace-nowrap shrink-0 hidden sm:block">My Trips</h1>

          {/* Desktop Search bar */}
          {isMobile === false && (
            <div
              className="flex-1 max-w-2xl mx-auto relative z-[60]"
              style={{
                opacity,
                transform: `scale(${scale}) translateY(${translateY}px)`,
                transformOrigin: "top center",
              }}
            >
              <div
                className={cn(
                  "flex items-center bg-muted/50 border rounded-full transition-all duration-300",
                  hasAnyPickerOpen ? "border-primary shadow-lg shadow-primary/10" : "border-border"
                )}
              >
                <div className="flex-1 min-w-0">
                  <DestinationPicker
                    value={searchQuery}
                    onChange={onSearchChange}
                    isOpen={activePicker === "destination"}
                    onOpenChange={(open) => handlePickerChange(open ? "destination" : null)}
                  />
                </div>
                <div className="h-6 w-px bg-border" />
                <div className="flex-shrink-0">
                  <DatePicker
                    value={dateValue}
                    onChange={setDateValue}
                    isOpen={activePicker === "date"}
                    onOpenChange={(open) => handlePickerChange(open ? "date" : null)}
                  />
                </div>
                <div className="self-stretch flex items-center pr-1.5 py-1.5">
                  <Button size="sm" className="h-full px-5 gap-2 rounded-full">
                    <LottieIcon name="search" size={16} playOnHover />
                    <span>Search</span>
                  </Button>
                </div>
              </div>
            </div>
          )}

          {/* Mobile Search trigger */}
          {isMobile === true && (
            <div ref={mobileSearchRef} className="flex-1">
              {/* Placeholder to maintain layout when search bar becomes fixed */}
              {mobileSearchSticky && <div className="h-[44px]" />}
              <div
                className={cn(
                  "flex items-center gap-2 transition-all duration-150 ease-out",
                  mobileSearchSticky && "fixed top-3 left-14 right-14 z-[100]"
                )}
                style={!mobileSearchSticky ? {
                  marginLeft: `${scrollProgress * 50}px`,
                  marginRight: `${scrollProgress * 50}px`,
                  transform: `scale(${1 - scrollProgress * 0.05})`,
                } : undefined}
              >
                <button
                  type="button"
                  onClick={() => setMobileSearchOpen(true)}
                  className="flex-1 bg-background border border-border rounded-full shadow-sm py-2 px-4 flex items-center gap-3 active:scale-[0.98] transition-all duration-200"
                >
                  <LottieIcon name="search" size={16} playOnHover />
                  <span className={cn(
                    "text-sm",
                    searchQuery ? "text-foreground" : "text-muted-foreground"
                  )}>
                    {searchQuery || "Search trips..."}
                  </span>
                </button>
              </div>
            </div>
          )}

          {/* Controls */}
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="icon"
              onClick={onFilterClick}
              className={cn("h-10 w-10 rounded-full relative", hasActiveFilters && "border-primary text-primary")}
            >
              <LottieIcon name="filter" size={20} playOnHover />
              {hasActiveFilters && <span className="absolute -top-1 -right-1 h-3 w-3 rounded-full bg-primary" />}
            </Button>

            {/* View toggle - mobile only (desktop always shows grid) */}
            <div className="flex md:hidden items-center p-1.5 bg-muted rounded-full">
              <Button
                variant="ghost"
                size="icon"
                onClick={() => onViewModeChange("list")}
                className={cn(
                  "h-8 w-8 rounded-full transition-all",
                  viewMode === "list" ? "bg-primary text-white" : "text-muted-foreground hover:bg-transparent"
                )}
              >
                <LayoutList className="h-4 w-4" />
              </Button>
              <Button
                variant="ghost"
                size="icon"
                onClick={() => onViewModeChange("grid")}
                className={cn(
                  "h-8 w-8 rounded-full transition-all",
                  viewMode === "grid" ? "bg-primary text-white" : "text-muted-foreground hover:bg-transparent"
                )}
              >
                <LayoutGrid className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </div>

        {/* Segment toggle */}
        <div className="max-w-sm mx-auto">
          <SegmentToggle
            segments={[
              { label: "Trips", count: tripsCount },
              { label: "Places", count: placesCount },
            ]}
            activeIndex={activeTab}
            onChange={onTabChange}
          />
        </div>
      </div>

      {/* Mobile Search Modal */}
      {isMobile === true && (
        <MobileTripsSearchModal
          isOpen={mobileSearchOpen}
          onClose={() => setMobileSearchOpen(false)}
          searchQuery={searchQuery}
          onSearchChange={onSearchChange}
          dateValue={dateValue}
          onDateChange={setDateValue}
        />
      )}
    </div>
  );
}
