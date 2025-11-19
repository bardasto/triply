-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION: Create Places Cache Schema
-- Purpose: Google Places API compliant caching (30-day cache, 15-day refresh)
-- Date: 2025-11-18
-- Policy: Store place_id permanently, cache other data for 30 days max
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. PLACES_CATALOG TABLE
-- Purpose: Permanent catalog of place_id (exempt from caching restrictions)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS places_catalog (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- ✅ Google place_id - can store INDEFINITELY (Google Policy compliant)
  google_place_id VARCHAR(255) UNIQUE NOT NULL,

  -- ✅ Coordinates - can cache for 30 days (Google Policy compliant)
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  coordinates_cached_at TIMESTAMP,

  -- Organization metadata
  city VARCHAR(100),
  country_code VARCHAR(3),
  place_type VARCHAR(50) NOT NULL, -- 'restaurant', 'attraction', 'hotel', etc.
  category VARCHAR(50), -- More specific: 'french_restaurant', 'museum', etc.
  tags VARCHAR(50)[] DEFAULT '{}', -- ['fine_dining', 'romantic', 'michelin']

  -- Reference to POI table (if exists)
  poi_id UUID REFERENCES pois(id) ON DELETE SET NULL,

  -- Status
  is_active BOOLEAN DEFAULT true,
  priority INTEGER DEFAULT 0, -- Higher priority = refresh more frequently

  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_places_catalog_google_place_id ON places_catalog(google_place_id);
CREATE INDEX idx_places_catalog_location ON places_catalog(city, country_code);
CREATE INDEX idx_places_catalog_type ON places_catalog(place_type);
CREATE INDEX idx_places_catalog_active ON places_catalog(is_active) WHERE is_active = true;
CREATE INDEX idx_places_catalog_coordinates_cached ON places_catalog(coordinates_cached_at);
CREATE INDEX idx_places_catalog_tags ON places_catalog USING GIN(tags);

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. PLACES_CACHE TABLE
-- Purpose: Temporary cache for Google Places data (30 days max, 15 day refresh)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS places_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  place_catalog_id UUID REFERENCES places_catalog(id) ON DELETE CASCADE NOT NULL,

  -- ⚠️ CACHED DATA - Must be refreshed every 15 days, deleted after 30 days

  -- Basic Information
  name VARCHAR(255) NOT NULL,
  formatted_address TEXT,
  international_phone_number VARCHAR(50),
  website TEXT,

  -- Ratings & Reviews
  rating DECIMAL(2, 1),
  user_ratings_total INTEGER,

  -- Restaurant-specific
  price_level INTEGER CHECK (price_level BETWEEN 1 AND 4),
  cuisine_types VARCHAR(100)[] DEFAULT '{}',

  -- Opening Hours
  opening_hours JSONB,
  current_opening_hours JSONB,
  is_open_now BOOLEAN,

  -- Photos (store only photo_reference, not URLs)
  photos JSONB, -- Array of {photo_reference, width, height, attributions}

  -- Reviews (limited sample)
  reviews JSONB, -- Array of recent reviews (max 5)

  -- Additional metadata
  business_status VARCHAR(50),
  types VARCHAR(50)[] DEFAULT '{}',
  editorial_summary TEXT,

  -- Cache management
  cached_at TIMESTAMP DEFAULT NOW() NOT NULL,
  expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '30 days') NOT NULL,
  next_refresh_at TIMESTAMP DEFAULT (NOW() + INTERVAL '15 days') NOT NULL,
  refresh_count INTEGER DEFAULT 0,
  last_api_call_at TIMESTAMP,

  -- Raw data from Google (for debugging)
  raw_data JSONB,

  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  -- Constraints
  CONSTRAINT valid_cache_period CHECK (expires_at > cached_at),
  CONSTRAINT valid_refresh_period CHECK (next_refresh_at <= expires_at)
);

-- Indexes for cache management
CREATE INDEX idx_places_cache_catalog_id ON places_cache(place_catalog_id);
CREATE INDEX idx_places_cache_expires_at ON places_cache(expires_at);
CREATE INDEX idx_places_cache_next_refresh ON places_cache(next_refresh_at);
CREATE INDEX idx_places_cache_cached_at ON places_cache(cached_at DESC);

-- Unique constraint: only one cache per place (removed WHERE clause due to IMMUTABLE requirement)
CREATE UNIQUE INDEX idx_places_cache_active_place
  ON places_cache(place_catalog_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. CACHE_REFRESH_LOG TABLE
-- Purpose: Track cache refresh history and failures
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS cache_refresh_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  place_catalog_id UUID REFERENCES places_catalog(id) ON DELETE CASCADE,

  -- Refresh details
  refresh_type VARCHAR(50) NOT NULL, -- 'scheduled', 'manual', 'on_demand'
  status VARCHAR(50) NOT NULL, -- 'success', 'failed', 'skipped'

  -- Error tracking
  error_message TEXT,
  error_code VARCHAR(50),

  -- Performance
  api_latency_ms INTEGER,

  -- Metadata
  refreshed_at TIMESTAMP DEFAULT NOW(),
  triggered_by VARCHAR(50) -- 'cron_job', 'user_request', 'cache_miss'
);

