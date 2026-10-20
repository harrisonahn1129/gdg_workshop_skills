#!/usr/bin/env bash
# Links a billing account to a project and reports the resulting link.
# Usage: link_billing.sh <project-id> <billing-account-id>
# Output on success: STATUS=linked, PROJECT_ID, BILLING_ACCOUNT_ID, BILLING_ACCOUNT_NAME, BILLING_ENABLED
# Output on failure: STATUS=failed, ERROR=<gcloud message>
set -uo pipefail

project_id="${1:?project id required}"
billing_id="${2:?billing account id required}"

if ! err="$(gcloud billing projects link "$project_id" --billing-account="$billing_id" --quiet 2>&1)"; then
  echo "STATUS=failed"
  echo "ERROR=$(printf '%s' "$err" | tr '\n' ' ')"
  exit 1
fi

linked_id="$(gcloud billing projects describe "$project_id" --format='value(billingAccountName.basename())')"
enabled="$(gcloud billing projects describe "$project_id" --format='value(billingEnabled)')"
display="$(gcloud billing accounts describe "$linked_id" --format='value(displayName)' 2>/dev/null)"

echo "STATUS=linked"
echo "PROJECT_ID=$project_id"
echo "BILLING_ACCOUNT_ID=$linked_id"
echo "BILLING_ACCOUNT_NAME=$display"
echo "BILLING_ENABLED=$enabled"
