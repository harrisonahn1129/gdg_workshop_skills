#!/usr/bin/env bash
# GDG Brooklyn workshop setup: the same guided flow as the gdg-cloud-setup skill, no agent needed.
# Made for Google Cloud Shell (gcloud is already there); works in any bash terminal with gcloud.
# Usage: bash setup.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
S="$ROOT/skills/gdg-cloud-setup/scripts"
DEFAULT_PROJECT_NAME="GDG workshop"

if [[ -t 1 ]]; then
  B=$'\e[1m'; DIM=$'\e[2m'; G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; C=$'\e[36m'; X=$'\e[0m'
else
  B=""; DIM=""; G=""; Y=""; R=""; C=""; X=""
fi

# get KEY "<script output>" -> value of the first KEY=value line
get() { grep -m1 "^$1=" <<<"$2" | cut -d= -f2-; }
header() { printf '\n%s━━━ %s ━━━%s\n\n' "$B$C" "$1" "$X"; }
done_box() { printf '%s✅ %s%s\n' "$B$G" "$1" "$X"; }
fail() { printf '%s✗ %s%s\n' "$R" "$1" "$X"; }
note() { printf '%s%s%s\n' "$DIM" "$1" "$X"; }

# yes_no "question" -> 0 for yes, 1 for no; keeps asking until it gets y or n.
yes_no() {
  local a
  while true; do
    read -r -p "$1 [y/n] " a || exit 1
    case "$a" in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
    esac
  done
}

# ─── Step 1 ────────────────────────────────────────────────────────────────
header "Step 1 of 4 · Check your Gmail"

pre="$("$S/preflight.sh")"
if [[ "$(get GCLOUD_INSTALLED "$pre")" != "yes" ]]; then
  fail "The gcloud command isn't installed here."
  echo "Run this in Google Cloud Shell instead (gcloud is already there): https://shell.cloud.google.com"
  exit 1
fi

while true; do
  account="$(get ACTIVE_ACCOUNT "$("$S/preflight.sh")")"
  if [[ "$account" == "none" || -z "$account" ]]; then
    echo "You're not signed in yet."
    yes_no "Sign in now? (a browser link will open)" || exit 1
    gcloud auth login
    continue
  fi
  echo "Signed in as: ${B}$account${X}"
  yes_no "Is this the Gmail you claimed your workshop code with?" && break
  echo "Pick the Gmail you claimed the code with."
  gcloud auth login
done

done_box "Gmail: $account"

# ─── Step 2 ────────────────────────────────────────────────────────────────
header "Step 2 of 4 · Create your project"

name="$DEFAULT_PROJECT_NAME"
while true; do
  sug="$("$S/suggest_project_id.sh" "$name")"
  if [[ "$(get NAME_VALID "$sug")" != "yes" ]]; then
    fail "$(get NAME_ERROR "$sug")"
    read -r -p "Project name: " name || exit 1
    continue
  fi
  project_id="$(get PROJECT_ID "$sug")"
  echo "Creating project ${B}$name${X} (ID ${B}$project_id${X})…"
  out="$("$S/create_project.sh" "$project_id" "$name")"
  [[ "$(get STATUS "$out")" == "created" ]] && break
  fail "Couldn't create the project: $(get ERROR "$out")"
  note "See skills/gdg-cloud-setup/references/troubleshooting.md."
  yes_no "Try again with a new ID?" || exit 1
done

done_box "Project: $project_id"

# ─── Step 3 ────────────────────────────────────────────────────────────────
header "Step 3 of 4 · Connect your workshop credit"

while true; do
  list="$("$S/list_billing.sh")"
  if [[ "$list" == ERROR=* ]]; then
    fail "Couldn't list billing accounts: ${list#ERROR=}"
    exit 1
  fi
  if [[ "$list" == "NONE" ]] || ! grep -q '|OPEN$' <<<"$list"; then
    fail "No workshop credit found on $account."
    echo "Claim your code in the browser with ${B}$account${X}, then come back."
    read -r -p "Press Enter once you've claimed it… " _ || exit 1
    continue
  fi
  break
