# GDG Brooklyn workshop skills

Get from "I just claimed my Google Cloud credit" to "I'm signed in to Antigravity" in about 10 minutes:

1. Create a Google Cloud project (no organization)
2. Connect the workshop credit's billing account
3. Enable the 23 Agent Platform APIs (the same set as the console's **Enable APIs** banner)
4. Install Antigravity 2.0 (on a laptop) and sign in with **Use Business Account → Continue with Google Cloud → Pay As You Go → your project ID**

Every step asks first, confirms, then shows a summary. **Claim your credit first**, with the Gmail you'll use for everything below.

## Option A: Google Cloud Shell (recommended, nothing to install)

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/harrisonahn1129/gdg_workshop_skills&cloudshell_tutorial=tutorial.md)

Click the button. Cloud Shell opens with this repo and a tutorial panel. Then run:

```bash
bash setup.sh
```

Or, from any Cloud Shell terminal:

```bash
git clone https://github.com/harrisonahn1129/gdg_workshop_skills && cd gdg_workshop_skills && bash setup.sh
```

Cloud Shell runs in the cloud, so install Antigravity on your laptop yourself from https://antigravity.google/download. The script prints the sign-in steps and your project ID at the end.

## Option B: Your own terminal, no agent

Needs bash and the [gcloud CLI](https://cloud.google.com/sdk/docs/install) (macOS: `brew install --cask gcloud-cli`).

```bash
git clone https://github.com/harrisonahn1129/gdg_workshop_skills && cd gdg_workshop_skills && bash setup.sh
```

On a laptop, the script also checks for Antigravity 2.0 and installs the right build for your OS and chip.

## Option C: With an AI agent (Claude Code or Gemini CLI)

The same flow is packaged as an agent skill, `gdg-cloud-setup`. After setup, just ask: *"Help me set up my Google Cloud project for the workshop."*

### Claude Code

| Where | How |
|---|---|
| Inside this repo | `cd gdg_workshop_skills && claude`. The skill loads automatically from `.claude/skills/`. |
| Anywhere (install once) | In Claude Code: `/plugin marketplace add harrisonahn1129/gdg_workshop_skills`, then `/plugin install gdg-workshop@gdg-brooklyn` |
| In Cloud Shell | Install first with `curl -fsSL https://claude.ai/install.sh \| bash` (needs a Claude account), then use it inside this repo as above. |

### Gemini CLI

| Where | How |
|---|---|
| Inside this repo | `cd gdg_workshop_skills && gemini`, and choose **Trust folder** when asked. Workspace skills load from `.agents/skills/` only in trusted folders. Check with `/skills list`. |
| Anywhere (install once) | `gemini skills install https://github.com/harrisonahn1129/gdg_workshop_skills.git --path skills/gdg-cloud-setup` |
| In Cloud Shell | Gemini CLI is preinstalled. Use it inside this repo as above. |

## Repo layout

```
setup.sh                     guided script, no agent needed (Options A and B)
tutorial.md                  Cloud Shell side-panel walkthrough
skills/gdg-cloud-setup/      the skill: SKILL.md, scripts/, references/
.claude/skills/…  → skills/gdg-cloud-setup   (symlink, for Claude Code)
.agents/skills/…  → skills/gdg-cloud-setup   (symlink, for Gemini CLI and other Agent Skills tools)
.claude-plugin/              Claude Code plugin + marketplace manifests
```

The skill exists once, in `skills/gdg-cloud-setup/`, and the agent folders are symlinks to it, so there's only one copy to edit. On Windows, `git clone` may turn symlinks into plain text files. Windows users should use the "Anywhere" install commands above.

## Maintaining

- **API list:** `skills/gdg-cloud-setup/references/agent_platform_apis.txt`. Update it if the console's Enable APIs banner changes.
- **Antigravity installers:** the scripts read the latest links from https://antigravity.google/download, with a pinned fallback version in `scripts/antigravity.sh` and `scripts/antigravity.ps1`.
- **Common errors:** `skills/gdg-cloud-setup/references/troubleshooting.md`
