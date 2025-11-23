# Flutter + Supabase Integration для AI Trips

## ✅ Что было сделано

### 1. Database Schema (Supabase)
- ✅ Создана таблица `ai_generated_trips` в Supabase
- ✅ Row Level Security (RLS) - каждый пользователь видит только свои трипы
- ✅ Индексы для быстрых запросов
- ✅ Триггеры для автоматического обновления `updated_at`
- ✅ Foreign key к `auth.users` с CASCADE DELETE

### 2. Flutter Code Updates
- ✅ Переписан `ai_trips_storage_service.dart` для работы с Supabase
- ✅ Заменен SharedPreferences на Supabase queries
- ✅ Добавлена real-time синхронизация трипов
- ✅ Обновлен `ai_chat_screen.dart` - сохраняет `original_query`
- ✅ Обновлен `ai_trips_screen.dart` - загружает из Supabase с real-time обновлениями
- ✅ Функционал избранного (`is_favorite`) работает с базой данных

## 🚀 Как это работает

### Поток данных

```
┌──────────────────┐
│  User в Flutter  │
│  Генерирует трип │
└────────┬─────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│  Backend API (triply-workers)           │
│  • AI анализирует запрос                │
│  • Генерирует трип                      │
│  • Возвращает trip data                 │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│  Flutter App                            │
│  • Получает trip data                   │
│  • Добавляет original_query             │
│  • Вызывает AiTripsStorageService       │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│  Supabase Database                      │
│  • Проверяет RLS (auth.uid)             │
│  • Вставляет трип с user_id             │
│  • Триггер устанавливает timestamps     │
│  • Real-time событие отправляется       │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│  All User Devices (Real-time)           │
│  • Phone автоматически обновляется      │
│  • Tablet автоматически обновляется     │
│  • Web автоматически обновляется        │
└─────────────────────────────────────────┘
```

## 📦 Обновленные файлы

### Backend
- `supabase/migrations/create_ai_trips_table.sql` - SQL миграция
- `supabase/DATABASE_SETUP.md` - документация БД
- `supabase/DATABASE_SCHEMA.md` - схема БД
- `supabase/test_queries.sql` - тестовые запросы
- `supabase/QUICK_START.md` - быстрый старт

### Frontend
- `lib/core/services/ai_trips_storage_service.dart` - сервис работы с Supabase
- `lib/presentation/screens/ai_chat/ai_chat_screen.dart` - сохранение при генерации
- `lib/presentation/screens/trips/ai_trips_screen.dart` - отображение трипов
- `lib/presentation/screens/home/home_screen.dart` - навигация

## 🔧 Новые возможности сервиса

### AiTripsStorageService

```dart
// Сохранить трип
await AiTripsStorageService.saveTrip(tripData);

// Получить все трипы пользователя
final trips = await AiTripsStorageService.getAllTrips();

// Получить только избранные
final favorites = await AiTripsStorageService.getFavoriteTrips();

// Удалить трип
await AiTripsStorageService.deleteTrip(tripId);

// Переключить избранное
await AiTripsStorageService.toggleFavorite(tripId, true);

// Получить трип по ID
final trip = await AiTripsStorageService.getTripById(tripId);

// Поиск по городу
final parisTrips = await AiTripsStorageService.getTripsByCity('Paris');

// Статистика
final stats = await AiTripsStorageService.getTripStatistics();
// {
//   'total_trips': 15,
//   'favorite_trips': 3,
//   'unique_cities': 8,
//   'avg_duration': 3.5
// }
```

### Real-time Синхронизация

```dart
// Подписаться на изменения
RealtimeChannel? channel;

@override
void initState() {
  super.initState();
  channel = AiTripsStorageService.subscribeToTrips((trips) {
    setState(() {
      _trips = trips;
    });
  });
}

// Отписаться
@override
void dispose() {
  if (channel != null) {
    AiTripsStorageService.unsubscribeFromTrips(channel!);
  }
  super.dispose();
}
```

## 🔒 Безопасность

### Row Level Security (RLS)

Все запросы автоматически фильтруются по `user_id`:

```sql
-- Пользователь видит только свои трипы
SELECT * FROM ai_generated_trips;
-- Автоматически добавляется: WHERE user_id = auth.uid()

-- Попытка получить чужой трип вернет пустой результат
SELECT * FROM ai_generated_trips WHERE id = 'чужой-id';
-- Результат: []

-- Невозможно вставить трип для другого пользователя
INSERT INTO ai_generated_trips (user_id, ...) VALUES ('другой-user-id', ...);
-- Ошибка: "new row violates row-level security policy"
```

## 📱 User Experience

### До (SharedPreferences)
- ❌ Трипы хранятся только локально на одном устройстве
- ❌ Переустановка приложения = потеря всех трипов
- ❌ Нет синхронизации между устройствами
- ❌ Ограничение размера данных

### После (Supabase)
- ✅ Трипы доступны на всех устройствах пользователя
- ✅ Переустановка приложения = трипы остаются
- ✅ Автоматическая синхронизация в real-time
- ✅ Неограниченное хранилище
- ✅ Возможность бэкапов и восстановления

## 🧪 Тестирование

### 1. Проверка сохранения

