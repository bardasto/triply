// Brand colors
export const BRAND_COLORS = {
  primary: "#865cfe", // Purple
  primaryDark: "#30284D", // Dark purple
  accent: "#FC892E", // Orange
  background: {
    light: "#ffffff",
    dark: "#040404",
  },
} as const;

// Activity types matching the mobile app
export const ACTIVITY_TYPES = [
  { id: "cycling", label: "Cycling", color: "#A8E6CF", icon: "Bicycle" },
  { id: "beach", label: "Beach", color: "#87CEEB", icon: "Island" },
  { id: "skiing", label: "Skiing", color: "#B8D4E8", icon: "PersonSimpleSki" },
  { id: "mountains", label: "Mountains", color: "#D4D4D4", icon: "Mountains" },
  { id: "hiking", label: "Hiking", color: "#98D8C8", icon: "PersonSimpleHike" },
  { id: "sailing", label: "Sailing", color: "#7FCDCD", icon: "Sailboat" },
  { id: "desert", label: "Desert", color: "#FDD17B", icon: "Cactus" },
  { id: "camping", label: "Camping", color: "#D4A574", icon: "Tipi" },
  { id: "city", label: "City", color: "#B8B8B8", icon: "City" },
  { id: "wellness", label: "Wellness", color: "#DDA0DD", icon: "PersonSimpleTaiChi" },
  { id: "road_trip", label: "Road Trip", color: "#FFC8A2", icon: "RoadHorizon" },
] as const;

// Trip categories
export const TRIP_CATEGORIES = [
  "Adventure",
  "Beach",
  "City",
  "Culture",
  "Food",
  "History",
  "Leisure",
  "Luxury",
  "Nature",
  "Wellness",
] as const;

// Durations
export const TRIP_DURATIONS = [
  { value: "half_day", label: "Half day" },
  { value: "full_day", label: "Full day" },
  { value: "2_days", label: "2 days" },
  { value: "3_days", label: "3 days" },
  { value: "4_days", label: "4 days" },
  { value: "5_days", label: "5 days" },
  { value: "week", label: "1 week" },
  { value: "2_weeks", label: "2 weeks" },
] as const;

// Price ranges
export const PRICE_RANGES = [
  { value: "budget", label: "Budget", max: 100 },
  { value: "moderate", label: "Moderate", max: 300 },
  { value: "premium", label: "Premium", max: 700 },
  { value: "luxury", label: "Luxury", max: null },
] as const;

// API endpoints
export const API_ENDPOINTS = {
  chat: "/api/chat",
  trips: "/api/trips",
  auth: "/api/auth",
} as const;

// Rate limits
export const RATE_LIMITS = {
  chat: {
    free: 10, // messages per day
    pro: 100,
    unlimited: -1,
  },
  tripGeneration: {
    free: 3, // trips per day
    pro: 20,
    unlimited: -1,
  },
} as const;
