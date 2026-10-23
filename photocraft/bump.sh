#!/usr/bin/env bash
# Points the package at upstream PhotoCraft <version> (e.g. 0.14.0) as packaging revision 1: both
# photocraft tags become v<version> and `version` becomes 0.14.1 (0.11.1 would be 0.11.101).
# Prints the new package version. build.sh updates Cargo.lock to match.
set -euo pipefail
cd "$(dirname "$0")"

IFS=. read -r major minor patch <<< "$1"
version="$major.$minor.$((patch * 100 + 1))"
sed -i.bak -e "s|tag = \"v[^\"]*\"|tag = \"v$1\"|" -e "s|^version = \".*\"|version = \"$version\"|" Cargo.toml
rm Cargo.toml.bak
echo "$version"
