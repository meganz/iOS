---
name: mega-fastlane-metadata
description: MEGA iOS Fastlane and App Store metadata reference. Use when the user asks about Fastlane lanes, App Store screenshots, signing certificates, device registration, delivering to TestFlight or App Store, Jenkins CI trigger phrases, App Store Connect upload commands, or fastlane match.
user-invocable: false
allowed-tools: Bash
---

# MEGA iOS Fastlane & App Store Metadata

All `bundle exec fastlane` commands run from the project root directory.

---

## Jenkins CI Trigger Phrases

Post these as comments on the relevant GitLab MR to trigger Jenkins jobs.

| Phrase | Effect |
|---|---|
| `deliver_appStore` | Release (AppStore) build → TestFlight |
| `deliver_appStore --announce-release true --first-announcement true` | RC build + code freeze & RC notifications on Slack + creates next Jira version |
| `deliver_appStore --announce-release true` | RC build (subsequent rounds) |
| `deliver_appStore --announce-release true --hotfix-build true` | Hotfix build + notifications |
| `deliver_appStore_with_whats_new` | Release build with What's New metadata update |
| `deliver_qa` | QA (AdHoc) build → Firebase |
| `deliver_qa_include_new_devices` | QA build + re-generates provisioning profiles for newly registered devices |
| `verify_translations` | Runs `check_translations.py` — fails if any l10n keys are missing |
| `create_tag_and_sync_from_master` | Creates release tag, syncs from master using `-s ours` |
| `merge_release` | Merges release MR, creates GitLab/GitHub release, updates Jira |
| `jira_create_version` | Creates a new Fix Version in all Jira projects |
| `upload_whats_new_to_appstoreconnect` | Uploads release notes metadata only to App Store Connect |

---

## Fastlane Lanes Reference

### Build & Archive

| Lane | Purpose |
|---|---|
| `archive_appstore` | Builds Release `.ipa` using gym with App Store provisioning profiles (all 7 extensions). Writes `archive_path.txt`. |
| `archive_adhoc` | Builds QA `.ipa` with Ad Hoc profiles for Firebase distribution. |
| `build_simulator` | Debug build for iOS Simulator — CI validation only, no IPA. |

### Versioning

| Lane | Purpose |
|---|---|
| `set_time_as_build_number` | Generates build number as `YYMMDDHHMI` timestamp, sets in Xcode project, writes `build_number.txt`. |
| `fetch_version_number` | Reads MEGA target's marketing version, writes `version_number.txt`. |
| `fetch_latest_build_number` | Queries TestFlight for the latest build number for a given version. |

### Upload & Distribution

| Lane | Purpose |
|---|---|
| `upload_to_itunesconnect` | Generates changelog from last 20 git commits, uploads `.ipa` to TestFlight via App Store Connect API. Group: `["MEGA"]`. |
| `upload_symbols` / `upload_symbols_with_dsym_path` | Uploads dSYM files to Firebase Crashlytics for all 6 targets. |
| `upload_build_to_firebase` | Distributes QA `.ipa` to Firebase App Distribution `internal-testers` group. |
| `download_device_ids_from_firebase` | Pulls registered device UDIDs from Firebase. |
| `upload_device_ids_to_developer_portal` | Registers UDIDs with Apple's developer portal. |

### Metadata (App Store Connect)

| Lane | Purpose |
|---|---|
| `download_metadata` | Pulls current App Store metadata into `fastlane/metadata/`. |
| `upload_metadata_to_appstore_connect` | Pushes local metadata files to App Store Connect — skips screenshots and binary. |

### Testing

| Lane | Purpose |
|---|---|
| `run_tests_app` | Unit tests for main MEGA scheme. Parallel (2 workers), 20 retries, coverage enabled. |
| `run_tests_against_local_packages` | Swift Package unit tests using `MEGAModulesTests` scheme. |

### Developer Setup

| Lane | Purpose |
|---|---|
| `setup` | One-command local setup: installs dev certs (internal repo only), updates submodules, downloads 3rd-party libs, hooks pre-commit script. |

---

## Screenshots: Update Workflow

### Step 1 — Download Current Screenshots
```bash
bundle exec fastlane deliver download_screenshots
```
Downloads into `fastlane/screenshots/` organized by language folder (e.g. `ar-SA/`, `en-US/`).

### Step 2 — Swap Screenshots
- Replace images in the appropriate language folder
- iPad Pro 12.9" files must include `ipadPro129` in the filename (e.g. `ipadPro129_1.png`) so Fastlane assigns the correct display family
- Replace screenshots as directed by the Design team

