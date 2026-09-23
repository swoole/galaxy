# syntax=docker/dockerfile:1.7

FROM node:22-alpine AS frontend-builder

WORKDIR /src
COPY galaxy-fe/package.json galaxy-fe/package-lock.json ./
RUN npm ci --registry=https://registry.npmjs.org
COPY galaxy-fe/ ./
ARG VUE_APP_BASE_API=/api/
ARG VUE_APP_STATIC_PREFIX=/
ARG VUE_APP_TRUSTED_DOMAINS=
ARG VUE_APP_COOKIE_DOMAIN=
ENV VUE_APP_BASE_API=${VUE_APP_BASE_API} \
    VUE_APP_STATIC_PREFIX=${VUE_APP_STATIC_PREFIX} \
    VUE_APP_TRUSTED_DOMAINS=${VUE_APP_TRUSTED_DOMAINS} \
    VUE_APP_COOKIE_DOMAIN=${VUE_APP_COOKIE_DOMAIN}
RUN npm run build

FROM golang:1.24-alpine AS ssh-relay-builder

ARG GOPROXY=https://goproxy.cn,direct
ENV GOPROXY=${GOPROXY}
WORKDIR /src
COPY galaxy-api/ssh-relay/go.mod galaxy-api/ssh-relay/go.sum ./
RUN go mod download
COPY galaxy-api/ssh-relay/ ./
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/galaxy-ssh-relay .

FROM golang:1.24-alpine AS helm-service-builder

ARG GOPROXY=https://goproxy.cn,direct
ENV GOPROXY=${GOPROXY}
WORKDIR /src
COPY galaxy-api/helm-service/go.mod galaxy-api/helm-service/go.sum ./
RUN go mod download
COPY galaxy-api/helm-service/ ./
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/galaxy-helm-service .

FROM hyperf/hyperf:8.4-alpine-v3.21-swoole AS api-vendor

WORKDIR /deps
COPY galaxy-api/composer.json galaxy-api/composer.lock ./
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/ \
    && composer install \
        --no-dev \
        --no-interaction \
        --prefer-dist \
        --no-scripts \
        --no-autoloader

FROM hyperf/hyperf:8.4-alpine-v3.21-swoole

ARG VERSION=dev
ARG VCS_REF=unknown
ARG BUILD_DATE=unknown

LABEL org.opencontainers.image.title="CodeGalaxy" \
      org.opencontainers.image.description="Self-hosted CodeGalaxy control plane" \
      org.opencontainers.image.source="https://github.com/swoole/galaxy" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.licenses="Apache-2.0"

ENV APP_ENV=prod \
    SCAN_CACHEABLE=true \
    TIMEZONE=Asia/Shanghai \
    GALAXY_AUTO_INIT=true

RUN apk add --no-cache \
        curl \
        nginx \
        openssh-client \
        tzdata \
    && printf '%s\n' \
        'upload_max_filesize=128M' \
        'post_max_size=128M' \
        'memory_limit=1G' \
        'date.timezone=Asia/Shanghai' \
        > /etc/php84/conf.d/99-galaxy.ini \
    && printf '%s\n' "swoole.use_shortname = 'Off'" >> /etc/php84/conf.d/50_swoole.ini

WORKDIR /opt/www
COPY galaxy-api/ ./
COPY --from=api-vendor /deps/vendor ./vendor
COPY --from=ssh-relay-builder /out/galaxy-ssh-relay /usr/local/bin/galaxy-ssh-relay
COPY --from=helm-service-builder /out/galaxy-helm-service /usr/local/bin/galaxy-helm-service
COPY --from=frontend-builder /src/dist/ /usr/share/nginx/html/
COPY galaxy/image/nginx.conf /etc/nginx/http.d/default.conf
COPY galaxy/image/entrypoint.sh /usr/local/bin/galaxy-entrypoint
COPY galaxy/image/initialize-database.php /usr/local/lib/galaxy/initialize-database.php

RUN composer dump-autoload --no-dev --optimize \
    && cp .env.example .env \
    && php bin/hyperf.php \
    && chmod 0755 docker/entrypoint-api.sh /usr/local/bin/galaxy-entrypoint \
    && mkdir -p /run/nginx /usr/local/lib/galaxy

EXPOSE 80 9522

HEALTHCHECK --interval=10s --timeout=5s --start-period=45s --retries=6 \
    CMD curl -fsS http://127.0.0.1/api/healthz >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/galaxy-entrypoint"]
