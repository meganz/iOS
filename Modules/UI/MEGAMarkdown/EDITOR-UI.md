# MEGAMarkdown editor UI reference

The views of the Markdown editor: rich mode, source mode, the toolbar and the save path. They live in the
`MEGAMarkdownEditor` target, in `Sources/MEGAMarkdownEditor/UI/`. The rich mode model they drive is in
[EDITOR.md](EDITOR.md). The row list and the row chrome they share with the preview are in [PREVIEW.md](PREVIEW.md).

## Public API

```swift
MarkdownEditor(markdown: $markdown, mode: $mode, baseURL: nil)
    .markdownEditorStrings(strings)
    .markdownTheme(theme)
    .markdownImageLoading(.altTextOnly)
```

| Name | What it is |
|---|---|
| `MarkdownEditor` | The editor view. `markdown` is the save channel: the editor writes the new text into it. |
| `MarkdownEditorMode` | `.rich` (no Markdown syntax on screen) or `.source` (plain text). |
| `MarkdownEditor.richModeCharacterLimit` | 500,000 UTF-16 units. A larger file opens rich mode as source, with a notice. |
| `MarkdownEditorStrings` | Every string the editor shows. The init has no defaults, so a new string breaks the host's build. `.english` is the default. |

The binding must store a value at once, for example `@State`.

## Limits and notices

| Case | What the editor shows |
|---|---|
| Rich mode, file over 500,000 UTF-16 units | The source, with `fileTooLargeNotice` above it. |
| Rich mode, one text block over 100,000 UTF-16 units | The source, with `blockTooLongForRichNotice` above it. Checked when rich mode opens. |
| A line over 100,000 UTF-16 units | `lineTooLongNotice` and no text view. |
| A file over 100 MiB | `fileTooLargeToEditNotice` and no text view. |

A block that grows past 100,000 units while the user edits stays in rich mode.

## Saving

The editor writes the binding:

- 1 s after the last change (`RichIdleSaver` in rich mode, the source view's own timer in source mode),
- on a mode switch,
- on disappear,
- when the app resigns active.

A file the user did not edit is never written, also after a trip through rich mode. The rich model compares exports,
not files. Its own write comes back through the binding and is recognized by `RichEditorModel.holds(_:)`, so it does
not reload rich mode. The loaded text counts as its own text only until the first export is given out.
Any other new text reloads rich mode, and its undo history starts empty. The model writes to the binding of the latest render.

## Rich mode

```text
RichEditorLoad (off the main thread)
  -> RichEditorModel (owns the RichEditor value)
  -> RichRowAdapter (MarkdownRowList data source)
  -> RichRowView per list item (shared row chrome + RichTextRow, divider or raw piece)
```

| Type | Job |
|---|---|
| `RichEditorLoad` | Loads the editor, the estimate facts and chrome of each row, and the preview rows of each raw block, off the main thread. Refuses a block over the limit. |
| `RichEditorModel` | `@Observable` wrapper of `RichEditor`. One method per user action. After each action it calls the adapter first, then sets the toolbar, edit version, focus, menu and link values, each only when it changed. |
| `RichRowAdapter` | Applies each model change to the list. Keeps the row identities, the item map, the estimate facts, the chrome and the raw renders. Owns the focus path. |
| `RichChangePlan` | Pure. The same version is a selection change. One more applies `lastChange`. Anything else reloads every row. A typed row is an own edit only when it keeps its `RichRowShape` (plain, list item or quote), so Enter in an empty list item replaces the row. |
| `RichItemMap` | Model rows to list items and back. A raw block takes one item per preview row. |
| `RichChromeIndex` | The chrome the preview draws for the same Markdown: list markers, quote bars and gaps. |
| `RichRawRenderCache` | The preview rows of each raw block, by row identity, with the link definitions they used. |
| `RichTextRow`, `RichTextView` | The editable text of one row: a TextKit 1 `UITextView` with the inline code chip. |
| `RichTextStyler` | Row text to attributed text, with the fonts and colors of `MarkdownTheme.Resolved`. |
| `RichSelectionResponder` | Has the keyboard when the selection has no text view: a divider, a raw block, or a selection over rows. |
| `RichSelectionHandler` | Protocol for the component that owns a selection over rows. The editor forwards the keys it cannot handle in one row. |
| `RichPasteboard` | Writes a copy as one pasteboard item with plain text and Markdown. Reads both types, so the model uses Markdown for text rows and plain text for a code block. |
| `RichFormattingToolbar`, `LinkAlert` | The controls. The toolbar is always shown. Its buttons are enabled only while the editor has the keyboard. The heading chip is a native `Menu` and `LinkAlert` is a native alert. |
| `KeyboardOverlap` | The bottom inset for the part of the list or the source view that the keyboard covers. |

### Model changes

- A key typed in a row is an own edit. The text view already shows it, so the list is not updated.
- Another change replaces only the changed items. Leading rows that keep their identity and item count keep their cells.
- Rows outside the change whose chrome changed (renumbered items, a new gap) are configured again.
- A missed change or new link definitions reload every row.

A text view takes the model's text only when its input is newer than what it holds, so a typed key is never
overwritten. An input of another row always replaces the text: a reused cell gives its text view a new row.
It never writes while text is marked. View and model text are compared by bytes.

### Focus

`RichRowAdapter.focusSelection()` is the only place that moves the keyboard between rows. A caret or a range in one
text row goes to that row's text view: the row is pinned, and its text view becomes first responder. A row without
a cell is scrolled to first. A row with a cell only scrolls its caret into view, so a new gap below it does not move it.
Any other selection goes to `RichSelectionResponder`, with no pinned row. Select All does not scroll.

A new nesting level or heading changes the row's view tree, so SwiftUI replaces its text view. The removed view tells
the adapter, and the new view takes the keyboard one turn later.

### Keys

| Key | What happens |
|---|---|
| Typing, autocorrect, dictation | `replaceText` with the range the keyboard announced, else `didChangeText`. |
| Enter | Splits the row. In code, a line break, or the end of the block on an empty last line. |
| Backspace at the start of a row | Removes structure first, then joins with the row before. |
| Tab, ⇧Tab | Indent and outdent a list item or quote row, only when the model would move it. |
| Arrows at the edge of a row | The caret goes to the row before or after. A divider or raw block there is selected whole. |
| ⇧ with an arrow at the edge | Goes to the `RichSelectionHandler`. |
| ⌘A, Select All | Selects the whole document. |
| Copy, cut, paste | Through the model and `RichPasteboard`. A paste into a text row is parsed as Markdown, never typed. A paste into a code block is plain text. |

Undo and redo use the model's stack through `ModelUndoManager`. A text view has no undo manager while text is marked.

### Differences from the preview

The editor draws every block with the preview's chrome and the same fonts and spacing (snapshots `previewParity`
and `editorParity`). These differences are intended:

