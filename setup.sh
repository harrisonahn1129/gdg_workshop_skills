#!/usr/bin/env bash
# GDG Brooklyn workshop setup: the same guided flow as the gdg-cloud-setup skill, no agent needed.
# Runs in Google Cloud Shell or any bash terminal with gcloud.
# Usage: bash setup.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
S="$ROOT/skills/gdg-cloud-setup/scripts"
DOWNLOAD_PAGE="https://antigravity.google/download"
DEFAULT_PROJECT_NAME="GDG workshop"

if [[ -t 1 ]]; then
  B=$'\e[1m'; DIM=$'\e[2m'; G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; C=$'\e[36m'; X=$'\e[0m'
else
  B=""; DIM=""; G=""; Y=""; R=""; C=""; X=""
fi

# get KEY "<script output>" -> value of the first KEY=value line
get() { grep -m1 "^$1=" <<<"$2" | cut -d= -f2-; }
header() { printf '\n%s━━━ %s ━━━%s\n\n' "$B$C" "$1" "$X"; }
done_box() { printf '\n%s✅ %s%s\n' "$B$G" "$1" "$X"; }
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

in_cloud_shell() { [[ "${CLOUD_SHELL:-}" == "true" ]]; }

# ─── Step 0 ────────────────────────────────────────────────────────────────
header "Step 0 · Check your Google account"

pre="$("$S/preflight.sh")"
if [[ "$(get GCLOUD_INSTALLED "$pre")" != "yes" ]]; then
  fail "The gcloud command isn't installed on this computer."
  echo "Easiest fix: run this setup in Google Cloud Shell instead (gcloud is already there):"
  echo "  https://shell.cloud.google.com"
  echo "Or install gcloud: https://cloud.google.com/sdk/docs/install"
  exit 1
fi

while true; do
  account="$(get ACTIVE_ACCOUNT "$("$S/preflight.sh")")"
  if [[ "$account" == "none" || -z "$account" ]]; then
    echo "You're not signed in to gcloud yet."
    yes_no "Sign in now? (a browser link will open)" || exit 1
    gcloud auth login
    continue
  fi
  echo "Signed in as: ${B}$account${X}"
  if yes_no "Is this the Gmail account you claimed the Google Cloud credit with?"; then
    break
  fi
  echo "Let's switch accounts. Pick the Gmail you claimed the credit with."
  gcloud auth login
done

if ! yes_no "Have you already claimed the workshop credit (clicked the coupon link and accepted it)?"; then
  echo
  echo "Please claim it now in your browser, signed in as ${B}$account${X}."
  echo "Claiming creates the billing account we'll connect in Step 2."
  read -r -p "Press Enter once you've claimed it… " _ || exit 1
fi

done_box "Step 0 done: account checked"
echo "   Google account: $account"

# ─── Step 1 ────────────────────────────────────────────────────────────────
header "Step 1 · Create a new Google Cloud project"

while true; do
  if yes_no "Use the default project name \"$DEFAULT_PROJECT_NAME\"? (n = name it yourself)"; then
    name="$DEFAULT_PROJECT_NAME"
  else
    read -r -p "What would you like to name your project? " name || exit 1
  fi
  sug="$("$S/suggest_project_id.sh" "$name")"
  if [[ "$(get NAME_VALID "$sug")" != "yes" ]]; then
    fail "$(get NAME_ERROR "$sug")"
    continue
  fi
  project_id="$(get PROJECT_ID "$sug")"
  echo
  echo "  Project name: ${B}$name${X}"
  echo "  Project ID:   ${B}$project_id${X}   ${DIM}(permanent; you'll paste this into Antigravity)${X}"
  echo "  Organization: none"
  echo
  if ! yes_no "Use this project ID?"; then
    read -r -p "Type the project ID you want (6-30 lowercase letters, digits, hyphens; starts with a letter): " project_id || exit 1
  fi
  if ! yes_no "Create project \"$name\" with ID $project_id?"; then
    continue
  fi
  echo "Creating project…"
  out="$("$S/create_project.sh" "$project_id" "$name")"
  if [[ "$(get STATUS "$out")" == "created" ]]; then
    break
  fi
  fail "Couldn't create the project: $(get ERROR "$out")"
  note "See skills/gdg-cloud-setup/references/troubleshooting.md. Let's try again with a different name or ID."
