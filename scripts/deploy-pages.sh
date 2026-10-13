#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
node tools/site.mjs check
command -v wrangler >/dev/null || { echo 'Install and authenticate Wrangler before deployment.' >&2; exit 1; }
wrangler pages deploy site --project-name=opensah-dev --branch=main
