"use client";

import { useRef, useEffect, useState } from "react";
import Lottie, { type LottieRefCurrentProps } from "lottie-react";
import { cn } from "@/lib/utils";

// Dock icons (white)
import dockHome from "../../../public/icons/lottie/dock/home.json";
import dockExplore from "../../../public/icons/lottie/dock/explore.json";
import dockAiChat from "../../../public/icons/lottie/dock/aiChat.json";
import dockMyTrips from "../../../public/icons/lottie/dock/myTrips.json";
import dockProfile from "../../../public/icons/lottie/dock/profile.json";

// Header white icons (inactive state)
import headerWhiteHome from "../../../public/icons/lottie/header-white/home.json";
import headerWhiteExplore from "../../../public/icons/lottie/header-white/explore.json";
import headerWhiteAiChat from "../../../public/icons/lottie/header-white/aiChat.json";
import headerWhiteMyTrips from "../../../public/icons/lottie/header-white/myTrips.json";
import headerWhiteProfile from "../../../public/icons/lottie/header-white/profile.json";

// Header purple icons (active/hover state)
import headerPurpleHome from "../../../public/icons/lottie/header-purple/home.json";
import headerPurpleExplore from "../../../public/icons/lottie/header-purple/explore.json";
import headerPurpleAiChat from "../../../public/icons/lottie/header-purple/aiChat.json";
import headerPurpleMyTrips from "../../../public/icons/lottie/header-purple/myTrips.json";
import headerPurpleProfile from "../../../public/icons/lottie/header-purple/profile.json";

// Search icons (purple/orange)
import searchIcon from "../../../public/icons/lottie/search/search.json";
import searchCalendar from "../../../public/icons/lottie/search/calendar.json";
import searchMap from "../../../public/icons/lottie/search/map.json";
import searchUsers from "../../../public/icons/lottie/search/users.json";
import searchAiChat from "../../../public/icons/lottie/search/aiChat.json";

// Legacy icons (keep for backward compatibility)
import filterAnimation from "../../../public/icons/lottie/filter.json";
import settingsAnimation from "../../../public/icons/lottie/settings.json";
import shareAnimation from "../../../public/icons/lottie/share.json";

// Icon sets organized by variant
const dockIcons = {
  home: dockHome,
  explore: dockExplore,
  aiChat: dockAiChat,
  myTrips: dockMyTrips,
  profile: dockProfile,
} as const;

const headerWhiteIcons = {
  home: headerWhiteHome,
  explore: headerWhiteExplore,
  aiChat: headerWhiteAiChat,
  myTrips: headerWhiteMyTrips,
  profile: headerWhiteProfile,
} as const;

const headerPurpleIcons = {
  home: headerPurpleHome,
  explore: headerPurpleExplore,
  aiChat: headerPurpleAiChat,
  myTrips: headerPurpleMyTrips,
  profile: headerPurpleProfile,
} as const;

const searchIcons = {
  search: searchIcon,
  calendar: searchCalendar,
  map: searchMap,
  users: searchUsers,
  aiChat: searchAiChat,
} as const;

const miscIcons = {
  filter: filterAnimation,
  settings: settingsAnimation,
  share: shareAnimation,
} as const;

export type LottieIconVariant = "dock" | "header" | "search" | "misc";
export type DockIconName = keyof typeof dockIcons;
export type HeaderIconName = keyof typeof headerWhiteIcons;
export type SearchIconName = keyof typeof searchIcons;
export type MiscIconName = keyof typeof miscIcons;

interface BaseLottieIconProps {
  size?: number;
  className?: string;
  isActive?: boolean;
  isHovered?: boolean;
  playOnHover?: boolean;
  playOnce?: boolean;
}

interface DockLottieIconProps extends BaseLottieIconProps {
  variant: "dock";
  name: DockIconName;
}

interface HeaderLottieIconProps extends BaseLottieIconProps {
  variant: "header";
  name: HeaderIconName;
}

interface SearchLottieIconProps extends BaseLottieIconProps {
  variant: "search";
  name: SearchIconName;
}

interface MiscLottieIconProps extends BaseLottieIconProps {
  variant: "misc";
  name: MiscIconName;
}

export type LottieIconProps =
  | DockLottieIconProps
  | HeaderLottieIconProps
  | SearchLottieIconProps
  | MiscLottieIconProps;

function getAnimationData(props: LottieIconProps, isActiveOrHovered: boolean) {
  switch (props.variant) {
    case "dock":
      return dockIcons[props.name];
    case "header":
      // Use purple icon when active or hovered, white otherwise
      return isActiveOrHovered
        ? headerPurpleIcons[props.name]
        : headerWhiteIcons[props.name];
    case "search":
      return searchIcons[props.name];
    case "misc":
      return miscIcons[props.name];
  }
}

export function LottieIcon(props: LottieIconProps) {
  const {
    size = 24,
    className,
    isActive = false,
    isHovered: externalIsHovered,
    playOnHover = true,
    playOnce = true,
  } = props;

  const lottieRef = useRef<LottieRefCurrentProps>(null);
  const [internalIsHovered, setInternalIsHovered] = useState(false);
  const hasPlayedRef = useRef(false);
  const prevActiveOrHoveredRef = useRef(false);

  // Use external hover state if provided, otherwise use internal
  const isHovered = externalIsHovered ?? internalIsHovered;
  const isActiveOrHovered = isActive || isHovered;

  const animationData = getAnimationData(props, isActiveOrHovered);

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

    if (isActive && !prevActiveOrHoveredRef.current) {
      lottieRef.current.goToAndPlay(0);
    }
    prevActiveOrHoveredRef.current = isActive;
  }, [isActive]);

  // Reset played state when not hovered
  useEffect(() => {
    if (!isHovered && playOnce) {
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
      onMouseEnter={() => setInternalIsHovered(true)}
      onMouseLeave={() => setInternalIsHovered(false)}
    >
      <Lottie
        lottieRef={lottieRef}
        animationData={animationData}
        loop={false}
        autoplay={false}
        style={{
          width: size,
          height: size,
        }}
        className={cn(
          "transition-opacity",
          isActive ? "opacity-100" : "opacity-80"
        )}
      />
    </div>
  );
}
