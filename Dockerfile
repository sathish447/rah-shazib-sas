FROM php:8.4-apache

# Install PHP/system dependencies + Node.js
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    libzip-dev \
    libicu-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql zip intl bcmath gd \
    && a2enmod rewrite \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && node --version \
    && npm --version \
    && rm -rf /var/lib/apt/lists/*

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/sites-available/*.conf \
    /etc/apache2/apache2.conf \
    /etc/apache2/conf-available/*.conf

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Install frontend dependencies and build Vite assets
RUN npm install \
    && npm run build

# Permissions
RUN chown -R www-data:www-data storage bootstrap/cache

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

CMD ["docker-entrypoint.sh"]
