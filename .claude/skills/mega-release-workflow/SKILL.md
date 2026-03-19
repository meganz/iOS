---
name: mega-release-workflow
description: MEGA iOS release workflow commands and scripts. Use when the user asks about code freeze, release preparation, Monday release checklist, creating a release branch, release candidates, hotfixes, or finalizing and merging a release.
disable-model-invocation: true
---

# MEGA iOS Release Workflow

## Phase 0: Monday — Prepare Code Freeze (Manual Checklist)

Walk the user through each item below. These are all manual tasks — do not automate them. Present them as a checklist and confirm completion before moving to Phase 1.

### 1. Create Release Management Ticket
- Create a Jira ticket for the current release
- Link it to the **iOS Release Management Epic** to log work time

### 2. Prepare Release Notes (Change Logs)

**If this is a hotfix** (e.g. `v16.20` → `v16.20.1`):
- Use the default changelog: `Bug fixes and performance improvements.`
- No further action needed for release notes

**If this is a minor release** (e.g. `v16.20` → `v16.21`):
1. Post the following message in the **#mobile_platform** Slack channel:

   > Hi team(@iosdevs-urgent), we are preparing release notes for upcoming release **\<vXX.YY\>** on **\<XX XX 202X\>**, if you have highlight features to announce to our end user in your responsible area, please reply in this thread before tomorrow. Thank you.

   Fill in `<vXX.YY>` with the version number and `<XX XX 202X>` with the release date.

2. Check all tickets included in this release — if you spot a user-facing highlight, confirm the wording with the developer responsible

### 3. Check Weblate Setup
- Confirm you have a Weblate account and your `translate.json` is configured
- Re-read the **Setup** section of the iOS L10n (localisation) Process if in doubt
- If `translate.json` is missing or misconfigured, download the sample config from: https://mega.nz/fm/iyhV0ARY
- See the `/weblate` skill for full setup details

### 4. Create JIRA Package Search List
- Create a package search list in Jira for this release version (e.g. `iOS 8.25`)
- Include tickets across all relevant Jira projects: **IOS, AP, BAC, CC, CU, MEET, TRAN, SAO**, etc.

### 5. Add JIRA Package Link to iOS Release Plan
- Open the **iOS Release plan - 2026** document
- Add the JIRA package link for this release to the correct row

### 6. Start Release Process for iOS Shared Repo
- Follow the `/mega-shared-repo-release` skill for the full Shared Repo Monday checklist

---

## Phase 0.5: Tuesday — SDK & MEGAChat Releases (Manual Checklist)

> **Before starting:** Ask the user to confirm all Monday tasks (Phase 0) are complete before proceeding.

### 1. Notify SDK Team in #sdk Channel
- Go to the **#sdk** Slack channel and find the latest message that says:
  > *"A new Release Train is coming — Release Captains of the apps who are planning to consume the new release of the SDK, please, can you post the target version of the app in the thread? Thanks in advance."*
- Reply in **that same thread**:
  > Hi team, iOS **\<X.Y\>** release will be our next release. Would you please prepare the new SDK and MEGAChat releases? Thanks!

### 2. Create Release Notes and Upload to Weblate
**Skip this step if using the default release notes.**

- Write the changelog string in the following format:
  ```
  /* */
  "Changelog version X.Y" = "<release note text>";
  ```
- Upload to Weblate using the `/weblate` skill (Use Case 4 — upload changelog source strings)

### 3. Notify Content Team
- Once the changelog string has landed in Weblate, post in the **#ios** channel:
  - Mention **@Jeraiza Molina** (@content) to prepare the translation

---

## Phase 1: Wednesday — Create the Release Candidate Build

> **Before starting:** Confirm with the user that ALL of the following are done:
> - Monday tasks (Phase 0) ✅
> - Tuesday SDK & MEGAChat tasks (Phase 0.5) — SDK and ChatSDK releases must be out (you need their commit hashes) ✅
> - Shared Repo Tuesday tasks (`/mega-shared-repo-release`) ✅

### Step 1 — Check Ticket Statuses
- All tickets in this release must be in one of: `QA`, `QA Awaiting Dev Fix`, `Resolved`, or `Closed`
- Use the Jira filter to find tickets with incorrect status (remember to check `fixVersion`)
- Contact the relevant engineers and QAs to fix status or move tickets to the next release

### Step 2 — Notify HelpDesk in #release Channel
Post in the **#release** Slack channel:
```
Hi @hdleads, in iOS vX.Y, we will have these highlighted changes.
• <CONTENTS OF THE RELEASE NOTES>
```

### Step 3 — Check Next Version Type
- Check the latest **Release Train** announcement on **#mobile-platform**
- Determine if the next version will be a **minor release** (e.g. `9.3`) or **major release** (e.g. `10.0`)

### Step 4 — Run PrepareRelease Script

> ⚠️ **Close Xcode before running any scripts.** Leaving it open can interfere with `git` and `SPM`.

