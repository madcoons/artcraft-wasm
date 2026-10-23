#!/usr/bin/env bash
# Prints the package version of upstream PhotoCraft <version> at the packaging revision in REVISION (1-99):
# the revision is appended to the patch number as two digits, so 0.11.1 is 0.11.101 and 0.14.0 is 0.14.1.
set -euo pipefail
cd "$(dirname "$0")"

revision="$(tr -d '[:space:]' < REVISION)"
# 100 or more would run into the upstream patch digit.
if ! [[ "$revision" =~ ^[1-9][0-9]?$ ]]; then
  echo "REVISION must be 1-99, not '$revision'." >&2
  exit 1
fi

IFS=. read -r major minor patch <<< "$1"
echo "$major.$minor.$((patch * 100 + revision))"
