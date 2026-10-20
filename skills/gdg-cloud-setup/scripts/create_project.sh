#!/usr/bin/env bash
# Creates a Google Cloud project with no organization/folder and makes it the active gcloud project.
# Usage: create_project.sh <project-id> "<project name>"
# Output on success: STATUS=created, PROJECT_NAME, PROJECT_ID, PROJECT_NUMBER, ACCOUNT
# Output on failure: STATUS=failed, ERROR=<gcloud message>
set -uo pipefail

project_id="${1:?project id required}"
project_name="${2:?project name required}"

# No --organization / --folder: the project is created with no parent organization.
if ! err="$(gcloud projects create "$project_id" --name="$project_name" --quiet 2>&1)"; then
  echo "STATUS=failed"
  echo "ERROR=$(printf '%s' "$err" | tr '\n' ' ')"
  exit 1
fi

gcloud config set project "$project_id" --quiet >/dev/null 2>&1

echo "STATUS=created"
gcloud projects describe "$project_id" \
  --format='value[separator="\n"](format("PROJECT_NAME={0}",name),format("PROJECT_ID={0}",projectId),format("PROJECT_NUMBER={0}",projectNumber))'
echo "ACCOUNT=$(gcloud config get account 2>/dev/null)"
