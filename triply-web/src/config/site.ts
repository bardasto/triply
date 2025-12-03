export const siteConfig = {
  name: "Triply",
  description:
    "Plan your dream trip in seconds with AI-powered travel planning. Get personalized itineraries, discover hidden gems, and book experiences effortlessly.",
  url: process.env.NEXT_PUBLIC_APP_URL || "https://triply.ai",
  ogImage: "/og-image.png",
  links: {
    twitter: "https://twitter.com/triplyai",
    github: "https://github.com/triply",
    instagram: "https://instagram.com/triplyai",
  },
  creator: "Triply Team",
  keywords: [
    "travel planning",
    "AI travel",
    "trip planner",
    "itinerary generator",
    "travel assistant",
    "vacation planning",
    "smart travel",
    "personalized trips",
  ],
} as const;

export type SiteConfig = typeof siteConfig;
