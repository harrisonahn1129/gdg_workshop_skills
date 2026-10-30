#!/usr/bin/env bash
# Re-checks the whole setup from scratch, independent of what earlier steps reported.
# Usage: verify.sh <project-id>
# Output: one line per check, "<ok|fail>|<label>|<detail>", then ALL_OK=yes|no
set -uo pipefail

project_id="${1:?project id required}"
api_file="$(cd "$(dirname "$0")/.." && pwd)/references/apis.txt"
all_ok=yes

row() {
  echo "$1|$2|$3"
  [[ "$1" == "ok" ]] || all_ok=no
}

account="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null | head -n1)"
if [[ -n "$account" ]]; then row ok "Signed in" "$account"; else row fail "Signed in" "no account"; fi

if gcloud projects describe "$project_id" >/dev/null 2>&1; then
  row ok "Project exists" "$project_id"
else
  row fail "Project exists" "$project_id not found for $account"
fi

billing="$(gcloud billing projects describe "$project_id" --format='value(billingEnabled)' 2>/dev/null)"
if [[ "$billing" == "True" || "$billing" == "true" ]]; then
  row ok "Credit connected" "billing enabled"
else
  row fail "Credit connected" "billing not enabled"
fi

enabled="$(gcloud services list --enabled --project="$project_id" --format='value(config.name)' 2>/dev/null)"
off=()
while IFS='|' read -r id name; do
  [[ -z "$id" || "$id" == \#* ]] && continue
  grep -qx "$id" <<<"$enabled" || off+=("$name")
done <"$api_file"
if [[ ${#off[@]} -eq 0 ]]; then
  row ok "APIs turned on" "all"
else
  row fail "APIs turned on" "off: $(IFS=,; echo "${off[*]}" | sed 's/,/, /g')"
fi

echo "ALL_OK=$all_ok"
