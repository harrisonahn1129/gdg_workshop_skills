#!/usr/bin/env bash
# Lists the billing accounts the signed-in user can see, numbered 1..N.
# Usage: list_billing.sh
# Output: one line per account: "<n>|<display name>|<billing account id>|OPEN|CLOSED"
#         or "NONE" if the user has no billing accounts.
set -uo pipefail

rows="$(gcloud billing accounts list \
  --sort-by=~open,displayName \
  --format='csv[no-heading,separator="|"](displayName,name.basename(),open)' 2>&1)" || {
  echo "ERROR=$(printf '%s' "$rows" | tr '\n' ' ')"
  exit 1
}

if [[ -z "$rows" ]]; then
  echo "NONE"
  exit 0
fi

n=0
while IFS='|' read -r display id open; do
  n=$((n + 1))
  state="CLOSED"
  [[ "$open" == "True" || "$open" == "true" ]] && state="OPEN"
  echo "$n|$display|$id|$state"
done <<<"$rows"
