"use client";

import { useRef, useEffect, useState } from "react";
import Lottie, { type LottieRefCurrentProps } from "lottie-react";
import { cn } from "@/lib/utils";

// Hook to detect mobile
function useIsMobile() {
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    const checkMobile = () => setIsMobile(window.innerWidth < 768);
    checkMobile();
    window.addEventListener("resize", checkMobile);
    return () => window.removeEventListener("resize", checkMobile);
  }, []);

  return isMobile;
}

// Dock icons (white - inactive)
import dockHome from "../../../public/icons/lottie/dock-white/home.json";
import dockExplore from "../../../public/icons/lottie/dock-white/explore.json";
import dockAiChat from "../../../public/icons/lottie/dock-white/aiChat.json";
import dockMyTrips from "../../../public/icons/lottie/dock-white/myTrips.json";
import dockProfile from "../../../public/icons/lottie/dock-white/profile.json";

// Dock icons (purple - active)
import dockPurpleHome from "../../../public/icons/lottie/dock-purple/home.json";
import dockPurpleExplore from "../../../public/icons/lottie/dock-purple/explore.json";
import dockPurpleAiChat from "../../../public/icons/lottie/dock-purple/aiChat.json";
import dockPurpleMyTrips from "../../../public/icons/lottie/dock-purple/myTrips.json";
import dockPurpleProfile from "../../../public/icons/lottie/dock-purple/profile.json";

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

// Misc icons
import filterAnimation from "../../../public/icons/lottie/misc/filter.json";
import settingsAnimation from "../../../public/icons/lottie/misc/settings.json";
import shareAnimation from "../../../public/icons/lottie/misc/share.json";
import backAnimation from "../../../public/icons/lottie/misc/back.json";
import backPurpleAnimation from "../../../public/icons/lottie/misc/back-purple.json";
import photosAnimation from "../../../public/icons/lottie/misc/photos.json";

// Icon sets organized by variant
const dockWhiteIcons = {
  home: dockHome,
  explore: dockExplore,
  aiChat: dockAiChat,
  myTrips: dockMyTrips,
  profile: dockProfile,
} as const;

const dockPurpleIcons = {
  home: dockPurpleHome,
  explore: dockPurpleExplore,
  aiChat: dockPurpleAiChat,
  myTrips: dockPurpleMyTrips,
  profile: dockPurpleProfile,
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
  back: backAnimation,
  photos: photosAnimation,
} as const;

const miscPurpleIcons = {
  back: backPurpleAnimation,
} as const;

export type LottieIconVariant = "dock" | "header" | "search" | "misc";
export type DockIconName = keyof typeof dockWhiteIcons;
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

function getAnimationData(props: LottieIconProps, isActive: boolean, isHovered: boolean) {
  switch (props.variant) {
    case "dock":
      // Use purple icon only when active (current page), white otherwise
      return isActive
        ? dockPurpleIcons[props.name]
        : dockWhiteIcons[props.name];
    case "header":
      // Use purple icon only when active (current page), white otherwise
      return isActive
        ? headerPurpleIcons[props.name]
        : headerWhiteIcons[props.name];
    case "search":
      return searchIcons[props.name];
    case "misc":
      // For misc icons with purple variants (like back), use purple on hover
      if (isHovered && props.name in miscPurpleIcons) {
        return miscPurpleIcons[props.name as keyof typeof miscPurpleIcons];
      }
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
  const isMobile = useIsMobile();

  // Use external hover state if provided, otherwise use internal
  const isHovered = externalIsHovered ?? internalIsHovered;

  // Use isActive for icon color switching, and isHovered for misc icons with purple variants
  const animationData = getAnimationData(props, isActive, isHovered);

  // On mobile, stop at first frame (static icon)
  useEffect(() => {
    if (isMobile && lottieRef.current) {
      lottieRef.current.goToAndStop(0, true);
    }
  }, [isMobile, animationData]);

  // Play animation on hover (desktop only)
  useEffect(() => {
    if (!lottieRef.current || isMobile) return;

    if (playOnHover && isHovered) {
      if (playOnce && hasPlayedRef.current) return;
      lottieRef.current.goToAndPlay(0);
      hasPlayedRef.current = true;
    }
  }, [isHovered, playOnHover, playOnce, isMobile]);

  // Play animation when becoming active (desktop only)
  useEffect(() => {
    if (!lottieRef.current || isMobile) return;

    if (isActive && !prevActiveOrHoveredRef.current) {
      lottieRef.current.goToAndPlay(0);
    }
    prevActiveOrHoveredRef.current = isActive;
  }, [isActive, isMobile]);

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
