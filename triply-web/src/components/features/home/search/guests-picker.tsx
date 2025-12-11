"use client";

import { useEffect, useRef, useState, useCallback } from "react";
import { createPortal } from "react-dom";
import { Minus, Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { LottieIcon } from "@/components/ui/lottie-icon";
import { cn } from "@/lib/utils";

interface GuestsValue {
  adults: number;
  children: number;
  infants: number;
}

interface GuestsPickerProps {
  value: GuestsValue;
  onChange: (value: GuestsValue) => void;
  isOpen: boolean;
  onOpenChange: (open: boolean) => void;
  compact?: boolean;
}

interface CounterRowProps {
  label: string;
  description: string;
  value: number;
  onChange: (value: number) => void;
  min?: number;
  max?: number;
}

function CounterRow({ label, description, value, onChange, min = 0, max = 10 }: CounterRowProps) {
  return (
    <div className="flex items-center justify-between py-4">
      <div>
        <div className="font-medium text-foreground">{label}</div>
        <div className="text-sm text-muted-foreground">{description}</div>
      </div>
      <div className="flex items-center gap-3">
        <Button
          variant="outline"
          size="icon"
          type="button"
          className="h-8 w-8 rounded-full"
          onClick={() => onChange(Math.max(min, value - 1))}
          disabled={value <= min}
        >
          <Minus className="h-4 w-4" />
        </Button>
        <span className="w-6 text-center font-medium text-foreground">{value}</span>
        <Button
          variant="outline"
          size="icon"
          type="button"
          className="h-8 w-8 rounded-full"
          onClick={() => onChange(Math.min(max, value + 1))}
          disabled={value >= max}
        >
          <Plus className="h-4 w-4" />
        </Button>
      </div>
    </div>
  );
}

export function GuestsPicker({ value, onChange, isOpen, onOpenChange, compact = false }: GuestsPickerProps) {
  const [mounted, setMounted] = useState(false);
  const [dropdownPosition, setDropdownPosition] = useState<{ top: number; right: number } | null>(null);
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
        // Find the search container to align with its right edge
        const searchContainer = triggerRef.current.closest('[class*="max-w-4xl"]');
        const containerRect = searchContainer?.getBoundingClientRect();

        setDropdownPosition({
          top: rect.bottom + 8,
          // Align with search container right edge if available, otherwise with trigger
          right: containerRect
            ? window.innerWidth - containerRect.right + 8
            : window.innerWidth - rect.right,
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
    if (target.closest('[data-dropdown-content="guests"]')) {
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

  const totalGuests = value.adults + value.children + value.infants;

  const getDisplayText = () => {
    if (totalGuests === 0) return "Add guests";

    const parts = [];
    if (value.adults > 0) {
      parts.push(`${value.adults} adult${value.adults > 1 ? "s" : ""}`);
    }
    if (value.children > 0) {
      parts.push(`${value.children} child${value.children > 1 ? "ren" : ""}`);
    }
    if (value.infants > 0) {
      parts.push(`${value.infants} infant${value.infants > 1 ? "s" : ""}`);
    }
    return parts.join(", ");
  };

  const handleChange = (key: keyof GuestsValue, newValue: number) => {
    onChange({ ...value, [key]: newValue });
  };

  const dropdown = isOpen && mounted && dropdownPosition ? createPortal(
    <div
      ref={dropdownRef}
      data-dropdown-content="guests"
      className="fixed w-[320px] bg-background rounded-3xl shadow-2xl border border-border overflow-hidden z-[9999]"
      style={{ top: dropdownPosition.top, right: dropdownPosition.right }}
      onMouseDown={(e) => e.stopPropagation()}
    >
      <div className="p-5">
        <CounterRow
          label="Adults"
          description="Ages 13 or above"
          value={value.adults}
          onChange={(v) => handleChange("adults", v)}
        />

        <div className="border-t border-border" />

        <CounterRow
          label="Children"
          description="Ages 2 - 12"
          value={value.children}
          onChange={(v) => handleChange("children", v)}
        />

        <div className="border-t border-border" />

        <CounterRow
          label="Infants"
          description="Under 2"
          value={value.infants}
          onChange={(v) => handleChange("infants", v)}
          max={5}
        />
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
        <LottieIcon name="users" size={compact ? 16 : 20} playOnHover isActive={isOpen} />
        <div className="flex-1 min-w-0">
          <div className={cn("font-medium text-foreground", compact ? "text-[10px]" : "text-xs")}>Who</div>
          <div className={cn(
            "text-sm truncate",
            totalGuests > 0 ? "text-foreground" : "text-muted-foreground"
          )}>
            {getDisplayText()}
          </div>
        </div>
      </div>

      {dropdown}
    </div>
  );
}
