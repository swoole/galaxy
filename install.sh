#!/bin/sh
set -eu

RELEASE_BASE_URL="${GALAXY_RELEASE_BASE_URL:-https://git.code-galaxy.net/github/galaxy-docs/raw/branch/main/downloads}"
INSTALL_DIR="${GALAXY_INSTALL_DIR:-$PWD/galaxy}"

command -v curl >/dev/null 2>&1 || {
    printf '安装需要 curl。\n' >&2
    exit 1
}

mkdir -p "$INSTALL_DIR"
for file in compose.yaml stack.yaml .env.example galaxyctl; do
    curl -fsSL "$RELEASE_BASE_URL/$file" -o "$INSTALL_DIR/$file"
done
chmod 0755 "$INSTALL_DIR/galaxyctl"

printf 'CodeGalaxy 安装目录：%s\n' "$INSTALL_DIR"
exec "$INSTALL_DIR/galaxyctl" install "$@"
