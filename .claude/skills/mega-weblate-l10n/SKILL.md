---
name: mega-weblate-l10n
description: MEGA iOS Weblate localization workflows. Use when the user mentions "weblate", "l10n", "localization", "upload strings", "upload plurals", "download translations", "sync strings", "changelog translation", or asks to run "lang.sh". Also use when the user says things like "push new strings to Weblate", "pull translations for release", or "upload changelogs to App Store".
allowed-tools: Bash
argument-hint: "[upload-strings | upload-plurals | download | changelogs]"
---

# MEGA iOS Weblate Localization

Script: `./iosTransifex/weblate/lang.sh`
Run all commands from the project root unless otherwise noted.
Prerequisite: `iosTransifex/weblate/translate.json` must exist with valid `SOURCE_TOKEN` (Weblate) and `GITLAB_TOKEN`.

---

## Ground Rules

- iOS team **only edits `Base.lproj` and `en.lproj`** when adding new strings. Never manually edit other language `.lproj` files — those are owned by translators and downloaded from Weblate.
- All other language translations are downloaded from Weblate during the release phase (after translators finish).
- The script auto-downloads after every upload (`-u`) — so after uploading, your local files will reflect the latest state.

---

## Use Case 1: Daily — Adding New Strings

Use this when a developer has added new string keys to the source files and needs to push them to Weblate so translators can start working.

### Step 1 — Edit source files (developer task, not this script)

| What | File location |
|---|---|
| App strings | `Modules/Presentation/MEGAL10n/Framework/MEGAL10n/MEGAL10n/Resources/Base.lproj/Localizable.strings` and `en.lproj/Localizable.strings` |
| App plurals | Same folder, `Base.lproj/Localizable.stringsdict` and `en.lproj/Localizable.stringsdict` |
| InfoPlist strings | `iMEGA/Languages/Base.lproj/InfoPlist.strings` and `en.lproj/InfoPlist.strings` |
| Shared repo strings | `MEGASharedRepoL10n/Sources/Resources/Base.lproj/Localizable.strings` and `en.lproj/Localizable.strings` |

### Step 2 — Upload to Weblate

**Main app strings:**
```bash
./iosTransifex/weblate/lang.sh -a ios -u
```

**Main app plurals (.stringsdict):**
```bash
./iosTransifex/weblate/lang.sh -a ios -u -c plurals
```

**InfoPlist strings:**
```bash
./iosTransifex/weblate/lang.sh -a ios -u -c infoplist
```

**Shared repo strings** (run from the MEGASharedRepo directory):
```bash
./iosTransifex/weblate/lang.sh -a ios -u -l ios-lib
```

### What the upload does
- Reads the local `Base.lproj` file
- Compares against the current `develop` branch on GitLab to find new/changed keys
- Uploads only the diff to the Weblate branch component (creates the branch component if it doesn't exist yet)
- Automatically downloads the current state back after uploading

---

## Use Case 2: Release — Download All Translated Strings

Use this during the release phase after translators have finished their work. Downloads all language translations for all components.

```bash
./iosTransifex/weblate/lang.sh -a ios -p
```

This production (`-p`) download covers: `localizable`, `plurals`, `infoplist`, and `changelogs` components.
Translated files are written to the appropriate `<lang>.lproj/` folders beside `Base.lproj` and `en.lproj`.

After downloading, review the diff before committing:
```bash
git diff --stat
```

---

## Use Case 3: Release — Changelogs to App Store Connect

This is a two-step process: download translated changelogs from Weblate, then run the Swift script to push them to App Store Connect metadata.

### Step 1 — Download translated changelogs from Weblate

```bash
./iosTransifex/weblate/lang.sh -a ios -c changelogs
```

Downloaded files land in `download/` (e.g. `download/Changelogs.strings-fr`, `download/Changelogs.strings-de`).

### Step 2 — Upload changelogs to App Store Connect via Swift script

Navigate to the AppMetadataUpdater script directory and run:

```bash
cd scripts/AppMetadataUpdater
swift run AppMetadataUpdater --update-release-notes --version <X.Y> "Token <YOUR_WEBLATE_TOKEN>"
```

Replace `<X.Y>` with the release version number (e.g. `8.25`) and `<YOUR_WEBLATE_TOKEN>` with your Weblate API token.

To also update the App Store description in the same run:
```bash
swift run AppMetadataUpdater --update-description --update-release-notes --version <X.Y> "Token <YOUR_WEBLATE_TOKEN>"
```

The script writes Fastlane metadata files which are picked up by `fastlane deliver` during App Store submission.

---

## Use Case 4: Adding New Changelog Source Strings (before translation)

When you write new changelog entries in English and need to push them to Weblate for translation:

```bash
./iosTransifex/weblate/lang.sh -a ios -u -c changelogs -pm
```

The `-pm` (`--pushmain`) flag uploads directly to the main Weblate component instead of a branch component. Use this for changelogs since they are release-level content, not feature-branch content.

---

## Quick Reference

| Intent | Command |
|---|---|
| Upload new strings | `./iosTransifex/weblate/lang.sh -a ios -u` |
| Upload new plurals | `./iosTransifex/weblate/lang.sh -a ios -u -c plurals` |
| Upload InfoPlist strings | `./iosTransifex/weblate/lang.sh -a ios -u -c infoplist` |
| Upload shared repo strings | `./iosTransifex/weblate/lang.sh -a ios -u -l ios-lib` (from MEGASharedRepo dir) |
| Upload changelog source strings | `./iosTransifex/weblate/lang.sh -a ios -u -c changelogs -pm` |
| Download all translations (release) | `./iosTransifex/weblate/lang.sh -a ios -p` |
| Download changelogs only | `./iosTransifex/weblate/lang.sh -a ios -c changelogs` |
| Push changelogs to App Store Connect | `cd scripts/AppMetadataUpdater && swift run AppMetadataUpdater --update-release-notes --version <X.Y> "Token <TOKEN>"` |

---

## Troubleshooting

**"download folder does not exist" or similar download folder error** — Create it before retrying:
```bash
mkdir -p iosTransifex/weblate/download
```
After the script finishes and you have processed the downloaded files, manually delete the contents:
```bash
rm iosTransifex/weblate/download/*
```
Do NOT delete the folder automatically — let the user decide when it is safe to clean up.

**"Warning: Trying sample config"** — `translate.json` is missing. Copy `translate.json.example` to `translate.json` and fill in your tokens.

**401 Unauthorized from GitLab** — `GITLAB_TOKEN` in `translate.json` is invalid or expired.

**"Error: Must specify a valid application parser"** — Missing `-a ios` argument.

**"Error: Invalid developer comment"** — Every new string key in `Base.lproj` must have a `/* comment */` line above it before uploading.

**"Error: Uploading branch resource without developer comments"** — Same as above. Add comments and retry.
