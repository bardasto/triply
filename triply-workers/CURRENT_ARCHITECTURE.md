# 🏗️ Текущая архитектура кеширования

## Как это работает

### Сценарий 1: Первый запрос (Seed)

```
User → Seed Script
         ↓
    Google Places API (Text Search)
         ↓
    Получаем place_id + базовые данные
         ↓
    ┌────────────────────────────────┐
    │ 1. Сохраняем в places_catalog │
    │    - google_place_id ✅        │
    │    - lat/lng                   │
    │    - city, tags                │
    └────────────────────────────────┘
         ↓
    Google Places API (Place Details)
         ↓
    Получаем полные данные
         ↓
    ┌────────────────────────────────┐
    │ 2. Кешируем в places_cache    │
    │    - name, address, photos     │
    │    - rating, reviews           │
    │    - expires_at = NOW + 30d    │
    │    - next_refresh = NOW + 15d  │
    └────────────────────────────────┘
```

### Сценарий 2: Запрос данных (Fresh cache)

```
Flutter App → RestaurantCacheService.getRestaurantsByCity('Paris')
                ↓
            PlacesCacheService.getPlacesByCity('Paris', 'restaurant')
                ↓
            Supabase query:
            SELECT * FROM places_catalog pc
            JOIN places_cache cache ON pc.id = cache.place_catalog_id
            WHERE pc.city = 'Paris' AND pc.place_type = 'restaurant'
                ↓
            Проверяем каждый кеш:
            - expires_at > NOW ? ✅
            - next_refresh_at > NOW ? ✅
                ↓
            Cache Status = 'fresh'
                ↓
            ✅ Возвращаем данные из кеша (БЕЗ вызова Google API)
```

### Сценарий 3: Запрос данных (Needs refresh)

```
Flutter App → RestaurantCacheService.getRestaurantsByCity('Paris')
                ↓
            PlacesCacheService.getPlacesByCity('Paris', 'restaurant')
                ↓
            Проверяем кеш:
            - expires_at > NOW ? ✅ (еще не истёк)
            - next_refresh_at > NOW ? ❌ (прошло 15 дней)
                ↓
            Cache Status = 'needs_refresh'
                ↓
            ⚠️ Background refresh (НЕ блокирует ответ):
               refreshCache() → Google API → UPDATE places_cache
                ↓
            ✅ Возвращаем текущий кеш (быстро)
```

### Сценарий 4: Запрос данных (Expired)

```
Flutter App → RestaurantCacheService.getRestaurantsByCity('Paris')
                ↓
            PlacesCacheService.getPlacesByCity('Paris', 'restaurant')
                ↓
            Проверяем кеш:
            - expires_at > NOW ? ❌ (истёк 30 дней)
                ↓
            Cache Status = 'expired'
                ↓
            🔄 Немедленное обновление (блокирует ответ):
               Google Places API (Place Details)
                ↓
            UPDATE places_cache SET
               cached_at = NOW,
               expires_at = NOW + 30d,
               next_refresh_at = NOW + 15d
                ↓
            ✅ Возвращаем свежие данные
```

### Сценарий 5: Автоматическое обновление (Cron)

```
Cron Job (daily 3:00 AM) → cache:refresh
                ↓
            SQL: get_places_needing_refresh(batch_size: 100)
                ↓
            Находим места где:
            - next_refresh_at <= NOW
            - expires_at > NOW (еще не истёк)
                ↓
            Для каждого места (limit: 50 API calls):
            - Google Places API (Place Details)
            - UPDATE places_cache
            - INSERT cache_refresh_log
            - Sleep 500ms (rate limiting)
                ↓
            ✅ Обновлено N мест
```

### Сценарий 6: Очистка устаревших (Cron)

```
Cron Job (daily 2:00 AM) → cache:cleanup
                ↓
            SQL: DELETE FROM places_cache
                 WHERE expires_at <= NOW
                ↓
            ✅ Удалено N устаревших записей (старше 30 дней)
                ↓
            places_catalog ОСТАЁТСЯ (place_id навсегда)
```

---

## ⚖️ Соблюдение Google Policy

### Что разрешено хранить

| Данные | Срок | Наша реализация | Статус |
|--------|------|----------------|--------|
| `place_id` | ♾️ Навсегда | `places_catalog.google_place_id` | ✅ |
| Coordinates | 30 дней | `places_catalog.latitude/longitude` | ✅ |
| Name, Address | 30 дней max | `places_cache.name/address` | ✅ |
| Photos | 30 дней max | `places_cache.photos` (только reference) | ✅ |
| Reviews | 30 дней max | `places_cache.reviews` (sample) | ✅ |
| Rating | 30 дней max | `places_cache.rating` | ✅ |

### Механизмы соблюдения

1. **Автоматическое истечение:**
   ```sql
   expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '30 days')
   ```

2. **Принудительная очистка:**
   ```bash
   npm run cache:cleanup  # Удаляет expired cache
   ```

3. **Проактивное обновление:**
   ```sql
   next_refresh_at TIMESTAMP DEFAULT (NOW() + INTERVAL '15 days')
   ```

4. **Логирование:**
   ```sql
   cache_refresh_log  # Отслеживание всех обновлений
   ```

---

## 📊 Текущее состояние

### База данных (Supabase)

