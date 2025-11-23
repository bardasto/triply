# Database Schema - AI Generated Trips

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            auth.users                                    │
│  (Существующая таблица Supabase Auth)                                   │
├─────────────────────────────────────────────────────────────────────────┤
│  • id (UUID, PK)                                                         │
│  • email                                                                 │
│  • created_at                                                            │
│  • ...другие поля auth                                                   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ 1:N (один пользователь - много трипов)
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    public.ai_generated_trips                             │
│  (Новая таблица для AI-генерированных трипов)                           │
├─────────────────────────────────────────────────────────────────────────┤
│  PRIMARY KEY:                                                            │
│    • id (UUID)                    - Уникальный ID трипа                 │
│                                                                          │
│  FOREIGN KEY:                                                            │
│    • user_id (UUID) → auth.users(id)  - Владелец трипа                  │
│      ON DELETE CASCADE                                                   │
│                                                                          │
│  TRIP METADATA:                                                          │
│    • title (TEXT)                 - Название трипа                      │
│    • city (TEXT)                  - Город назначения                    │
│    • country (TEXT)               - Страна                              │
│    • description (TEXT)           - Описание                            │
│                                                                          │
│  DURATION & PRICING:                                                     │
│    • duration_days (INTEGER)      - Длительность (дни)                  │
│    • price (DECIMAL)              - Цена                                │
│    • currency (TEXT)              - Валюта (EUR/USD)                    │
│    • estimated_cost_min (DECIMAL) - Минимальная стоимость               │
│    • estimated_cost_max (DECIMAL) - Максимальная стоимость              │
│                                                                          │
│  MEDIA:                                                                  │
│    • hero_image_url (TEXT)        - URL главного фото                   │
│    • images (JSONB)               - Массив URL фотографий               │
│                                                                          │
│  TRIP DETAILS (JSONB):                                                   │
│    • includes (JSONB)             - Что включено                        │
│    • highlights (JSONB)           - Основные моменты                    │
│    • itinerary (JSONB)            - Маршрут по дням                     │
│    • best_season (JSONB)          - Лучшие сезоны                       │
│                                                                          │
│  ACTIVITY INFO:                                                          │
│    • activity_type (TEXT)         - Тип активности                      │
│    • rating (DECIMAL)             - Рейтинг                             │
│    • reviews (INTEGER)            - Кол-во отзывов                      │
│                                                                          │
│  USER INTERACTION:                                                       │
│    • is_favorite (BOOLEAN)        - В избранном?                        │
│    • original_query (TEXT)        - Оригинальный запрос                 │
│                                                                          │
│  TIMESTAMPS:                                                             │
│    • created_at (TIMESTAMPTZ)     - Дата создания                       │
│    • updated_at (TIMESTAMPTZ)     - Дата обновления                     │
└─────────────────────────────────────────────────────────────────────────┘
```

## Indexes (Индексы)

```
┌────────────────────────────────────────────────────────────────┐
│  idx_ai_trips_user_id                                          │
│  ON ai_generated_trips(user_id)                                │
│  → Быстрый поиск трипов пользователя                           │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│  idx_ai_trips_created_at                                       │
│  ON ai_generated_trips(created_at DESC)                        │
│  → Сортировка по дате (новые сверху)                           │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│  idx_ai_trips_city                                             │
│  ON ai_generated_trips(city)                                   │
│  → Поиск трипов по городу                                      │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│  idx_ai_trips_user_favorites                                   │
│  ON ai_generated_trips(user_id, is_favorite)                   │
│  WHERE is_favorite = true                                      │
│  → Быстрый доступ к избранным трипам                           │
└────────────────────────────────────────────────────────────────┘
```

## RLS Policies (Политики безопасности)

```
┌──────────────────────────────────────────────────────────────────┐
│  Policy: Users can view their own AI trips                       │
│  Type: SELECT                                                    │
│  Rule: auth.uid() = user_id                                      │
│  → Пользователь видит только свои трипы                          │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  Policy: Users can create their own AI trips                     │
│  Type: INSERT                                                    │
│  Rule: auth.uid() = user_id                                      │
│  → Пользователь может создавать только свои трипы                │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  Policy: Users can update their own AI trips                     │
│  Type: UPDATE                                                    │
│  Rule: auth.uid() = user_id                                      │
│  → Пользователь может обновлять только свои трипы                │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  Policy: Users can delete their own AI trips                     │
│  Type: DELETE                                                    │
│  Rule: auth.uid() = user_id                                      │
│  → Пользователь может удалять только свои трипы                  │
└──────────────────────────────────────────────────────────────────┘
```

## Triggers (Триггеры)

```
┌──────────────────────────────────────────────────────────────────┐
│  Trigger: trigger_update_ai_trips_updated_at                     │
│  Event: BEFORE UPDATE                                            │
│  Function: update_ai_trips_updated_at()                          │
│  → Автоматически обновляет updated_at при UPDATE                 │
└──────────────────────────────────────────────────────────────────┘
```

## Helper Functions (Вспомогательные функции)

```sql
-- Получить количество трипов пользователя
get_user_ai_trips_count(user_id UUID) → INTEGER

