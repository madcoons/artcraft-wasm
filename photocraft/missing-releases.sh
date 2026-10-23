#!/usr/bin/env bash
# Prints, as a JSON array oldest first, the upstream PhotoCraft versions to release: stable releases from
# <min-version> on, at least <min-age-hours> old, whose package (revision 1) has no release here yet.
# Needs GH_TOKEN.
set -euo pipefail
cd "$(dirname "$0")"

min_version="$1"
cutoff="$(date -u -d "-$2 hours" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v "-$2H" +%Y-%m-%dT%H:%M:%SZ)"
released="$(gh release list --repo "${GITHUB_REPOSITORY:-madcoons/artcraft-wasm}" --limit 1000 --json tagName --jq '.[].tagName')"

gh release list --repo storytold/photocraft --exclude-drafts --exclude-pre-releases --limit 1000 \
  --json tagName,publishedAt --jq ".[] | select(.publishedAt <= \"$cutoff\") | .tagName | ltrimstr(\"v\")" \
  | sort -V \
  | while read -r upstream; do
      # Older than min-version: sorts before it.
      [ "$(printf '%s\n%s\n' "$min_version" "$upstream" | sort -V | head -n 1)" = "$min_version" ] || continue
      grep -qxF "photocraft-v$(./package-version.sh "$upstream")" <<< "$released" || echo "$upstream"
    done \
  | jq -Rnc '[inputs]'
