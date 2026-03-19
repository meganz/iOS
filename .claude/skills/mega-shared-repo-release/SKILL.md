---
name: mega-shared-repo-release
description: MEGA iOS Shared Repo release workflow. Use when the user asks about the shared repo release process, shared repo code freeze, or shared repo Monday release checklist.
disable-model-invocation: true
allowed-tools: Bash
---

# MEGA iOS Shared Repo Release Workflow

Run this in parallel with the main iOS release. The Shared Repo has its own release cycle that must be coordinated.

> **Why Tuesday?** The Shared Repo RC is built one day ahead of other apps so that dependent apps (MEGA Cloud, VPN, Pass) can consume it by Wednesday.

---

## Monday — Prepare Code Freeze (Manual Checklist)

Walk the user through each item. These are all manual tasks.

### 1. Ensure Latest Weblate Setup in MEGASharedRepo
- Verify `translate.json` exists and is configured at:
  ```
  ./Modules/MEGASharedRepo/iosTransifex/weblate/translate.json
  ```
- Check it contains valid `SOURCE_TOKEN` (Weblate API key) and `GITLAB_TOKEN`
- If `translate.json` is missing or you need a reference template, download the sample config from: https://mega.nz/fm/iyhV0ARY
- See the `/weblate` skill for full Weblate setup details

---

## Tuesday — Release Preparation MR

### 1. Create the Prepare Branch
Manually create a branch from `main`:
```
branch name: task/prepare-[major].[minor]
```

### 2. Update L10n (run from MEGASharedRepo folder)

First, ensure `iosTransifex` is up to date — prompt the RC to pull the latest:
```bash
cd iosTransifex && git pull && cd ..
```

Then run the L10n download script:
```bash
./iosTransifex/weblate/lang.sh -a ios -p -l ios-lib
```

After the script completes, **prompt the RC to review the downloaded translations** — check that the updated string files look correct before committing.

**What to look for — suspicious changes:**
- Plural form values replaced with `%#@ignore@` in `.stringsdict` files — this is a known bad Weblate output.
  Example (from `ar.lproj/Localizable.stringsdict`):
  ```diff
  - <string>%d رهش لك [A] ليصحت متي</string>   ← real Arabic translation
  + <string>%#@ignore@</string>                  ← corrupted / ignore placeholder
  ```
  If you see `%#@ignore@` replacing real translated strings, **do NOT commit**. Report in the `#weblate` Slack channel to investigate before proceeding.

### 3. Create MR and Merge
- Create a new MR titled `Prepare release [major].[minor]` targeting `main`
- Request review
- Merge once the pipeline passes and approval is received

---

## Tuesday — Create Release Branch and RC Tag

### 1. Create Release Branch
Manually create from `main`:
```
branch name: release/[major].[minor]
```

> **Branch naming convention:** Trailing zeros in the minor version are dropped.
> e.g., version `2.20` → branch `release/2.2`, version `2.21` → branch `release/2.21`

### 2. Create Release MR
- Title: `Release [major].[minor]`
- Target branch: `main`

### 3. Create RC Tag
Create a tag `[major].[minor]-rc.1` from the `release/[major].[minor]` branch.

> **Tags are created manually** — do NOT attempt to detect, create, or verify release tags programmatically. Tag creation is the user's responsibility.

> **Note:** Do NOT delete the release branch until all dependent apps (MEGA Cloud, VPN, Pass) have completed their own releases.

---

## Tuesday — Post Release Announcement

Post in the **#mobile_shared_module** Slack channel.

### Get the commit list first
```bash
git log --oneline <last-release-tag>..<major>.<minor>-rc.1
```
Copy the output for the "What's new" section.

### Slack message format

```
:mega: New iOS Shared Repo version → [major].[minor]-rc.1

Commit: <commit hash of the rc.1 tag>

What's new:
<paste git log --oneline output here>

Target app/s
• MEGA Cloud: <version>
• MEGA VPN: <version>
• MEGA Pass: <version>

CC: [Release Captain(s)]
```

Then in the **thread**, mention the Release Captains of each target app individually.
