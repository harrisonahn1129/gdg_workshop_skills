# GDG Brooklyn workshop setup

Everything happens in the room. Bring a laptop and a Gmail account.

**1. Claim your code** with your Gmail.

**2. Run the setup in Cloud Shell.** Cloud Shell is a terminal in your browser, so there's nothing to install. Click:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/harrisonahn1129/gdg_workshop_skills&cloudshell_tutorial=tutorial.md)

then type:

```bash
bash setup.sh
```

If Cloud Shell asks you to **Authorize**, click **Authorize**. The script creates your project, connects your credit, and turns on the APIs. It ends with a check list. All ✅ means you're done. Any ❌, show the screen to a mentor.

**3. Install Antigravity** from https://antigravity.google/download.

**4. Sign in with your credit:**

1. Open Antigravity and click **Sign in**, then **Business account**.
2. Click **Continue with Google Cloud** and pick the same Gmail in the browser.
3. Choose **Other**, paste your project ID, location **global**.

## Free plan or credit?

| | Free plan | Your workshop credit |
|---|---|---|
| How you sign in | **Sign in** with Gmail | **Sign in** → **Business account** → your project ID |
| Limit | Weekly. When it runs out, the agent stops until next week | Your credit |
| Today | Don't use it | Build on this |

**If the agent stops mid-build, you're probably on the free plan.** Sign out and sign in with Business account.

For the codelab's Gemini API key, create it in AI Studio and pick this project when it asks.

## With an AI agent instead of the script

The same steps are packaged as an agent skill, `gdg-cloud-setup`. Ask: *"Help me set up my Google Cloud project for the workshop."*

| Agent | How |
|---|---|
| Antigravity CLI (`agy`) | Inside this repo, run `agy`. It loads the skill from `.agents/skills/`. Install: `curl -fsSL https://antigravity.google/cli/install.sh \| bash` (Windows PowerShell: `irm https://antigravity.google/cli/install.ps1 \| iex`). |
| Claude Code | Inside this repo, run `claude`. It loads the skill from `.claude/skills/`. Or install it anywhere: `/plugin marketplace add harrisonahn1129/gdg_workshop_skills`, then `/plugin install gdg-workshop@gdg-brooklyn`. |

Gemini CLI no longer serves free or Google AI Pro/Ultra accounts (since June 18, 2026). Use `agy`.

## Repo layout

```
setup.sh                     guided script, no agent needed
tutorial.md                  Cloud Shell side-panel walkthrough
skills/gdg-cloud-setup/      the skill: SKILL.md, scripts/, references/
.claude/skills/…  → skills/gdg-cloud-setup   (symlink, for Claude Code)
.agents/skills/…  → skills/gdg-cloud-setup   (symlink, for Antigravity CLI and other Agent Skills tools)
.claude-plugin/              Claude Code plugin + marketplace manifests
```

## Maintaining

- **APIs:** `skills/gdg-cloud-setup/references/apis.txt`.
- **Sign-in screen names** come from https://antigravity.google/docs/enterprise. Check them against the current app before each workshop and update `setup.sh`, `tutorial.md`, `SKILL.md` and this file together.
- **Common errors:** `skills/gdg-cloud-setup/references/troubleshooting.md`.