Make sure you are on the latest `develop` branch. Run from the project root:

```bash
cd Modules/MEGASharedRepo/scripts/PrepareRelease && \
swift run PrepareRelease \
  --version-number <<version-number>> \
  --sdk-commit-hash <<SDK-Commit-Hash-Here>> \
  --chat-sdk-commit-hash <<Chat-SDK-Commit-Hash-Here>> \
  --shared-repo-commit-hash <<Shared-Repo-Commit-Hash-Here>>
```

- Opens an MR in GitLab against `develop` called `Prepare v[major].[minor]`
- This script exports strings from Weblate — if any keys disappear from `Base` or `en` `.stringsdict` files, **revert those deletions** or the build will fail

### Step 5 — Run CreateRelease Script (after Prepare MR is merged)

Once the `Prepare v[major].[minor]` MR has been reviewed, pipeline passed, and merged, switch to the latest `develop` branch and run:

```bash
cd scripts/ReleaseScripts/CreateRelease && ./run.sh
```

- Opens an MR in GitLab against `master` called `Release [major].[minor]`

### Step 6 — Trigger TestFlight Deployment
Comment on the newly created `Release [major].[minor]` MR:
```
deliver_appStore --announce-release true --first-announcement true
```
This triggers:
- Deployment to TestFlight for the QA team
- Creation of the next iOS release version
- Code freeze and release candidate notifications on Slack

---

## Phase 2: QA Testing Cycle (Ongoing — Days to 1–2 Weeks)

> **Before starting:** Confirm ALL of the following with the user:
> - [ ] PrepareRelease MR merged into `develop`
> - [ ] CreateRelease MR opened (`Release X.Y` → `master`)
> - [ ] TestFlight first RC build triggered (`deliver_appStore --announce-release true --first-announcement true` commented on the Release MR)
> - [ ] Build is visible to QA team in TestFlight

After the first TestFlight build is live, QA begins regression testing. The release captain monitors progress and keeps iterating until QA signs off.

### QA Monitoring (daily)

- Monitor test progress in **TestRail** and notify the relevant engineers and managers about failed test cases
- Set a daily Slack reminder to check QA status:
  ```
  /remind me to check QA test status everyday at 9.00am
  ```
- Observe crashes reported in **Crashlytics** and **TestFlight**
- When an engineer marks a failed test case as `fixed`, the release captain must update those cases to **`Retest`** before asking QA to retest the new build

### Generating a New Release Candidate Build

Repeat this whenever QA finishes a round and all failed cases have been fixed.

**1. Update SDK (only if a new SDK release is available)**
```bash
git -C Modules/DataSource/MEGASDK/ fetch && \
git -C ./Modules/DataSource/MEGASDK/Sources/MEGASDK checkout <<SDK-Commit-hash-here>>
```

**2. Update MEGAChatSDK (only if a new MEGAChatSDK release is available)**
```bash
git -C Modules/DataSource/MEGAChatSDK/ fetch && \
git -C ./Modules/DataSource/MEGAChatSDK/Sources/MEGAChatSDK checkout <<Chat-SDK-Commit-hash-here>>
```

**3. Commit and push** SDK/MEGAChatSDK changes to the release branch — only if at least one of the above two steps was executed.

**4. Shared Repo fixes** — If there are any fixes in the shared repo, follow the `/mega-shared-repo-release` checklist to create a new tag. Then ensure the release branch points to the new tag by pushing a commit that references it.

**5. Trigger new TestFlight build** — Comment on the code freeze MR:
```
deliver_appStore --announce-release true
```

**6. Add to external TestFlight group** — Ask **@Harry Yan** or **@Javier Navarro** to add the new build with the official release notes to the external TestFlight group for beta testers.

> ⚠️ **Warning:** Before scheduling the next TF build, make sure the previous build has already been reviewed in App Store Connect (if it has a new version number). The CI job will fail at the upload stage if the previous build is not yet reviewed.

**Repeat** Steps 1–6 until a build has no failed test cases and QA signs off.

---

## Phase 3: App Store Submission (After QA Sign-Off)

> **Before starting:** Confirm ALL of the following with the user:
> - [ ] QA has officially signed off — zero failed test cases remain
> - [ ] All blocker bugs fixed and merged into the release branch
> - [ ] Build number confirmed in App Store Connect matches the QA-approved TestFlight build
> - [ ] Changelogs reviewed and correct
> - [ ] Updated app description looks correct in all languages

### ⚠️ Mission-Critical Pre-Check
Before doing anything else:
- Confirm the **build number** in App Store Connect matches the exact TestFlight build QA signed off on
- Thoroughly check the **changelogs** — verify all fixed test cases and expected changes are included
- Confirm the **updated app description** looks correct in all languages
- If in doubt, ask a former release captain for a second opinion

### Step 1 — Notify #devops-cicd to Submit to App Store

Post in the **#devops-cicd** Slack channel:

