#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
VERSION="${1:-dev}"
IMAGE="${GALAXY_IMAGE:-phpswoole/galaxy:$VERSION}"
AGENT_IMAGE="${GALAXY_AGENT_IMAGE:-phpswoole/galaxy-agent:$VERSION}"
VCS_REF="$(git -C "$WORKSPACE_DIR/galaxy-api" rev-parse --short=12 HEAD 2>/dev/null || printf unknown)"
BUILD_DATE="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

docker build \
    --file "$SCRIPT_DIR/Dockerfile" \
    --build-arg "VERSION=$VERSION" \
    --build-arg "VCS_REF=$VCS_REF" \
    --build-arg "BUILD_DATE=$BUILD_DATE" \
    --tag "$IMAGE" \
    "$WORKSPACE_DIR"

docker build \
    --file "$WORKSPACE_DIR/galaxy-cli/Dockerfile.agent" \
    --build-arg "VERSION=$VERSION" \
    --build-arg "AGENT_IMAGE=$AGENT_IMAGE" \
    --tag "$AGENT_IMAGE" \
    "$WORKSPACE_DIR/galaxy-cli"

printf '构建完成：\n  %s\n  %s\n' "$IMAGE" "$AGENT_IMAGE"
