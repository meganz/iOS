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
A selection over rows scrolls to the row of its head, the end the user moved (`RichSelectionHandler.selectionHead`).
So after a drag the list stays at the finger, and ⇧↑ shows the row it reached.

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

### Selection over rows

A selection inside one row stays with that row's text view: its handles, menu and loupe are the system's.
A selection that spans rows belongs to `CrossBlockSelectionController`. The model holds it. The controller keeps its
direction: the anchor stays, and the head moves.

`SelectionDisplayInput`, `SelectionDragWatcher`, `SelectionAutoScroller` and `SelectionGeometry` are in the
`MEGAMarkdown` target, in `Sources/MEGAMarkdown/Views/Selection/`. The preview uses them too.

| Part | What it does |
|---|---|
| `SelectionDisplayInput` | A small `UITextInput` for `UITextSelectionDisplayInteraction` on the list. It gives the carets and highlight rects of the rows on screen, so the handles and highlight look like the system's. An end whose row is off screen gets a rect at that row's stored frame. A divider or raw block can span several items. Its caret before the block (offset 0) is on the first item. Its caret after the block (offset 1) is on the last item. |
| `SelectionDragWatcher` | Sees every touch on the list. It never blocks another recognizer. It takes a touch over only for a selection drag. |
| `CrossBlockSelectionController+Drag` | A native handle drag that leaves its row is taken over: the other end of the native range is the anchor, the head follows the finger. The handles of a selection over rows drag the same way. The model gets the selection once, when the finger lifts. Then the edit menu shows, if the selection still spans rows. |
| `SelectionAutoScroller` | Scrolls the list while the finger holds in a 54 pt zone at its top or bottom edge, up to 1,500 pt/s. |

Rules:

- Only a touch that starts on a native handle (`SelectionGeometry.handleZone`: 22 pt on each side of its caret,
  20 pt past it on the knob side and 8 pt on the other side) can take over. A swipe from elsewhere
  in the row scrolls. The model's selection names the row of the native range. So a touch on the start knob counts
  also when the knob reaches over the row above.
- A content change during a drag (⌘X, undo) ends the drag. The model's selection then shows, and the lift changes nothing.
- After every model change the controller reads the model's selection. Over rows, or a divider or raw block selected
  whole: the highlight and handles show, also after undo, redo and Select All. Inside one text row: they go.
- A divider or raw block shows only this highlight, no background of its own. The highlight covers the block and
  leaves out the gap below it.
- A tap on a handle or inside the highlight shows the edit menu and keeps the selection. A tap elsewhere places a
  caret. A scroll keeps the selection. A touch the system cancels still hands a drag's selection to the model.
- A touch inside the highlight stops the row's own recognizers, but not the list pan. So a checkbox tap or a long
  press inside a selection does nothing while the selection shows.
- The edit menu sits on `RichSelectionResponder`, so it shows the responder's own edit actions as system items.
  It points at the part of the selection on screen.
- ⇧ with an arrow at a row edge moves the head one row and keeps the anchor.
- Focus moves only through `RichRowAdapter.focusSelection()`. The controller draws nothing while the adapter applies
  a change.

### Differences from the preview

The editor draws every block with the preview's chrome and the same fonts and spacing (snapshots `previewParity`
and `editorParity`). These differences are intended:

| Case | Preview | Editor |
|---|---|---|
| A long code line | Scrolls sideways. | Wraps. |
| An empty list item | Not shown (the viewer parse drops it). | Shown with its marker, to type in. |
| A link | Opens. | Is text to edit. In a raw block it does nothing. |
| A raw block that shows nothing (definitions only) | Nothing. | Its source, dimmed, so it can be selected and deleted. |
| A list item at an accessibility text size | Its height. | Up to 1 pt taller: the marker can sit a fraction of a point lower, and the cell rounds the row up. |

## Source mode

`SourceTextView` is a TextKit 1 `UITextView` with non-contiguous layout. A far caret jump (Find, ⌘↓) does not animate.
The view owns the text while the user types. `SourceTextSync` writes it to the binding as native UTF-8.

## Tests and benchmarks

