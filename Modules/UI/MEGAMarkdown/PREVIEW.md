# Large-file preview

`MarkdownPreview` is the public, read-only reader for big Markdown text. This page explains how text becomes
rows on screen, which thread does what, and how the list keeps the reading place.
The terms are defined in [TERMINOLOGY.md](TERMINOLOGY.md).

## Public API

```swift
MarkdownPreview(
    markdown,
    baseURL: url,
    softBreak: .lineBreak,
    restoreLine: savedLine,
    onReadingPositionChange: { position in
        savedLine = position.topLine
        progress = position.progress
    }
)
.markdownTheme(theme)
.markdownImageLoading(.altTextOnly)
.markdownPreviewStrings(strings)
```

- `MarkdownPreview.sizeLimitInBytes` is 100 MiB of UTF-8. Bigger text shows `strings.tooLarge`.
  A host checks the file size before it reads the file into a `String`.
- `restoreLine` is a 0-based source line. The preview opens with the row that contains it at the top.
- `onReadingPositionChange` gets a `MarkdownReadingPosition` when its top line or its read progress changes.
  It is a callback, not a binding, so a scroll does not redraw the parent view.
  - `topLine` is the source line of the top row.
  - `progress` is from 0 to 1. The top line never reaches the end of the text,
    so a host uses the progress to know that the user read to the end.

## From text to screen

| Step | Type | Thread |
|---|---|---|
| 1. `.task(id:)` starts a load for the request (text, base URL, soft break). | `MarkdownPreview` | main |
| 2. The load runs the pipeline and reads its batches from the `AsyncThrowingStream` that `PreviewPipeline.run` returns. | `PreviewModel` | main |
| 3. The pipeline cuts the text into chunks, parses each chunk with the definitions known so far, and turns the blocks into rows. It sends the line count of the whole text once, then one batch per chunk. | `PreviewPipeline` | background |
| 4. Each batch is appended to the store, and `rowCount` grows. The model keeps the line count. | `PreviewModel`, `PreviewRowStore` | main |
| 5. The view passes the store, `generation` and `rowCount` to the list. New rows are appended with a height guess each. | `PreviewRowList` | main |
| 6. Each cell on screen hosts a `PreviewRowView` and sizes itself. | `MarkdownRowList`, `MarkdownRowCell` | main |

- Rows are only appended. A later batch never changes an earlier row, so the list never reloads while a text arrives.
- Each append adds one collection view section. The list inserts that section and leaves the earlier sections alone.
  `MarkdownRowLayout.sectionStarts` maps a row index to its section and item.
- The pipeline keeps the last row of a batch until the next chunk, because the next row sets the gap below it.
- A reference to a definition in a later chunk stays literal text. See [CHUNKING.md](CHUNKING.md).
- `PreviewParseLimits.maxRowWeight` is 0: every block is split, so each cell draws one short piece.
  A big code block becomes pieces of 100 lines, and a big table pages of up to 50 rows.
  Known limit: each code piece and each table page scrolls sideways on its own.
- One row per block was measured and dropped (Release, iPhone 17 simulator):

  | File | Open, split rows | Open, one row per block | Peak memory, split → one row |
  |---|---|---|---|
  | Paragraph 1 MB | 0.05 s | 2.41 s | 30 MB → 1,381 MB |
  | Line 1 MB, no space | 0.03 s | 2.67 s | 27 MB → 1,096 MB |
  | Code block 5.8 MB | 0.15 s | no result after 8.5 min | 55 MB → not measured |
  | Table of 100,000 rows | 0.28 s | crash in SwiftUI ("exhausted data space") | 37 MB → not measured |
- A long paragraph is cut into text pieces of about 4,000 bytes. The cut moves back to a newline when one is near,
  else to a space. Each piece is its own `Text`, so a cut at a space leaves a short last line in its piece.
  A paragraph without newlines always shows this seam.
- The store keeps one part per batch. An append never copies the earlier rows.
  A store of more than 10,000 rows frees its rows in a background task.

## Cancellation and new text

- SwiftUI cancels the task when the request changes or the view goes away. The pipeline checks for
  cancellation before each chunk. The rows that arrived stay.
- The stream ends normally when every chunk was sent. It throws `PreviewPipeline.Failure.tooLarge` for
  a text over the limit. Stopping the iteration cancels the parse task.
- A cancelled load sees the stream end normally. So `PreviewModel` checks `Task.isCancelled` after the loop.
- Each load gets a token. A batch of an older load is dropped.
- The old rows stay on screen until the new text sends its first batch. Then `generation` grows,
  the list reads every row again and goes to the top. The spinner shows only before the first text.
