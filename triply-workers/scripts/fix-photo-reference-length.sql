-- ═══════════════════════════════════════════════════════════════════════════
-- Fix photo_reference field length
-- Google Places photo references can be longer than 255 characters
-- ═══════════════════════════════════════════════════════════════════════════

-- Change photo_reference from VARCHAR(255) to TEXT
ALTER TABLE restaurant_photos
  ALTER COLUMN photo_reference TYPE TEXT;

-- Verify the change
SELECT
  column_name,
  data_type,
  character_maximum_length
FROM information_schema.columns
WHERE table_name = 'restaurant_photos'
  AND column_name = 'photo_reference';
