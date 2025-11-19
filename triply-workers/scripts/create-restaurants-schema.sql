-- ═══════════════════════════════════════════════════════════════════════════
-- RESTAURANTS DATABASE SCHEMA
-- Schema for detailed restaurant information, menu items, photos, and reviews
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. RESTAURANTS TABLE (detailed restaurant information)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS restaurants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poi_id UUID REFERENCES pois(id) ON DELETE CASCADE,

  -- Basic Info
  name VARCHAR(255) NOT NULL,
  description TEXT,
  cuisine_types VARCHAR(100)[] DEFAULT '{}',

  -- Location
  address TEXT,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,

  -- Contact
  phone VARCHAR(50),
  website TEXT,

  -- Ratings & Reviews
  rating DECIMAL(2, 1),
  review_count INTEGER DEFAULT 0,
  google_rating DECIMAL(2, 1),
  google_review_count INTEGER DEFAULT 0,

  -- Pricing
  price_level INTEGER CHECK (price_level BETWEEN 1 AND 4),
  average_price_per_person DECIMAL(10, 2),
  currency VARCHAR(3) DEFAULT 'EUR',

  -- Hours
  opening_hours JSONB,
  is_open_now BOOLEAN,

  -- External IDs
  google_place_id VARCHAR(255) UNIQUE,
  foursquare_id VARCHAR(255),

  -- Features
  features VARCHAR(100)[] DEFAULT '{}', -- e.g., ['wifi', 'outdoor_seating', 'reservations']
  dietary_options VARCHAR(50)[] DEFAULT '{}', -- e.g., ['vegetarian', 'vegan', 'gluten_free']

  -- Menu Info
  has_menu BOOLEAN DEFAULT false,
  menu_last_updated_at TIMESTAMP,

  -- Status
  is_active BOOLEAN DEFAULT true,
  last_verified_at TIMESTAMP DEFAULT NOW(),

  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_restaurants_poi_id ON restaurants(poi_id);
CREATE INDEX idx_restaurants_google_place_id ON restaurants(google_place_id);
CREATE INDEX idx_restaurants_cuisine_types ON restaurants USING GIN(cuisine_types);
CREATE INDEX idx_restaurants_rating ON restaurants(rating DESC);
CREATE INDEX idx_restaurants_location ON restaurants USING GIST(ll_to_earth(latitude, longitude));

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. MENU_ITEMS TABLE (dishes and menu items)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS menu_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,

  -- Item Info
  name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(50), -- e.g., 'appetizer', 'main_course', 'dessert', 'beverage'

  -- Pricing
  price DECIMAL(10, 2),
  currency VARCHAR(3) DEFAULT 'EUR',

  -- Details
  ingredients TEXT[],
  allergens VARCHAR(50)[],
  dietary_tags VARCHAR(50)[], -- e.g., ['vegan', 'gluten_free', 'spicy']

  -- Source
  source_type VARCHAR(50) DEFAULT 'ml', -- 'ml' | 'manual' | 'api'
  source_image_url TEXT,
  ocr_confidence DECIMAL(3, 2), -- 0.00 to 1.00

  -- Popularity
  popularity_score DECIMAL(3, 2) DEFAULT 0.5,
  is_signature_dish BOOLEAN DEFAULT false,

  -- Status
  is_active BOOLEAN DEFAULT true,
  verified_at TIMESTAMP,

  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_menu_items_restaurant_id ON menu_items(restaurant_id);
CREATE INDEX idx_menu_items_category ON menu_items(category);
CREATE INDEX idx_menu_items_dietary_tags ON menu_items USING GIN(dietary_tags);

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. RESTAURANT_PHOTOS TABLE (photos classified by type)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS restaurant_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
  menu_item_id UUID REFERENCES menu_items(id) ON DELETE SET NULL,

  -- Photo Info
  photo_url TEXT NOT NULL,
  photo_reference VARCHAR(255), -- Google Places photo reference

  -- Classification
  photo_type VARCHAR(50) NOT NULL, -- 'menu', 'food', 'interior', 'exterior', 'dish'
  confidence DECIMAL(3, 2), -- ML classification confidence

  -- Attribution
  source VARCHAR(50) DEFAULT 'google_places', -- 'google_places' | 'user_upload' | 'ml_generated'
  photographer_name VARCHAR(255),

  -- Dimensions
  width INTEGER,
  height INTEGER,

  -- Display
  display_order INTEGER DEFAULT 0,
  is_primary BOOLEAN DEFAULT false,

  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_restaurant_photos_restaurant_id ON restaurant_photos(restaurant_id);
