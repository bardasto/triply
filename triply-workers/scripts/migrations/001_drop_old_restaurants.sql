-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION: Drop Old Restaurant Tables
-- Purpose: Remove old restaurant database tables (Google Policy Compliance)
-- Date: 2025-11-18
-- ═══════════════════════════════════════════════════════════════════════════

-- Drop dependent tables first (foreign key constraints)
DROP TABLE IF EXISTS restaurant_reviews CASCADE;
DROP TABLE IF EXISTS restaurant_photos CASCADE;
DROP TABLE IF EXISTS menu_items CASCADE;
DROP TABLE IF EXISTS restaurants CASCADE;

-- Drop associated views
DROP VIEW IF EXISTS restaurants_with_menu_stats CASCADE;
DROP VIEW IF EXISTS popular_menu_items CASCADE;

-- Drop associated functions
DROP FUNCTION IF EXISTS get_restaurants_by_cuisine(VARCHAR);
DROP FUNCTION IF EXISTS search_menu_items(VARCHAR);

-- Confirm deletion
DO $$
BEGIN
  RAISE NOTICE '✅ Successfully dropped all old restaurant tables';
  RAISE NOTICE '📋 Removed: restaurants, menu_items, restaurant_photos, restaurant_reviews';
  RAISE NOTICE '📋 Removed: views and functions';
END $$;
