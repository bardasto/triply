-- ============================================================================
-- TEST QUERIES FOR AI_GENERATED_TRIPS TABLE
-- Use these queries in Supabase SQL Editor to test the table
-- ============================================================================

-- 1. Check if table was created successfully
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public' AND table_name = 'ai_generated_trips';

-- 2. View table structure
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'ai_generated_trips'
ORDER BY ordinal_position;

-- 3. Check RLS policies
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'ai_generated_trips';

-- 4. Check indexes
SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'ai_generated_trips';

-- ============================================================================
-- EXAMPLE: Insert a test trip (replace YOUR_USER_ID with actual user ID)
-- ============================================================================

/*
INSERT INTO public.ai_generated_trips (
  user_id,
  title,
  city,
  country,
  description,
  duration_days,
  price,
  currency,
  hero_image_url,
  itinerary,
  original_query
) VALUES (
  'YOUR_USER_ID'::uuid,  -- Replace with actual user ID from auth.users
  'Romantic Weekend in Paris',
  'Paris',
  'France',
  'Experience the magic of Paris with a romantic weekend getaway',
  3,
  850.00,
  'EUR',
  'https://images.unsplash.com/photo-1502602898657-3e91760cbb34',
  '[
    {
      "day": 1,
      "title": "Arrival & Eiffel Tower",
      "description": "Start your romantic journey",
      "places": [
        {
          "name": "Eiffel Tower",
          "description": "Iconic landmark",
          "image_url": "https://example.com/eiffel.jpg"
        }
      ]
    }
  ]'::jsonb,
  'romantic weekend in Paris'
);
*/

-- ============================================================================
-- EXAMPLE: Query user's trips
-- ============================================================================

/*
-- Get all trips for a user (ordered by most recent)
SELECT
  id,
  title,
  city,
  country,
  duration_days,
  price,
  currency,
  is_favorite,
  created_at
FROM public.ai_generated_trips
WHERE user_id = 'YOUR_USER_ID'::uuid
ORDER BY created_at DESC;
*/

-- ============================================================================
-- EXAMPLE: Update trip to favorite
-- ============================================================================

/*
UPDATE public.ai_generated_trips
SET is_favorite = true
WHERE id = 'TRIP_ID'::uuid AND user_id = 'YOUR_USER_ID'::uuid;
*/

-- ============================================================================
-- EXAMPLE: Delete a trip
-- ============================================================================

/*
DELETE FROM public.ai_generated_trips
WHERE id = 'TRIP_ID'::uuid AND user_id = 'YOUR_USER_ID'::uuid;
*/

-- ============================================================================
-- USEFUL QUERIES FOR DEBUGGING
-- ============================================================================

-- Count total trips in database
SELECT COUNT(*) as total_trips FROM public.ai_generated_trips;

-- Count trips per user
SELECT
  user_id,
  COUNT(*) as trip_count
FROM public.ai_generated_trips
GROUP BY user_id
ORDER BY trip_count DESC;

-- Get most popular cities
SELECT
  city,
  country,
  COUNT(*) as times_generated
FROM public.ai_generated_trips
GROUP BY city, country
ORDER BY times_generated DESC
LIMIT 10;

-- Get recent trips across all users (admin view)
-- Note: This requires admin access, regular users can only see their own
SELECT
  title,
  city,
  country,
  duration_days,
  created_at
FROM public.ai_generated_trips
ORDER BY created_at DESC
LIMIT 20;