done

open_rows="$(grep '|OPEN$' <<<"$list")"
if [[ "$(wc -l <<<"$open_rows")" -eq 1 ]]; then
  IFS='|' read -r _ billing_name billing_id _ <<<"$open_rows"
  echo "Found: ${B}$billing_name${X}"
else
  echo "Your billing accounts:"
  echo
  while IFS='|' read -r n display id _; do
    printf '  %s%2s.%s %s %s(%s)%s\n' "$B" "$n" "$X" "$display" "$DIM" "$id" "$X"
  done <<<"$open_rows"
  echo
  note "Your workshop credit looks like \"[date] GDP Credit: XXXX-…\". Pick the newest one."
  while true; do
    read -r -p "Which number? " pick || exit 1
    line="$(grep -m1 "^${pick}|.*|OPEN$" <<<"$open_rows" || true)"
    [[ "$pick" =~ ^[0-9]+$ && -n "$line" ]] && break
    fail "Type one of the numbers above."
  done
  IFS='|' read -r _ billing_name billing_id _ <<<"$line"
fi

while true; do
  echo "Connecting…"
  out="$("$S/link_billing.sh" "$project_id" "$billing_id")"
  [[ "$(get STATUS "$out")" == "linked" ]] && break
  fail "Couldn't connect the credit: $(get ERROR "$out")"
  note "See skills/gdg-cloud-setup/references/troubleshooting.md."
  yes_no "Try again?" || exit 1
done

done_box "Credit connected: $billing_name"

# ─── Step 4 ────────────────────────────────────────────────────────────────
header "Step 4 of 4 · Turn on the APIs"

echo "Turning on APIs… this can take a minute or two."
apis="$("$S/enable_apis.sh" enable "$project_id")"
if [[ "$(get STATUS "$apis")" == "partial" ]]; then
  fail "Some APIs didn't turn on:"
  grep '^ERROR=' <<<"$apis" | cut -d= -f2- | sed 's/^/   /'
fi

# ─── Check ─────────────────────────────────────────────────────────────────
header "Final check"

check="$("$S/verify.sh" "$project_id")"
while IFS='|' read -r state label detail; do
  [[ "$state" == ALL_OK=* || -z "$state" ]] && continue
  if [[ "$state" == "ok" ]]; then
    printf '   %s✅%s %-24s %s%s%s\n' "$G" "$X" "$label" "$DIM" "$detail" "$X"
  else
    printf '   ❌ %-24s %s%s%s\n' "$label" "$R" "$detail" "$X"
  fi
done <<<"$check"
echo

if [[ "$(get ALL_OK "$check")" != "yes" ]]; then
  fail "Something's missing. Show this screen to a mentor."
  note "Fixes: skills/gdg-cloud-setup/references/troubleshooting.md. Re-check any time:"
  note "  skills/gdg-cloud-setup/scripts/verify.sh $project_id"
  exit 1
fi

cat <<EOF
${B}${G}🎉 Cloud setup done. Keep this screen open.${X}

${B}📋 Your project ID:${X}       ${B}${Y}$project_id${X}

${B}Now on your laptop:${X}
  1. Install Antigravity: ${B}https://antigravity.google/download${X}
  2. Open it, click ${B}Sign in${X}, then ${B}Business account${X}.
  3. Click ${B}Continue with Google Cloud${X} and pick ${B}$account${X} in the browser.
  4. Choose ${B}Other${X}, paste ${B}$project_id${X}, location ${B}global${X}.

${B}Free plan or credit?${X}
  Skip ${B}Business account${X} and you're on the ${B}free plan${X}: a weekly limit,
  and when it runs out the agent stops until next week. Don't use it today.
  ${B}Business account${X} + your project ID = ${B}your credit${X}.
  If the agent stops mid-build, you're probably on the free plan:
  sign out and do steps 2-4 again.
EOF