CREATE INDEX idx_cache_refresh_log_catalog_id ON cache_refresh_log(place_catalog_id);
CREATE INDEX idx_cache_refresh_log_status ON cache_refresh_log(status);
CREATE INDEX idx_cache_refresh_log_refreshed_at ON cache_refresh_log(refreshed_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. TRIGGERS
-- ═══════════════════════════════════════════════════════════════════════════

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_places_catalog_updated_at
  BEFORE UPDATE ON places_catalog
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_places_cache_updated_at
  BEFORE UPDATE ON places_cache
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ═══════════════════════════════════════════════════════════════════════════
-- 5. HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- Function: Get places that need cache refresh
CREATE OR REPLACE FUNCTION get_places_needing_refresh(
  batch_size INTEGER DEFAULT 100
)
RETURNS TABLE (
  catalog_id UUID,
  google_place_id VARCHAR,
  place_type VARCHAR,
  city VARCHAR,
  last_cached_at TIMESTAMP,
  days_since_refresh NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    pc.id,
    pc.google_place_id,
    pc.place_type,
    pc.city,
    cache.cached_at,
    EXTRACT(EPOCH FROM (NOW() - cache.next_refresh_at)) / 86400 as days_since_refresh
  FROM places_catalog pc
  LEFT JOIN places_cache cache ON pc.id = cache.place_catalog_id
  WHERE pc.is_active = true
    AND (
      cache.id IS NULL -- No cache exists
      OR cache.next_refresh_at <= NOW() -- Cache needs refresh
      OR cache.expires_at <= NOW() -- Cache expired
    )
  ORDER BY
    pc.priority DESC,
    cache.next_refresh_at ASC NULLS FIRST
  LIMIT batch_size;
END;
$$ LANGUAGE plpgsql;

-- Function: Get expired cache entries
CREATE OR REPLACE FUNCTION get_expired_cache_entries()
RETURNS TABLE (
  cache_id UUID,
  place_name VARCHAR,
  expired_since_days NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    cache.id,
    cache.name,
    EXTRACT(EPOCH FROM (NOW() - cache.expires_at)) / 86400 as expired_since_days
  FROM places_cache cache
  WHERE cache.expires_at <= NOW()
  ORDER BY cache.expires_at ASC;
END;
$$ LANGUAGE plpgsql;

-- Function: Get cache statistics
CREATE OR REPLACE FUNCTION get_cache_statistics()
RETURNS TABLE (
  place_type VARCHAR,
  total_places BIGINT,
  cached_places BIGINT,
  fresh_cache BIGINT,
  needs_refresh BIGINT,
  expired_cache BIGINT,
  cache_coverage_percent NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    pc.place_type,
    COUNT(DISTINCT pc.id) as total_places,
    COUNT(DISTINCT CASE WHEN cache.id IS NOT NULL THEN pc.id END) as cached_places,
    COUNT(DISTINCT CASE WHEN cache.next_refresh_at > NOW() THEN pc.id END) as fresh_cache,
    COUNT(DISTINCT CASE WHEN cache.next_refresh_at <= NOW() AND cache.expires_at > NOW() THEN pc.id END) as needs_refresh,
    COUNT(DISTINCT CASE WHEN cache.expires_at <= NOW() THEN pc.id END) as expired_cache,
    ROUND(
      COUNT(DISTINCT CASE WHEN cache.id IS NOT NULL THEN pc.id END)::NUMERIC /
      NULLIF(COUNT(DISTINCT pc.id), 0)::NUMERIC * 100,
      2
    ) as cache_coverage_percent
  FROM places_catalog pc
  LEFT JOIN places_cache cache ON pc.id = cache.place_catalog_id
  WHERE pc.is_active = true
  GROUP BY pc.place_type;
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════════════════
-- 6. VIEWS
-- ═══════════════════════════════════════════════════════════════════════════

-- View: Active cached places with metadata
CREATE OR REPLACE VIEW active_cached_places AS
SELECT
  pc.id as catalog_id,
  pc.google_place_id,
  pc.place_type,
  pc.category,
  pc.city,
  pc.tags,
  cache.name,
  cache.formatted_address,
  cache.rating,
  cache.price_level,
  cache.is_open_now,
  cache.cached_at,
  cache.expires_at,
  cache.next_refresh_at,
  EXTRACT(EPOCH FROM (NOW() - cache.cached_at)) / 86400 as cache_age_days,
  EXTRACT(EPOCH FROM (cache.next_refresh_at - NOW())) / 86400 as days_until_refresh,
  CASE
    WHEN cache.expires_at <= NOW() THEN 'expired'
    WHEN cache.next_refresh_at <= NOW() THEN 'needs_refresh'
    ELSE 'fresh'
  END as cache_status
FROM places_catalog pc
INNER JOIN places_cache cache ON pc.id = cache.place_catalog_id
WHERE pc.is_active = true;

-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION COMPLETE
-- ═══════════════════════════════════════════════════════════════════════════

DO $$
BEGIN
  RAISE NOTICE '✅ Successfully created places cache schema';
  RAISE NOTICE '📋 Created tables: places_catalog, places_cache, cache_refresh_log';
  RAISE NOTICE '📋 Created functions: get_places_needing_refresh, get_expired_cache_entries, get_cache_statistics';
  RAISE NOTICE '📋 Created view: active_cached_places';
  RAISE NOTICE '🔄 Cache policy: 15-day refresh, 30-day expiration';
END $$;