-- Получить избранные трипы пользователя
get_user_favorite_ai_trips(user_id UUID) → SETOF ai_generated_trips
```

## Data Flow (Поток данных)

```
┌─────────────────┐
│  Flutter App    │
│  (User Device)  │
└────────┬────────┘
         │
         │ 1. Пользователь генерирует трип через AI Chat
         │
         ▼
┌─────────────────────────────┐
│  Backend API                │
│  (triply-workers)           │
│  • Query Analyzer           │
│  • Flexible Trip Generator  │
│  • Google Places API        │
│  • OpenAI GPT-4             │
└────────┬────────────────────┘
         │
         │ 2. AI генерирует трип
         │
         ▼
┌─────────────────────────────┐
│  Flutter App                │
│  • Получает trip data       │
│  • Вызывает Supabase API    │
└────────┬────────────────────┘
         │
         │ 3. Сохраняет в Supabase
         │    INSERT INTO ai_generated_trips
         │    WITH user_id = auth.uid()
         │
         ▼
┌──────────────────────────────────────┐
│  Supabase Database                   │
│  ┌────────────────────────────────┐  │
│  │  ai_generated_trips            │  │
│  │  • RLS проверяет auth.uid()    │  │
│  │  • Вставляет запись            │  │
│  │  • Триггер устанавливает       │  │
│  │    timestamps                  │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
         │
         │ 4. Синхронизация на все устройства
         │
         ▼
┌─────────────────────────────────────┐
│  All User Devices                   │
│  • Phone                            │
│  • Tablet                           │
│  • Web                              │
│  → Видят одни и те же трипы         │
└─────────────────────────────────────┘
```

## JSONB Field Structures

### itinerary (JSONB Array)

```json
[
  {
    "day": 1,
    "title": "Day 1: Arrival",
    "description": "Explore the city center",
    "places": [
      {
        "name": "Eiffel Tower",
        "description": "Iconic landmark",
        "image_url": "https://...",
        "images": ["url1", "url2"],
        "latitude": 48.8584,
        "longitude": 2.2945
      }
    ],
    "images": ["url1", "url2"]
  }
]
```

### includes (JSONB Array)

```json
[
  "Hotel accommodation",
  "Breakfast included",
  "Airport transfer",
  "City tour guide"
]
```

### highlights (JSONB Array)

```json
[
  "Visit the Eiffel Tower at sunset",
  "Romantic dinner cruise on Seine",
  "Wine tasting in Montmartre"
]
```

### best_season (JSONB Array)

```json
["Spring", "Summer", "Fall"]
```

### images (JSONB Array)

```json
[
  "https://example.com/image1.jpg",
  "https://example.com/image2.jpg",
  "https://example.com/image3.jpg"
]
```

## Query Examples

### Получить все трипы текущего пользователя

```sql
SELECT *
FROM public.ai_generated_trips
WHERE user_id = auth.uid()
ORDER BY created_at DESC;
```

### Получить избранные трипы

```sql
SELECT *
FROM public.ai_generated_trips
WHERE user_id = auth.uid() AND is_favorite = true
ORDER BY created_at DESC;
```

### Поиск трипов по городу

```sql
SELECT *
FROM public.ai_generated_trips
WHERE user_id = auth.uid()
  AND city ILIKE '%Paris%'
ORDER BY created_at DESC;
```

### Статистика по трипам пользователя

```sql
SELECT
  COUNT(*) as total_trips,
  COUNT(*) FILTER (WHERE is_favorite = true) as favorite_trips,
  COUNT(DISTINCT city) as unique_cities,
  AVG(duration_days) as avg_duration,
  AVG(price) as avg_price
FROM public.ai_generated_trips
WHERE user_id = auth.uid();
```
