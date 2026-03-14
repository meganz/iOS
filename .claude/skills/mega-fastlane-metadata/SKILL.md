---
name: mega-fastlane-metadata
description: MEGA iOS Fastlane and App Store metadata reference. Use when the user asks about Fastlane lanes, App Store screenshots, delivering to TestFlight or App Store, Jenkins CI trigger phrases, or App Store Connect upload commands.
user-invocable: false
---

# MEGA iOS Fastlane & App Store Metadata

## Fastlane Deliver (App Store Connect)

| Action | Command |
|---|---|
| Download current screenshots | `bundle exec fastlane deliver download_screenshots` |
| Upload screenshots only | `bundle exec fastlane deliver app_version: "<version>" force: true skip_binary_upload: true overwrite_screenshots: true skip_metadata: true` |

**Deliverfile config**: `fastlane/Deliverfile` defaults to `app_identifier("mega.ios")`.

---

## Jenkins CI Trigger Phrases (via GitLab MR Comments)

| Phrase | Effect |
|---|---|
| `deliver_appStore` | Triggers Release build |
| `deliver_appStore_with_whats_new` | Triggers Release build (with What's New) |
| `deliver_qa` | Triggers QA (AdHoc) build |
| `verify_translations` | Runs `check_translations.py` to verify no missing keys |

---

## Fastlane Lanes Overview

| Lane | Description |
|---|---|
| `archive_appstore` | Builds Release ipa using gym, exports for App Store |
| `upload_to_itunesconnect` | Generates changelog and uploads ipa to TestFlight |
| `upload_symbols` | Uploads dSYM to Firebase Crashlytics |
