# Troubleshooting

## Contents
- Account and auth problems
- Project creation errors
- Billing errors
- API enabling errors
- Antigravity install and sign-in
- Running on Windows (raw gcloud commands)

## Account and auth problems

**"You do not currently have an active account selected"**: run `gcloud auth login`. A browser opens; pick the Gmail account that claimed the credit.

**Several Google accounts signed in**: `gcloud auth list` shows them all, and `gcloud config set account <email>` switches the active one.

## Project creation errors

**"The project ID you specified is already in use"**: IDs are unique across all of Google Cloud, including deleted projects for 30 days. Generate a new suggestion and confirm it with the user.

**"You have reached the project quota" / "Project creation quota exceeded"**: personal Gmail accounts have a limited number of projects. Options:
- Use an existing project they no longer need. Confirm it's theirs with `gcloud projects list`, then continue from Step 2 with that ID.
- Delete an unused project (`gcloud projects delete <id>`). Only do this if the user explicitly picks a specific project and confirms; deletion shuts down everything in it.

**Callers must accept Terms of Service**: brand-new accounts must open https://console.cloud.google.com once in a browser and accept the terms, then retry.

## Billing errors

**No billing accounts listed (`NONE`)**: the credit was claimed with a different Gmail, or not claimed yet. Check `gcloud auth list` against the account they used for the coupon link.

**"Cloud billing quota exceeded"**: a billing account can only be linked to a few projects at a time. Unlink an old project from it in the console (Billing → Account management → ⋮ → Disable billing), or with `gcloud billing projects unlink <old-project-id>`, but only after the user confirms which project.

**"The caller does not have permission"**: the user isn't a Billing Account Administrator/User on that account. That's typical for someone else's billing account. Pick an account they own (the credit's account).

**Billing account is CLOSED**: a closed or expired trial account can't be linked. Pick an open one.

## API enabling errors

**"Billing account for project is not found" / "requires billing to be enabled"**: Step 2 didn't complete. Re-check with `gcloud billing projects describe <id>`.

**Timeouts or "operation still in progress"**: re-run `agent_platform_apis.sh enable <id>`. Enabling is idempotent, and already-enabled APIs are skipped.

**One API is permanently unavailable**: Google occasionally renames or retires services. Confirm the current ID with `gcloud services list --available --filter="config.title:'<Display Name>'"` and update `references/agent_platform_apis.txt`.

## Antigravity install and sign-in

**macOS "Antigravity can't be opened"**: right-click the app in Applications → Open, then confirm.

**Only "Antigravity IDE" is installed**: that's a different product. Install the 2.0 app (`antigravity.sh install`); both can live side by side.

**Download link 404s**: the scripts read the latest link from https://antigravity.google/download and fall back to a pinned version. If both fail, send the user to that page to download manually.

**Sign-in: billing model screen says the project is invalid or has no access**:
- Make sure the Gmail chosen in the browser is the one that owns the project.
- Make sure the Agent Platform API (`aiplatform.googleapis.com`) is enabled and billing is linked.
- Check for a typo in the project ID: use the project **ID**, not the project name or number.

## Running on Windows (raw gcloud commands)

The `.sh` scripts need bash (Git Bash or WSL work). In plain PowerShell, run the same gcloud commands directly:

| Step | Command |
|---|---|
| Who's signed in | `gcloud auth list` |
| Create project | `gcloud projects create <id> --name="<name>"` then `gcloud config set project <id>` |
| List billing | `gcloud billing accounts list` |
| Link billing | `gcloud billing projects link <id> --billing-account=<billing-id>` |
| Check billing | `gcloud billing projects describe <id>` |
| Enable APIs | `gcloud services enable <ids from agent_platform_apis.txt, ≤20 per call> --project=<id>` |
| Show enabled | `gcloud services list --enabled --project=<id>` |
| Antigravity | `powershell -ExecutionPolicy Bypass -File scripts\antigravity.ps1 check` (or `install` / `open`) |
