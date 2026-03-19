---
name: mega-hotfix
description: MEGA iOS hotfix workflow. Use when the user reports a crash or critical bug in production, needs to stop a phased release, or wants to prepare and release a hotfix build.
disable-model-invocation: true
allowed-tools: Bash
---

# MEGA iOS Hotfix Workflow

For new crashes or bugs in production, first assess the impact. If a hotfix is needed, stop the phased release if it is in progress, then follow the steps below.

---

## Step 1 — Stop the Phased Release (if in progress)

Contact one of the following people to pause the phased release:
- **@Harry Yan**
- **@Javier Navarro**
- **@André Meister**

---

## Step 2 — Run PrepareHotfix Script

Make sure you are on the latest `develop` branch. From the project root:

```bash
cd scripts/ReleaseScripts/PrepareHotfix && ./run.sh
```

This creates a MR in GitLab called `Hotfix [major].[minor].[patch]`.

---

## Step 3 — Document the Reason on the Hotfix MR

Add a detailed description to the hotfix MR explaining:
- What the bug/crash is
- Impact on users
- Root cause (if known)

---

## Step 4 — Create Jira Version

Comment on the release MR:
```
jira_create_version
```

---

## Step 5 — Create JIRA Tickets and Fix

- Create JIRA tickets for each crash/bug included in the hotfix
- Collaborate with the relevant engineers to fix the issues
- Cherry-pick the fixes into the hotfix branch

---

## Step 6 — Trigger Hotfix Build

Once all issues are fixed, comment on the code freeze MR:
```
deliver_appStore --announce-release true --hotfix-build true
```

---

## Step 7 — Post Hotfix Report

Once the hotfix build is uploaded and the automation posts the release announcement, **reply in that announcement thread** in **#ios** and **#qa** channels:

```
Here is the hotfix report:

[Build the report following the Hotfix report template]
```

---

## Step 8 — Release the Hotfix

Follow the standard release process starting from **Phase 3** of `/mega-release-workflow` (App Store Submission) to submit and release the hotfix build.

---

## ⚠️ Warning: Higher Version Release Branch Exists

If there is already a release branch with a greater version number (e.g. you are creating a hotfix for `13.3` but `release/13.4` already exists):
- Cherry-pick the hotfix commits into the `release/13.4` branch so those fixes are included there as well
- Add links to those cherry-picked commits to the hotfix MR description
