-- ═══════════════════════════════════════════════════════════════════════════
-- Check Restaurants Data
-- Queries to verify seeded restaurant data
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. Count all restaurants
SELECT COUNT(*) as total_restaurants FROM restaurants;

-- 2. View all restaurants with ratings
SELECT
  name,
  rating,
  review_count,
  price_level,
  cuisine_types,
  address
FROM restaurants
ORDER BY rating DESC;

-- 3. Count photos by type
SELECT
  photo_type,
  COUNT(*) as count
FROM restaurant_photos
GROUP BY photo_type
ORDER BY count DESC;

-- 4. Count reviews by sentiment
SELECT
  sentiment_label,
  COUNT(*) as count,
  ROUND(AVG(rating), 2) as avg_rating
FROM restaurant_reviews
GROUP BY sentiment_label;

-- 5. Top rated restaurants
SELECT
  r.name,
  r.rating,
  r.review_count,
  COUNT(DISTINCT rp.id) as photo_count,
  COUNT(DISTINCT rv.id) as review_count_local
FROM restaurants r
LEFT JOIN restaurant_photos rp ON r.id = rp.restaurant_id
LEFT JOIN restaurant_reviews rv ON r.id = rv.restaurant_id
GROUP BY r.id, r.name, r.rating, r.review_count
ORDER BY r.rating DESC;

-- 6. Restaurants with most photos
SELECT
  r.name,
  COUNT(rp.id) as photo_count
FROM restaurants r
LEFT JOIN restaurant_photos rp ON r.id = rp.restaurant_id
GROUP BY r.id, r.name
ORDER BY photo_count DESC
LIMIT 10;

-- 7. Average metrics
SELECT
  COUNT(*) as total_restaurants,
  ROUND(AVG(rating), 2) as avg_rating,
  ROUND(AVG(review_count), 0) as avg_reviews,
  ROUND(AVG(price_level), 1) as avg_price_level
FROM restaurants;

-- 8. Cuisine type distribution
SELECT
  UNNEST(cuisine_types) as cuisine,
  COUNT(*) as count
FROM restaurants
GROUP BY cuisine
ORDER BY count DESC;
