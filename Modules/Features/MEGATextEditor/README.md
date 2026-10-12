# MEGATextEditor

MEGATextEditor shows the content of a Markdown file. It decides where a Markdown file opens.
It shows the Markdown preview or the Markdown editor.
The host screen owns the navigation bar, the toolbars, the file download and the upload.

## Public types

| Type | What it does |
|---|---|
| `MarkdownTextEditorRoute` | Decides where a file opens from its name, its size and a flag. The result is `otherFile`, `markdownFile` or `tooLarge`. |
| `MarkdownTextEditorSizeCheck` | Compares a size in bytes with `MarkdownPreview.sizeLimitInBytes`. |
| `MarkdownTextEditorText` | Decodes file bytes as UTF-8. It returns nil for other bytes. |
| `MarkdownTextEditorContentState` | An `@Observable` object with the screen, the text, the loading progress and the editor mode. |
| `MarkdownTextEditorContentView` | Shows a loading view, `MarkdownPreview` or `MarkdownEditor` for the state. |
| `MarkdownTextEditorMode` | The modes in the mode menu: plain text and rich text. |
| `MarkdownTextEditorBottomBarItem` | The bottom bar actions for an access level. |
| `MarkdownEditorStrings.mega`, `MarkdownPreviewStrings.mega` | The strings of the two Markdown views, taken from MEGAL10n. |

## What it does not hold

- Navigation and toolbars.
- SDK access, file reads, download and upload.
- The New text file dialog. It lives in the CloudDrive package.

## How a host uses it

1. Ask `MarkdownTextEditorRoute` before the file is read or downloaded. A `tooLarge` result means the host shows a message and reads nothing.
2. Decode the bytes with `MarkdownTextEditorText.decode`. Bytes that are not valid UTF-8 use another viewer.
3. Own a `MarkdownTextEditorContentState` and show `MarkdownTextEditorContentView` in a hosting controller.
4. Set `fileName` for the loading icon. Write `screen` and `text` when the host screen changes.
5. Call `flushEditor()` before a save, then read `text`.

## Dependencies

MEGAMarkdown, MEGADomain, MEGAL10n, MEGAAssets, MEGASwift and MEGADesignToken.

## Tests

```sh
cd Modules/Features/MEGATextEditor
xcodebuild test -scheme MEGATextEditor \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -skipPackagePluginValidation -skipMacroValidation SWIFT_SUPPRESS_WARNINGS=NO
```

The image snapshot tests in `MEGATextEditorSnapshotTests` skip in this run.
They run only from the snapshot script, on a pinned simulator:

```sh
scripts/snapshot.sh Modules/Features/MEGATextEditor
```