| Test | What it checks |
|---|---|
| `RichTextRowTests`, `RichTextStylerTests` | One row: typing, Enter, Backspace, Tab, arrows, marked text, older and newer inputs, styles. |
| `RichTextRowFocusTests` | One row with the focus: a style turned off for the next key, a user caret move, and plain text typed after inline code or after a saved link. |
| `RichRowAdapterTests` | The list: own edits, Enter at the bottom edge, joins, undo, a pinned row 20 screens away, height changes. |
| `RichEditorControlsTests` | Atomic rows, the selection responder and handler, the toolbar, focus hand-overs when a row gets a new text view. |
| `RichRowClipboardTests`, `RichPasteboardTests` | Copy, cut, paste and the edit menu in one row. |
| `RichKeyboardTests` | The last rows scroll above the keyboard. Select All does not scroll. |
| `RichLateKeyboardTests` | A keyboard that comes after the focus scroll or after Enter at the bottom edge. The caret stays on screen when the list gets shorter and when a keyboard frame covers it. |
| `SourceEditorUIKitTests`, `MarkdownEditorSaveTests` | Source mode, notices, mode switches and every save path. |
| `RichListLayoutParityTests` | After each kind of edit, the item heights equal the heights of a list read again from the model. A row that stepped out of a list has no marker. |
| `RichRowGeometryTests` | After Enter on the last list item, a paste, a scroll and a fast scroll to the end, each cell shows its own row at the height of its content, and no cell overlaps the next one. |
| `RichPreviewLayoutParityTests` | Each row with inline code has the same height in the editor and in the preview, up to 1 pt at accessibility text sizes. Every row height in both lists is a whole point. |
| `RichInlineCodeLayoutTests` | A row with inline code is as tall as the chip, with the line gap between wrapped lines. The list marker baseline matches the text. |
| `RichItemMapTests`, `RichChangePlanTests`, `RichChromeIndexTests`, `RichRawRenderCacheTests` | The pure adapter parts. `RichChromeIndexTests` compares the chrome with the preview rows. |
| `SelectionGeometryTests` | The pure rules of the selection over rows: handle zones, the grabbed end, taps, autoscroll speed and how the head moves. |
| `CrossBlockSelectionControllerTests`, `SelectionDragTests` | Selection over rows in a window: the highlight and handle rects (also right to left and off screen), ⇧ with arrows, undo, Select All, a second controller on the same rows, and drags through the controller's touch entry points. |
| `SelectionEdgeCaseTests` | The list follows the head after a drag and after ⇧↑, the start knob over the row above, the menu bounds on screen, ⌘X or ⌘B during a drag, and the handles at a table split into pages. |
| `SelectionSnapshotTests` | A selection over text, a divider and a Hebrew row, both directions, light and dark. |
| `EditorSnapshotTests` | Rows of every kind in both directions, light and dark, a large text size, the controls and the notices. |

Tests that need the focus are in `MEGAMarkdownEditorHostedTests`, and the CI test plan runs them.
Their windows are visible but never the key window:

- A row still takes the focus, but no software keyboard shows.
- A real keyboard comes up at a different time in each run and makes the list shorter.
  A caret row could then end off screen in one run and not in the next.
- A test that needs a keyboard posts its frame as a notification, so the frame is the same on every run.
- Tests with the `.hostedUI` trait run one at a time, because they share the first responder.
- Some tests still wait for a save timer or for rich mode to load. Each wait gives up after 5 s.

Layout tests that do not need the focus are in `MEGAMarkdownLayoutTests`, and the CI test plan runs them.
`RichLayoutHarness` keeps them stable on every run:

- The window is visible but never the key window. No row takes the focus, so no keyboard shows.
- A test drives the model, then calls `flushLayout()`. It runs layout passes until the heights stop changing.
- A test has no sleep. Only the preview waits, because it parses off the main thread.
- `rowProblems()` checks each cell on screen. The height is measured, the cell is as tall as its content,
  the text view shows its own row, and no cell overlaps the next one.

`RichTextRowTests` types into a row without the focus, through the text view delegate. Its `RichTextRowHarness` follows the same rules.

A test that needs the focus, the keyboard, a timer or a save stays in `MEGAMarkdownEditorHostedTests`.
Without the focus, a style turned off at the caret does not reach the next key, and a caret move is not reported.

These benchmarks in `MEGAMarkdownBenchmarks` were measured once. `Limits.json` has no limits for them:

| Benchmark | Result |
|---|---|
| `RichEditorUIBenchmarks.testKeysAt167kRows` | 50 keys in 0.02 s: about 0.4 ms per key. |
| `RichEditorUIBenchmarks.testEnterAt167kRows` | 10 Enters in 0.44 s: about 44 ms per Enter. |
| `RichEditorUIBenchmarks.testOpenRichModeAtLimitMainThread` | 0.09 s, longest main-thread stall 90 ms. |
| `RichEditorUIBenchmarks.testOpenSourceModeTwoMegabytes`, `...TenMegabytes` | 0.02 s and 0.03 s. |
| `RichToolbarBenchmarks.testToolbarAfterSelectAllAt167kRows` | 0.01 s per toolbar read. |
| `SelectionBenchmarks.testAutoscrollWithASelection`, `...WithoutASelection` | 10,000 pt of autoscroll: 7.25 s with a selection and 7.24 s without, 0 late frames with a selection. |
| `SelectionBenchmarks.testScrollWithSelectAll`, `...WithoutASelection` | 100 screens: 6.03 s with Select All and 6.21 s without. |
| `SelectionBenchmarks.testHeadMovesOverVisibleRows` | 300 head moves in 0.02 s, longest main-thread stall 16 ms. |
| `SelectionBenchmarks.testSelectAllShowsTheSelection` | 0.07 s, longest main-thread stall 72 ms. |
| `RichChromeIndexBenchmarks.testRebuildAt167kRows` | 0.12 s for the whole index. An edit builds only the rows around it: under 1 ms. |

## Known limits

| Case | What happens |
|---|---|
| Enter at the rich limit | About 44 ms on the simulator, over one frame. |
| Opening rich mode at the limit | The main thread stalls about 90 ms while the list estimates every row. |
| A row that gets a new nesting level or heading | Its text view is replaced. The keyboard moves to the new view one turn later. Not checked on a device. |
| Writing Tools in source mode | Panel only: TextKit 1 has no inline Writing Tools. |
| A selection over rows with VoiceOver | No announcement of the selected rows. Select All and a hardware keyboard work. |
| A native handle drag that leaves its row | Taken over by a touch on the list. The text view's own drag has no public cancel, so its recognizers are turned off and on. The package supports iOS 17, but the selection display, the handle zones and the drag cancel are checked only on iOS 18.6 and 26.4. |
