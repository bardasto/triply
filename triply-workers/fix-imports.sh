#!/bin/bash

# Fix imports after modular refactoring

echo "🔧 Fixing imports in modules..."

# Find all TypeScript files in modules
find src/modules -name "*.ts" -type f | while read file; do
  # Determine depth based on file location
  if [[ $file == *"/jobs/"* ]]; then
    # Files in jobs/ need ../../../../shared
    SHARED_PATH="../../../../shared"
    MODULE_PATH="../../"
  elif [[ $file == *"/services/"* ]]; then
    # Files in services/ need ../../../shared
    SHARED_PATH="../../../shared"
    MODULE_PATH="../../"
  else
    # Root module files need ../../shared
    SHARED_PATH="../../shared"
    MODULE_PATH="../"
  fi

  # Replace config imports
  sed -i '' "s|from ['\"]\.\.\/config\/env\.js['\"]|from '${SHARED_PATH}/config/env.js'|g" "$file"
  sed -i '' "s|from ['\"]\.\.\/config\/supabase\.js['\"]|from '${SHARED_PATH}/config/supabase.js'|g" "$file"

  # Replace utils imports
  sed -i '' "s|from ['\"]\.\.\/utils\/logger\.js['\"]|from '${SHARED_PATH}/utils/logger.js'|g" "$file"

  # Replace models imports
  sed -i '' "s|from ['\"]\.\.\/models\/index\.js['\"]|from '${SHARED_PATH}/types/index.js'|g" "$file"
  sed -i '' "s|from ['\"]\.\.\/models['\"]|from '${SHARED_PATH}/types'|g" "$file"

  echo "  ✅ Fixed: $file"
done

echo ""
echo "🔧 Fixing service cross-imports..."

# Fix cross-module service imports in specific modules

# AI module → Google Places
find src/modules/ai -name "*.ts" -exec sed -i '' "s|from ['\"]\.\.\/services\/google-places\.service\.js['\"]|from '../../google-places/services/google-places.service.js'|g" {} \;

# Photos module → Google Places
find src/modules/photos -name "*.ts" -exec sed -i '' "s|from ['\"]\.\.\/services\/google-places\.service\.js['\"]|from '../../google-places/services/google-places.service.js'|g" {} \;

# Restaurants module → Google Places & Cache
find src/modules/restaurants -name "*.ts" -exec sed -i '' "s|from ['\"]\.\.\/services\/google-places\.service\.js['\"]|from '../../google-places/services/google-places.service.js'|g" {} \;
find src/modules/restaurants -name "*.ts" -exec sed -i '' "s|from ['\"]\.\.\/services\/places-cache\.service\.js['\"]|from '../../cache/services/places-cache.service.js'|g" {} \;

# Cache module → Google Places
find src/modules/cache -name "*.ts" -exec sed -i '' "s|from ['\"]\.\.\/services\/google-places\.service\.js['\"]|from '../../google-places/services/google-places.service.js'|g" {} \;

# POIs module → Google Places
find src/modules/pois -name "*.ts" -exec sed -i '' "s|from ['\"]\.\.\/services\/google-places\.service\.js['\"]|from '../../google-places/services/google-places.service.js'|g" {} \;

echo ""
echo "✅ Import fixes complete!"
echo "🧪 Test with: npm run trips:generate"
