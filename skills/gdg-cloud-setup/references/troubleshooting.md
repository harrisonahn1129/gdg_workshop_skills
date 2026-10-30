# Troubleshooting

## Contents
- Account and auth problems
- Project creation errors
- Billing errors
- API enabling errors
- Antigravity sign-in
- Running on Windows (raw gcloud commands)

## Account and auth problems

**"You do not currently have an active account selected"**: run `gcloud auth login`. A browser opens; pick the Gmail that claimed the code.

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

**"Billing account for project is not found" / "requires billing to be enabled"**: Step 3 didn't complete. Re-check with `gcloud billing projects describe <id>`.

**Timeouts or "operation still in progress"**: re-run `enable_apis.sh enable <id>`. Enabling is idempotent.

**One API is permanently unavailable**: confirm the current ID with `gcloud services list --available --filter="config.title:'<Display Name>'"` and update `references/apis.txt`.

## Antigravity sign-in

**The agent stops mid-build with a limit message**: they're on the free plan. Sign out, then **Sign in** → **Business account** → **Continue with Google Cloud** → **Other** → project ID, location `global`.

**The project is rejected or not listed**:
- The Gmail picked in the browser must be the one that owns the project.
- Run `verify.sh <id>`: billing and the Agent Platform API must both be ✅.
- Use the project **ID**, not the project name or number.

**Wrong project or location**: sign out and sign in again; that's the only way to change them.

## Running on Windows (raw gcloud commands)

The setup is meant for Cloud Shell. If someone insists on plain PowerShell with gcloud installed:

| Step | Command |
|---|---|
| Who's signed in | `gcloud auth list` |
| Create project | `gcloud projects create <id> --name="GDG workshop"` |
| List billing | `gcloud billing accounts list` |
| Link billing | `gcloud billing projects link <id> --billing-account=<billing-id>` |
| Enable APIs | `gcloud services enable <ids from apis.txt> --project=<id>` |
