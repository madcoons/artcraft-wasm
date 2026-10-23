#!/usr/bin/env bash
# Points the package at upstream PhotoCraft <version> (e.g. 0.14.0) at packaging [revision] (default 1):
# both photocraft tags become v<version> and `version` becomes its package version. Prints that version.
# build.sh updates Cargo.lock to match.
set -euo pipefail
cd "$(dirname "$0")"

version="$(./package-version.sh "$1" "${2:-1}")"
sed -i.bak -e "s|tag = \"v[^\"]*\"|tag = \"v$1\"|" -e "s|^version = \".*\"|version = \"$version\"|" Cargo.toml
rm Cargo.toml.bak
echo "$version"
