"use client";

import { useState, useEffect } from "react";
import { createPortal } from "react-dom";
import { X, Search, MapPin, Calendar, Users, ChevronRight, ChevronLeft, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";

interface Destination {
  id: string;
  name: string;
  country: string;
  description: string;
  icon: string;
}

const popularDestinations: Destination[] = [
  { id: "1", name: "Paris", country: "France", description: "City of lights and romance", icon: "🗼" },
  { id: "2", name: "Tokyo", country: "Japan", description: "Modern meets traditional", icon: "🏯" },
  { id: "3", name: "New York", country: "USA", description: "The city that never sleeps", icon: "🗽" },
  { id: "4", name: "Barcelona", country: "Spain", description: "Art, beach and architecture", icon: "🏖️" },
  { id: "5", name: "Bali", country: "Indonesia", description: "Tropical paradise", icon: "🌴" },
  { id: "6", name: "Rome", country: "Italy", description: "Ancient history awaits", icon: "🏛️" },
];

const months = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
];

const weekDays = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"];

interface GuestsValue {
  adults: number;
  children: number;
  infants: number;
}

interface DateValue {
  startDate: Date | null;
  endDate: Date | null;
  flexible: boolean;
}

interface MobileSearchModalProps {
  isOpen: boolean;
  onClose: () => void;
  destination: string;
  onDestinationChange: (value: string) => void;
  dateValue: DateValue;
  onDateChange: (value: DateValue) => void;
  guests: GuestsValue;
  onGuestsChange: (value: GuestsValue) => void;
  onSearch: () => void;
}

type ActiveSection = "destination" | "date" | "guests" | null;

function getDaysInMonth(year: number, month: number) {
  return new Date(year, month + 1, 0).getDate();
}

function getFirstDayOfMonth(year: number, month: number) {
  const day = new Date(year, month, 1).getDay();
  return day === 0 ? 6 : day - 1;
}