```dart
// Сгенерируй трип через AI Chat
// Запрос: "romantic weekend in Paris"

// Проверь в Supabase Dashboard:
SELECT id, title, city, original_query, created_at
FROM ai_generated_trips
WHERE user_id = auth.uid()
ORDER BY created_at DESC
LIMIT 1;

// Должен вернуть только что созданный трип
```

### 2. Проверка RLS

```dart
// Войди под разными пользователями
// User A генерирует трип
// User B не должен его видеть

// В Supabase:
SELECT COUNT(*) FROM ai_generated_trips;
// User A: 1
// User B: 0
```

### 3. Проверка Real-time

```dart
// Открой приложение на двух устройствах
// Device 1: Сгенерируй трип
// Device 2: Должен автоматически появиться новый трип
```

## 🐛 Troubleshooting

### Ошибка: "User not authenticated"

```dart
// Проверь что пользователь залогинен
final user = Supabase.instance.client.auth.currentUser;
if (user == null) {
  // Перенаправь на экран логина
  Navigator.pushReplacementNamed(context, '/login');
}
```

### Ошибка: "table ai_generated_trips does not exist"

```bash
# Примени миграцию в Supabase Dashboard
# SQL Editor → Вставь содержимое create_ai_trips_table.sql → Run
```

### Трипы не сохраняются

```dart
// Проверь логи
try {
  await AiTripsStorageService.saveTrip(trip);
} catch (e) {
  print('Error saving trip: $e');
}

// Проверь в Supabase Dashboard → Table Editor → ai_generated_trips
// Должны появиться новые записи
```

### Real-time не работает

```dart
// Проверь что включил Real-time в Supabase Dashboard
// Settings → API → Realtime → Enable

// Проверь что подписка активна
print('Channel status: ${channel?.status}');
// Должно быть: joined
```

## 📊 Мониторинг

### Проверка данных в Supabase

```sql
-- Количество трипов по пользователям
SELECT
  u.email,
  COUNT(t.id) as trip_count
FROM auth.users u
LEFT JOIN ai_generated_trips t ON t.user_id = u.id
GROUP BY u.id, u.email
ORDER BY trip_count DESC;

-- Самые популярные города
SELECT
  city,
  COUNT(*) as times_generated
FROM ai_generated_trips
GROUP BY city
ORDER BY times_generated DESC
LIMIT 10;

-- Средняя длительность трипов
SELECT AVG(duration_days) as avg_duration
FROM ai_generated_trips;
```

## 🔄 Миграция старых данных

Если у пользователей есть старые трипы в SharedPreferences:

```dart
// Добавь этот код в initState главного экрана (один раз)
Future<void> _migrateOldTrips() async {
  final prefs = await SharedPreferences.getInstance();
  final oldTripsJson = prefs.getStringList('ai_generated_trips') ?? [];

  if (oldTripsJson.isEmpty) return;

  for (final tripJson in oldTripsJson) {
    try {
      final trip = jsonDecode(tripJson);
      await AiTripsStorageService.saveTrip(trip);
    } catch (e) {
      print('Error migrating trip: $e');
    }
  }

  // Удали старые данные после успешной миграции
  await prefs.remove('ai_generated_trips');
  print('Migration completed: ${oldTripsJson.length} trips migrated');
}
```

## 🎯 Следующие шаги

1. ✅ База данных создана и настроена
2. ✅ Flutter код обновлен
3. ⏳ Протестируй на реальном устройстве
4. ⏳ Добавь error handling для offline режима
5. ⏳ Реализуй кеширование для быстрой загрузки

## 💡 Best Practices

### 1. Обработка ошибок

```dart
try {
  await AiTripsStorageService.saveTrip(trip);
} catch (e) {
  if (e.toString().contains('not authenticated')) {
    // Перенаправь на логин
  } else {
    // Покажи ошибку пользователю
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save trip: $e')),
    );
  }
}
```

### 2. Loading States

```dart
bool _isLoading = true;

@override
void initState() {
  super.initState();
  _loadTrips();
}

Future<void> _loadTrips() async {
  setState(() => _isLoading = true);
  try {
    final trips = await AiTripsStorageService.getAllTrips();
    setState(() {
      _trips = trips;
      _isLoading = false;
    });
  } catch (e) {
    setState(() => _isLoading = false);
    // Handle error
  }
}
```

### 3. Optimistic Updates

```dart
// Сразу обновляй UI, затем синхронизируй с сервером
Future<void> _toggleFavorite(String tripId, bool currentValue) async {
  // Оптимистичное обновление UI
  setState(() {
    final index = _trips.indexWhere((t) => t['id'] == tripId);
    if (index != -1) {
      _trips[index]['is_favorite'] = !currentValue;
    }
  });

  // Синхронизация с сервером
  try {
    await AiTripsStorageService.toggleFavorite(tripId, !currentValue);
  } catch (e) {
    // Откат изменений в случае ошибки
    setState(() {
      final index = _trips.indexWhere((t) => t['id'] == tripId);
      if (index != -1) {
        _trips[index]['is_favorite'] = currentValue;
      }
    });
  }
}
```

## 🎉 Готово!

Теперь у тебя:
- ✅ Персональные трипы для каждого пользователя
- ✅ Синхронизация между устройствами
- ✅ Real-time обновления
- ✅ Безопасное хранение с RLS
- ✅ Неограниченное хранилище в Supabase

Трипы будут доступны на всех устройствах пользователя! 🚀
