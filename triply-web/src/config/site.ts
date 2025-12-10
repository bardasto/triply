export const siteConfig = {
  name: "Toogo",
  description:
    "The simplest way to plan a trip. You talk, AI listens — and turns your ideas into a trip you'll actually want to take.",
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