- `.task` runs again each time the view appears. A request that is already complete loads nothing,
  so the list keeps its place.
- A load of the same text that was cancelled part way keeps its rows. The next load parses again
  and skips the rows that are already there, so `generation` does not grow and the list keeps its place.

## Row heights

- `MarkdownRowEstimator` guesses each row's height from plain facts (text length, line count) when the row is appended.
  Only the rows of one batch are guessed at a time, so no main-thread pass covers the whole file.
- A cell sizes itself when it shows. Its height is then measured and is not sized again,
  until the width, the text size, Bold Text or the theme changes. Image rows size themselves every time.
- Layout passes never animate (`MarkdownRowListView`).

## Restore and reports

- A restore line waits until its row is known: a later row exists, or the text is complete.
  It also waits while the rows on screen belong to an older text.
  A line after the last row shows the last row.
- The list then jumps there and keeps that row at the top for 1 s (`pinDuration`), while the rows around it size themselves.
  This is the restore pin. A drag or a status bar tap ends it.
- While a restore waits, nothing is reported. So a host that saves every report never saves line 0 by mistake.
- Reports run in layout passes, never inside a SwiftUI update, and only when the position changed.
  After the view is gone, nothing is reported.
- The read progress is the source line of the first row below the screen divided by the line count of the text.
  It is 1 when the last row of the complete text is on screen. While more batches are on the way, the last row
  on screen gives its own line, so the progress stays below 1.
- The chunker counts the lines off the main actor, with the same line ends as cmark (`\n`, `\r\n` and `\r`).
  So the line count and the source lines of the rows always match.

## Environment and traits

- The text size, the layout direction and the color scheme come from the SwiftUI environment.
  The list sets them as trait overrides, and the hosted rows read them from the cell traits.
- The theme, the preview strings and the image loading are passed into each hosted row.
  A change of the strings or the image loading configures the visible rows again, also in an update that adds a batch.
  The host's `openURL` is called through a forwarding action, so a new handler needs no new cells.
- The list fills the safe area, so rows scroll under the bars. `MarkdownPreview` reads the SwiftUI safe area first.
  It includes host bars added with `safeAreaInset`, which UIKit does not see.
  UIKit adds the window safe area to the list insets by itself. `PreviewRowList.Coordinator` adds the rest to `contentInset`.
  So the first and last rows stay clear of every bar, and cells never get a safe area of their own.
- A paragraph, heading or list item row takes the direction of its first strong letter (UAX #9 rules P2 and P3,
  like HTML `dir="auto"`). A right-to-left row is right-aligned, with its bullet, number or checkbox on the right.
  The list columns of the row mirror with it, so a nested item indents from the text side. Quote bars follow the layout.
  A row without a letter follows the layout.
  Tables and code stay left to right in every layout.
- Only the list scrolls to the top on a status bar tap. Code and table rows turn off `scrollsToTop` on their own scroll views.

## Block selection

The reader selects whole blocks, not characters. `PreviewSelectionController` holds the selection, because the
preview has no model. It draws with the same parts as the editor's selection over rows: `SelectionDisplayInput`,
`SelectionDragWatcher` and `SelectionAutoScroller`.

- A long press selects the block under the finger. Moving on grows the selection block by block.
  A long press inside the selection selects the block under the finger again. A long press on a notice does nothing.
- The handles grow or shrink the selection by whole blocks. The list scrolls while the finger holds near its top or bottom edge.
- A split block is selected with all its rows: every text piece, code piece or table page.
  A list item and a quote child are blocks of their own.
- The edit menu shows Copy and Select All. It points at the part of the selection on screen.
- Copy writes plain text only: the text of the blocks without Markdown syntax, blocks joined by a blank line.
  Table cells are joined by a tab. A long code line cut over several pieces is joined back, without the `↪ ` marker.
  Notices are never copied. Select All and a handle drag can still reach over them.
- A tap outside the selection clears it. A scroll keeps it. A new text clears it.
- Text inside a block cannot be selected. Text with inline code is drawn by TextKit in `InlineCodeText`, which has
  no selection. In a table cell, SwiftUI `.textSelection` would turn off the inline code chip renderer.

## Notices and errors

| Case | What the reader sees |
|---|---|
| Text over `sizeLimitInBytes` | `strings.tooLarge`, no list. |
| A part with no safe cut within the 8 MiB chunk cap | `strings.shownAsPlainText`, then the rest of the file as plain text rows. |
| cmark cannot parse a chunk | The chunk as one plain paragraph. The pipeline logs it. |
| Empty text | An empty list. |