### Step 3 — Upload New Screenshots
```bash
bundle exec fastlane deliver app_version:"<X.Y>" force:true skip_binary_upload:true overwrite_screenshots:true skip_metadata:true
```

| Parameter | Value | Notes |
|---|---|---|
| `app_version` | e.g. `13.0` | The upcoming version you intend to submit |
| `force` | `true` | Skips HTML preview verification |
| `skip_binary_upload` | `true` | Does not upload an ipa |
| `overwrite_screenshots` | `true` | Clears previously uploaded screenshots before uploading new ones |
| `skip_metadata` | `true` | Does not update title/description — screenshots only |

> **Note:** `overwrite_screenshots` only works correctly if the new filenames match the downloaded ones. If filenames differ, either rename the new files or remove screenshots from the version in App Store Connect first.

---

## Signing Certificates

MEGA uses **fastlane match** to manage all signing. Certs are stored encrypted in the internal `iOSCertificates` GitLab repo.

**Rules:**
- Never use "Automatically manage signing" in Xcode — it modifies the project file
- Never manually push changes to `iOSCertificates` — always use fastlane commands

### Sync Certs to Local (Read-Only)

```bash
# Development (needed when debugging on a device)
bundle exec fastlane cert_dev readonly:true

# QA / AdHoc (rarely needed locally)
bundle exec fastlane cert_qa readonly:true

# App Store (rarely needed locally)
bundle exec fastlane cert_appstore readonly:true
```

### Register a New Test Device

**Preferred: via CI**
1. Invite the user to the `internal-testers` group on Crashlytics (not "all testers")
2. Ask the user to follow the invitation email on the new device to register it
3. Crashlytics collects the UDID and sends it via email
4. Trigger a build on an **empty MR** with the comment:
   ```
   deliver_qa_include_new_devices
   ```
   MR title: `*DO NOT MERGE* To add test device`
5. Sync dev certs to local for debugging (check match passcode with your lead):
   ```bash
   bundle exec fastlane cert_dev readonly:true
   ```

**Manual (appops only — use only if CI fails):**
```bash
bundle exec fastlane run register_device udid:"1234…890" name:"Mike's test iPhone"
bundle exec fastlane cert_dev readonly:false
bundle exec fastlane cert_qa readonly:false
```
Check with your lead for access to the `appops` user.

### Update All Signing Certificates (appops only)

Must be run using `appops@mega.co.nz` account.

```bash
# Step 1: Nuke (revokes all certs and profiles)
fastlane match nuke <type>   # type: development | adhoc | appstore

# Step 2: Regenerate
bundle exec fastlane all_certs

# Step 3: Set a reminder
# Post in #mobile-dev-team 2 weeks before the next expiration date
```

### Update Some Certificates (appops only)

1. Revoke the expired/expiring certs on App Store Connect
2. Delete them from the `iOSCertificates` repo at https://code.developers.mega.co.nz/mobile/ios/iOSCertificates
3. Regenerate:
   ```bash
   bundle exec fastlane all_certs readonly:false
   ```
   (Run as `appops@mega.co.nz`)
4. Sync certs to local (see Sync Certs section above)

---

## Configuration Files

| File | Purpose |
|---|---|
| `fastlane/Fastfile` | Main lanes. Imports 5 sub-Fastfiles. All lanes under `platform :ios`. |
| `fastlane/Matchfile` | Cert/profile sync config. Points to `iOSCertificates.git`. `force_for_new_devices(true)`. |
| `fastlane/Deliverfile` | App Store metadata defaults: `app_identifier("mega.ios")`, `force(true)`, skips precheck and IAP. |
| `fastlane/Pluginfile` | `fastlane-plugin-firebase_app_distribution` (QA builds), `fastlane-plugin-appcenter` (legacy). |
| `fastlane/.env.default` | Environment defaults loaded automatically by Fastlane. |

### Bundle ID Mapping

| Profile type | Bundle IDs |
|---|---|
| `development` | `mega.ios.dev.*` |
| `adhoc` | `mega.ios.qa.*` |
| `appstore` | `mega.ios.*` |

---

## App Store Submission (Jenkins Job)

The App Store submission job (`iOS-Submit-App-Store`) is run by the **DevOps / Secure Systems team** — not directly by the release captain.

The release captain provides the job parameters via the #devops-cicd Slack message (see `/mega-release-workflow` Phase 3):
- **Job URL:** https://controller.cibuild.mega.co.nz/job/iOS/job/iOS-Submit-App-Store/
- **Parameters:** MR Number, Version Number, Build Number
- **Hotfix only:** `7-day phased: false`
