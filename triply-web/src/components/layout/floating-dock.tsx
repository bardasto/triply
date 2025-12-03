"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, Compass, Map } from "lucide-react";
import { GeminiIcon } from "@/components/ui/gemini-icon";
import { cn } from "@/lib/utils";

const dockItems = [
  { name: "Home", href: "/", icon: Home },
  { name: "Explore", href: "/explore", icon: Compass },
  { name: "AI Chat", href: "/chat", icon: GeminiIcon },
  { name: "My Trips", href: "/trips", icon: Map },
];

export function FloatingDock() {
  const [isVisible, setIsVisible] = useState(false);
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null);
  const pathname = usePathname();

  useEffect(() => {
    const handleScroll = () => {
      setIsVisible(window.scrollY > 200);
    };

    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <div
      className={cn(
        "fixed bottom-8 left-1/2 -translate-x-1/2 z-50",
        "transition-all duration-500 ease-out",
        isVisible
          ? "opacity-100 translate-y-0"
          : "opacity-0 translate-y-16 pointer-events-none"
      )}
    >
      <div
        className={cn(
          "flex items-center gap-8 px-8 py-4",
          "rounded-full",
          "bg-neutral-900/95 backdrop-blur-xl",
          "border border-neutral-800"
        )}
        onMouseLeave={() => setHoveredIndex(null)}
      >
        {dockItems.map((item, index) => {
          const Icon = item.icon;
          const isActive = pathname === item.href;
          const isHovered = hoveredIndex === index;

          return (
            <Link
              key={item.name}
              href={item.href}
              onMouseEnter={() => setHoveredIndex(index)}
              className="relative flex flex-col items-center"
            >
              {/* Tooltip - appears above on hover */}
              <div
                className={cn(
                  "absolute -top-12 flex flex-col items-center",
                  "transition-all duration-200",
                  isHovered
                    ? "opacity-100 translate-y-0"
                    : "opacity-0 translate-y-2 pointer-events-none"
                )}
              >
                <span
                  className={cn(
                    "px-3 py-1.5 rounded-lg",
                    "text-xs font-medium text-white",
                    "bg-neutral-800 border border-neutral-700",
                    "whitespace-nowrap"
                  )}
                >
                  {item.name}
                </span>
                <div className="w-2 h-2 bg-neutral-800 border-r border-b border-neutral-700 rotate-45 -mt-1" />
              </div>

              {/* Icon */}
              <div
                className={cn(
                  "flex items-center justify-center",
                  "w-10 h-10",
                  "transition-all duration-200 ease-out",
                  isHovered && "-translate-y-2 scale-110",
                  isActive
                    ? "text-primary"
                    : "text-neutral-400 hover:text-white"
                )}
              >
                <Icon className="h-5 w-5" />
              </div>
            </Link>
          );
        })}

      </div>
    </div>
  );
}
