#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_CONTEXT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/galaxy-build.XXXXXX")"
VERSION="${1:-dev}"
IMAGE="${GALAXY_IMAGE:-registry.cn-shanghai.aliyuncs.com/swoole-public/galaxy:$VERSION}"
AGENT_IMAGE="${GALAXY_AGENT_IMAGE:-registry.cn-shanghai.aliyuncs.com/swoole-public/galaxy-agent:$VERSION}"
VCS_REF="$(git -C "$WORKSPACE_DIR/galaxy-api" rev-parse --short=12 HEAD 2>/dev/null || printf unknown)"
BUILD_DATE="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

cleanup() {
    rm -rf "$BUILD_CONTEXT_DIR"
}
trap cleanup EXIT HUP INT TERM

copy_source_tree() {
    source_dir="$1"
    target_dir="$2"
    mkdir -p "$target_dir"
    tar -C "$source_dir" \
        --exclude='./.git' \
        --exclude='./.env' \
        --exclude='./node_modules' \
        --exclude='./vendor' \
        --exclude='./runtime' \
        --exclude='./dist' \
        --exclude='./coverage' \
        --exclude='./asserts' \
        --exclude='./storage/keys' \
        -cf - . | tar -C "$target_dir" -xf -
}

copy_source_tree "$WORKSPACE_DIR/galaxy-api" "$BUILD_CONTEXT_DIR/galaxy-api"
copy_source_tree "$WORKSPACE_DIR/galaxy-fe" "$BUILD_CONTEXT_DIR/galaxy-fe"
copy_source_tree "$SCRIPT_DIR" "$BUILD_CONTEXT_DIR/galaxy"

docker build \
    --file "$BUILD_CONTEXT_DIR/galaxy/Dockerfile" \
    --build-arg "VERSION=$VERSION" \
    --build-arg "VCS_REF=$VCS_REF" \
    --build-arg "BUILD_DATE=$BUILD_DATE" \
    --tag "$IMAGE" \
    "$BUILD_CONTEXT_DIR"

docker build \
    --file "$WORKSPACE_DIR/galaxy-cli/Dockerfile.agent" \
    --build-arg "VERSION=$VERSION" \
    --build-arg "AGENT_IMAGE=$AGENT_IMAGE" \
    --tag "$AGENT_IMAGE" \
    "$WORKSPACE_DIR/galaxy-cli"

printf '构建完成：\n  %s\n  %s\n' "$IMAGE" "$AGENT_IMAGE"
