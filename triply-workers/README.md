# Triply Workers - Restaurant Caching Backend

Clean, modular backend with Google Places API compliant caching.

## 🚀 Quick Start

### Check System Status
```bash
npx tsx diagnose-restaurants-view.ts
```

### Seed Restaurants
```bash
npm run seed:restaurants:paris
```

### Test Everything Works
```bash
npx tsx test-after-migration.ts
```

---

## 📁 Architecture

Clean modular structure organized by business domains:

```
src/
├── modules/              # Business domains
│   ├── google-places/   # Google API integration
│   ├── cache/           # 30-day caching
│   ├── restaurants/     # Restaurant logic
│   ├── photos/          # Image management
│   ├── ai/              # OpenAI services
│   ├── trips/           # Trip generation
│   ├── pois/            # Points of Interest
│   ├── cities/          # City data
│   └── external-apis/   # Third-party APIs
│
└── shared/              # Common code
    ├── config/          # Environment config
    ├── types/           # TypeScript types
    └── utils/           # Helpers
```

**📖 Read full architecture:** [ARCHITECTURE.md](./ARCHITECTURE.md)

---

## 🏗️ Google Policy Compliant

### Legal 30-Day Caching ✅

```
places_catalog (permanent)
  └─ place_id ✅ stored forever

places_cache (temporary - 30 days)
  └─ name, photos, rating ✅
     expires_at = NOW + 30 days
     next_refresh_at = NOW + 15 days
```

### Auto-Refresh Cycle
```
Day 0:   Seed → Cache created
Day 15:  Auto-refresh → Update from Google
Day 30:  Auto-cleanup → Delete expired
         → Repeat
```

**100% Compliant with Google Places API Terms** ✅

---

## 📦 Available Commands

### Restaurant Data

```bash
# Seed 5 Paris restaurants for testing
npm run seed:restaurants:paris

# Custom city and cuisine
npm run seed:restaurants custom "Rome" "IT" "Pizza" 20
```

### Cache Management

```bash
# Refresh places needing update (15+ days)
npm run cache:refresh

# Cleanup expired cache (30+ days)
npm run cache:cleanup
```

### Diagnostics

```bash
# Diagnose why restaurants don't show
npx tsx diagnose-restaurants-view.ts

# Test after applying migration
npx tsx test-after-migration.ts
```

---

## 🔧 Modules

### Core Modules

| Module | Purpose | Key Files |
|--------|---------|-----------|
| **google-places** | Google API | `google-places.service.ts` |
| **cache** | 30-day caching | `places-cache.service.ts` |
| **restaurants** | Restaurant logic | `restaurant-cache.service.ts` |
| **photos** | Image management | `image-gallery.service.ts` |
| **ai** | OpenAI services | `openai.service.ts` |
| **trips** | Trip generation | `generate-trips.ts` |

### Usage Example

```typescript
// ✅ Clean imports
import { GooglePlacesService } from '@/modules/google-places';
import { RestaurantCacheService } from '@/modules/restaurants';
import { OpenAIService } from '@/modules/ai';

// Use services
const places = await GooglePlacesService.textSearch({
  query: 'restaurants in Paris'
});

const restaurants = await RestaurantCacheService.getRestaurantsByCity('Paris');

const description = await OpenAIService.generateRestaurantDescription(restaurant);
```

---

## 🗄️ Database Structure

### Tables

```sql
-- Permanent storage (Google compliant)
places_catalog
  ├─ google_place_id ✅ forever
  ├─ latitude, longitude
  └─ city, place_type, tags

-- 30-day cache (Google compliant)
places_cache
  ├─ place_catalog_id (FK)
  ├─ name, address, photos, rating
  ├─ cached_at
  ├─ expires_at (NOW + 30 days)
  └─ next_refresh_at (NOW + 15 days)
```

### SQL Views (Flutter compatibility)

```sql
-- restaurants VIEW
-- Combines places_catalog + places_cache
-- Includes photos embedded as JSON
-- Auto-filters expired cache
```

---

## ⚙️ Environment Variables

```env
SUPABASE_URL=your-supabase-url
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
GOOGLE_PLACES_API_KEY=your-google-api-key
OPENAI_API_KEY=your-openai-key
```

---

## 🐛 Troubleshooting

### Restaurants not showing in Flutter

**Symptom:**
```
❌ Error: Could not find a relationship between 'restaurants' and 'restaurant_photos'
```

**Solution:** Read [CHECK_AND_FIX.md](./CHECK_AND_FIX.md)

### View returns 0 restaurants

**Cause:** No data in cache

**Solution:**
```bash
npm run seed:restaurants:paris
```

### Photos not displaying

**Cause:** Google API key not configured

**Solution:** Check Migration 004 contains correct API key

---

## 📊 Cron Jobs (Production)

```bash
# Refresh cache every day at 3:00 AM
0 3 * * * cd /path/to/triply-workers && npm run cache:refresh

# Cleanup expired cache every day at 2:00 AM
0 2 * * * cd /path/to/triply-workers && npm run cache:cleanup
```

---

## 📚 Documentation

- **Architecture:** [ARCHITECTURE.md](./ARCHITECTURE.md) - Full system design
- **Fix Guide:** [CHECK_AND_FIX.md](./CHECK_AND_FIX.md) - Fix restaurant display
- **Current State:** [CURRENT_ARCHITECTURE.md](./CURRENT_ARCHITECTURE.md) - Caching details

---

## 🎯 Key Features

✅ **Modular Architecture** - Clean domain separation
✅ **Google Policy Compliant** - Legal 30-day caching
✅ **Auto-Refresh** - Updates every 15 days
✅ **Auto-Cleanup** - Removes expired data
✅ **Type-Safe** - Full TypeScript support
✅ **Scalable** - Easy to add new modules
✅ **Well-Documented** - Comprehensive docs

---

## 🚀 Next Steps

1. **Run diagnostics** to check system health
2. **Seed test data** for Paris
3. **Test in Flutter app** with "View All"
4. **Set up cron jobs** for production
5. **Add more cities** as needed

---

**Need Help?**
- Read: [ARCHITECTURE.md](./ARCHITECTURE.md)
- Fix Issues: [CHECK_AND_FIX.md](./CHECK_AND_FIX.md)
- Check Status: `npx tsx diagnose-restaurants-view.ts`

---

**Last Updated:** 2025-11-18
**Version:** 2.0.0
**Architecture:** Modular + Domain-Driven
