"use client";

import { useState, useEffect, useRef } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { LottieIcon, type LottieIconName } from "@/components/ui/lottie-icon";
import { cn } from "@/lib/utils";
import {
  motion,
  useMotionValue,
  useSpring,
  useTransform,
  AnimatePresence,
  type MotionValue,
} from "framer-motion";

// Navigation items - left and right of center button
const leftNavItems = [
  { name: "Home", href: "/", lottieIcon: "home" as LottieIconName },
  { name: "Explore", href: "/explore", lottieIcon: "explore" as LottieIconName },
];

const rightNavItems = [
  { name: "My Trips", href: "/trips", lottieIcon: "myTrips" as LottieIconName },
  { name: "Profile", href: "/profile", lottieIcon: "profile" as LottieIconName },
];

// Animation constants
const MAGNIFICATION = 1.5;
const DISTANCE = 100;
const SPRING_CONFIG = {
  mass: 0.1,
  stiffness: 150,
  damping: 12,
};

// Apple-style spring for dock appearance - faster and snappier
const DOCK_SPRING = {
  type: "spring" as const,
  stiffness: 500,
  damping: 35,
};

function DockIcon({
  mouseX,
  item,
  isActive,
  index,
  side,
  isExpanded,
}: {
  mouseX: MotionValue<number>;
  item: { name: string; href: string; lottieIcon: LottieIconName };
  isActive: boolean;
  index: number;
  side: "left" | "right";
  isExpanded: boolean;
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

  // Calculate staggered delay - items closer to center animate first
  const staggerDelay = side === "left"
    ? (leftNavItems.length - 1 - index) * 0.03
    : index * 0.03;

  return (
    <motion.div
      initial={false}
      animate={isExpanded ? {
        x: 0,
        opacity: 1,
        scale: 1,
      } : {
        x: side === "left" ? 60 : -60,
        opacity: 0,
        scale: 0.6,
      }}
      transition={{
        type: "spring",
        stiffness: 600,
        damping: 35,
        delay: isExpanded ? staggerDelay : 0,
      }}
    >
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
          <LottieIcon
            name={item.lottieIcon}
            size={24}
            isActive={isActive || isHovered}
            playOnHover
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
    </motion.div>
  );
}

function CenterDockIcon({
  href,
  isActive,
}: {
  href: string;
  isActive: boolean;
}) {
  const [isHovered, setIsHovered] = useState(false);
  const scale = useSpring(1, SPRING_CONFIG);

  return (
    <Link
      href={href}
      onMouseEnter={() => { setIsHovered(true); scale.set(MAGNIFICATION); }}
      onMouseLeave={() => { setIsHovered(false); scale.set(1); }}
      className="absolute left-1/2 -translate-x-1/2 -top-5 z-10 flex items-center justify-center"
    >
      <motion.div
        style={{ scale }}
        className={cn(
          "flex items-center justify-center w-14 h-14 rounded-full shadow-lg",
          "origin-center",
          isActive ? "bg-primary/90" : "bg-primary"
        )}
      >
        <LottieIcon
          name="aiChat"
          size={28}
          isActive={isActive || isHovered}
          playOnHover
        />
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
  const [isVisible, setIsVisible] = useState(false);
  const [isExpanded, setIsExpanded] = useState(false);
  const pathname = usePathname();

  const mouseX = useMotionValue(Infinity);

  // Scroll-triggered visibility on both mobile and desktop
  useEffect(() => {
    const handleScroll = () => {
      const isMobile = window.innerWidth < 768;
      // Lower threshold on mobile for better UX
      const threshold = isMobile ? 50 : 100;
      setIsVisible(window.scrollY > threshold);
    };

    handleScroll();
    window.addEventListener("scroll", handleScroll, { passive: true });
    window.addEventListener("resize", handleScroll, { passive: true });
    return () => {
      window.removeEventListener("scroll", handleScroll);
      window.removeEventListener("resize", handleScroll);
    };
  }, []);

  // Trigger expansion after dock becomes visible
  useEffect(() => {
    if (isVisible) {
      // Minimal delay for smoother sync
      const timer = setTimeout(() => {
        setIsExpanded(true);
      }, 50);
      return () => clearTimeout(timer);
    } else {
      setIsExpanded(false);
    }
  }, [isVisible]);

  return (
    <AnimatePresence>
      {isVisible && (
        <motion.div
          initial={{ y: 100, opacity: 0, scale: 0.8 }}
          animate={{ y: 0, opacity: 1, scale: 1 }}
          exit={{ y: 100, opacity: 0, scale: 0.8 }}
          transition={DOCK_SPRING}
          className="fixed bottom-6 md:bottom-8 left-1/2 -translate-x-1/2 z-50"
        >
          <motion.div
            onMouseMove={(e) => mouseX.set(e.pageX)}
            onMouseLeave={() => mouseX.set(Infinity)}
            className="relative"
          >
            {/* SVG Background with notch and blur */}
            <motion.div
              className="relative"
              initial={{ scaleX: 0.4 }}
              animate={{ scaleX: 1 }}
              transition={DOCK_SPRING}
            >
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
            </motion.div>

            {/* Center AI Button */}
            <CenterDockIcon
              href="/chat"
              isActive={pathname === "/chat"}
            />

            {/* Navigation Items */}
            <div className="absolute inset-0 flex items-center justify-between px-5 pointer-events-none">
              {/* Left items */}
              <div className="flex items-center gap-4 pointer-events-auto">
                {leftNavItems.map((item, index) => (
                  <DockIcon
                    key={item.name}
                    mouseX={mouseX}
                    item={item}
                    isActive={pathname === item.href}
                    index={index}
                    side="left"
                    isExpanded={isExpanded}
                  />
                ))}
              </div>

              {/* Center space for the button */}
              <div className="w-20" />

              {/* Right items */}
              <div className="flex items-center gap-4 pointer-events-auto">
                {rightNavItems.map((item, index) => (
                  <DockIcon
                    key={item.name}
                    mouseX={mouseX}
                    item={item}
                    isActive={pathname === item.href}
                    index={index}
                    side="right"
                    isExpanded={isExpanded}
                  />
                ))}
              </div>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