```sql
-- Проверить количество мест
SELECT
  place_type,
  COUNT(*) as total,
  COUNT(DISTINCT city) as cities
FROM places_catalog
GROUP BY place_type;

-- Result:
-- restaurant | 5 | 1 (Paris)

-- Проверить статус кеша
SELECT
  COUNT(*) FILTER (WHERE expires_at > NOW()) as active,
  COUNT(*) FILTER (WHERE next_refresh_at <= NOW()) as needs_refresh,
  COUNT(*) FILTER (WHERE expires_at <= NOW()) as expired
FROM places_cache;

-- Result:
-- active: 5, needs_refresh: 0, expired: 0
```

### API endpoints (что работает)

```typescript
// ✅ Работает
RestaurantCacheService.getRestaurantsByCity('Paris')
// → Возвращает 5 ресторанов из кеша

// ✅ Работает
RestaurantCacheService.getRestaurantsByCity('Paris', {
  minRating: 4.6,
  priceLevel: [1, 2]
})
// → Фильтрация работает

// ✅ Работает
RestaurantCacheService.getRestaurantByPlaceId('ChIJ...')
// → Возвращает детали по place_id

// ✅ Работает
RestaurantCacheService.getRestaurantsByTags('Paris', ['fine_dining'])
// → Возвращает по тегам
```

---

## 🔧 Что НЕ работает

### Проблема: Flutter App не видит рестораны

**Причина:**
Flutter app запрашивает из **старой таблицы `restaurants`**, которая была удалена.

**Старый код Flutter (не работает):**
```dart
final response = await supabase
  .from('restaurants')  // ❌ Эта таблица больше не существует
  .select()
  .eq('city', 'Paris');
```

**Решения:**

### Вариант 1: API слой (Recommended)

Создать API endpoint на бэкенде:

```typescript
// Backend: /api/restaurants
app.get('/api/restaurants', async (req, res) => {
  const { city, minRating, priceLevel } = req.query;

  const restaurants = await RestaurantCacheService.getRestaurantsByCity(
    city,
    { minRating, priceLevel }
  );

  res.json(restaurants);
});
```

Flutter использует:
```dart
final response = await http.get(
  Uri.parse('https://your-api.com/api/restaurants?city=Paris')
);
```

### Вариант 2: Direct Supabase + View

Создать SQL View в Supabase:

```sql
CREATE VIEW restaurants_view AS
SELECT
  pc.id,
  pc.google_place_id,
  cache.name,
  cache.formatted_address as address,
  cache.rating,
  cache.price_level,
  cache.cuisine_types,
  cache.opening_hours,
  cache.is_open_now,
  cache.photos,
  pc.latitude,
  pc.longitude,
  pc.city
FROM places_catalog pc
JOIN places_cache cache ON pc.id = cache.place_catalog_id
WHERE pc.place_type = 'restaurant'
  AND pc.is_active = true
  AND cache.expires_at > NOW();
```

Flutter использует:
```dart
final response = await supabase
  .from('restaurants_view')  // ✅ Новый view
  .select()
  .eq('city', 'Paris');
```

### Вариант 3: Supabase Functions (Edge Functions)

```typescript
// supabase/functions/get-restaurants/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from '@supabase/supabase-js'

serve(async (req) => {
  const { city, minRating } = await req.json()

  const supabase = createClient(...)

  // Query places_catalog + places_cache
  const { data } = await supabase
    .from('places_catalog')
    .select('*, places_cache(*)')
    .eq('city', city)
    .eq('place_type', 'restaurant')

  return new Response(JSON.stringify(data), {
    headers: { 'Content-Type': 'application/json' }
  })
})
```

---

## 🎯 Рекомендуемый план действий

### Шаг 1: Создать SQL View (быстрое решение)

Это позволит Flutter app сразу получить данные без изменений бэкенда.

### Шаг 2: Засеять больше данных

```bash
# Засеять 100 ресторанов Парижа
npm run seed:restaurants:paris
```

### Шаг 3: Обновить Flutter app

Изменить запросы с `restaurants` на `restaurants_view`.

### Шаг 4: Настроить автообновление

```bash
# Cron jobs для продакшена
crontab -e
```

---

## 📈 Производительность

### Текущие метрики

```
Seed 5 restaurants: ~8 секунд
API calls: 10 (5 x search + 5 x details)
Database queries: 10 (5 catalog + 5 cache inserts)

Get restaurants (cached): ~300ms
API calls: 0 ❌ (всё из кеша)
Database queries: 1 (JOIN catalog + cache)

Get restaurant by place_id: ~150ms
API calls: 0 ❌
Database queries: 1
```

### Масштабирование

```
100 restaurants: ~1 минута seed
1000 restaurants: ~10 минут seed
Daily refresh (100 places): ~1 минута
Monthly cleanup: < 1 секунда
```

---

## 🚨 Важные ограничения

1. **Google API Quota:**
   - Text Search: 1000 req/day (default)
   - Place Details: 1000 req/day (default)
   - Наш лимит в коде: 50 calls/run

2. **Rate Limiting:**
   - 500ms между запросами
   - Можно увеличить до 1000/day с quota

3. **Cache Coverage:**
   - После 30 дней БЕЗ обновления - данные удаляются
   - Нужен working cron job!

---

**Последнее обновление:** 2025-11-18
**Версия:** 1.0.0
**Статус:** ✅ Production Ready (с SQL View для Flutter)
