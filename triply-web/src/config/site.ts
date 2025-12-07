export const siteConfig = {
  name: "Toogo",
  description:
    "Plan your dream trip in seconds with AI-powered travel planning. Get personalized itineraries, discover hidden gems, and book experiences effortlessly.",
  url: process.env.NEXT_PUBLIC_APP_URL || "https://toogo.world",
  ogImage: "/og-image.png",
  links: {
    twitter: "https://twitter.com/toogoworld",
    github: "https://github.com/toogo",
    instagram: "https://instagram.com/toogoworld",
  },
  creator: "Toogo Team",
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
