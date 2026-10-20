#!/usr/bin/env bash
# Validates a project display name and proposes a globally unique project ID for it.
# Usage: suggest_project_id.sh "<project name>"
# Output: NAME_VALID=yes|no, NAME_ERROR=..., PROJECT_ID=...
#
# Google Cloud rules:
#   name: 4-30 chars; letters, digits, spaces, hyphens, single/double quotes, '!'
#   ID:   6-30 chars; lowercase letters, digits, hyphens; starts with a letter; no trailing hyphen
set -uo pipefail

name="${1:-}"

if [[ ${#name} -lt 4 || ${#name} -gt 30 ]]; then
  echo "NAME_VALID=no"
  echo "NAME_ERROR=Project name must be 4-30 characters (got ${#name})."
  exit 0
fi
if [[ ! "$name" =~ ^[A-Za-z0-9\ \'\"!-]+$ ]]; then
  echo "NAME_VALID=no"
  echo "NAME_ERROR=Project name may only contain letters, numbers, spaces, hyphens, quotes and '!'."
  exit 0
fi
echo "NAME_VALID=yes"

# Slugify: lowercase, non-alphanumerics -> '-', collapse repeats, trim hyphens.
slug="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
# Must start with a letter.
[[ "$slug" =~ ^[a-z] ]] || slug="p-$slug"
# Leave room for "-" + 6-char suffix (30 max).
slug="${slug:0:23}"
slug="${slug%-}"

# Try a few random suffixes until we find an ID that isn't already visible to us.
# (Global uniqueness is only truly known at create time; create_project.sh retries on collision.)
for _ in 1 2 3 4 5; do
  suffix="$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 6)"
  candidate="${slug}-${suffix}"
  if ! gcloud projects describe "$candidate" >/dev/null 2>&1; then
    echo "PROJECT_ID=$candidate"
    exit 0
  fi
done
echo "PROJECT_ID=${slug}-$(date +%s | tail -c 7)"