export function MobileSearchModal({
  isOpen,
  onClose,
  destination,
  onDestinationChange,
  dateValue,
  onDateChange,
  guests,
  onGuestsChange,
  onSearch,
}: MobileSearchModalProps) {
  const [mounted, setMounted] = useState(false);
  const [activeSection, setActiveSection] = useState<ActiveSection>("destination");
  const [searchQuery, setSearchQuery] = useState(destination);
  const [currentMonth, setCurrentMonth] = useState(new Date().getMonth());
  const [currentYear, setCurrentYear] = useState(new Date().getFullYear());
  const [selecting, setSelecting] = useState<"start" | "end">("start");

  const today = new Date();

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = "hidden";
      setSearchQuery(destination);
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [isOpen, destination]);

  const filteredDestinations = searchQuery
    ? popularDestinations.filter(
        (d) =>
          d.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
          d.country.toLowerCase().includes(searchQuery.toLowerCase())
      )
    : popularDestinations;

  const handleDestinationSelect = (dest: Destination) => {
    onDestinationChange(`${dest.name}, ${dest.country}`);
    setSearchQuery(`${dest.name}, ${dest.country}`);
    setActiveSection("date");
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
      setActiveSection("guests");
    }
  };

  const handleFlexible = () => {
    onDateChange({ startDate: null, endDate: null, flexible: true });
    setActiveSection("guests");
  };

  const isDateDisabled = (day: number) => {
    const date = new Date(currentYear, currentMonth, day);
    const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    return date < todayStart;
  };

  const isDateSelected = (day: number) => {
    if (!dateValue.startDate) return false;
    const date = new Date(currentYear, currentMonth, day);
    const dateTime = date.getTime();
    if (dateValue.startDate && dateTime === dateValue.startDate.getTime()) return "start";
    if (dateValue.endDate && dateTime === dateValue.endDate.getTime()) return "end";
    return false;
  };

  const isDateInRange = (day: number) => {
    if (!dateValue.startDate || !dateValue.endDate) return false;
    const date = new Date(currentYear, currentMonth, day);
    return date > dateValue.startDate && date < dateValue.endDate;
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

  const getGuestsDisplayText = () => {
    const total = guests.adults + guests.children + guests.infants;
    if (total === 0) return "Add guests";
    const parts = [];
    if (guests.adults > 0) parts.push(`${guests.adults} adult${guests.adults > 1 ? "s" : ""}`);
    if (guests.children > 0) parts.push(`${guests.children} child${guests.children > 1 ? "ren" : ""}`);
    if (guests.infants > 0) parts.push(`${guests.infants} infant${guests.infants > 1 ? "s" : ""}`);
    return parts.join(", ");
  };

  const handleClearAll = () => {
    onDestinationChange("");
    setSearchQuery("");
    onDateChange({ startDate: null, endDate: null, flexible: false });
    onGuestsChange({ adults: 0, children: 0, infants: 0 });
    setActiveSection("destination");
  };

  const handleSearchClick = () => {
    onSearch();
    onClose();
  };

  const canGoPrev = !(currentYear === today.getFullYear() && currentMonth === today.getMonth());

  const goToPrevMonth = () => {
    if (currentMonth === 0) {
      setCurrentMonth(11);
      setCurrentYear(currentYear - 1);
    } else {
      setCurrentMonth(currentMonth - 1);
    }
  };

  const goToNextMonth = () => {
    if (currentMonth === 11) {
      setCurrentMonth(0);
      setCurrentYear(currentYear + 1);
    } else {
      setCurrentMonth(currentMonth + 1);
    }
  };

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
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-border">
          <button
            type="button"
            onClick={handleClose}
            className="p-2 -ml-2 rounded-full hover:bg-muted transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
          <span className="font-semibold">Search</span>
          <div className="w-9" />
        </div>

        {/* Content */}
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
                <div className={cn("text-base font-medium", destination ? "text-foreground" : "text-muted-foreground")}>
                  {destination || "Search destinations"}
                </div>
              </div>
            </button>

            <div className={cn(
              "overflow-hidden transition-all duration-300",
              activeSection === "destination" ? "max-h-[500px] opacity-100" : "max-h-0 opacity-0"
            )}>
              <div className="px-4 pb-4 space-y-4">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Input
                    type="text"
                    placeholder="Search destinations"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="pl-10 h-12 rounded-xl"
                  />
                </div>

                <div>
                  <div className="text-xs font-medium text-muted-foreground mb-3">Popular destinations</div>
                  <div className="space-y-1">
                    {filteredDestinations.map((dest) => (
                      <button
                        key={dest.id}
                        type="button"
                        onClick={() => handleDestinationSelect(dest)}
                        className="w-full flex items-center gap-3 p-3 rounded-xl hover:bg-muted transition-colors"
                      >
                        <div className="h-12 w-12 rounded-xl bg-muted flex items-center justify-center text-2xl">
                          {dest.icon}
                        </div>
                        <div className="text-left">
                          <div className="font-medium text-foreground">{dest.name}, {dest.country}</div>
                          <div className="text-sm text-muted-foreground">{dest.description}</div>
                        </div>
                      </button>
                    ))}
                  </div>
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
                {/* Flexible Button */}
                <button
                  type="button"
                  onClick={handleFlexible}
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

                {/* Calendar */}
                <div>
                  <div className="flex items-center justify-between mb-4">
                    <Button
                      variant="ghost"
                      size="icon"
                      type="button"
                      className="h-8 w-8 rounded-full"
                      onClick={goToPrevMonth}
                      disabled={!canGoPrev}
                    >
                      <ChevronLeft className="h-4 w-4" />
                    </Button>
                    <span className="font-semibold text-foreground">
                      {months[currentMonth]} {currentYear}
                    </span>
                    <Button
                      variant="ghost"
                      size="icon"
                      type="button"
                      className="h-8 w-8 rounded-full"
                      onClick={goToNextMonth}
                    >
                      <ChevronRight className="h-4 w-4" />
                    </Button>
                  </div>
                  <div className="grid grid-cols-7 gap-1 mb-2">
                    {weekDays.map((day) => (
                      <div key={day} className="h-10 w-10 flex items-center justify-center text-xs text-muted-foreground font-medium">
                        {day}
                      </div>
                    ))}
                  </div>
                  <div className="grid grid-cols-7 gap-1">
                    {renderCalendar()}
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Who Section Card */}
          <div
            className={cn(
              "bg-background rounded-2xl border shadow-sm overflow-hidden transition-all duration-300",
              activeSection === "guests" ? "border-primary shadow-lg" : "border-border"
            )}
          >
            <button
              type="button"
              onClick={() => setActiveSection(activeSection === "guests" ? null : "guests")}
              className="w-full p-4 flex items-center justify-between"
            >
              <div className="text-left">
                <div className="text-xs font-medium text-muted-foreground">Who</div>
                <div className={cn("text-base font-medium", guests.adults + guests.children + guests.infants > 0 ? "text-foreground" : "text-muted-foreground")}>
                  {getGuestsDisplayText()}
                </div>
              </div>
            </button>

            <div className={cn(
              "overflow-hidden transition-all duration-300",
              activeSection === "guests" ? "max-h-[400px] opacity-100" : "max-h-0 opacity-0"
            )}>
              <div className="px-4 pb-4 space-y-4">
                {/* Adults */}
                <div className="flex items-center justify-between py-3">
                  <div>
                    <div className="font-medium text-foreground">Adults</div>
                    <div className="text-sm text-muted-foreground">Ages 13 or above</div>
                  </div>
                  <div className="flex items-center gap-3">
                    <Button
                      variant="outline"
                      size="icon"
                      type="button"
                      className="h-8 w-8 rounded-full"
                      onClick={() => onGuestsChange({ ...guests, adults: Math.max(0, guests.adults - 1) })}
                      disabled={guests.adults <= 0}
                    >
                      -
                    </Button>
                    <span className="w-6 text-center font-medium">{guests.adults}</span>
                    <Button
                      variant="outline"
                      size="icon"
                      type="button"
                      className="h-8 w-8 rounded-full"
                      onClick={() => onGuestsChange({ ...guests, adults: Math.min(10, guests.adults + 1) })}
                      disabled={guests.adults >= 10}
                    >
                      +
                    </Button>
                  </div>
                </div>

                <div className="h-px bg-border" />

                {/* Children */}
                <div className="flex items-center justify-between py-3">
                  <div>
                    <div className="font-medium text-foreground">Children</div>
                    <div className="text-sm text-muted-foreground">Ages 2 - 12</div>
                  </div>
                  <div className="flex items-center gap-3">
                    <Button
                      variant="outline"
                      size="icon"
                      type="button"
                      className="h-8 w-8 rounded-full"
                      onClick={() => onGuestsChange({ ...guests, children: Math.max(0, guests.children - 1) })}
                      disabled={guests.children <= 0}
                    >
                      -
                    </Button>
                    <span className="w-6 text-center font-medium">{guests.children}</span>
                    <Button
                      variant="outline"
                      size="icon"
                      type="button"
                      className="h-8 w-8 rounded-full"
                      onClick={() => onGuestsChange({ ...guests, children: Math.min(10, guests.children + 1) })}
                      disabled={guests.children >= 10}
                    >
                      +
                    </Button>
                  </div>
                </div>

                <div className="h-px bg-border" />

                {/* Infants */}
                <div className="flex items-center justify-between py-3">
                  <div>
                    <div className="font-medium text-foreground">Infants</div>
                    <div className="text-sm text-muted-foreground">Under 2</div>
                  </div>
                  <div className="flex items-center gap-3">
                    <Button
                      variant="outline"
                      size="icon"
                      type="button"
                      className="h-8 w-8 rounded-full"
                      onClick={() => onGuestsChange({ ...guests, infants: Math.max(0, guests.infants - 1) })}
                      disabled={guests.infants <= 0}
                    >
                      -
                    </Button>
                    <span className="w-6 text-center font-medium">{guests.infants}</span>
                    <Button
                      variant="outline"
                      size="icon"
                      type="button"
                      className="h-8 w-8 rounded-full"
                      onClick={() => onGuestsChange({ ...guests, infants: Math.min(5, guests.infants + 1) })}
                      disabled={guests.infants >= 5}
                    >
                      +
                    </Button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-border flex items-center justify-between gap-4 bg-background">
          <button
            type="button"
            onClick={handleClearAll}
            className="text-sm font-medium text-foreground underline underline-offset-2"
          >
            Clear all
          </button>
          <Button onClick={handleSearchClick} className="h-12 px-6 gap-2">
            <Search className="h-5 w-5" />
            Search
          </Button>
        </div>
      </div>
    </div>,
    document.body
  );
}
