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

## Use Case 0: Add a New String (Interactive)

Use this when a developer wants to add a brand-new localisation string — from scratch — including writing it to the source files, rebuilding the framework, and committing.

### Step 1 — Collect inputs (single prompt)

Ask for all of the following in one message:

- **Key** — dot-notation key, e.g. `home.recent.menu.action.showRecentActivity`
- **Value** — the English string, e.g. `Show recent activity`
- **Comment** — translator context, e.g. `The title for menu action button that will show the recent activity`

**Key format check** — The input key should be in camelCase format. If the key violates camelCase format, ask user to input again.

### Step 2 — Run checks silently (no prompt unless an issue is found)

Run all checks immediately after receiving the inputs. Do NOT pause between them.

File to search: `Modules/Presentation/MEGAL10n/Framework/MEGAL10n/MEGAL10n/Resources/Base.lproj/Localizable.strings`

**Duplicate key check** — Grep for an exact match of the key (e.g. `"home.recent.menu.action.showRecentActivity"`).

**Duplicate value check** — Grep (case-insensitive) for the value.

**Grammar / style check** — review the value for:
- Spelling errors or typos
- Capitalisation (sentence case is the norm — check surrounding entries)
- Punctuation consistency (ellipses `…` vs `...`, trailing full stops)
- Trailing spaces

**Only pause if there is a real issue:**
- Duplicate key found → tell the user the key already exists and stop. They must choose a different key.
- Duplicate value found → show existing key(s), ask: *"This value already exists under `<key>`. Use the existing key or proceed with adding `<new-key>`?"*
- Grammar/style issue found → show the issue, ask the user to confirm or correct the value

If no issues are found, proceed directly to Step 3 without asking anything.

### Step 3 — Write the string to both source files

Append the new entry at the **end** of both files.

Format:
```
/* <comment> */
"<key>"="<value>";
```

Files to edit (both identically):
- `Modules/Presentation/MEGAL10n/Framework/MEGAL10n/MEGAL10n/Resources/Base.lproj/Localizable.strings`
- `Modules/Presentation/MEGAL10n/Framework/MEGAL10n/MEGAL10n/Resources/en.lproj/Localizable.strings`

After new entries are added, remove all empty lines in both files using:
```bash
sed -i '' '/^[[:space:]]*$/d' <file>
```

Prompt user with 3 options "Generate framework" and "Add another string", "Done" as numbered list. After listing the item, wait for user to select a number to proceed.
 - If user chooses "1" proceed to Step 4 
 - If user chooses "2" proceed to Step 1 
 - If user chooses "3" process to Step 6

### Step 4 — Regenerate MEGAL10n xcframework

Run from project root:
```bash
./scripts/generate-megal10n-xcframework.sh
```

If the output is `"No changes, skip building xcframework"`, the file edits were not detected — flag this to the user and stop.

### Step 5 — Commit

Extract the ticket number from the current branch name if it matches the pattern `<user>/<TICKET>-...` (e.g. `bl/IOS-11649-...` → `IOS-11649`). Otherwise ask the user for the ticket number.

```bash
git add Modules/Presentation/MEGAL10n/
git commit -m "<TICKET>: Add localisation string \"<key>\""
```

### Step 6 — Summary

Print a summary of what was done:
- Key added
- Value
- Comment
- Files modified
- Whether xcframework was rebuilt
- Commit hash

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

**Shared repo strings** — MEGASharedRepo has its **own** `iosTransifex/` directory with its own `translate.json` and `lang.sh`. You must `cd` into the MEGASharedRepo directory and run its local script, NOT the main repo's script:
```bash
cd Modules/MEGASharedRepo
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

**Main app translations** (run from project root):
```bash
./iosTransifex/weblate/lang.sh -a ios -p
```

This production (`-p`) download covers: `localizable`, `plurals`, `infoplist`, and `changelogs` components.
Translated files are written to the appropriate `<lang>.lproj/` folders beside `Base.lproj` and `en.lproj`.

**Shared repo translations** — must `cd` into MEGASharedRepo and use its own `iosTransifex/` script:
```bash
cd Modules/MEGASharedRepo
./iosTransifex/weblate/lang.sh -a ios -p -l ios-lib
```

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
| Add a new string interactively | say "add new string" |
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
