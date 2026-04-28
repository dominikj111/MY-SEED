# No COPY commands in this file — every config is bind-mounted at runtime.
# Rebuild only needed when system packages or PHP extensions change.

ARG PHP_VERSION=8.4
FROM php:${PHP_VERSION}-fpm

# System dependencies
# libpq-dev   — required for pdo_pgsql and pgsql extensions
# libpng-dev, libjpeg-dev, libfreetype6-dev — required for GD
# libzip-dev  — required for zip extension
# libxml2-dev — required for xml extension
# libonig-dev — required for mbstring extension
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    unzip \
    msmtp \
    libfreetype6-dev \
    libpng-dev \
    libjpeg-dev \
    libzip-dev \
    libxml2-dev \
    libonig-dev \
    libpq-dev \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# GD must be configured before install to include JPEG and FreeType support
RUN docker-php-ext-configure gd --with-freetype --with-jpeg

# Install PHP extensions
RUN docker-php-ext-install \
    pdo_pgsql \
    pgsql \
    mbstring \
    xml \
    gd \
    zip \
    bcmath \
    pcntl \
    opcache

# Composer — official installer, globally available at /usr/local/bin/composer
RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin \
    --filename=composer

# Node.js — version controlled via ARG (passed from docker-compose build.args)
# ARG must be redeclared after FROM to be available in RUN instructions
ARG NODE_VERSION=20
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Log directories — ownership set here so php-fpm (www-data) can write to them
# The actual paths are bind-mounted from the host logs/ directory
RUN mkdir -p /var/log/php /var/log/mail \
    && chown www-data:www-data /var/log/php /var/log/mail

WORKDIR /app

# ENTRYPOINT and CMD are set in docker-compose.yml, not here.
# This keeps the image generic — entrypoint.sh is bind-mounted at runtime.
