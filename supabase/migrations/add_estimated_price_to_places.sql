-- Add estimated_price column to ai_generated_places table
-- This stores real prices like "€17", "€25-35 per person", "Free"

ALTER TABLE ai_generated_places
ADD COLUMN IF NOT EXISTS estimated_price TEXT DEFAULT '';
