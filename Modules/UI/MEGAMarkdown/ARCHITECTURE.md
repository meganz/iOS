# MEGAMarkdown architecture

This guide is the overview of the package. It names each layer, its public contract, and where the details live. The model, parser, internal chunking, rendering, large-file preview, editor model and Markdown import and export layers are implemented. Sections marked **Coming soon** outline future responsibilities; their APIs and implementation decisions will be filled in with the corresponding changes.

Each implemented layer has a reference page with the full detail. Keep this guide short and put new detail in the reference pages.

## Package layers

| Layer | Status | Responsibility | Reference |
|---|---|---|---|
| [Document model](#public-document-model) | Implemented | Public block tree and inline attributes shared by consumers. | This guide |
| [Parser](#parsing-pipeline) | Implemented | Markdown syntax recognition, conversion, and behavior rules. | [PARSER.md](PARSER.md) |
| [Large-input support](#large-input-support) | Internal helpers implemented | Safe chunk ranges and reference-definition collection. | [CHUNKING.md](CHUNKING.md) |
| [Rendering and styling](#rendering-and-styling) | Implemented | SwiftUI block views, rows for big blocks, and the theme. | |
| [Large-file preview](#large-file-preview) | Implemented | Background parsing in chunks, a row list that shows only visible rows, restore and top-line reports. | [PREVIEW.md](PREVIEW.md) |
| [Editor model and mutations](#editor-model-and-mutations) | Implemented | Editable state, selection, document changes, undo, and the clipboard. | [EDITOR.md](EDITOR.md) |
| [Markdown import and export](#markdown-import-and-export) | Implemented | Conversion between editable content and Markdown source. | [EDITOR.md](EDITOR.md) |
| [Editor UI](#editor-ui) | Coming soon | Rich/source editing modes, controls, and accessibility. | |
| [App integration](#app-integration) | Coming soon | File lifecycle, navigation, saving, and host-provided behavior. | |

## Public document model

[MarkdownDocument.swift](Sources/MEGAMarkdown/Model/MarkdownDocument.swift) defines the public value tree. The types conform to `Equatable` and `Sendable`, so callers can compare results and pass them from parsing work to a consumer.

| Type | Responsibility |
|---|---|
| `MarkdownDocument` | Holds the top-level blocks in document order. |
| `MarkdownBlock` | Holds an ID, source line, and block kind. Kinds include headings, paragraphs, lists, code blocks, quotes, tables, thematic breaks, and images. |
| `MarkdownList` / `MarkdownListItem` | Keep ordering, the starting number, optional task-checkbox state, and child blocks. |
| `MarkdownTable` | Holds column alignment, header cells, and body rows. Cell text is an `AttributedString`. |

The parser produces these contracts:

- Block IDs start at zero and follow depth-first order, with each parent before its children. They are unique within a parsed document and are reassigned on every parse; they do not identify the same content across edits.
- Source lines are zero-based. They come from cmark positions, with fallbacks for nodes that report no position. Containers such as lists and quotes use the first retained content's line. These are navigation hints, not complete source ranges.
- Headings and paragraphs carry inline attributes in `AttributedString`. Block structure lives in the tree; inline text has no Foundation block presentation intent or Markdown source-position attributes.
- Ordered lists retain their starting number, adjusted when leading empty items are dropped. Bullet lists start at one.
- Each table row has the header's column count. Missing cells are padded and extra cells are dropped. Entirely empty body rows are omitted.
- Code blocks contain literal code without trailing newlines. The optional language field carries cmark's fence-info string.

This is a semantic model. A consumer that needs the original Markdown spelling, whitespace, or exact edit ranges must also retain the source.

## Parsing pipeline

[MarkdownParser.parse](Sources/MEGAMarkdown/Parsing/MarkdownParser.swift) turns a source string into a `MarkdownDocument`. It takes an optional base URL for relative links and a soft-break mode. It is synchronous, parses the whole input, and can run off the main thread.

```mermaid
flowchart TD
    A[MarkdownParser.parse] --> B[CmarkParser: feed UTF-8 to cmark-gfm]
    B --> C[cmark syntax tree]
    C --> D[CmarkTreeWalker: build blocks and inline runs]
    D --> E[ParsedBlock and InlineText]
    E --> F[Assign IDs, resolve URLs, create attributed text]
    F --> G[MarkdownDocument]
```

- cmark-gfm owns syntax recognition. The pinned version is a behavior contract.
- The tree walker builds blocks from enter/exit events without recursion, with a nesting limit of 64.
- Inline text stays in a compact form until the final conversion to `AttributedString`.
- The conversion keeps established Foundation `AttributedString(markdown:)` behavior where intended.

[PARSER.md](PARSER.md) has the API example, the walker state, the compact text model, the full table of behavior decisions, and the parser test map.

## Large-input support

[MarkdownChunker.swift](Sources/MEGAMarkdown/Parsing/MarkdownChunker.swift) cuts a large input into chunks. Each chunk parses to the same tree as the whole file would give for that range, so one cmark tree at a time is enough. The chunker only cuts where a cmark probe confirms the last block is closed. It also collects link reference definitions from all chunks and shares them, so a reference can point to a later chunk.

The helper is internal. The large-file preview drives it. `MarkdownParser.parse` always parses the whole input.

[CHUNKING.md](CHUNKING.md) explains why chunks are needed, the cut rules, the definition prefix, and how a consumer should drive the chunker.

## Rendering and styling

The views are SwiftUI. They are `package` API: other targets of this package use them.

- `MarkdownView` shows short Markdown. It parses on the main thread and builds every block with `MarkdownBlockView`.
- `PreviewRows` splits blocks into rows. A big block (long list, table, code or text) becomes many rows.
  `PreviewRowView` draws one row: its chrome (quote bars, list markers, the gap below), then its content.
- `InlineStyling` turns `InlineText` into `AttributedString` when a view draws it, so only drawn text pays for it.
- The public API is the theme and the strings: `markdownTheme(_:)`, `markdownImageLoading(_:)` and `markdownPreviewStrings(_:)`.

[DECISIONS.md](DECISIONS.md) has the display rules, with the reason for each.

## Large-file preview

`MarkdownPreview` is the public reader for big text, up to `MarkdownPreview.sizeLimitInBytes` (100 MiB).

- `PreviewPipeline` parses the text chunk by chunk off the main actor and sends the rows of each chunk as one batch.
- `PreviewModel` (`@Observable`, owned by the view with `@State`) appends each batch to a `PreviewRowStore`.
  The view starts the load with `.task(id:)`, so SwiftUI cancels an old load.
- `PreviewRowList` shows the rows in a `MarkdownRowList`, one hosted `PreviewRowView` per row.
  New rows are appended with a height guess each. Cells size themselves when they show.
- The list restores a source line and reports the top line to the host. Rows keep their source line for this.

[PREVIEW.md](PREVIEW.md) has the data flow, the threads, the row heights, the restore rules, the notices and the tests.

## Editor model and mutations

The `MEGAMarkdownEditor` target holds the rich mode without UI. `RichEditor` is a value type: a UI keeps one, shows its `rows` and `selection`, and calls one method per user action.

- `RichDocument` is a flat list of `RichBlock`s. Lists and quotes are rows with an indent or a depth.
- `RichText` is plain text with style spans in UTF-16 offsets. It holds no Markdown syntax.
- Each row has a `RichRowID` that stays the same while the row is edited. It is not related to the parser's block IDs, which change on every parse.
- Undo keeps the replaced rows of each change, not whole documents. Keys in one row form one step.
- Copy writes plain text and Markdown. Paste reads Markdown, also plain text from other apps.

[EDITOR.md](EDITOR.md) has the model rules, the method for each user action, and the known limits.

## Markdown import and export

`RichMarkdownConverter` converts between Markdown and `RichDocument`. It parses with `ParseMode.editor`, which keeps the empty blocks the viewer drops.

- A block the model cannot hold (tables, images, HTML, lists with block content) stays `.rawSource` with its exact source lines.
- The import checks itself: it exports the rows, parses the export, and compares the meaning with the parse of the file. A block that changes stays raw.
- The export escapes plain text, nests style markers, and writes HTML tags when markers cannot parse back.
- A file that was not edited is never saved, so its bytes stay as they are.

[EDITOR.md](EDITOR.md) has the import steps, the export rules, and the round-trip tests.

## Editor UI

**Coming soon.** This section will describe rich and source editing modes, bindings and callbacks, text-system integration, keyboard and selection behavior, formatting controls, and mode transitions. Include localization, accessibility, focus, and text input behavior as the UI is implemented.

## App integration

**Coming soon.** This section will explain how the host app loads and saves files, presents previews and editors, supplies themes and localized strings, and handles links and image resources. Document lifecycle and error handling at the package boundary, with a minimal integration example once an app flow uses the package.

## Testing

The tests use Swift Testing and are included in the repository's [MEGAModulesTests plan](../../../MEGAModulesTests/MEGAModulesTests.xctestplan). Each reference page lists the tests for its layer: [parser tests](PARSER.md#tests-for-this-layer), [chunking tests](CHUNKING.md#tests-for-this-layer) and [preview tests](PREVIEW.md#tests).

### Running tests

Open `Package.swift` in Xcode, choose the `MEGAMarkdown` scheme and an installed iOS simulator, then run tests. From the package directory, the equivalent command is:

```sh
xcodebuild test \
  -scheme MEGAMarkdown \
  -destination 'platform=iOS Simulator,id=<SIMULATOR_UDID>' \
  -skipPackagePluginValidation
```

Replace `<SIMULATOR_UDID>` with an available simulator ID from `xcrun simctl list devices available`.

The time, memory, and scaling benchmarks are a separate target, `MEGAMarkdownBenchmarks`. Run them with
`scripts/benchmark.sh Modules/UI/MEGAMarkdown` (see the README).

For optional runs, export these variables before invoking `xcodebuild`. The `TEST_RUNNER_` prefix passes them into the test process; setting an arbitrary Xcode build setting is not equivalent.

| Exported variable | Effect |
|---|---|
| `TEST_RUNNER_MARKDOWN_FUZZ_ITERATIONS=400` | Sets the seeded fuzz iteration count for the snippet fuzz and the spec-example fuzz; 400 is the default, with three chunk targets per iteration. |
| `TEST_RUNNER_MARKDOWN_CHUNK_FILES=/absolute/a.md:/absolute/b.md` | Enables whole-versus-chunked comparison for additional files. |
| `TEST_RUNNER_MARKDOWN_REFERENCE_ITERATIONS=3000` | Sets the number of seeded mutations in the cmark comparison. 3,000 is the default. |
| `TEST_RUNNER_MARKDOWN_REFERENCE_SEED=11` | Sets the seed of those mutations. 11 is the default. |
| `TEST_RUNNER_MARKDOWN_REFERENCE_REPORT=/absolute/report.txt` | Writes every difference from cmark to the file, with both sides. |
| `TEST_RUNNER_MARKDOWN_REFERENCE_FILES=/absolute/a.md:/absolute/b.md` | Compares additional files with cmark, for example real documents or another parser's test inputs. |
| `TEST_RUNNER_MARKDOWN_FOUNDATION_PARITY=1` | Enables the comparison with Foundation's `AttributedString(markdown:)`. Foundation is not a source of truth, and its output changes with the OS. |

Report benchmark results with the input, build configuration, simulator/device, and measured operation.

### Updating golden output

For an intentional output change, set `TEST_RUNNER_MARKDOWN_WRITE_GOLDENS` to the absolute path of `Tests/MEGAMarkdownTests/Fixtures/golden` and run the golden tests (`ParserGoldenTests` and `SpecCorpusGoldenTests`). Write mode records a test issue deliberately. Review the changed snapshots, unset the variable, and rerun in comparison mode. Include a focused behavior test when the change introduces a new contract.

## Extending the guide

Update this guide in the same MR that adds or changes an implementation layer. Replace the relevant **Coming soon** text with a short summary of the APIs, data flow, and limitations, then update the layer's status above. Put the full detail in a reference page next to this guide and link it from the layers table.

Keep unimplemented responsibilities clearly marked; a placeholder does not commit to a particular UI framework or state-management design. The README remains the package entry point, while this guide explains the implementation and the remaining layers.