| Case | Preview | Editor |
|---|---|---|
| A long code line | Scrolls sideways. | Wraps. |
| An empty list item | Not shown (the viewer parse drops it). | Shown with its marker, to type in. |
| A link | Opens. | Is text to edit. In a raw block it does nothing. |
| A raw block that shows nothing (definitions only) | Nothing. | Its source, dimmed, so it can be selected and deleted. |

## Source mode

`SourceTextView` is a TextKit 1 `UITextView` with non-contiguous layout. A far caret jump (Find, ⌘↓) does not animate.
The view owns the text while the user types. `SourceTextSync` writes it to the binding as native UTF-8.

## Tests and benchmarks

| Test | What it checks |
|---|---|
| `RichTextRowTests`, `RichTextStylerTests` | One row: typing, Enter, Backspace, Tab, arrows, marked text, older and newer inputs, styles. |
| `RichRowAdapterTests` | The list: own edits, Enter at the bottom edge, joins, undo, a pinned row 20 screens away, height changes. |
| `RichEditorControlsTests` | Atomic rows, the selection responder and handler, the toolbar, focus hand-overs when a row gets a new text view. |
| `RichRowClipboardTests`, `RichPasteboardTests` | Copy, cut, paste and the edit menu in one row. |
| `RichKeyboardTests` | The last rows scroll above the keyboard. Select All does not scroll. |
| `SourceEditorUIKitTests`, `MarkdownEditorSaveTests` | Source mode, notices, mode switches and every save path. |
| `RichListLayoutParityTests` | After each kind of edit, the item heights equal the heights of a list read again from the model. A row that stepped out of a list has no marker. |
| `RichInlineCodeLayoutTests` | Plain text typed after inline code keeps the code baseline and the row height. The list marker baseline matches the text. |
| `RichItemMapTests`, `RichChangePlanTests`, `RichChromeIndexTests`, `RichRawRenderCacheTests` | The pure adapter parts. `RichChromeIndexTests` compares the chrome with the preview rows. |
| `EditorSnapshotTests` | Rows of every kind in both directions, light and dark, a large text size, the controls and the notices. |

Tests that need a window on the simulator are in `MEGAMarkdownEditorHostedTests`.
Their results depend on the simulator and on timing:

- UIKit can skip a `scrollRectToVisible` call. Then a caret row stays off screen and gets no focus.
- The keyboard is system state. A software keyboard sends real frame changes, and these replace the test frames.
- Some tests sleep for a fixed time, then check a save or a layout. A slow machine can miss that time.
- A window closed without `endEditing(true)` can keep the keyboard for the next test. The test order changes between runs.
- Each wait gives up after 5 s. A busy machine can need longer.

So the CI test plan has this target turned off. Run it locally with the `MEGAMarkdown-Package` scheme.

These benchmarks in `MEGAMarkdownBenchmarks` were measured once. `Limits.json` has no limits for them:

| Benchmark | Result |
|---|---|
| `RichEditorUIBenchmarks.testKeysAt167kRows` | 50 keys in 0.02 s: about 0.4 ms per key. |
| `RichEditorUIBenchmarks.testEnterAt167kRows` | 10 Enters in 0.44 s: about 44 ms per Enter. |
| `RichEditorUIBenchmarks.testOpenRichModeAtLimitMainThread` | 0.09 s, longest main-thread stall 90 ms. |
| `RichEditorUIBenchmarks.testOpenSourceModeTwoMegabytes`, `...TenMegabytes` | 0.02 s and 0.03 s. |
| `RichToolbarBenchmarks.testToolbarAfterSelectAllAt167kRows` | 0.01 s per toolbar read. |
| `RichChromeIndexBenchmarks.testRebuildAt167kRows` | 0.12 s for the whole index. An edit builds only the rows around it: under 1 ms. |

## Known limits

| Case | What happens |
|---|---|
| Enter at the rich limit | About 44 ms on the simulator, over one frame. |
| Opening rich mode at the limit | The main thread stalls about 90 ms while the list estimates every row. |
| A row that gets a new nesting level or heading | Its text view is replaced. The keyboard moves to the new view one turn later. Not checked on a device. |
| Writing Tools in source mode | Panel only: TextKit 1 has no inline Writing Tools. |
