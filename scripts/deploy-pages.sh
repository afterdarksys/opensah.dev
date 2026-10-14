#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
node tools/site.mjs check
command -v wrangler >/dev/null || { echo 'Install and authenticate Wrangler before deployment.' >&2; exit 1; }
# Upload a copy without dot-files: agent tooling writes state directories such as .omc/ inside site/.
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
rsync -a --exclude='.*' site/ "$stage/"
wrangler pages deploy "$stage" --project-name=opensah-dev --branch=main
