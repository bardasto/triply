// Re-export database types
export * from './database';

// Re-export new trip types (with DB prefix to avoid conflicts)
export {
  type Trip as DBTrip,
  type TripDay as DBTripDay,
  type TripPlace as DBTripPlace,
  type City as DBCity,
  type TripsByCity,
  type TripsResponse,
  type TripResponse,
  type CitiesResponse,
  type TripFilters as DBTripFilters,
  type TripSortOptions,
  type ActivityType,
  type DifficultyLevel,
  type PlaceType,
  type MealType,
  type TransportInfo,
  type TripImage,
  type POISnapshot,
} from './trip';

// User types
export interface User {
  id: string;
  email: string;
  name: string | null;
  image: string | null;
  createdAt: Date;
  plan: "free" | "pro" | "unlimited";
}

// Legacy Trip types (for backwards compatibility)
export interface Trip {
  id: string;
  title: string;
  description: string;
  destination: string;
  country: string;
  coverImage: string;
  images: string[];
  duration: string;
  price: string;
  rating: number;
  reviewCount?: number;
  category: string;
  activityType?: string;
  activities?: string[];
  includes?: string[];
  highlights?: string[];
  itinerary?: DayItinerary[];
  createdAt: Date;
  userId?: string;
  isPublic?: boolean;
}

export interface DayItinerary {
  day: number;
  title: string;
  description?: string;
  places: Place[];
}

export interface Place {
  id: string;
  name: string;
  description?: string;
  imageUrl: string;
  category: "attraction" | "restaurant" | "hotel" | "activity";
  rating: number;
  price?: string;
  duration?: string;
  address?: string;
  coordinates?: {
    lat: number;
    lng: number;
  };
}

// Chat types
export interface ChatMessage {
  id: string;
  role: "user" | "assistant" | "system";
  content: string;
  createdAt: Date;
  metadata?: {
    tripGenerated?: boolean;
    tripId?: string;
  };
}

export interface ChatSession {
  id: string;
  title: string;
  messages: ChatMessage[];
  createdAt: Date;
  updatedAt: Date;
  userId: string;
}

// Search & Filter types
export interface TripFilters {
  destination?: string;
  activityTypes?: string[];
  categories?: string[];
  priceRange?: {
    min: number;
    max: number;
  };
  duration?: string;
  rating?: number;
}

export interface SearchParams {
  query?: string;
  filters?: TripFilters;
  page?: number;
  limit?: number;
  sortBy?: "rating" | "price" | "newest" | "popular";
}

// API Response types
export interface ApiResponse<T> {
  data: T;
  success: boolean;
  error?: string;
  meta?: {
    page: number;
    limit: number;
    total: number;
    hasMore: boolean;
  };
}

// Booking types (for future use)
export interface Booking {
  id: string;
  tripId: string;
  userId: string;
  status: "pending" | "confirmed" | "cancelled";
  startDate: Date;
  endDate: Date;
  guests: number;
  totalPrice: number;
  createdAt: Date;
}
