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
# PENTING: flag --no-reload WAJIB ada.
# Tanpa flag ini, `artisan serve` hanya meneruskan sebagian variabel
# lingkungan (APP_ENV, PATH, dll) ke proses `php -S`. Variabel dari
# Railway (DB_*, APP_KEY, APP_DEBUG, CLOUDINARY_*) akan DIBUANG, sehingga
# request HTTP jatuh ke nilai .env bawaan image (DB_HOST=127.0.0.1)
# -> koneksi database gagal -> website balas HTTP 500.
exec php artisan serve --host=0.0.0.0 --port=${PORT:-8000} --no-reload