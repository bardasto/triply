# AI Generated Trips - Database Setup

## Обзор

Эта миграция создает таблицу `ai_generated_trips` в Supabase для хранения AI-генерированных трипов пользователей.

## Структура таблицы

### ai_generated_trips

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | UUID | Уникальный ID трипа (primary key) |
| `user_id` | UUID | ID пользователя (foreign key → auth.users) |
| `title` | TEXT | Название трипа |
| `city` | TEXT | Город |
| `country` | TEXT | Страна |
| `description` | TEXT | Описание трипа |
| `duration_days` | INTEGER | Длительность в днях (default: 3) |
| `price` | DECIMAL | Цена |
| `currency` | TEXT | Валюта (default: 'EUR') |
| `hero_image_url` | TEXT | URL главного изображения |
| `images` | JSONB | Массив URL изображений |
| `includes` | JSONB | Что включено в трип |
| `highlights` | JSONB | Основные моменты |
| `itinerary` | JSONB | Маршрут по дням с местами |
| `rating` | DECIMAL | Рейтинг (default: 4.5) |
| `reviews` | INTEGER | Количество отзывов |
| `estimated_cost_min` | DECIMAL | Минимальная стоимость |
| `estimated_cost_max` | DECIMAL | Максимальная стоимость |
| `activity_type` | TEXT | Тип активности |
| `best_season` | JSONB | Лучшие сезоны для поездки |
| `is_favorite` | BOOLEAN | Избранное (default: false) |
| `original_query` | TEXT | Оригинальный запрос пользователя |
| `created_at` | TIMESTAMPTZ | Дата создания |
| `updated_at` | TIMESTAMPTZ | Дата обновления |

## Индексы

Созданы следующие индексы для оптимизации запросов:

1. `idx_ai_trips_user_id` - для быстрого поиска трипов пользователя
2. `idx_ai_trips_created_at` - для сортировки по дате
3. `idx_ai_trips_city` - для поиска по городу
4. `idx_ai_trips_user_favorites` - для быстрого доступа к избранным

## Row Level Security (RLS)

Включены следующие политики безопасности:

### SELECT Policy
- Пользователи видят **только свои** трипы
- `WHERE auth.uid() = user_id`

### INSERT Policy
- Пользователи могут создавать трипы **только для себя**
- `WITH CHECK (auth.uid() = user_id)`

### UPDATE Policy
- Пользователи могут обновлять **только свои** трипы
- `USING (auth.uid() = user_id)`

### DELETE Policy
- Пользователи могут удалять **только свои** трипы
- `USING (auth.uid() = user_id)`

## Триггеры

### Автоматическое обновление `updated_at`
При каждом UPDATE автоматически обновляется поле `updated_at`

## Вспомогательные функции

### `get_user_ai_trips_count(user_id)`
Возвращает количество трипов пользователя

```sql
SELECT public.get_user_ai_trips_count('user-uuid-here');
```

### `get_user_favorite_ai_trips(user_id)`
Возвращает все избранные трипы пользователя

```sql
SELECT * FROM public.get_user_favorite_ai_trips('user-uuid-here');
```

## Применение миграции

### Вариант 1: Через Supabase Dashboard (Рекомендуется)

1. Открой [Supabase Dashboard](https://app.supabase.com)
2. Выбери свой проект
3. Перейди в **SQL Editor**
4. Создай новый запрос
5. Скопируй содержимое файла `create_ai_trips_table.sql`
6. Вставь в редактор и нажми **Run**

### Вариант 2: Через Supabase CLI

```bash
# Убедись что Supabase CLI установлен
supabase --version

# Перейди в директорию проекта
cd /Users/heorhii.fedulov/development/travel_ai_new

# Примени миграцию
supabase db push

# Или если используешь локальную разработку
supabase migration up
```

## Тестирование

После применения миграции, используй файл `test_queries.sql` для проверки:

```bash
# В Supabase SQL Editor выполни запросы из test_queries.sql
```

### Пример: Вставить тестовый трип

```sql
-- Замени YOUR_USER_ID на реальный ID пользователя
INSERT INTO public.ai_generated_trips (
  user_id,
  title,
  city,
  country,
  description,
  duration_days,
  original_query
) VALUES (
  'YOUR_USER_ID'::uuid,
  'Test Trip to Paris',
  'Paris',
  'France',
  'A wonderful trip to the City of Light',
  3,
  'romantic weekend in Paris'
);
```

### Пример: Получить трипы пользователя

```sql
SELECT
  id,
  title,
  city,
  country,
  duration_days,
  created_at
FROM public.ai_generated_trips
WHERE user_id = auth.uid()
ORDER BY created_at DESC;
```

## JSONB Структура

### Itinerary Format

```json
[
  {
    "day": 1,
    "title": "Arrival Day",
    "description": "Explore the city",
    "places": [
      {
        "name": "Eiffel Tower",
        "description": "Iconic landmark",
        "image_url": "https://...",
        "images": ["url1", "url2"]
      }
    ],
    "images": ["url1", "url2"]
  }
]
```

### Images Format

```json
[
  "https://image1.url",
  "https://image2.url",
  "https://image3.url"
]
```

## Безопасность

✅ **RLS включен** - пользователи видят только свои данные
✅ **Cascade Delete** - при удалении пользователя удаляются его трипы
✅ **JSONB validation** - данные хранятся в структурированном формате
✅ **Timestamps** - автоматическое отслеживание создания и обновления

## Следующие шаги

После применения миграции:

1. ✅ Обнови Flutter код для работы с Supabase
2. ✅ Замени SharedPreferences на Supabase queries
3. ✅ Добавь синхронизацию трипов между устройствами
4. ✅ Реализуй функционал избранного (is_favorite)

## Rollback (Откат миграции)

Если нужно откатить изменения:

```sql
-- Удалить таблицу и все связанные объекты
DROP TABLE IF EXISTS public.ai_generated_trips CASCADE;

-- Удалить функции
DROP FUNCTION IF EXISTS public.update_ai_trips_updated_at() CASCADE;
DROP FUNCTION IF EXISTS public.get_user_ai_trips_count(UUID);
DROP FUNCTION IF EXISTS public.get_user_favorite_ai_trips(UUID);
```

## Проверка RLS

Для проверки работы RLS:

```sql
-- Должно вернуть только трипы текущего пользователя
SELECT COUNT(*) FROM public.ai_generated_trips;

-- Попытка вставить трип для другого пользователя должна провалиться
INSERT INTO public.ai_generated_trips (user_id, title, city, country)
VALUES ('00000000-0000-0000-0000-000000000000', 'Test', 'City', 'Country');
-- Должно вернуть ошибку: "new row violates row-level security policy"
```
