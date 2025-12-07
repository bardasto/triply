"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, Heart, Map, User } from "lucide-react";
import { GeminiIcon } from "@/components/ui/gemini-icon";
import { cn } from "@/lib/utils";
import {
  motion,
  useMotionValue,
  useSpring,
  useTransform,
  type MotionValue,
} from "framer-motion";

// Navigation items - left and right of center button
const leftNavItems = [
  { name: "Home", href: "/", icon: Home },
  { name: "Explore", href: "/explore", icon: Heart },
];

const rightNavItems = [
  { name: "My Trips", href: "/trips", icon: Map },
  { name: "Profile", href: "/profile", icon: User },
];

// Animation constants
const MAGNIFICATION = 1.5;
const DISTANCE = 100;
const SPRING_CONFIG = {
  mass: 0.1,
  stiffness: 150,
  damping: 12,
};

function DockIcon({
  mouseX,
  item,
  isActive,
}: {
  mouseX: MotionValue<number>;
  item: { name: string; href: string; icon: React.ElementType };
  isActive: boolean;
}) {
  const ref = useRef<HTMLAnchorElement>(null);
  const [isHovered, setIsHovered] = useState(false);

  const distance = useTransform(mouseX, (val) => {
    const bounds = ref.current?.getBoundingClientRect() ?? { x: 0, width: 0 };
    return val - bounds.x - bounds.width / 2;
  });

  const scaleSync = useTransform(
    distance,
    [-DISTANCE, 0, DISTANCE],
    [1, MAGNIFICATION, 1]
  );
  const scale = useSpring(scaleSync, SPRING_CONFIG);

  const Icon = item.icon;

  return (
    <Link
      ref={ref}
      href={item.href}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      className="relative flex items-center justify-center"
    >
      <motion.div
        style={{ scale }}
        className={cn(
          "flex items-center justify-center w-10 h-10 rounded-full transition-colors",
          "origin-bottom"
        )}
      >
        <Icon
          className={cn(
            "h-6 w-6 transition-colors",
            isActive ? "text-primary" : "text-white/80"
          )}
        />
      </motion.div>

      {/* Tooltip */}
      <motion.span
        initial={{ opacity: 0, y: 0, scale: 0.8 }}
        animate={isHovered ? { opacity: 1, y: -8, scale: 1 } : { opacity: 0, y: 0, scale: 0.8 }}
        transition={{ type: "spring", stiffness: 300, damping: 20 }}
        className="absolute -top-10 left-1/2 -translate-x-1/2 px-2.5 py-1 rounded-lg bg-white text-black text-xs font-medium whitespace-nowrap pointer-events-none shadow-lg"
      >
        {item.name}
      </motion.span>
    </Link>
  );
}

function CenterDockIcon({
  href,
  isActive,
}: {
  href: string;
  isActive: boolean;
}) {
  const buttonRef = useRef<HTMLAnchorElement>(null);
  const [isHovered, setIsHovered] = useState(false);
  const [clipPath, setClipPath] = useState('circle(0% at 50% 50%)');
  const scale = useSpring(1, SPRING_CONFIG);

  const handleMouseEnter = useCallback((event: React.MouseEvent<HTMLAnchorElement>) => {
    setIsHovered(true);
    scale.set(MAGNIFICATION);

    if (!buttonRef.current) return;
    const rect = buttonRef.current.getBoundingClientRect();
    const x = ((event.clientX - rect.left) / rect.width) * 100;
    const y = ((event.clientY - rect.top) / rect.height) * 100;
    setClipPath(`circle(0% at ${x}% ${y}%)`);

    requestAnimationFrame(() => {
      setClipPath(`circle(150% at ${x}% ${y}%)`);
    });
  }, [scale]);

  const handleMouseLeave = useCallback((event: React.MouseEvent<HTMLAnchorElement>) => {
    setIsHovered(false);
    scale.set(1);

    if (!buttonRef.current) return;
    const rect = buttonRef.current.getBoundingClientRect();
    const x = ((event.clientX - rect.left) / rect.width) * 100;
    const y = ((event.clientY - rect.top) / rect.height) * 100;
    setClipPath(`circle(0% at ${x}% ${y}%)`);
  }, [scale]);

  const handleMouseMove = useCallback((event: React.MouseEvent<HTMLAnchorElement>) => {
    if (!buttonRef.current || !isHovered) return;
    const rect = buttonRef.current.getBoundingClientRect();
    const x = ((event.clientX - rect.left) / rect.width) * 100;
    const y = ((event.clientY - rect.top) / rect.height) * 100;

    // Keep the expanded size while updating position
    setClipPath(`circle(150% at ${x}% ${y}%)`);
  }, [isHovered]);

  return (
    <Link
      ref={buttonRef}
      href={href}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      onMouseMove={handleMouseMove}
      className="absolute left-1/2 -translate-x-1/2 -top-5 z-10 flex items-center justify-center"
    >
      <motion.div
        style={{ scale }}
        className={cn(
          "relative flex items-center justify-center w-14 h-14 rounded-full overflow-hidden shadow-lg",
          "origin-center"
        )}
      >
        {/* Base background - purple */}
        <div className={cn(
          "absolute inset-0 rounded-full",
          isActive ? "bg-primary/90" : "bg-primary"
        )} />

        {/* Overlay background - orange, revealed by clip-path */}
        <div
          className="absolute inset-0 rounded-full bg-accent"
          style={{
            clipPath,
            transition: 'clip-path 300ms ease-out'
          }}
        />

        {/* Icon */}
        <GeminiIcon className="relative z-10 h-6 w-6 text-white" />
      </motion.div>

      {/* Tooltip */}
      <motion.span
        initial={{ opacity: 0, y: 0, scale: 0.8 }}
        animate={isHovered ? { opacity: 1, y: -8, scale: 1 } : { opacity: 0, y: 0, scale: 0.8 }}
        transition={{ type: "spring", stiffness: 300, damping: 20 }}
        className="absolute -top-10 left-1/2 -translate-x-1/2 px-2.5 py-1 rounded-lg bg-white text-black text-xs font-medium whitespace-nowrap pointer-events-none shadow-lg"
      >
        AI Chat
      </motion.span>
    </Link>
  );
}