```
Hi team and @eu-mobile-release & @nz-mobile-release, the QA team has approved our latest MEGA iOS Release Candidate Build v<X.Y> in TestFlight and the build is now ready to be submitted to the App Store.

Job: https://controller.cibuild.mega.co.nz/job/iOS/job/iOS-Submit-App-Store/
MR Number: { Release MR Number e.g. 7556 }
Version Number: { iOS Version Number e.g. 16.2 }
Build Number: { iOS Build Number e.g. 2406101618 }

Please help to run the release script that we have configured, and reply to this thread if there's any failure or errors along the way. Thank you!
```

> **Note on @nz-mobile-release:** Only tag them if sending between **7am–7pm NZST**.

> **For hotfix only:** Add this extra line: `7-day phased: false`

### Step 2 — Upload Demo Videos to App Review
- Upload demo videos to **App Store Connect → App Review Information → Attachment**
- Reason: MEGA ads are available in specific countries only; the IDFA message won't be visible to Apple reviewers in other regions — demo videos let them see the flow
- If you cannot upload the demo videos, contact **@Harry Yan** for help

### Step 3 — Verify Localized Metadata
- Confirm release notes are applied to **all localized languages** in App Store Connect
- Confirm the updated app description is applied to all languages
- Confirm the correct build is selected for review submission

---

## Phase 4: Merge the Release Branch

> **Before starting:** Confirm ALL of the following with the user:
> - [ ] App Store submission sent (notified #devops-cicd)
> - [ ] Demo videos uploaded to App Store Connect
> - [ ] Localized metadata verified in all languages
> - [ ] Correct build selected for review submission

### Step 1 — Tag and Sync from Master
Comment on the release MR:
```
create_tag_and_sync_from_master
```
This creates a tag for the new release and syncs from master using the `-s ours` strategy to resolve any conflicts.

> ⚠️ **Do NOT merge the MR manually on GitLab.** The `MergeRelease` script handles the merge. Just make sure the MR is approved.

### Step 2 — Merge the Release
Once the release MR is **approved**, all **MR discussions are resolved**, and **CI has passed**, comment:
```
merge_release
```
This command will:
- Merge the release MR on GitLab
- Create a release on GitLab
- Push current `master` to GitHub
- Create a release on GitHub
- Mark the current version as released in all Jira projects

### Step 3 — Notify SDK Team
Reply to the corresponding release thread in **#sdk** and **#megachat_native** (reply in thread, not a new message):
```
Hi team, the iOS RC build <X.Y> is signed off by QA and is now being released. You can also merge your release branches when you are ready. Thanks!
```

### Step 4 — Notify iOS Shared Repo Team
Reply to the corresponding release thread in **#mobile_shared_module** (reply in thread, not a new message):
```
Hi team, the MEGA Cloud iOS RC build <major>.<minor> is signed off by QA and is now being released. You can create your final release tag when you are ready. Thanks!
```

### Step 5 — End iOS Shared Repo Release Process
- Remember to end the iOS Shared Repo release process once **all dependent apps** (MEGA Cloud, VPN, Pass) have completed their releases
- See `/mega-shared-repo-release` for the Shared Repo release steps

---

## Phase 5: Release to App Store (After Apple Approval)

> **Before starting:** Confirm ALL of the following with the user:
> - [ ] Apple has approved the build
> - [ ] Release MR merged (`merge_release` completed successfully)
> - [ ] SDK and MEGAChatSDK teams notified (Phase 4 Step 3)
> - [ ] iOS Shared Repo team notified (Phase 4 Step 4)

### Step 1 — Set Up Crash Monitoring Reminders
Run both commands in Slack (replace `X.Y` with the actual release version):
```
/remind #mobile-dev-team to check new & velocity crashes in the new iOS X.Y release in 4 hours
/remind #mobile-dev-team to check new & velocity crashes in the new iOS X.Y release in 8 hours
```

### Step 2 — Notify #ios and #apps_release_updates
Reply to the corresponding release thread (reply in thread, not a new message):

**Normal release:**
```
Hi team, iOS <X.Y> (<build-number>) is approved by Apple and is on a 7 days phased release now.
```

**Hotfix:**
```
Hi team, iOS <X.Y.Z> (<build-number>) is approved by Apple and is released to all users now.
```

### Step 3 — Update iOS Release Plan
- Open the **iOS Release plan - 2026** document
- Fill in the actual release date for this version

### Step 4 — Publish Remote Feature Flags
- If you have a remote feature flag for this release, request a release percentage (e.g. **10%**) before publishing
- Publish the flag
- Update the **Remote Feature Flags Tracking** page

---

## Phase 6: Hotfix (If Needed After Release)

If a critical crash or bug is found in production after the release, use the dedicated hotfix skill:

> Use `/mega-hotfix` for the full hotfix workflow — stopping phased release, running the PrepareHotfix script, fixing issues, triggering the build, and releasing.
