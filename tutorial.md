# GDG Brooklyn workshop setup

<walkthrough-tutorial-duration duration="10"></walkthrough-tutorial-duration>

## Welcome

This walks you through everything you need before the workshop:

1. Create a Google Cloud project
2. Connect your workshop credit's billing account to it
3. Enable the Agent Platform APIs
4. Sign in to the Antigravity app with your project

Before you start, check that the account picture in the **top right** of this page is the Gmail you **claimed the workshop credit with**. If it isn't, switch accounts first.

Click **Start** to begin.

## Run the setup

Click the copy button on the command below to paste it into the terminal, then press **Enter**:

```bash
bash setup.sh
```

The script asks you a question at each step and checks with you before changing anything:

- **Project name**: pick anything, like `My Agent Workshop`
- **Billing account**: type the number of your workshop credit. It usually looks like `[date] GDP Credit: XXXX-…`
- **Enable APIs**: answer `y`

If Cloud Shell asks you to **Authorize** gcloud, click **Authorize**.

## Prefer an AI agent?

Instead of the script, you can ask Gemini CLI (already installed here) to guide you with the same steps:

```bash
gemini
```

When it asks whether to trust this folder, choose **Trust folder**. Then type:

```
Help me set up my Google Cloud project for the workshop
```

## Sign in to Antigravity on your laptop

At the end, the setup prints your **project ID** in yellow. Copy it.

On your **laptop** (not here in Cloud Shell):

1. Download and install Antigravity: https://antigravity.google/download
2. Open it and click **Use Business Account**
3. Click **Continue with Google Cloud**
4. Choose the **same Gmail** you used here
5. Choose **Pay As You Go**
6. Paste your **project ID** and continue

## You're done 🎉

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

See you at the workshop! If something went wrong, ask an organizer. Bring the error message shown in the terminal.