done

project_name="$(get PROJECT_NAME "$out")"
done_box "Step 1 done: project created"
echo "   Project name: $project_name"
echo "   Project ID:   ${B}$project_id${X}"

# ─── Step 2 ────────────────────────────────────────────────────────────────
header "Step 2 · Connect billing to $project_id"

while true; do
  list="$("$S/list_billing.sh")"
  if [[ "$list" == ERROR=* ]]; then
    fail "Couldn't list billing accounts: ${list#ERROR=}"
    exit 1
  fi
  if [[ "$list" == "NONE" ]]; then
    fail "No billing accounts found for $account."
    echo "This usually means the credit was claimed with a different Gmail, or not claimed yet."
    read -r -p "Claim it with $account, then press Enter to check again… " _ || exit 1
    continue
  fi
  break
done

echo "Billing accounts on your Google account:"
echo
count=0
while IFS='|' read -r n display id state; do
  count=$n
  if [[ "$state" == "OPEN" ]]; then
    printf '  %s%2s.%s %-50s %s(%s)%s  %sOPEN%s\n' "$B" "$n" "$X" "$display" "$DIM" "$id" "$X" "$G" "$X"
  else
    printf '  %s%2s. %-50s (%s)  CLOSED, can'"'"'t be used%s\n' "$DIM" "$n" "$display" "$id" "$X"
  fi
done <<<"$list"
echo
note "Workshop credits usually look like \"[date] GDP Credit: XXXX-…\". Pick the newest OPEN one."
echo

while true; do
  read -r -p "Which number do you want to connect to $project_id? " pick || exit 1
  line="$(grep -m1 "^${pick}|" <<<"$list" || true)"
  if [[ ! "$pick" =~ ^[0-9]+$ || -z "$line" ]]; then
    fail "Please type a number from 1 to $count."
    continue
  fi
  IFS='|' read -r _ billing_name billing_id state <<<"$line"
  if [[ "$state" != "OPEN" ]]; then
    fail "\"$billing_name\" is closed and can't be linked. Pick an OPEN one."
    continue
  fi
  if ! yes_no "Connect \"$billing_name\" ($billing_id) to $project_id?"; then
    continue
  fi
  echo "Connecting billing…"
  out="$("$S/link_billing.sh" "$project_id" "$billing_id")"
  [[ "$(get STATUS "$out")" == "linked" ]] && break
  fail "Couldn't connect billing: $(get ERROR "$out")"
  note "See skills/gdg-cloud-setup/references/troubleshooting.md, or pick another account."
done

billing_name="$(get BILLING_ACCOUNT_NAME "$out")"
done_box "Step 2 done: billing connected"
echo "   Project:         $project_id"
echo "   Billing account: $billing_name ($(get BILLING_ACCOUNT_ID "$out"))"
echo "   Billing enabled: $(get BILLING_ENABLED "$out")"

# ─── Step 3 ────────────────────────────────────────────────────────────────
header "Step 3 · Enable Agent Platform APIs"

print_apis() {
  while IFS='|' read -r state display _; do
    [[ -z "$state" || "$state" == STATUS=* || "$state" == ERROR=* ]] && continue
    if [[ "$state" == "Enabled" ]]; then
      printf '   %s✅%s %s\n' "$G" "$X" "$display"
    else
      printf '   ❌ %s\n' "$display"
    fi
  done <<<"$1"
}

