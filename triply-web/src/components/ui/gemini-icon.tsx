import { cn } from "@/lib/utils";

interface GeminiIconProps {
  className?: string;
}

export function GeminiIcon({ className }: GeminiIconProps) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      className={cn("h-5 w-5", className)}
    >
      <path
        d="M12 2L13.5 8.5L20 10L13.5 11.5L12 18L10.5 11.5L4 10L10.5 8.5L12 2Z"
        fill="currentColor"
      />
      <path
        d="M19 16L19.75 18.25L22 19L19.75 19.75L19 22L18.25 19.75L16 19L18.25 18.25L19 16Z"
        fill="currentColor"
        opacity="0.7"
      />
      <path
        d="M5 14L5.5 15.5L7 16L5.5 16.5L5 18L4.5 16.5L3 16L4.5 15.5L5 14Z"
        fill="currentColor"
        opacity="0.5"
      />
    </svg>
  );
}
