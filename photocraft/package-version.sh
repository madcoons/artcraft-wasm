#!/usr/bin/env bash
# Prints the package version of upstream PhotoCraft <version> at packaging [revision] (1-99, default 1):
# the revision is appended to the patch number as two digits, so 0.11.1 is 0.11.101 and 0.14.0 is 0.14.1.
set -euo pipefail

IFS=. read -r major minor patch <<< "$1"
echo "$major.$minor.$((patch * 100 + ${2:-1}))"
