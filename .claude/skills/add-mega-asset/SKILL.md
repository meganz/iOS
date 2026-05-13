---
name: add-mega-asset
description: Batch-add one or many SVG icons to MEGAAssetsBundle xcassets from an input folder whose subfolders encode the xcassets group path. Creates an imageset per icon, defines Swift constants in MEGAAssetsBundle (SwiftUI Image + UIKit UIImage) and the MEGAAssets wrapper, then rebuilds the xcframework once. Use when the user says "add icon to MEGAAssets", "add new icon(s)", "add asset to MEGAAssetsBundle", "batch add SVG icons", "add icons from folder", or "add image constant".
user-invocable: true
allowed-tools: Bash, Read, Write, Edit
argument-hint: "[assetsFolderPath]"
---

# Add New SVG Icons to MEGAAssetsBundle (batch)

Automates the full workflow of adding one or many SVG icon assets in a single run: xcassets imageset creation per icon, Swift constant definitions in the bundle and MEGAAssets wrapper, and a single xcframework rebuild at the end.

## Key Paths

| Role | Path |
|---|---|
| xcassets root | `MEGAFrameworks/MEGAAssetsBundle/MEGAAssetsBundle/Resources/Images.xcassets/` |
| SwiftUI bundle constants | `MEGAFrameworks/MEGAAssetsBundle/MEGAAssetsBundle/Image.swift` |
| UIKit bundle constants | `MEGAFrameworks/MEGAAssetsBundle/MEGAAssetsBundle/UIImage.swift` |
| MEGAAssets wrapper | `Modules/Presentation/MEGAAssets/Sources/MEGAAssets/MEGAAssetsImageProvider.swift` |
| xcframework build script | `Modules/Presentation/MEGAAssets/build_xcframework.sh` |

---

## Step 1 — Collect Inputs

The skill takes **one** input: a path to a folder containing the SVG icons to add. Ask the user for it in one message if not already provided as an argument.

### Required folder layout

The input folder's structure encodes both the **xcassets group** and the **icon name**:

```
<assetsFolderPath>/
├── <groupName>/                  ← xcassets group (one level)
│   ├── <iconFileName>.svg        ← iconName derived from filename
│   └── …
├── <groupName>/<subGroup>/       ← nested groups supported, joined with "/"
│   └── <iconFileName>.svg
└── …
```

Rules — state these to the user if input is missing or invalid:

- Every `.svg` MUST live inside at least one subfolder. Subfolder path (relative to the input folder) becomes the xcassets group path. Nested subfolders are supported and joined with `/` (e.g. `NavigationRevamp/Tabbar`).
- Each SVG's filename (without `.svg`) is the source of the **iconName**. Names are auto-converted to camelCase, so `search-bar.svg`, `Search Bar.svg`, and `searchBar.svg` all yield `searchBar`. Prefer naming files in camelCase already to avoid surprises.
- Icons are always template-rendered, no dark-mode variant. Tinting is handled at the call site via `.foregroundStyle` / `.tintColor`.
- Do NOT accept pasted SVG content. If the user pastes SVG, ask them to save it into the layout above and provide the folder path.

### Pre-flight (before any writes)

1. Recursively list all `.svg` files under `<assetsFolderPath>`.
2. Reject any SVGs sitting directly at the top level (no group). Print their paths and abort.
3. Skip non-`.svg` files inside subfolders with a one-line warning per file.
4. For each remaining SVG, derive `(groupPath, iconName, sourceSvg)`:
   - `groupPath` = parent directory relative to the input folder.
   - `iconName` = camelCase of the filename stem (see **camelCase conversion** below).
5. Print a confirmation table of `(groupPath, iconName, sourceSvg)` and ask the user to confirm before writing anything.

### camelCase conversion

```
stem    = filename without ".svg"
tokens  = split stem on /[-_\s]+/ AND on lower→Upper case boundaries; drop empties
first   = tokens[0].lowercased()
rest    = tokens[1..].map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
iconName = first + rest.joined()
```

After conversion, `iconName` must match `^[a-z][a-zA-Z0-9]*$`. If not, abort with the offending filename.

---

## Step 2 — Create the Imagesets (loop)

For each derived `(groupPath, iconName, sourceSvg)`:

**Target directory**: `MEGAFrameworks/MEGAAssetsBundle/MEGAAssetsBundle/Resources/Images.xcassets/<groupPath>/<iconName>.imageset/`

### 2a. For each new level in `<groupPath>`, write a `Contents.json`

If any intermediate folder under `Images.xcassets/` is being created for the first time, write this into that folder:

```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

### 2b. Copy the SVG into the imageset folder

```bash
cp <sourceSvg> MEGAFrameworks/MEGAAssetsBundle/MEGAAssetsBundle/Resources/Images.xcassets/<groupPath>/<iconName>.imageset/<iconName>.svg
```

### 2c. Write Contents.json into the imageset folder

```json
{
  "images" : [
    {
      "filename" : "<iconName>.svg",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "template-rendering-intent" : "template"
  }
}
```

---

## Step 3 — Add Swift Constants (batch)

Four insertion points, same as before. To minimize churn:

- Read each of the four files once.
- For each file, build a single multi-line block containing **all** new icons sorted by `iconName`.
- Apply with one Edit per file, appending before the closing `}` of the relevant struct. Match the indentation of surrounding entries exactly.

**Duplicate-name pre-check (critical):** before writing to any file, scan all four files for existing `static var <iconName>:` entries that collide with the batch. If any collision is found, abort the entire run and report the conflict — do not partially apply.

### 3a. `MEGAFrameworks/MEGAAssetsBundle/MEGAAssetsBundle/Image.swift`

Inside `public struct MEGAImageBundle { … }`, append per icon:
```swift
    public static var <iconName>: Image { Image(.<iconName>) }
```

### 3b. `MEGAFrameworks/MEGAAssetsBundle/MEGAAssetsBundle/UIImage.swift`

Inside `public struct MEGAUIImageBundle { … }`, append per icon:
```swift
    public static var <iconName>: UIImage { UIImage.<iconName> }
```

### 3c. `Modules/Presentation/MEGAAssets/Sources/MEGAAssets/MEGAAssetsImageProvider.swift` — SwiftUI Image block

In the `extension MEGAAssets { public struct Image { … } }` block (ends around line 326), append per icon:
```swift
        public static var <iconName>: SwiftUI.Image { MEGAImageBundle.<iconName> }
```

### 3d. Same file — UIKit UIImage block

In the `extension MEGAAssets { public struct UIImage { … } }` block (ends around line 795), append per icon:
```swift
        public static var <iconName>: UIKit.UIImage { MEGAUIImageBundle.<iconName> }
```

---

## Step 4 — Rebuild xcframework (once)

Run this **once**, after all imagesets and constants are written:

```bash
cd Modules/Presentation/MEGAAssets && sh build_xcframework.sh
```

This archives the framework for both iOS and iOS Simulator and outputs to `Modules/Presentation/MEGAAssets/Frameworks/MEGAAssetsBundle.xcframework`. Wait for it to complete. If it fails, surface the error output for the user to review.

---

## Step 5 — Summary

Report back, grouped by `groupPath`:

- Imagesets created (one bullet per icon): `Images.xcassets/<groupPath>/<iconName>.imageset/`
- Constants added per icon:
  - `MEGAAssets.Image.<iconName>` (SwiftUI)
  - `MEGAAssets.UIImage.<iconName>` (UIKit)
- xcframework build: success / error
