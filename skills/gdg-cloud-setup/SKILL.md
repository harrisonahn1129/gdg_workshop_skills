---
name: gdg-cloud-setup
description: Guides a GDG workshop attendee, one confirmed step at a time, through Google Cloud setup for Antigravity. It creates a Google Cloud project, links a billing account (such as the workshop credit), enables the Agent Platform APIs, installs the Antigravity 2.0 desktop app if needed, and walks them through signing in with Business Account, Continue with Google Cloud, and Pay As You Go using their project ID. Use this whenever someone wants to set up Google Cloud or Antigravity for a workshop or codelab, create a GCP project and attach their credits or billing, enable Vertex AI or Agent Platform APIs, or is stuck on Antigravity's "Continue with Google Cloud" or "Pay As You Go" project ID screen, even if they don't name this skill.
---

# GDG Cloud + Antigravity setup

Workshop attendees often get stuck before the workshop even starts. They have to create a project, attach the credit's billing account, turn on a long list of APIs, and sign in to Antigravity with exactly the right account and project. This skill does the cloud work for them and leaves only the clicks that truly need a human.

The person you're helping may never have used Google Cloud or a terminal. Keep the language plain, run one step at a time, and never leave them guessing what just happened.

## How every step works

Each step follows the same rhythm, because attendees need to stay in control of their own account and money:

1. **Ask**: get the input the step needs (a name, a number, a yes/no).
2. **Confirm**: repeat back exactly what you're about to do, and wait for a yes.

**How to ask.** If you have a structured question tool (Claude Code: AskUserQuestion), use it for every question in this flow, including the project name and the billing choice. These tools always add a free-text "Other" option, so the user can still type their own answer. A plain question in chat ends your turn, and to a first-time user that looks like the setup just stopped. They don't realize you're waiting for them.

If you have to ask in plain text (no question tool, or more choices than the tool can show), make the waiting obvious. End your message with a bold line starting with 👉 that says exactly what to type, e.g. **👉 Type your project name and press Enter.** Don't put anything after it.
3. **Do it**: run the script for the step.
4. **Summarize**: show a short "✅ Step N done" block with the facts listed for that step below.

If a step fails, say what went wrong in one or two plain sentences, check `references/troubleshooting.md`, and offer the fix. Don't move on to the next step until the current one has succeeded, because every later step depends on the earlier ones.

All scripts live in `scripts/` next to this file. They print simple `KEY=value` lines; read them and turn them into friendly summaries, rather than pasting raw output at the user. On Windows without bash, run the equivalent `gcloud` commands from `references/troubleshooting.md` ("Running on Windows").

## Step 0: Check gcloud and the signed-in account

Run `scripts/preflight.sh`.

- **gcloud is missing** (`GCLOUD_INSTALLED=no`): ask whether to install it. On macOS with Homebrew, run `brew install --cask gcloud-cli`. Otherwise follow https://cloud.google.com/sdk/docs/install for their OS. Then re-run the preflight.
- **No one is signed in, or it's the wrong account**: the account has to be the Gmail they used to claim the credit. Otherwise the credit's billing account won't show up in Step 2. Show `ACTIVE_ACCOUNT` and ask: *"Is this the Gmail account you claimed the Google Cloud credit with?"* If not, run `gcloud auth login`, which opens a browser so they can pick the right account, and check again.

Also ask whether they have already claimed the credit (redeemed the coupon link). If they haven't, have them do it now in the browser with that same Gmail. Claiming creates the billing account Step 2 needs, and it can't be done from the command line.

Summary: the signed-in Google account, and that the credit has been claimed.

## Step 1: Create a new Google Cloud project

1. Ask: *"What would you like to name your project?"* (4–30 characters; letters, numbers, spaces, hyphens). With a question tool, offer two or three ready-made names as options (e.g. "GDG Workshop", "My Agent Lab") and let them type their own through "Other".
2. Run `scripts/suggest_project_id.sh "<name>"`. If `NAME_VALID=no`, explain `NAME_ERROR` and ask again.
3. Confirm: *"I'll create a project named **<name>** with ID **<PROJECT_ID>**, with no organization. OK?"* The project ID is permanent and is what they'll paste into Antigravity later. If they'd like a different ID (6–30 lowercase letters, digits, hyphens, starting with a letter), use theirs.
4. Run `scripts/create_project.sh <PROJECT_ID> "<name>"`. It creates the project without an organization or folder and makes it gcloud's active project. If it fails because the ID is taken, suggest a new ID and confirm again.

Summary:

```
✅ Step 1 done: project created
   Project name: <PROJECT_NAME>
   Project ID:   <PROJECT_ID>
```

## Step 2: Connect billing to the project

1. Run `scripts/list_billing.sh` and show the accounts as a numbered list, exactly in the order the script gives them:
   ```
   1. Google Cloud Platform Trial Billing Account  (01A2B3-...)  OPEN
   2. My Billing Account                           (0174F5-...)  OPEN
   ```
   Closed accounts can't be linked. Show them anyway so the list makes sense, but mark them as unusable. Workshop credits usually show up as their own billing account, named like `[2026-10-17] GDP Credit: XXXX-XXXX-XXXX-XXXX`. Point out the newest open one. Older credit accounts show as CLOSED once they expire or run out. You can't see remaining balances from here, so if it's ambiguous, say so rather than guessing.
   If the output is `NONE`, the credit probably wasn't claimed with this account. Go back to Step 0.
