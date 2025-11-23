# Quick Start - Применение миграции AI Trips

## Шаг 1: Примени SQL миграцию

### Через Supabase Dashboard (Самый простой способ)

1. Открой https://app.supabase.com
2. Выбери свой проект
3. Перейди в **SQL Editor** (левое меню)
4. Нажми **New Query**
5. Скопируй весь код из файла `create_ai_trips_table.sql`
6. Вставь в редактор
7. Нажми **Run** (или Ctrl+Enter)
8. Должно появиться: ✅ **Success. No rows returned**

## Шаг 2: Проверь что таблица создалась

В том же SQL Editor выполни:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public' AND table_name = 'ai_generated_trips';
```

Должно вернуть:
```
table_name
ai_generated_trips
```

## Шаг 3: Проверь RLS политики

```sql
SELECT policyname
FROM pg_policies
WHERE tablename = 'ai_generated_trips';
```

Должно вернуть 4 политики:
- Users can view their own AI trips
- Users can create their own AI trips
- Users can update their own AI trips
- Users can delete their own AI trips

## Шаг 4: Тестовая вставка (опционально)

Получи свой user_id:

```sql
SELECT auth.uid();
```

Вставь тестовый трип:

```sql
INSERT INTO public.ai_generated_trips (
  user_id,
  title,
  city,
  country,
  description,
  duration_days,
  original_query
) VALUES (
  auth.uid(),  -- Это автоматически подставит твой user_id
  'Test Trip to Paris',
  'Paris',
  'France',
  'A wonderful trip',
  3,
  'romantic weekend in Paris'
) RETURNING id, title, city;
```

Должно вернуть созданный трип.

## Шаг 5: Проверь что трип виден только тебе

```sql
-- Это должно вернуть твой тестовый трип
SELECT id, title, city, created_at
FROM public.ai_generated_trips
WHERE user_id = auth.uid();
```

## Шаг 6: Удали тестовый трип (если создавал)

```sql
DELETE FROM public.ai_generated_trips
WHERE title = 'Test Trip to Paris';
```

## ✅ База данных готова!

Теперь можно переходить к обновлению Flutter кода.

## Что дальше?

1. Обнови `ai_trips_storage_service.dart` для работы с Supabase
2. Замени SharedPreferences на Supabase queries
3. Синхронизация трипов будет работать автоматически между всеми устройствами

## Troubleshooting

### Ошибка: "permission denied for schema public"

Убедись что ты залогинен в Supabase Dashboard и выполняешь запросы как аутентифицированный пользователь.

### Ошибка: "relation already exists"

Таблица уже существует. Если хочешь пересоздать:

```sql
DROP TABLE IF EXISTS public.ai_generated_trips CASCADE;
```

Затем запусти миграцию заново.

### Проверка что RLS работает

```sql
-- Это должно вернуть только ТВОИ трипы
SELECT COUNT(*) FROM public.ai_generated_trips;

-- Попытка вставить трип для другого пользователя должна провалиться
INSERT INTO public.ai_generated_trips (user_id, title, city, country)
VALUES ('00000000-0000-0000-0000-000000000000', 'Test', 'City', 'Country');
-- Ожидаемая ошибка: "new row violates row-level security policy"
```