echo "Checking which Agent Platform APIs are on…"
status="$("$S/agent_platform_apis.sh" status "$project_id")"
total="$(grep -c '|' <<<"$status")"
print_apis "$status"
echo
if yes_no "Enable all of these Agent Platform APIs on $project_id?"; then
  echo "Enabling APIs… this can take a minute or two."
  status="$("$S/agent_platform_apis.sh" enable "$project_id")"
  if [[ "$(get STATUS "$status")" == "partial" ]]; then
    fail "Some APIs didn't enable:"
    grep '^ERROR=' <<<"$status" | cut -d= -f2- | sed 's/^/   /'
  fi
else
  note "Skipped. Antigravity's Pay As You Go mode may not work until these are enabled."
fi
enabled="$(grep -c '^Enabled|' <<<"$status")"
done_box "Step 3 done: Agent Platform APIs ($enabled/$total enabled)"
print_apis "$status"

# ─── Step 4 ────────────────────────────────────────────────────────────────
header "Step 4 · Antigravity 2.0 app"

ag_status="download it on your laptop"
if in_cloud_shell; then
  echo "You're in Google Cloud Shell, which runs in the cloud, not on your laptop."
  echo "Download Antigravity on your laptop from: ${B}$DOWNLOAD_PAGE${X}"
  note "The page picks the right version for macOS, Windows or Linux."
else
  case "$(uname -s)" in
    MINGW* | MSYS* | CYGWIN*) ag=(powershell -ExecutionPolicy Bypass -File "$(cygpath -w "$S/antigravity.ps1" 2>/dev/null || echo "$S/antigravity.ps1")") ;;
    *) ag=("$S/antigravity.sh") ;;
  esac
  chk="$("${ag[@]}" check | tr -d '\r')"
  if [[ "$(get INSTALLED "$chk")" != "yes" ]]; then
    echo "Antigravity 2.0 isn't installed on this computer."
    note "(\"Antigravity IDE\" is a different app and doesn't count.)"
    if yes_no "Install Antigravity 2.0 for $(get PLATFORM "$chk") now?"; then
      "${ag[@]}" install
      chk="$("${ag[@]}" check | tr -d '\r')"
    else
      echo "OK. You can download it later from $DOWNLOAD_PAGE"
    fi
  fi
  if [[ "$(get INSTALLED "$chk")" == "yes" ]]; then
    ag_status="installed (v$(get VERSION "$chk"))"
    done_box "Step 4 done: Antigravity $ag_status"
    yes_no "Open Antigravity now?" && "${ag[@]}" open >/dev/null
  fi
fi

# ─── Step 5 ────────────────────────────────────────────────────────────────
copied=""
if ! in_cloud_shell; then
  for cmd in pbcopy clip.exe wl-copy "xclip -selection clipboard"; do
    if command -v "${cmd%% *}" >/dev/null 2>&1; then
      printf '%s' "$project_id" | $cmd 2>/dev/null && copied="yes" && break
    fi
  done
fi

cat <<EOF

${B}${G}🎉 All set! Here's your setup${X}

  Google account:   $account
  Project name:     $project_name
  Billing account:  $billing_name
  APIs enabled:     $enabled/$total
  Antigravity:      $ag_status

${B}📋 YOUR PROJECT ID (you'll paste this into Antigravity):${X}

      ${B}${Y}$project_id${X}
$( [[ -n "$copied" ]] && echo "      ${DIM}(already copied to your clipboard)${X}" )

${B}Sign in to Antigravity:${X}
  1. Open the Antigravity app.
  2. On "Welcome to Antigravity", click ${B}Use Business Account${X} (not "Continue with Google").
  3. On "Business Account Sign In", click ${B}Continue with Google Cloud${X}.
  4. In the browser, choose ${B}$account${X} and allow access.
  5. On "Select Billing Model", choose ${B}Pay As You Go${X}.
  6. Under "Provide Google Cloud Project", paste ${B}$project_id${X} and continue.

${DIM}Common mistakes: clicking "Continue with Google" instead of "Use Business Account",
or picking a different Gmail in the browser than $account.${X}
EOF