2. Ask: *"Which number do you want to connect to **<PROJECT_ID>**?"* Always show the full numbered list first, so the numbers stay meaningful.
   - If there are 4 or fewer **open** accounts and you have a question tool, offer them as options labeled with their list number (e.g. "3. [2026-10-17] GDP Credit: 1DBF-…").
   - Otherwise, ask in plain text and end with **👉 Type the number of the billing account and press Enter.**
3. Confirm: *"Connect billing account **<name> (<id>)** to project **<PROJECT_ID>**?"*
4. Run `scripts/link_billing.sh <PROJECT_ID> <BILLING_ACCOUNT_ID>`.

Summary:

```
✅ Step 2 done: billing connected
   Project:          <PROJECT_ID>
   Billing account:  <BILLING_ACCOUNT_NAME> (<BILLING_ACCOUNT_ID>)
   Billing enabled:  <BILLING_ENABLED>
```

## Step 3: Enable the Agent Platform APIs

These are the same 23 APIs the **Enable APIs** banner on the Cloud Console's Agent Platform page turns on (listed in `references/agent_platform_apis.txt`). Billing has to be linked first, because some of them, such as Compute Engine, refuse to enable without it.

1. Run `scripts/agent_platform_apis.sh status <PROJECT_ID>` and show which are already enabled and which aren't.
2. Ask: *"Do you want me to enable all of these Agent Platform APIs on **<PROJECT_ID>**?"*
3. If yes, run `scripts/agent_platform_apis.sh enable <PROJECT_ID>`. Tell them it can take a minute or two. If no, note that Antigravity's Pay As You Go mode may not work until they're enabled, and continue.

Summary: list every API with ✅ (enabled) or ❌ (not enabled), using the display names. If `STATUS=partial`, say which ones failed and why.

```
✅ Step 3 done: Agent Platform APIs enabled (23/23)
   ✅ Agent Identity API
   ✅ Agent Registry API
   ✅ Agent Platform API
   ...
```

## Step 4: Antigravity 2.0 app

**In Google Cloud Shell** (the `CLOUD_SHELL` environment variable is `true`, or the script prints `ENVIRONMENT=cloudshell`), you're running on a remote machine, not the attendee's laptop. Don't try to check for or install the app. Tell them to download it on their laptop from https://antigravity.google/download (it picks the right version for their OS), then go on to Step 5. Clipboard copying won't reach their laptop from there either, so just show the project ID clearly.

Otherwise, run `scripts/antigravity.sh check` (Windows: `powershell -ExecutionPolicy Bypass -File scripts/antigravity.ps1 check`).

The 2.0 desktop app is called **Antigravity**. There's also a separate older product called **Antigravity IDE**. The scripts only count the 2.0 app, so an attendee who only has the IDE will show as "not installed". That's correct; tell them that's why.

- **Not installed**: ask *"Antigravity 2.0 isn't installed. Want me to install it for you?"* If yes, run `antigravity.sh install` (Windows: `antigravity.ps1 install`). The scripts pick the right build for the OS and chip (Apple Silicon or Intel Mac, Windows x64 or ARM64, Linux x64 or ARM). On macOS they use Homebrew when it's available and the official DMG otherwise. On Windows the setup wizard opens, and the user clicks through it. If they say no, give them https://antigravity.google/download and continue with the guide.
- **Installed (or just installed)**: report the version, then ask whether they want you to open it (`antigravity.sh open` / `antigravity.ps1 open`).

## Step 5: Final summary and Antigravity sign-in guide

Finish with one clear block. Put the project ID on its own line in a code block so it's easy to copy. It's the single most important thing they need from this whole process. If you can, also copy it to their clipboard (`printf '%s' <PROJECT_ID> | pbcopy` on macOS, `clip` on Windows, `xclip -selection clipboard` or `wl-copy` on Linux) and tell them you did.

```
🎉 All set! Here's your setup

  Google account:   <ACCOUNT>
  Project name:     <PROJECT_NAME>
  Billing account:  <BILLING_ACCOUNT_NAME> (<BILLING_ACCOUNT_ID>)
  APIs enabled:     <n>/23
  Antigravity:      installed (v<VERSION>)

📋 YOUR PROJECT ID (you'll paste this into Antigravity):

    <PROJECT_ID>

Sign in to Antigravity:
  1. Open the Antigravity app.
  2. On "Welcome to Antigravity", click **Use Business Account**
     (not "Continue with Google").
  3. On "Business Account Sign In", click **Continue with Google Cloud**.
  4. In the browser, choose **<ACCOUNT>**, the Gmail you claimed the
     credit and created the project with, and allow access.
  5. On "Select Billing Model", choose **Pay As You Go**.
  6. Under "Provide Google Cloud Project", paste your project ID:
         <PROJECT_ID>
     and continue.
```

Point out the two most common mistakes: clicking **Continue with Google** instead of **Use Business Account**, and choosing a different Gmail in the browser than the one shown above.
