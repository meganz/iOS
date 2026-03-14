---
name: mega-release-workflow
description: MEGA iOS release workflow commands and scripts. Use when the user asks about code freeze, creating a release branch, release candidates, hotfixes, or finalizing and merging a release.
---

# MEGA iOS Release Workflow

## 1. Prepare Code Freeze (Release Branch)

- **Path**: `Modules/MEGASharedRepo/scripts/PrepareRelease`
- **Command**:
  ```bash
  swift run PrepareRelease \
    --version-number <version> \
    --sdk-commit-hash <hash> \
    --chat-sdk-commit-hash <hash> \
    --shared-repo-commit-hash <hash>
  ```
- **Result**: Opens an MR in GitLab called `Prepare v[major].[minor]`.

---

## 2. Create Release Candidate

- **Path**: `scripts/ReleaseScripts/CreateRelease`
- **Command**: `./run.sh`
- **Result**: Opens an MR in GitLab called `Release [major].[minor]` against master.
- **Trigger CI**: Comment on the created MR:
  ```
  deliver_appStore --announce-release true --first-announcement true
  ```

---

## 3. Hotfix Workflow

- **Path**: `scripts/ReleaseScripts/PrepareHotfix`
- **Command**: `./run.sh` (run from latest `develop` branch)
- **Result**: Creates a `Hotfix [major].[minor].[patch]` MR.
- **Trigger CI**: Comment on the MR:
  ```
  deliver_appStore --announce-release true --hotfix-build true
  ```

---

## 4. Finalize & Merge Release

| Action | GitLab MR Comment |
|---|---|
| Sync master | `create_tag_and_sync_from_master` |
| Merge release | `merge_release` |

`merge_release` merges branches, creates tags, pushes to GitHub, and updates Jira.
