#!/bin/sh
set -eu

if [ "$#" -gt 0 ]; then
    exec "$@"
fi

php /usr/local/lib/galaxy/initialize-database.php

nginx
exec /opt/www/docker/entrypoint-api.sh
