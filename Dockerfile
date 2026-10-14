# ===============================
# Dockerfile — Laravel 13 on Railway
# ===============================
# PHP 8.3 CLI runtime with all required extensions,
# Node.js for frontend asset building, and Composer.
#
# Railway provides the PORT env var at runtime; the
# startup script (start.sh) binds the server to it.
# ===============================

FROM php:8.3-cli

# --- System dependencies + PHP extensions -------------------------------
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    ca-certificates \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        pdo_mysql \
        gd \
        mbstring \
        zip \
        intl \
    && rm -rf /var/lib/apt/lists/*

# --- Node.js LTS (for Vite frontend builds) ---------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# --- Composer ----------------------------------------------------------
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# --- Working directory -------------------------------------------------
WORKDIR /var/www/html

# --- Copy project (respects .dockerignore) -----------------------------
COPY . /var/www/html

# --- Create .env (placeholder untuk build-time) ------------------------
# Env dari Railway menimpa isi .env saat runtime (dotenv immutable),
# jadi nilai di sini hanya dipakai oleh perintah build.
RUN cp .env.example .env

# --- PHP dependencies (production) ------------------------------------
# WAJIB sebelum perintah `php artisan ...` apa pun, karena artisan
# membutuhkan vendor/autoload.php (vendor/ dikecualikan .dockerignore).
RUN composer install --no-dev --optimize-autoloader --no-interaction

# --- APP_KEY untuk kebutuhan build-time -------------------------------
# Dijalankan SETELAH composer install (memerlukan vendor/).
RUN php artisan key:generate --force

# --- Frontend assets (Vite) -------------------------------------------
RUN npm install && npm run build

# --- Permissions -------------------------------------------------------
RUN chown -R www-data:www-data storage bootstrap/cache

# --- Startup script ----------------------------------------------------
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8000
ENTRYPOINT ["/start.sh"]