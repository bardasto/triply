-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION 003: Create Flutter App Compatibility Views
-- Purpose: Allow Flutter app to query restaurants without code changes
-- Date: 2025-11-18
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. CREATE RESTAURANTS VIEW
-- Purpose: Emulate old restaurants table for Flutter app compatibility
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW restaurants AS
SELECT
  pc.id,
  NULL::UUID as poi_id,

  -- Basic Info (from cache)
  cache.name,
  NULL::TEXT as description,
  cache.cuisine_types,

  -- Location (from catalog)
  cache.formatted_address as address,
  pc.latitude,
  pc.longitude,

  -- Contact (from cache)
  cache.international_phone_number as phone,
  cache.website,

  -- Ratings & Reviews (from cache)
  cache.rating,
  cache.user_ratings_total as review_count,
  cache.rating as google_rating,
  cache.user_ratings_total as google_review_count,

  -- Pricing (from cache)
  cache.price_level,
  NULL::DECIMAL as average_price_per_person,
  'EUR' as currency,

  -- Hours (from cache)
  cache.opening_hours,
  cache.is_open_now,

  -- External IDs
  pc.google_place_id,
  NULL::VARCHAR as foursquare_id,

  -- Features (from tags)
  pc.tags as features,
  ARRAY[]::VARCHAR[] as dietary_options,

  -- Menu Info
  false as has_menu,
  NULL::TIMESTAMP as menu_last_updated_at,

  -- Status
  pc.is_active,
  cache.cached_at as last_verified_at,

  -- Metadata
  pc.created_at,
  pc.updated_at
FROM places_catalog pc
INNER JOIN places_cache cache ON pc.id = cache.place_catalog_id
WHERE pc.place_type = 'restaurant'
  AND pc.is_active = true
  AND cache.expires_at > NOW();

-- Add comment
COMMENT ON VIEW restaurants IS 'Compatibility view for Flutter app - maps places_catalog + places_cache to old restaurants structure';

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. CREATE RESTAURANT_PHOTOS VIEW
-- Purpose: Emulate old restaurant_photos table
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW restaurant_photos AS
SELECT
  gen_random_uuid() as id,
  pc.id as restaurant_id,
  NULL::UUID as menu_item_id,

  -- Photo Info
  photo->>'photo_reference' as photo_reference,
  -- Build Google Places photo URL
  'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=' ||
    (photo->>'photo_reference') ||
    '&key=YOUR_API_KEY' as photo_url,

  -- Classification
  'food' as photo_type,
  NULL::DECIMAL as confidence,

  -- Attribution
  'google_places' as source,
  COALESCE(photo->'attributions'->0->>'author_name', 'Google') as photographer_name,

  -- Dimensions
  (photo->>'width')::INTEGER as width,
  (photo->>'height')::INTEGER as height,

  -- Display
  ROW_NUMBER() OVER (PARTITION BY pc.id ORDER BY (photo->>'photo_reference')) as display_order,
  ROW_NUMBER() OVER (PARTITION BY pc.id ORDER BY (photo->>'photo_reference')) = 1 as is_primary,

  -- Metadata
  cache.cached_at as created_at,
  cache.updated_at
FROM places_catalog pc
INNER JOIN places_cache cache ON pc.id = cache.place_catalog_id,
LATERAL jsonb_array_elements(cache.photos) as photo
WHERE pc.place_type = 'restaurant'
  AND pc.is_active = true
  AND cache.expires_at > NOW()
  AND cache.photos IS NOT NULL;

COMMENT ON VIEW restaurant_photos IS 'Compatibility view for Flutter app - extracts photos from places_cache JSON';

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. CREATE RESTAURANT_REVIEWS VIEW (Optional)
-- Purpose: Emulate old restaurant_reviews table
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW restaurant_reviews AS
SELECT
  gen_random_uuid() as id,
  pc.id as restaurant_id,

  -- Review Content
  review->>'author_name' as author_name,
  NULL::TEXT as author_profile_url,
  (review->>'rating')::DECIMAL as rating,
  review->>'text' as comment,

  -- Source
  'google' as source,
  NULL::VARCHAR as external_review_id,

  -- Sentiment (could add ML later)
  NULL::DECIMAL as sentiment_score,
  CASE
    WHEN (review->>'rating')::DECIMAL >= 4 THEN 'positive'
    WHEN (review->>'rating')::DECIMAL >= 3 THEN 'neutral'
    ELSE 'negative'
  END as sentiment_label,

  -- Helpfulness
  0 as helpful_count,

  -- Timing
  to_timestamp((review->>'time')::BIGINT) as review_date,

  -- Metadata
  cache.cached_at as created_at,
  cache.updated_at
FROM places_catalog pc
INNER JOIN places_cache cache ON pc.id = cache.place_catalog_id,
LATERAL jsonb_array_elements(cache.reviews) as review
WHERE pc.place_type = 'restaurant'
  AND pc.is_active = true
  AND cache.expires_at > NOW()
  AND cache.reviews IS NOT NULL;

COMMENT ON VIEW restaurant_reviews IS 'Compatibility view for Flutter app - extracts reviews from places_cache JSON';

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. GRANT PERMISSIONS (if needed)
-- ═══════════════════════════════════════════════════════════════════════════

-- Grant SELECT on views to authenticated users
-- GRANT SELECT ON restaurants TO authenticated;
-- GRANT SELECT ON restaurant_photos TO authenticated;
-- GRANT SELECT ON restaurant_reviews TO authenticated;

-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION COMPLETE
-- ═══════════════════════════════════════════════════════════════════════════

DO $$
BEGIN
  RAISE NOTICE '✅ Successfully created Flutter compatibility views';
  RAISE NOTICE '📋 Created: restaurants (view)';
  RAISE NOTICE '📋 Created: restaurant_photos (view)';
  RAISE NOTICE '📋 Created: restaurant_reviews (view)';
  RAISE NOTICE '🔄 Flutter app can now query without code changes!';
END $$;