## Tests

| Test | Covers |
|---|---|
| `PreviewPipelineTests` | Batch order, rows equal to one builder over the same chunks, late definitions, limits, notices, cancellation, the stream, the line count for each line ending. |
| `PreviewRowStoreTests` | Reads across parts and the line lookup. |
| `PreviewModelTests` | Load, new text, too large, dropped batches of an older load, cancellation, a second load of the same text. |
| `PreviewRowListRestoreTests` | Restore in both directions and into a later batch, full code rows after a restore, width change, pins, top-line and read progress reports, new text, appends. |
| `MarkdownRowLayoutTests` | Layout attributes, self-sizing, and the row index to section and item math, also with an empty section. |
| `MarkdownRowListTests` | One section per append (`eachAppendAddsExactlyOneSection`), an append on an empty list, items in a later section, replace across a section edge. |
| `PreviewRowListTests` | Text size, color scheme, direction, status bar tap, full width, theme, strings and `openURL` changes, an image loading change in the same update as a batch. |
| `MarkdownPreviewTests` | The too large message, the spinner, a restore with the real chunk size, host bars. |
| `PreviewSnapshotTests` | Images of all blocks, an accessibility text size, the plain-text notice, a restored place and host bars. |
| `PreviewSelectionTests` | Long press and handle drags by whole blocks, a long press inside the selection or on a notice, autoscroll, taps, the menu bounds, a selection in a later batch, Copy of split blocks and cut code lines, Select All, a new text, detach, right to left. |
| `PreviewSelectionSnapshotTests` | Blocks selected over a paragraph, a list item, a divider, code and a Hebrew row, both directions, light and dark. |

Window tests poll a condition every 10 ms. They do not sleep for a fixed time.

## Benchmarks

`PreviewPipelineBenchmarks` and `PreviewList{Two,Ten,Fifty,Hundred}MegabyteBenchmarks` in `MEGAMarkdownBenchmarks`.
The list tests show rows that are already parsed. `testOpenToFirstContent` and `testLoadWhileShown` run the whole preview.
`MarkdownRowListBenchmarks/testAppendParseBatchAfter20Batches` measures one append after 20 sections.

Simulator, iPhone 17, iOS 26.4, Release, 2026-10-03. The machine was not idle (load average 3 to 6).

| Measure | 2 MB | 10 MB |
|---|---|---|
| Open to the first rows, whole preview | 0.16 s | 0.17 s |
| Longest main-thread stall while every batch arrives | 39 ms | 40 ms |
| Open with every row already parsed | 0.04 s | 0.10 s |
| 100 screens of scroll | 1.89 s | 1.93 s |
| Jump to the end | 0.02 s | 0.02 s |
| Late frames in a 3 s steady scroll | 0.8 | 0.3 |

The pipeline gives the first batch of 10 MB in 0.10 s and all of it in 0.95 s.

`HugeBlockBenchmarks` opens files that are one huge block. Such a file has no safe cut, so it is one chunk.
Its first rows wait for the whole parse. Same simulator, Release, 2026-10-04, load average about 7:

| File | Open to the first rows | Longest main-thread stall |
|---|---|---|
| Table of 100,000 rows (2.5 MB) | 0.29 s | 60 ms |
| List of 100,000 items (1.3 MB) | 0.17 s | 61 ms |
| Code block of 250,000 lines (5.8 MB) | 0.16 s | 36 ms |
| Quote of 20,000 paragraphs (1 MB) | 0.07 s | 41 ms |
| Paragraph of 1 MB | 0.05 s | 18 ms |
| Line of 1 MB with no space | 0.03 s | 23 ms |

A Debug build opens the table in 1.34 s. Most of that is the tree walk, which Debug does not optimize.

`PreviewSelectionBenchmarks` runs on 10 MB with every row parsed. `Limits.json` has no limits for it.
iPhone 17 Pro simulator, iOS 26.4, Release, 2026-10-08, five runs each. The machine was very busy
(load average up to 139), so the numbers are rough:

| Measure | Average |
|---|---|
| 100 screens of scroll with Select All (`testScrollWithSelectAllTenMegabytes`) | 3.17 s (2.30 to 5.24 s), longest main-thread stall 276 ms |
| 100 screens of scroll without a selection (`testScrollWithoutASelectionTenMegabytes`) | 2.29 s, longest main-thread stall 32 ms |
| Plain text of a Select All on 10 MB (`testCopySelectAllTenMegabytes`) | 0.04 s, longest main-thread stall 43 ms |
