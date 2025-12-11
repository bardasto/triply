"use client";

import { useRef, useEffect, useState } from "react";
import Lottie, { type LottieRefCurrentProps } from "lottie-react";
import { cn } from "@/lib/utils";

// Import all animation data statically for better performance
import homeAnimation from "../../../public/icons/lottie/home.json";
import searchAnimation from "../../../public/icons/lottie/search.json";
import profileAnimation from "../../../public/icons/lottie/profile.json";
import myTripsAnimation from "../../../public/icons/lottie/my_trips.json";
import aiChatAnimation from "../../../public/icons/lottie/ai_chat_for_all.json";
import filterAnimation from "../../../public/icons/lottie/filter.json";
import calendarAnimation from "../../../public/icons/lottie/calendar.json";
import settingsAnimation from "../../../public/icons/lottie/settings.json";
import shareAnimation from "../../../public/icons/lottie/share.json";
import mapAnimation from "../../../public/icons/lottie/mapforsearch.json";

// Map icon names to animation data
const animations = {
  home: homeAnimation,
  search: searchAnimation,
  profile: profileAnimation,
  myTrips: myTripsAnimation,
  aiChat: aiChatAnimation,
  filter: filterAnimation,
  calendar: calendarAnimation,
  settings: settingsAnimation,
  share: shareAnimation,
  map: mapAnimation,
  explore: myTripsAnimation, // Reuse my_trips for explore (heart/favorites)
} as const;

export type LottieIconName = keyof typeof animations;

interface LottieIconProps {
  name: LottieIconName;
  size?: number;
  className?: string;
  isActive?: boolean;
  playOnHover?: boolean;
  playOnce?: boolean;
  color?: string;
}

export function LottieIcon({
  name,
  size = 24,
  className,
  isActive = false,
  playOnHover = true,
  playOnce = true,
  color,
}: LottieIconProps) {
  const lottieRef = useRef<LottieRefCurrentProps>(null);
  const [isHovered, setIsHovered] = useState(false);
  const hasPlayedRef = useRef(false);

  const animationData = animations[name];

  // Play animation on hover
  useEffect(() => {
    if (!lottieRef.current) return;

    if (playOnHover && isHovered) {
      if (playOnce && hasPlayedRef.current) return;
      lottieRef.current.goToAndPlay(0);
      hasPlayedRef.current = true;
    }
  }, [isHovered, playOnHover, playOnce]);

  // Play animation when becoming active
  useEffect(() => {
    if (!lottieRef.current) return;

    if (isActive) {
      lottieRef.current.goToAndPlay(0);
    }
  }, [isActive]);

  // Reset played state when not hovered
  useEffect(() => {
    if (!isHovered && playOnce) {
      // Reset after a delay to allow re-triggering on next hover
      const timer = setTimeout(() => {
        hasPlayedRef.current = false;
      }, 500);
      return () => clearTimeout(timer);
    }
  }, [isHovered, playOnce]);

  return (
    <div
      className={cn("flex items-center justify-center", className)}
      style={{ width: size, height: size }}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      <Lottie
        lottieRef={lottieRef}
        animationData={animationData}
        loop={false}
        autoplay={false}
        style={{
          width: size,
          height: size,
          filter: color ? `drop-shadow(0 0 0 ${color})` : undefined,
        }}
        className={cn(
          "transition-opacity",
          isActive ? "opacity-100" : "opacity-80"
        )}
      />
    </div>
  );
}
