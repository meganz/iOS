# MEGAMarkdown demo app

A small iOS app for testing the `MEGAMarkdown` and `MEGAMarkdownEditor` packages by hand.
It is not part of the MEGA app target or CI.

## What it does

- The first screen has one entry for each Preview feature:
  - Imported files: Markdown files that other apps shared with the demo. Swipe to delete.
  - Open at a line: opens an imported file with `restoreLine`. The field starts with the line the file showed last time, or 0. 0 means no scroll.
  - Switch text in one preview: one `MarkdownPreview` shows text Alpha or Bravo. The Bravo button sets a new text and line 10000 together.
  - Images and Large files: shortcuts into the synced test folders.
  - All test files: the synced `TestFiles` folder, with the Sync button. Folders first, then files with their size.
- Every file reopens at the line it showed last time. `SavedLines` keeps the line in `UserDefaults`.
- Another app can share a `.md` or `.markdown` file with the demo, for example the Files app or MEGA.
  The demo copies it to `Documents/Imported` and opens it. Other file types show an error.
- A file opens in `MarkdownPreview` with `baseURL` set to the file's folder.
- Files over `MarkdownPreview.sizeLimitInBytes` are not read. The screen shows the "too large" text.
- The options menu picks the mode, the image loading and the soft break:
  - Images: local files next to the Markdown file, remote images, or alt text only (the package default).
  - Soft break: a line break (like Android) or a space (CommonMark).
  - Each file opens with the options its test case needs. Files under `images/remote/` load remote images.
    Other files load local files. The `commonmark-spec` and `gfm-spec` examples use the CommonMark soft break.
- The GitHub button pushes the same file on GitHub in an in-app browser. The preview stays below it in the stack.
  The Settings sheet holds the base URL, for example `https://github.com/owner/repo/blob/main`.
  The app adds the path below `TestFiles`. An empty URL hides the button.
- The Source button in the navigation bar switches between the preview and the raw text (read-only).
- The Edit button opens the file in `MarkdownEditor`, in rich mode. The mode picker in the options menu switches to the source editor.
  The editor writes the text back to the file, so the preview shows the edit. Sync replaces an edited test file again.

## Test files

The app downloads the test files from the public repo
[mega-bl/markdown-test-files](https://github.com/mega-bl/markdown-test-files), branch `main`.
A change in the repo needs no new build: tap Sync on the first screen.

- Sync reads the file list with one GitHub API call. It needs no token while the repo is public.
  GitHub allows 60 such calls per hour from one network without a token.
- It downloads only the files whose Git hash changed, into `Documents/TestFiles`.
  It removes the files that left the repo. `Documents/TestFiles-manifest.json` keeps the hashes.
- `large-files/too-large-101mib-over-limit.md` is over 100 MB, and GitHub rejects files of that size.
  The app writes this file itself after a sync, when it is missing.
- `editing/selection` and `preview/selection` list steps for text and block selection. This app has no selection, so it shows them in the preview only.

`scripts/make_test_files.py` writes the repo content. Each file name says what the case is.
The script uses the package fixtures under `Tests/MEGAMarkdownTests/Fixtures`.
`commonmark-spec` and `gfm-spec` hold one file per spec example. The number is the example number.

```sh
python3 scripts/make_test_files.py TestFiles      # TestFiles/ is ignored by git
rsync -a --delete --exclude='.*' TestFiles/ <repo checkout>/
```

The script deletes its output folder first, so never point it at the checkout.
`--exclude='.*'` keeps the checkout's `.git` and other dot files. Then commit and push the checkout.

## Run

From this folder:

```sh
bash scripts/run-demo.sh <simulator-udid>
bash scripts/run-demo.sh --device <device-udid>
```

- The script builds, installs and launches the app.
- A device build needs a signing team. Set it in Xcode under Signing & Capabilities.
- The app builds from the worktree only after `Modules/MEGASharedRepo` is checked out (`MEGAFoundation` needs it).

## Capture

`scripts/capture.sh` opens every test file in the app on a simulator and saves screenshots.

```sh
bash scripts/capture.sh <simulator-udid>              # all files
bash scripts/capture.sh <simulator-udid> images/      # one folder
```

- The app runs in capture mode (launch argument `-capture`). It opens each file like a person would,
  waits until the list stops growing, and saves up to 4 screens per file.
- Remote images get 5 s to download before the first screen.
- The output goes to `derivedData/markdown-captures/<prefix>/` (`all` for every file): the PNGs, `index.json`,
  and contact sheets in `sheets/`.

## Project

`MEGAMarkdownDemo.xcodeproj` uses a synchronized folder for `MEGAMarkdownDemo/`.
A new Swift file in that folder joins the app target without a project edit.
