---
name: gdg-cloud-setup
description: Guides a GDG workshop attendee, one step at a time, from a Gmail account to Antigravity running on their workshop credit. It creates a Google Cloud project, connects the credit's billing account, turns on the APIs Antigravity needs, re-checks everything, and walks them through signing in with Business account and their project ID. Use this whenever someone wants to set up Google Cloud or Antigravity for a workshop or codelab, attach credits or billing to a project, or is stuck on Antigravity's Business account or project ID sign-in, even if they don't name this skill.
---

# GDG Cloud + Antigravity setup

The workshop is in person. Attendees arrive with a laptop and a Gmail account, and get their credit code in the room. This skill takes them through project, credit and APIs, then installing Antigravity and signing in with Business account so the credit pays.

The person you're helping may never have used Google Cloud or a terminal. Keep the language plain, run one step at a time, and never leave them guessing what just happened.

## How every step works

1. **Ask** only what the step needs. If you have a structured question tool (Claude Code: AskUserQuestion), use it: a plain question in chat ends your turn, and a first-time user thinks the setup stopped. Without one, end your message with a bold line starting with 👉 that says exactly what to type, e.g. **👉 Type the number and press Enter.**
2. **Do it**: run the script for the step.
3. **Summarize** in one ✅ line.

If a step fails, say what went wrong in one or two plain sentences, check `references/troubleshooting.md`, and offer the fix. Don't move on until it has succeeded.

All scripts live in `scripts/` next to this file. They print `KEY=value` lines; turn them into friendly summaries rather than pasting raw output.

## Step 1: Check the Gmail

Run `scripts/preflight.sh`. If `GCLOUD_INSTALLED=no`, tell them to use Google Cloud Shell (https://shell.cloud.google.com), where gcloud is already installed. If no one is signed in, run `gcloud auth login`.

Show `ACTIVE_ACCOUNT` and ask: *"Is this the Gmail you claimed your workshop code with?"* If not, run `gcloud auth login` and check again. The credit only shows up for the Gmail that claimed it.

## Step 2: Create the project

Use the name **GDG workshop** unless they've asked for another. Run `scripts/suggest_project_id.sh "GDG workshop"`, then `scripts/create_project.sh <PROJECT_ID> "GDG workshop"`. If the ID is taken, suggest a new one and retry. No confirmation needed: creating a project costs nothing.

✅ `Project: <PROJECT_ID>`

## Step 3: Connect the credit

Run `scripts/list_billing.sh`. Only **OPEN** accounts can be linked.

- **One open account:** use it.
- **Several:** show the open ones as a numbered list and ask which. The credit looks like `[2026-10-17] GDP Credit: XXXX-XXXX-XXXX-XXXX`; point out the newest.
- **None** (`NONE`, or nothing OPEN): the code wasn't claimed with this Gmail. Have them claim it in the browser, then list again.

Run `scripts/link_billing.sh <PROJECT_ID> <BILLING_ACCOUNT_ID>`.

✅ `Credit connected: <BILLING_ACCOUNT_NAME>`

## Step 4: APIs

Run `scripts/enable_apis.sh enable <PROJECT_ID>` (a minute or two; the list is `references/apis.txt`). For the codelab's Gemini API key, create it in AI Studio and pick this project when it asks.

## Step 5: Final check

Run `scripts/verify.sh <PROJECT_ID>`. It re-checks everything from scratch. Show every row as ✅ or ❌. If `ALL_OK=no`, fix the ❌ rows (troubleshooting) before going on.

## Step 6: Install Antigravity and sign in

Show the project ID on its own line in a code block, then:

```
On your laptop:
  1. Install Antigravity: https://antigravity.google/download
  2. Open it, click Sign in, then Business account.
  3. Click Continue with Google Cloud and pick <ACCOUNT> in the browser.
  4. Choose Other, paste <PROJECT_ID>, location global.
```

Then explain the two plans in two lines: skipping **Business account** puts them on the free plan, with a weekly limit that stops the agent until next week when it runs out; **Business account** with their project ID uses the credit. If the agent stops mid-build, they're probably on the free plan: sign out and repeat steps 2-4.
