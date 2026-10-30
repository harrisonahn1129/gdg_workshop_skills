# GDG Brooklyn workshop setup

<walkthrough-tutorial-duration duration="15"></walkthrough-tutorial-duration>

## Welcome

Before you start:

- You've claimed your workshop code.
- The account picture in the **top right** of this page is the Gmail you claimed it with. If it isn't, switch accounts first.

Click **Start**.

## Run the setup

Click the copy button on the command below, paste it into the terminal and press **Enter**:

```bash
bash setup.sh
```

If Cloud Shell asks you to **Authorize**, click **Authorize**.

The script asks two things:

- **Is this your Gmail?** Answer `y` if it's the one you claimed the code with.
- **Which billing account?** Only asked if you have more than one. Pick the newest `GDP Credit`.

It ends with a check list. All ✅ means you're done. Any ❌, show the screen to a mentor.

## Install Antigravity and sign in

The script prints your **project ID** in yellow. Keep this tab open.

On your laptop:

1. Install Antigravity from https://antigravity.google/download.
2. Open it and click **Sign in**, then **Business account**.
3. Click **Continue with Google Cloud** and pick the same Gmail.
4. Choose **Other**, paste your project ID, location **global**.

Skipping **Business account** puts you on the free plan, which stops when its weekly limit runs out. If the agent stops mid-build, sign out and repeat steps 2-4.

## You're done 🎉

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

For the codelab's Gemini API key, create it in AI Studio and pick this project when it asks.
