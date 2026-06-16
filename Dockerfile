# Stage 1: Build React/Vite Assets
FROM node:20-alpine AS frontend-builder
WORKDIR /app
COPY web/package*.json ./
RUN npm ci
COPY web/resources ./resources
COPY web/tsconfig.json web/vite.config.js web/tailwind.config.js web/postcss.config.js ./
RUN npm run build

# Stage 2: Run PHP & Nginx Server
FROM webdevops/php-nginx:8.2-alpine

# Set Nginx Document Root to Laravel's public directory
ENV WEB_DOCUMENT_ROOT=/app/public
ENV PHP_DATE_TIMEZONE=Asia/Jakarta

WORKDIR /app

# Copy Laravel codebase
COPY web/ .

# Copy compiled frontend assets from Stage 1
COPY --from=frontend-builder /app/public/build ./public/build

# Install PHP dependencies via Composer
RUN composer install --no-dev --optimize-autoloader

# Set permissions for Laravel storage and cache
RUN chown -R application:application /app/storage /app/bootstrap/cache
