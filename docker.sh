#!/bin/bash

mkdir -p {logs,cache} && chmod -R a+w {logs,cache} && chown -R www-data:www-data {logs,cache}

if [ "$SYMFONY__ENV" = prod ]; then
  # disable xdebug on "prod" environment
	unlink /usr/local/etc/php/conf.d/xdebug.ini;
fi

composer install --optimize-autoloader --no-suggest

php bin/console cache:clear -e $SYMFONY__ENV
# php bin/console doctrine:migrations:status --show-versions
# php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration --query-time

chmod -R a+w {logs,cache}

php-fpm