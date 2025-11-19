-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION 004: Fix Restaurants View to Include Photos Directly
-- Purpose: Embed photos in restaurants view so Flutter doesn't need to join
-- Date: 2025-11-18
-- ═══════════════════════════════════════════════════════════════════════════

-- Drop existing views
DROP VIEW IF EXISTS restaurant_reviews;
DROP VIEW IF EXISTS restaurant_photos;
DROP VIEW IF EXISTS restaurants;

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. CREATE RESTAURANTS VIEW (with embedded photos)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW restaurants AS
WITH photo_data AS (
  SELECT
    pc.id as restaurant_id,
    -- Extract photo URLs from places_cache.photos JSONB array
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', gen_random_uuid(),
          'restaurant_id', pc.id,
          'photo_url', 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=' ||
                       (photo->>'photo_reference') ||
                       '&key=AIzaSyBIWSw-eLxzzsuPcQxstnXBXcZTGh-nDrA',
          'photo_reference', photo->>'photo_reference',
          'photo_type', 'food',
          'source', 'google_places',
          'display_order', idx,
          'is_primary', CASE WHEN idx = 1 THEN true ELSE false END,
          'width', (photo->>'width')::INTEGER,
          'height', (photo->>'height')::INTEGER,
          'created_at', cache.cached_at
        )
      )
      FROM jsonb_array_elements(cache.photos) WITH ORDINALITY AS t(photo, idx)
      WHERE cache.photos IS NOT NULL
    ) as photos_array,
    -- Get first photo URL for image_url field
    CASE
      WHEN cache.photos IS NOT NULL AND jsonb_array_length(cache.photos) > 0 THEN
        'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=' ||
        (cache.photos->0->>'photo_reference') ||
        '&key=YOUR_GOOGLE_API_KEY'
      ELSE NULL
    END as primary_photo_url
  FROM places_catalog pc
  INNER JOIN places_cache cache ON pc.id = cache.place_catalog_id
  WHERE pc.place_type = 'restaurant'
    AND pc.is_active = true
    AND cache.expires_at > NOW()
)
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
  pc.updated_at,

  -- ✅ Photos embedded as JSONB (for Supabase joins)
  pd.photos_array as photos,

  -- ✅ Photos as simple array of URLs (for Flutter map compatibility)
  CASE
    WHEN pd.photos_array IS NOT NULL THEN
      (
        SELECT array_agg(elem->>'photo_url')
        FROM jsonb_array_elements(pd.photos_array) elem
      )
    ELSE ARRAY[]::TEXT[]
  END as images,

  -- ✅ Primary photo URL (for Flutter map compatibility)
  pd.primary_photo_url as image_url

FROM places_catalog pc
INNER JOIN places_cache cache ON pc.id = cache.place_catalog_id
LEFT JOIN photo_data pd ON pc.id = pd.restaurant_id
WHERE pc.place_type = 'restaurant'
  AND pc.is_active = true
  AND cache.expires_at > NOW();

COMMENT ON VIEW restaurants IS 'Compatibility view for Flutter app - includes photos embedded as JSON to avoid join issues';

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. CREATE RESTAURANT_PHOTOS VIEW (for backward compatibility if needed)
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
    '&key=YOUR_GOOGLE_API_KEY' as photo_url,

  -- Classification
  'food' as photo_type,
  NULL::DECIMAL as confidence,

  -- Attribution
  'google_places' as source,
  COALESCE((photo->'html_attributions'->0)::TEXT, 'Google') as photographer_name,

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

COMMENT ON VIEW restaurant_photos IS 'Compatibility view for restaurant photos';

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. CREATE RESTAURANT_REVIEWS VIEW
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

COMMENT ON VIEW restaurant_reviews IS 'Compatibility view for restaurant reviews';

-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION COMPLETE
-- ═══════════════════════════════════════════════════════════════════════════

DO $$
BEGIN
  RAISE NOTICE '✅ Successfully updated restaurants view with embedded photos';
  RAISE NOTICE '📋 Updated: restaurants (view) - now includes photos, images, image_url fields';
  RAISE NOTICE '📋 Updated: restaurant_photos (view)';
  RAISE NOTICE '📋 Updated: restaurant_reviews (view)';
  RAISE NOTICE '🔄 Flutter app can now query with or without photo joins!';
  RAISE NOTICE '';
  RAISE NOTICE '⚠️  IMPORTANT: Update YOUR_GOOGLE_API_KEY in the view with actual API key';
END $$;
