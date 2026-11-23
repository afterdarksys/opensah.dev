#!/usr/bin/env bash
# Publish site/ as the static-assets Worker named in cloudflare.config.ts.
# Extra arguments go to cf deploy (e.g. --dry-run).
set -euo pipefail
cd "$(dirname "$0")/.."
node tools/site.mjs check
[ -x node_modules/.bin/cf ] || { echo 'Run npm ci first: it pins cf and the Wrangler cf builds with.' >&2; exit 1; }
# Stage a copy without dot-files: agent tooling writes state directories such as .omc/ inside site/.
rm -rf dist
rsync -a --exclude='.*' site/ dist/
node_modules/.bin/cf deploy "$@"
