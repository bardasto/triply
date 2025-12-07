"use client";

import { useState, useCallback, useRef, useEffect } from "react";
import { cn } from "@/lib/utils";

interface DraggableBottomSheetProps {
  isOpen: boolean;
  onClose: () => void;
  children: React.ReactNode;
}

export function DraggableBottomSheet({
  isOpen,
  onClose,
  children,
}: DraggableBottomSheetProps) {
  const sheetRef = useRef<HTMLDivElement>(null);
  const contentRef = useRef<HTMLDivElement>(null);
  const [dragOffset, setDragOffset] = useState(0);
  const [isDragging, setIsDragging] = useState(false);
  const [isClosing, setIsClosing] = useState(false);
  const startYRef = useRef(0);
  const currentYRef = useRef(0);
  const isAtTopRef = useRef(true);

  const sheetHeight = typeof window !== "undefined" ? window.innerHeight * 0.85 : 600;
  const closeThreshold = sheetHeight * 0.5;

  // Reset state when opening - using layout effect for synchronous update
  useEffect(() => {
    if (isOpen) {
      // Reset synchronously before render
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [isOpen]);

  // Reset drag state when opening
  const prevIsOpen = useRef(isOpen);
  if (isOpen && !prevIsOpen.current) {
    // Just opened - reset state
    if (dragOffset !== 0) setDragOffset(0);
    if (isClosing) setIsClosing(false);
  }
  prevIsOpen.current = isOpen;

  const handleTouchStart = useCallback((e: React.TouchEvent) => {
    const contentEl = contentRef.current;
    if (contentEl) {
      isAtTopRef.current = contentEl.scrollTop <= 0;
    }
    startYRef.current = e.touches[0].clientY;
    currentYRef.current = e.touches[0].clientY;
  }, []);

  const handleTouchMove = useCallback((e: React.TouchEvent) => {
    const contentEl = contentRef.current;
    if (contentEl) {
      isAtTopRef.current = contentEl.scrollTop <= 0;
    }

    currentYRef.current = e.touches[0].clientY;
    const deltaY = currentYRef.current - startYRef.current;

    if (deltaY > 0 && isAtTopRef.current) {
      e.preventDefault();
      setIsDragging(true);
      setDragOffset(deltaY);
    } else if (isDragging && deltaY <= 0) {
      setIsDragging(false);
      setDragOffset(0);
    }
  }, [isDragging]);

  const handleTouchEnd = useCallback(() => {
    if (!isDragging) return;

    setIsDragging(false);

    if (dragOffset > closeThreshold) {
      setIsClosing(true);
      setDragOffset(sheetHeight);
      setTimeout(() => {
        onClose();
        setDragOffset(0);
        setIsClosing(false);
      }, 300);
    } else {
      setDragOffset(0);
    }
  }, [isDragging, dragOffset, closeThreshold, sheetHeight, onClose]);

  const handleBackdropClick = useCallback(() => {
    setIsClosing(true);
    setDragOffset(sheetHeight);
    setTimeout(() => {
      onClose();
      setDragOffset(0);
      setIsClosing(false);
    }, 300);
  }, [sheetHeight, onClose]);

  if (!isOpen && !isClosing) return null;

  const translateY = dragOffset;
  const backdropOpacity = Math.max(0, 1 - dragOffset / sheetHeight);

  return (
    <div className="fixed inset-0 z-100">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/50 transition-opacity duration-300"
        style={{ opacity: backdropOpacity }}
        onClick={handleBackdropClick}
      />

      {/* Sheet */}
      <div
        ref={sheetRef}
        className={cn(
          "absolute inset-x-0 bottom-0 bg-background rounded-t-3xl border-t border-white/10 overflow-hidden",
          !isDragging && !isClosing && "transition-transform duration-300 ease-out"
        )}
        style={{
          height: `${sheetHeight}px`,
          transform: `translateY(${translateY}px)`,
        }}
        onTouchStart={handleTouchStart}
        onTouchMove={handleTouchMove}
        onTouchEnd={handleTouchEnd}
      >
        <div
          ref={contentRef}
          className="h-full overflow-y-auto overscroll-contain"
          style={{
            touchAction: isDragging ? "none" : "pan-y",
          }}
        >
          {children}
        </div>
      </div>
    </div>
  );
}