CREATE INDEX idx_restaurant_photos_menu_item_id ON restaurant_photos(menu_item_id);
CREATE INDEX idx_restaurant_photos_type ON restaurant_photos(photo_type);

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. RESTAURANT_REVIEWS TABLE (reviews from various sources)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS restaurant_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,

  -- Review Content
  author_name VARCHAR(255),
  author_profile_url TEXT,
  rating DECIMAL(2, 1) NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,

  -- Source
  source VARCHAR(50) DEFAULT 'google', -- 'google' | 'tripadvisor' | 'yelp' | 'internal'
  external_review_id VARCHAR(255),

  -- Sentiment (ML-based)
  sentiment_score DECIMAL(3, 2), -- -1.00 to 1.00
  sentiment_label VARCHAR(20), -- 'positive' | 'neutral' | 'negative'

  -- Helpfulness
  helpful_count INTEGER DEFAULT 0,

  -- Timing
  review_date TIMESTAMP NOT NULL,

  -- Metadata
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_restaurant_reviews_restaurant_id ON restaurant_reviews(restaurant_id);
CREATE INDEX idx_restaurant_reviews_rating ON restaurant_reviews(rating DESC);
CREATE INDEX idx_restaurant_reviews_date ON restaurant_reviews(review_date DESC);
CREATE INDEX idx_restaurant_reviews_source ON restaurant_reviews(source);

-- ═══════════════════════════════════════════════════════════════════════════
-- 5. TRIGGERS (auto-update timestamps)
-- ═══════════════════════════════════════════════════════════════════════════

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables
CREATE TRIGGER update_restaurants_updated_at
  BEFORE UPDATE ON restaurants
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_menu_items_updated_at
  BEFORE UPDATE ON menu_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_restaurant_photos_updated_at
  BEFORE UPDATE ON restaurant_photos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_restaurant_reviews_updated_at
  BEFORE UPDATE ON restaurant_reviews
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ═══════════════════════════════════════════════════════════════════════════
-- 6. VIEWS (useful queries)
-- ═══════════════════════════════════════════════════════════════════════════

-- View: Restaurants with menu item count
CREATE OR REPLACE VIEW restaurants_with_menu_stats AS
SELECT
  r.*,
  COUNT(DISTINCT mi.id) as menu_item_count,
  COUNT(DISTINCT CASE WHEN mi.is_signature_dish THEN mi.id END) as signature_dish_count,
  COUNT(DISTINCT rp.id) as photo_count,
  COUNT(DISTINCT rv.id) as review_count_local
FROM restaurants r
LEFT JOIN menu_items mi ON r.id = mi.restaurant_id AND mi.is_active = true
LEFT JOIN restaurant_photos rp ON r.id = rp.restaurant_id
LEFT JOIN restaurant_reviews rv ON r.id = rv.restaurant_id
GROUP BY r.id;

-- View: Popular menu items
CREATE OR REPLACE VIEW popular_menu_items AS
SELECT
  mi.*,
  r.name as restaurant_name,
  r.cuisine_types
FROM menu_items mi
JOIN restaurants r ON mi.restaurant_id = r.id
WHERE mi.is_active = true
  AND mi.popularity_score >= 0.7
ORDER BY mi.popularity_score DESC;

-- ═══════════════════════════════════════════════════════════════════════════
-- 7. SAMPLE DATA FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- Function to get restaurants by cuisine
CREATE OR REPLACE FUNCTION get_restaurants_by_cuisine(cuisine_filter VARCHAR)
RETURNS TABLE (
  id UUID,
  name VARCHAR,
  rating DECIMAL,
  price_level INTEGER,
  address TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT r.id, r.name, r.rating, r.price_level, r.address
  FROM restaurants r
  WHERE cuisine_filter = ANY(r.cuisine_types)
    AND r.is_active = true
  ORDER BY r.rating DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql;

-- Function to search menu items
CREATE OR REPLACE FUNCTION search_menu_items(search_term VARCHAR)
RETURNS TABLE (
  menu_item_id UUID,
  menu_item_name VARCHAR,
  restaurant_name VARCHAR,
  price DECIMAL,
  category VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    mi.id,
    mi.name,
    r.name,
    mi.price,
    mi.category
  FROM menu_items mi
  JOIN restaurants r ON mi.restaurant_id = r.id
  WHERE mi.is_active = true
    AND (
      mi.name ILIKE '%' || search_term || '%'
      OR mi.description ILIKE '%' || search_term || '%'
    )
  ORDER BY mi.popularity_score DESC;
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════════════════
-- END OF SCHEMA
-- ═══════════════════════════════════════════════════════════════════════════
