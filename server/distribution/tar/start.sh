#!/bin/sh
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$BASE_DIR/lib/app"
exec "$BASE_DIR/bin/openintegrationengine" "$@"
