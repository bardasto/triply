/**
 * Database Types for Supabase
 * Based on actual database schema from Flutter project
 */

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export interface Database {
  public: {
    Tables: {
      // Chat history for AI conversations (RLS protected by user_id)
      chat_history: {
        Row: {
          id: string;
          user_id: string;
          title: string;
          mode: string;
          messages: Json;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          title: string;
          mode: string;
          messages?: Json;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          user_id?: string;
          title?: string;
          mode?: string;
          messages?: Json;
          created_at?: string;
          updated_at?: string;
        };
      };
      // User's personal AI-generated trips (RLS protected by user_id)
      ai_generated_trips: {
        Row: {
          id: string;
          user_id: string;
          title: string;
          city: string;
          country: string | null;
          description: string | null;
          duration_days: number | null;
          price: number | null;
          currency: string;
          hero_image_url: string | null;
          images: Json | null;
          includes: Json | null;
          highlights: Json | null;
          itinerary: Json | null;
          rating: number | null;
          reviews: number | null;
          estimated_cost_min: number | null;
          estimated_cost_max: number | null;
          activity_type: string | null;
          best_season: Json | null;
          is_favorite: boolean;
          original_query: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          title: string;
          city: string;
          country?: string | null;
          description?: string | null;
          duration_days?: number | null;
          price?: number | null;
          currency?: string;
          hero_image_url?: string | null;
          images?: Json | null;
          includes?: Json | null;
          highlights?: Json | null;
          itinerary?: Json | null;
          rating?: number | null;
          reviews?: number | null;
          estimated_cost_min?: number | null;
          estimated_cost_max?: number | null;
          activity_type?: string | null;
          best_season?: Json | null;
          is_favorite?: boolean;
          original_query?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          user_id?: string;
          title?: string;
          city?: string;
          country?: string | null;
          description?: string | null;
          duration_days?: number | null;
          price?: number | null;
          currency?: string;
          hero_image_url?: string | null;
          images?: Json | null;
          includes?: Json | null;
          highlights?: Json | null;
          itinerary?: Json | null;
          rating?: number | null;
          reviews?: number | null;
          estimated_cost_min?: number | null;
          estimated_cost_max?: number | null;
          activity_type?: string | null;
          best_season?: Json | null;
          is_favorite?: boolean;
          original_query?: string | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      // Public trips for display on home page
      public_trips: {
        Row: {
          id: string;
          title: string;
          description: string | null;
          city: string;
          country: string | null;
          continent: string | null;
          status: string;
          activity_type: string | null;
          difficulty_level: string | null;
          duration: string | null; // String like "5 days"
          price: string | null; // String like "€1500"
          currency: string;
          estimated_cost_min: number | null;
          estimated_cost_max: number | null;
          itinerary: Json | null;
          includes: Json | null;
          highlights: Json | null;
          best_season: Json | null;
          hero_image_url: string | null;
          images: Json | null;
          relevance_score: number | null;
          generation_id: string | null;
          view_count: number;
          bookmark_count: number;
          created_at: string;
          valid_until: string | null;
        };
        Insert: {
          id?: string;
          title: string;
          description?: string | null;
          city: string;
          country?: string | null;
          continent?: string | null;
          status?: string;
          activity_type?: string | null;
          difficulty_level?: string | null;
          duration?: number | null;
          price?: number | null;
          currency?: string;
          estimated_cost_min?: number | null;
          estimated_cost_max?: number | null;
          itinerary?: Json | null;
          includes?: Json | null;
          highlights?: Json | null;
          best_season?: Json | null;
          hero_image_url?: string | null;
          images?: Json | null;
          relevance_score?: number | null;
          generation_id?: string | null;
          view_count?: number;
          bookmark_count?: number;
          created_at?: string;
          valid_until?: string | null;
        };
        Update: {
          id?: string;
          title?: string;
          description?: string | null;
          city?: string;
          country?: string | null;
          continent?: string | null;
          status?: string;
          activity_type?: string | null;
          difficulty_level?: string | null;
          duration?: number | null;
          price?: number | null;
          currency?: string;
          estimated_cost_min?: number | null;
          estimated_cost_max?: number | null;
          itinerary?: Json | null;
          includes?: Json | null;
          highlights?: Json | null;
          best_season?: Json | null;
          hero_image_url?: string | null;
          images?: Json | null;
          relevance_score?: number | null;
          generation_id?: string | null;
          view_count?: number;
          bookmark_count?: number;
          created_at?: string;
          valid_until?: string | null;
        };
      };
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      increment_trip_views: {
        Args: { trip_id: string };
        Returns: void;
      };
    };
    Enums: {
      activity_type:
        | 'city'
        | 'beach'
        | 'adventure'
        | 'cultural'
        | 'food'
        | 'wellness'
        | 'nightlife'
        | 'shopping'
        | 'hiking'
        | 'skiing'
        | 'cycling'
        | 'sailing'
        | 'camping'
        | 'road_trip'
        | 'mountains'
        | 'desert';
      difficulty_level: 'easy' | 'moderate' | 'hard' | 'extreme';
    };
  };
}

// Type helpers
export type Tables<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Row'];
export type InsertTables<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Insert'];
export type UpdateTables<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Update'];
export type Enums<T extends keyof Database['public']['Enums']> =
  Database['public']['Enums'][T];
