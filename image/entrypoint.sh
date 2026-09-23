#!/bin/sh
set -eu

load_secret_env() {
    name="$1"
    current="$(printenv "$name" 2>/dev/null || true)"
    secret_file="$(printenv "${name}_FILE" 2>/dev/null || true)"
    if [ -z "$current" ] && [ -n "$secret_file" ]; then
        [ -r "$secret_file" ] || {
            echo "$name secret file is not readable: $secret_file" >&2
            exit 1
        }
        value="$(cat "$secret_file")"
        [ -n "$value" ] || {
            echo "$name secret file is empty: $secret_file" >&2
            exit 1
        }
        export "$name=$value"
    fi
}

for secret_name in \
    DB_PASSWORD \
    REDIS_AUTH \
    REDIS_AUTH_QUEUE \
    SIMPLE_JWT_SECRET \
    SSO_JWT_SECRET \
    ENCRYPT_KEY \
    SWARM_CREDENTIAL_KEY \
    SSH_RELAY_INTERNAL_TOKEN \
    GALAXY_INSTALL_TOKEN
do
    load_secret_env "$secret_name"
done

if [ "$#" -gt 0 ]; then
    exec "$@"
fi

php /usr/local/lib/galaxy/initialize-database.php

nginx
exec /opt/www/docker/entrypoint-api.sh
