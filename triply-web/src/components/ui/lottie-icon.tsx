"use client";

import { useRef, useEffect, useState, useMemo } from "react";
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

// =============================================================================
// DYNAMIC ICON LOADING WITH CACHING
// =============================================================================

// Global cache for loaded animation data
const animationCache = new Map<string, unknown>();

// Icon path mapping
const ICON_PATHS = {
  dock: {
    white: {
      home: "dock-white/home",
      explore: "dock-white/explore",
      aiChat: "dock-white/aiChat",
      myTrips: "dock-white/myTrips",
      profile: "dock-white/profile",
    },
    purple: {
      home: "dock-purple/home",
      explore: "dock-purple/explore",
      aiChat: "dock-purple/aiChat",
      myTrips: "dock-purple/myTrips",
      profile: "dock-purple/profile",
    },
  },
  header: {
    white: {
      home: "header-white/home",
      explore: "header-white/explore",
      aiChat: "header-white/aiChat",
      myTrips: "header-white/myTrips",
      profile: "header-white/profile",
    },
    purple: {
      home: "header-purple/home",
      explore: "header-purple/explore",
      aiChat: "header-purple/aiChat",
      myTrips: "header-purple/myTrips",
      profile: "header-purple/profile",
    },
  },
  search: {
    search: "search/search",
    calendar: "search/calendar",
    map: "search/map",
    users: "search/users",
    aiChat: "search/aiChat",
  },
  misc: {
    filter: "misc/filter",
    settings: "misc/settings",
    share: "misc/share",
    back: "misc/back",
    photos: "misc/photos",
    chatHistory: "misc/chatforaichat",
    microphone: "misc/microiconforchat",
    send: "misc/gobuttonforchat",
  },
  miscPurple: {
    back: "misc/back-purple",
  },
} as const;

// Dynamic import function with caching
async function loadAnimationData(path: string): Promise<unknown> {
  if (animationCache.has(path)) {
    return animationCache.get(path)!;
  }

  try {
    // Dynamic import - webpack will create separate chunks for each
    const module = await import(`../../../public/icons/lottie/${path}.json`);
    const data = module.default;
    animationCache.set(path, data);
    return data;
  } catch (error) {
    console.error(`[Lottie] Failed to load: ${path}`, error);
    return null;
  }
}

// Hook to load animation data dynamically
function useAnimationData(
  variant: LottieIconVariant,
  name: string,
  isActive: boolean,
  isHovered: boolean
): unknown | null {
  const [animationData, setAnimationData] = useState<unknown | null>(null);

  const iconPath = useMemo(() => {
    switch (variant) {
      case "dock":
        return isActive
          ? ICON_PATHS.dock.purple[name as DockIconName]
          : ICON_PATHS.dock.white[name as DockIconName];
      case "header":
        return isActive
          ? ICON_PATHS.header.purple[name as HeaderIconName]
          : ICON_PATHS.header.white[name as HeaderIconName];
      case "search":
        return ICON_PATHS.search[name as SearchIconName];
      case "misc":
        if (isHovered && name in ICON_PATHS.miscPurple) {
          return ICON_PATHS.miscPurple[name as keyof typeof ICON_PATHS.miscPurple];
        }
        return ICON_PATHS.misc[name as MiscIconName];
    }
  }, [variant, name, isActive, isHovered]);

  useEffect(() => {
    let cancelled = false;

    // Check cache first for instant load
    if (animationCache.has(iconPath)) {
      setAnimationData(animationCache.get(iconPath)!);
      return;
    }

    loadAnimationData(iconPath).then((data) => {
      if (!cancelled && data) {
        setAnimationData(data);
      }
    });

    return () => {
      cancelled = true;
    };
  }, [iconPath]);

  return animationData;
}

// Preload specific icons (call on app init for critical icons)
export function preloadLottieIcons(icons: Array<{ variant: LottieIconVariant; name: string; isActive?: boolean }>) {
  icons.forEach(({ variant, name, isActive = false }) => {
    let path: string;
    switch (variant) {
      case "dock":
        path = isActive
          ? ICON_PATHS.dock.purple[name as DockIconName]
          : ICON_PATHS.dock.white[name as DockIconName];
        break;
      case "header":
        path = isActive
          ? ICON_PATHS.header.purple[name as HeaderIconName]
          : ICON_PATHS.header.white[name as HeaderIconName];
        break;
      case "search":
        path = ICON_PATHS.search[name as SearchIconName];
        break;
      case "misc":
        path = ICON_PATHS.misc[name as MiscIconName];
        break;
    }
    loadAnimationData(path);
  });
}

// =============================================================================
// TYPE DEFINITIONS
// =============================================================================

export type LottieIconVariant = "dock" | "header" | "search" | "misc";
export type DockIconName = "home" | "explore" | "aiChat" | "myTrips" | "profile";
export type HeaderIconName = "home" | "explore" | "aiChat" | "myTrips" | "profile";
export type SearchIconName = "search" | "calendar" | "map" | "users" | "aiChat";
export type MiscIconName = "filter" | "settings" | "share" | "back" | "photos" | "chatHistory" | "microphone" | "send";

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

// =============================================================================
// MAIN COMPONENT
// =============================================================================

export function LottieIcon(props: LottieIconProps) {
  const {
    size = 24,
    className,
    isActive = false,
    isHovered: externalIsHovered,
    playOnHover = true,
    playOnce = true,
    variant,
    name,
  } = props;

  const lottieRef = useRef<LottieRefCurrentProps>(null);
  const [internalIsHovered, setInternalIsHovered] = useState(false);
  const hasPlayedRef = useRef(false);
  const prevActiveOrHoveredRef = useRef(false);
  const isMobile = useIsMobile();

  // Use external hover state if provided, otherwise use internal
  const isHovered = externalIsHovered ?? internalIsHovered;

  // Load animation data dynamically
  const animationData = useAnimationData(variant, name, isActive, isHovered);

  // On mobile, stop at first frame (static icon)
  useEffect(() => {
    if (isMobile && lottieRef.current) {
      lottieRef.current.goToAndStop(0, true);
    }
  }, [isMobile, animationData]);

  // Play animation on hover (desktop only)
  useEffect(() => {
    if (!lottieRef.current || isMobile || !animationData) return;

    if (playOnHover && isHovered) {
      if (playOnce && hasPlayedRef.current) return;
      lottieRef.current.goToAndPlay(0);
      hasPlayedRef.current = true;
    }
  }, [isHovered, playOnHover, playOnce, isMobile, animationData]);

  // Play animation when becoming active (desktop only)
  useEffect(() => {
    if (!lottieRef.current || isMobile || !animationData) return;

    if (isActive && !prevActiveOrHoveredRef.current) {
      lottieRef.current.goToAndPlay(0);
    }
    prevActiveOrHoveredRef.current = isActive;
  }, [isActive, isMobile, animationData]);

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
      {animationData ? (
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
      ) : (
        // Placeholder while loading - same size to prevent layout shift
        <div
          style={{ width: size, height: size }}
          className="bg-muted/20 rounded animate-pulse"
        />
      )}
    </div>
  );
}
