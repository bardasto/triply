# ⚠️ ВАЖНО: Migration 004 НЕ БЫЛА ПРИМЕНЕНА

## Проблема

В Flutter логах видно:
```
❌ Error: Could not find a relationship between 'restaurants' and 'restaurant_photos'
✅ Loaded 0 restaurants from database
```

**Это означает что Migration 004 НЕ была применена.**

3 ресторана которые ты видишь - это из **saved trip itinerary**, а не из базы данных.

---

## 🔧 Решение (ПРОСТОЕ - 3 шага)

### Шаг 1: Открой Supabase SQL Editor

1. Перейди: https://supabase.com/dashboard/project/yhlpcoxyzmrahmjqlshe/sql/new
2. Или: Dashboard → SQL Editor → New Query

### Шаг 2: Скопируй и выполни этот SQL

```sql
-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION 004: Fix Restaurants View with Photos
-- ═══════════════════════════════════════════════════════════════════════════

-- Drop existing views
DROP VIEW IF EXISTS restaurant_reviews CASCADE;
DROP VIEW IF EXISTS restaurant_photos CASCADE;
DROP VIEW IF EXISTS restaurants CASCADE;

-- Create restaurants view with embedded photos
CREATE OR REPLACE VIEW restaurants AS
WITH photo_data AS (
  SELECT
    pc.id as restaurant_id,
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
    CASE
      WHEN cache.photos IS NOT NULL AND jsonb_array_length(cache.photos) > 0 THEN
        'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=' ||
        (cache.photos->0->>'photo_reference') ||
        '&key=AIzaSyBIWSw-eLxzzsuPcQxstnXBXcZTGh-nDrA'
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
  cache.name,
  NULL::TEXT as description,
  cache.cuisine_types,
  cache.formatted_address as address,
  pc.latitude,
  pc.longitude,
  cache.international_phone_number as phone,
  cache.website,
  cache.rating,
  cache.user_ratings_total as review_count,
  cache.rating as google_rating,
  cache.user_ratings_total as google_review_count,
  cache.price_level,
  NULL::DECIMAL as average_price_per_person,
  'EUR' as currency,
  cache.opening_hours,
  cache.is_open_now,
  pc.google_place_id,
  NULL::VARCHAR as foursquare_id,
  pc.tags as features,
  ARRAY[]::VARCHAR[] as dietary_options,
  false as has_menu,
  NULL::TIMESTAMP as menu_last_updated_at,
  pc.is_active,
  cache.cached_at as last_verified_at,
  pc.created_at,
  pc.updated_at,
  pd.photos_array as photos,
  CASE
    WHEN pd.photos_array IS NOT NULL THEN
      (
        SELECT array_agg(elem->>'photo_url')
        FROM jsonb_array_elements(pd.photos_array) elem
      )
    ELSE ARRAY[]::TEXT[]
  END as images,
  pd.primary_photo_url as image_url
FROM places_catalog pc
INNER JOIN places_cache cache ON pc.id = cache.place_catalog_id
LEFT JOIN photo_data pd ON pc.id = pd.restaurant_id
WHERE pc.place_type = 'restaurant'
  AND pc.is_active = true
  AND cache.expires_at > NOW();
```

### Шаг 3: Нажми "Run"

Должно показать:
```
Success. No rows returned
```

### Шаг 4: Проверь что работает

Выполни в том же SQL Editor:
```sql
SELECT name, address, array_length(images, 1) as photo_count
FROM restaurants
LIMIT 5;
```

Должно вернуть 5 ресторанов с фото.

### Шаг 5: Перезапусти Flutter

```bash
flutter run
# Или нажми 'R' для hot restart
```

---

## ✅ Результат

После применения миграции:
- ✅ "View All" откроет карту с 5 ресторанами
- ✅ Фото будут отображаться
- ✅ Рейтинги, адреса, часы работы - всё будет работать

---

## Почему не сработало автоматически?

Supabase JS client **не может выполнять DDL команды** (CREATE VIEW, DROP VIEW) напрямую из TypeScript.

Нужно использовать SQL Editor или прямое PostgreSQL подключение.

---

**Готов? Просто скопируй SQL выше и выполни в Supabase SQL Editor!** 🚀