export function FloatingDock() {
  const [isVisible, setIsVisible] = useState(true);
  const pathname = usePathname();

  const mouseX = useMotionValue(Infinity);

  // Always visible on mobile, scroll-triggered on desktop
  useEffect(() => {
    const handleScroll = () => {
      const isMobile = window.innerWidth < 768;
      if (isMobile) {
        setIsVisible(true);
      } else {
        setIsVisible(window.scrollY > 100);
      }
    };

    handleScroll(); // Initial check
    window.addEventListener("scroll", handleScroll, { passive: true });
    window.addEventListener("resize", handleScroll, { passive: true });
    return () => {
      window.removeEventListener("scroll", handleScroll);
      window.removeEventListener("resize", handleScroll);
    };
  }, []);

  return (
    <>
      {/* Dock with Magnification Effect */}
      <motion.div
        className={cn(
          "fixed bottom-6 md:bottom-8 left-1/2 -translate-x-1/2 z-50",
          "transition-all duration-500 ease-out",
          isVisible
            ? "opacity-100 translate-y-0"
            : "opacity-0 translate-y-16 pointer-events-none"
        )}
      >
        <motion.div
          onMouseMove={(e) => mouseX.set(e.pageX)}
          onMouseLeave={() => mouseX.set(Infinity)}
          className="relative"
        >
          {/* SVG Background with notch and blur */}
          <div className="relative">
            {/* Blur backdrop */}
            <div
              className="absolute inset-0 backdrop-blur-xl rounded-[30px]"
              style={{
                clipPath: `path('M 30 0 L 100 0 Q 120 0, 130 10 Q 145 24, 160 24 Q 175 24, 190 10 Q 200 0, 220 0 L 290 0 Q 320 0, 320 30 Q 320 60, 290 60 L 30 60 Q 0 60, 0 30 Q 0 0, 30 0 Z')`,
              }}
            />
            <svg
              width="320"
              height="60"
              viewBox="0 0 320 60"
              fill="none"
              className="drop-shadow-2xl relative"
            >
              {/* Main dock shape with larger notch */}
              <path
                d="M 30 0
                   L 100 0
                   Q 120 0, 130 10
                   Q 145 24, 160 24
                   Q 175 24, 190 10
                   Q 200 0, 220 0
                   L 290 0
                   Q 320 0, 320 30
                   Q 320 60, 290 60
                   L 30 60
                   Q 0 60, 0 30
                   Q 0 0, 30 0
                   Z"
                fill="rgba(30, 30, 35, 0.7)"
              />
              {/* Border */}
              <path
                d="M 30 0
                   L 100 0
                   Q 120 0, 130 10
                   Q 145 24, 160 24
                   Q 175 24, 190 10
                   Q 200 0, 220 0
                   L 290 0
                   Q 320 0, 320 30
                   Q 320 60, 290 60
                   L 30 60
                   Q 0 60, 0 30
                   Q 0 0, 30 0
                   Z"
                fill="none"
                stroke="rgba(255, 255, 255, 0.1)"
                strokeWidth="1"
              />
            </svg>
          </div>

          {/* Center AI Button */}
          <CenterDockIcon
            href="/chat"
            isActive={pathname === "/chat"}
          />

          {/* Navigation Items */}
          <div className="absolute inset-0 flex items-center justify-between px-5 pointer-events-none">
            {/* Left items */}
            <div className="flex items-center gap-4 pointer-events-auto">
              {leftNavItems.map((item) => (
                <DockIcon
                  key={item.name}
                  mouseX={mouseX}
                  item={item}
                  isActive={pathname === item.href}
                />
              ))}
            </div>

            {/* Center space for the button */}
            <div className="w-20" />

            {/* Right items */}
            <div className="flex items-center gap-4 pointer-events-auto">
              {rightNavItems.map((item) => (
                <DockIcon
                  key={item.name}
                  mouseX={mouseX}
                  item={item}
                  isActive={pathname === item.href}
                />
              ))}
            </div>
          </div>
        </motion.div>
      </motion.div>
    </>
  );
}
