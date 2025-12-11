"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import { createPortal } from "react-dom";
import { ChevronLeft, ChevronRight, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/button";
import { LottieIcon, type SearchIconName } from "@/components/ui/lottie-icon";
import { cn } from "@/lib/utils";

const months = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
];

const weekDays = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"];

interface DateValue {
  startDate: Date | null;
  endDate: Date | null;
  flexible: boolean;
}

interface DatePickerProps {
  value: DateValue;
  onChange: (value: DateValue) => void;
  isOpen: boolean;
  onOpenChange: (open: boolean) => void;
  compact?: boolean;
}

function getDaysInMonth(year: number, month: number) {
  return new Date(year, month + 1, 0).getDate();
}

function getFirstDayOfMonth(year: number, month: number) {
  const day = new Date(year, month, 1).getDay();
  return day === 0 ? 6 : day - 1;
}

export function DatePicker({ value, onChange, isOpen, onOpenChange, compact = false }: DatePickerProps) {
  const today = new Date();
  const [currentMonth, setCurrentMonth] = useState(today.getMonth());
  const [currentYear, setCurrentYear] = useState(today.getFullYear());
  const [selecting, setSelecting] = useState<"start" | "end">("start");
  const [mounted, setMounted] = useState(false);
  const [dropdownPosition, setDropdownPosition] = useState<{ top: number; left: number } | null>(null);
  const triggerRef = useRef<HTMLDivElement>(null);
  const dropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setMounted(true);
  }, []);

  // Update position on scroll and when open
  useEffect(() => {
    const updatePosition = () => {
      if (isOpen && triggerRef.current) {
        const rect = triggerRef.current.getBoundingClientRect();
        setDropdownPosition({
          top: rect.bottom + 8,
          left: rect.left + rect.width / 2 - 170,
        });
      }
    };

    if (isOpen) {
      updatePosition();
      window.addEventListener("scroll", updatePosition, { passive: true });
      window.addEventListener("resize", updatePosition, { passive: true });
      return () => {
        window.removeEventListener("scroll", updatePosition);
        window.removeEventListener("resize", updatePosition);
      };
    } else {
      setDropdownPosition(null);
    }
  }, [isOpen]);

  const handleClickOutside = useCallback((event: MouseEvent) => {
    const target = event.target as Element;

    // Check if click was on trigger
    if (triggerRef.current?.contains(target)) {
      return;
    }

    // Check if click was inside dropdown using data attribute
    if (target.closest('[data-dropdown-content="date"]')) {
      return;
    }

    onOpenChange(false);
  }, [onOpenChange]);

  useEffect(() => {
    if (isOpen) {
      // Small delay to ensure Portal has rendered
      const timeoutId = setTimeout(() => {
        document.addEventListener("mousedown", handleClickOutside);
      }, 10);
      return () => {
        clearTimeout(timeoutId);
        document.removeEventListener("mousedown", handleClickOutside);
      };
    }
  }, [isOpen, handleClickOutside]);

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

  const handleDateClick = (day: number) => {
    const clickedDate = new Date(currentYear, currentMonth, day);

    if (value.flexible) {
      onChange({ startDate: clickedDate, endDate: null, flexible: false });
      setSelecting("end");
      return;
    }

    if (selecting === "start" || !value.startDate) {
      onChange({ startDate: clickedDate, endDate: null, flexible: false });
      setSelecting("end");
    } else {
      if (clickedDate < value.startDate) {
        onChange({ startDate: clickedDate, endDate: value.startDate, flexible: false });
      } else {
        onChange({ ...value, endDate: clickedDate });
      }
      setSelecting("start");
    }
  };

  const handleFlexible = () => {
    onChange({ startDate: null, endDate: null, flexible: true });
    onOpenChange(false);
  };

  const isDateDisabled = (day: number) => {
    const date = new Date(currentYear, currentMonth, day);
    const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    return date < todayStart;
  };

  const isDateSelected = (day: number) => {
    if (!value.startDate) return false;
    const date = new Date(currentYear, currentMonth, day);
    const dateTime = date.getTime();

    if (value.startDate && dateTime === value.startDate.getTime()) return "start";
    if (value.endDate && dateTime === value.endDate.getTime()) return "end";
    return false;
  };

  const isDateInRange = (day: number) => {
    if (!value.startDate || !value.endDate) return false;
    const date = new Date(currentYear, currentMonth, day);
    return date > value.startDate && date < value.endDate;
  };

  const getDisplayText = () => {
    if (value.flexible) return "I'm flexible";
    if (value.startDate && value.endDate) {
      const start = value.startDate.toLocaleDateString("en-US", { month: "short", day: "numeric" });
      const end = value.endDate.toLocaleDateString("en-US", { month: "short", day: "numeric" });
      return `${start} - ${end}`;
    }
    if (value.startDate) {
      return value.startDate.toLocaleDateString("en-US", { month: "short", day: "numeric" });
    }
    return "Add dates";
  };

  const renderCalendar = () => {
    const daysInMonth = getDaysInMonth(currentYear, currentMonth);
    const firstDay = getFirstDayOfMonth(currentYear, currentMonth);
    const days = [];

    for (let i = 0; i < firstDay; i++) {
      days.push(<div key={`empty-${i}`} className="h-9 w-9" />);
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
            "h-9 w-9 rounded-full text-sm font-medium transition-all flex items-center justify-center",
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

  const canGoPrev = !(currentYear === today.getFullYear() && currentMonth === today.getMonth());

  const dropdown = isOpen && mounted && dropdownPosition ? createPortal(
    <div
      ref={dropdownRef}
      data-dropdown-content="date"
      className="fixed bg-background rounded-3xl shadow-2xl border border-border overflow-hidden z-[9999]"
      style={{ top: dropdownPosition.top, left: dropdownPosition.left }}
      onMouseDown={(e) => e.stopPropagation()}
    >
      <div className="p-5">
        {/* Flexible Button */}
        <button
          type="button"
          onClick={handleFlexible}
          className={cn(
            "w-full flex items-center justify-center gap-2 py-2.5 px-4 rounded-full border-2 transition-all mb-4",
            value.flexible
              ? "border-primary bg-primary/10 text-primary"
              : "border-border hover:border-primary/50 text-muted-foreground hover:text-foreground"
          )}
        >
          <Sparkles className="h-4 w-4" />
          <span className="font-medium text-sm">I'm flexible</span>
        </button>

        {/* Single Month Calendar */}
        <div className="w-[280px]">
          <div className="flex items-center justify-between mb-3">
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
              <div key={day} className="h-9 w-9 flex items-center justify-center text-xs text-muted-foreground font-medium">
                {day}
              </div>
            ))}
          </div>
          <div className="grid grid-cols-7 gap-1">
            {renderCalendar()}
          </div>
        </div>
      </div>
    </div>,
    document.body
  ) : null;

  return (
    <div className="relative">
      {/* Trigger */}
      <div
        ref={triggerRef}
        className={cn(
          "flex items-center gap-2 cursor-pointer rounded-full transition-colors",
          compact ? "px-2 py-1" : "px-4 py-3",
          isOpen && "bg-muted/50"
        )}
        onClick={() => onOpenChange(!isOpen)}
      >
        <LottieIcon variant="search" name="calendar" size={compact ? 20 : 24} playOnHover isActive={isOpen} />
        <div className="flex-1 min-w-0">
          <div className={cn("font-medium text-foreground", compact ? "text-[10px]" : "text-xs")}>When</div>
          <div className={cn(
            "text-sm",
            value.startDate || value.flexible ? "text-foreground" : "text-muted-foreground"
          )}>
            {getDisplayText()}
          </div>
        </div>
      </div>

      {dropdown}
    </div>
  );
}
