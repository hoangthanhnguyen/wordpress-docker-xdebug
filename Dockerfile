FROM wordpress:latest

   # Install Xdebug
   RUN pecl install xdebug && docker-php-ext-enable xdebug

   # Copy custom xdebug.ini
   COPY xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

   # Copy custom php.ini settings
   COPY custom.ini /usr/local/etc/php/conf.d/custom.ini