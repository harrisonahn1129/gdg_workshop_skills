#!/usr/bin/env bash
# Shows or enables the Agent Platform API set (references/agent_platform_apis.txt) on a project.
# Usage: agent_platform_apis.sh status <project-id>
#        agent_platform_apis.sh enable <project-id>
# Output: one line per API: "<Enabled|Not enabled>|<display name>|<service id>"
#         enable mode also prints STATUS=done or STATUS=partial with ERROR lines.
set -uo pipefail

mode="${1:?mode required: status|enable}"
project_id="${2:?project id required}"
api_file="$(cd "$(dirname "$0")/.." && pwd)/references/agent_platform_apis.txt"

ids=()
names=()
while IFS='|' read -r id name; do
  [[ -z "$id" || "$id" == \#* ]] && continue
  ids+=("$id")
  names+=("$name")
done <"$api_file"

print_status() {
  local enabled
  enabled="$(gcloud services list --enabled --project="$project_id" --format='value(config.name)' 2>/dev/null)"
  for i in "${!ids[@]}"; do
    if grep -qx "${ids[$i]}" <<<"$enabled"; then
      echo "Enabled|${names[$i]}|${ids[$i]}"
    else
      echo "Not enabled|${names[$i]}|${ids[$i]}"
    fi
  done
}

case "$mode" in
  status)
    print_status
    ;;
  enable)
    # gcloud accepts at most 20 services per call, so enable in batches.
    failed=0
    batch_size=10
    for ((start = 0; start < ${#ids[@]}; start += batch_size)); do
      batch=("${ids[@]:start:batch_size}")
      if ! err="$(gcloud services enable "${batch[@]}" --project="$project_id" --quiet 2>&1)"; then
        failed=1
        echo "ERROR=$(printf '%s' "$err" | tr '\n' ' ')"
      fi
    done
    print_status
    if [[ $failed -eq 0 ]]; then echo "STATUS=done"; else echo "STATUS=partial"; fi
    ;;
  *)
    echo "Unknown mode: $mode" >&2
    exit 2
    ;;
esac
