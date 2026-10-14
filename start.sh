#!/bin/sh
set -e

# Clear cached config — CRITICAL for Railway deployment
# bootstrap/cache/config.php has hardcoded env values from local .env
# that would override Railway environment variables.
php artisan config:clear
php artisan package:discover --ansi
php artisan route:clear 2>/dev/null || true

# 1. Ensure .env exists
if [ ! -f .env ]; then
    cp .env.example .env
fi

# 2. Generate APP_KEY if not set
if ! grep -q "^APP_KEY=base64:" .env; then
    php artisan key:generate --force
fi

# 3. Run migrations
php artisan migrate --force

# 4. Run seeders (idempotent)
php artisan db:seed --force

# 5. Create storage symlink
php artisan storage:link --force

# 6. Start server on Railway PORT
exec php artisan serve --host=0.0.0.0 --port=${PORT:-8000}