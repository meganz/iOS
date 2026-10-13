# MEGAMarkdown terminology

Short definitions of the terms used in the [README](README.md), the [architecture guide](ARCHITECTURE.md),
the [decision records](DECISIONS.md), the code comments and the tests.
Only terms that are specific to Markdown, cmark, or this package are listed. Add a term when a review asks what it means.

## Markdown and cmark

| Term | Meaning |
|---|---|
| CommonMark | The Markdown specification that cmark implements. It defines what a heading, a list, or a link is. |
| GFM (GitHub Flavored Markdown) | CommonMark plus extensions: tables, strikethrough (`~~text~~`), task lists, and bare-URL autolinks. |
| cmark-gfm | GitHub's C parser for GFM. The package uses the fork `swiftlang/swift-cmark`. |
| Extension | A cmark plug-in that adds one GFM feature. The package enables `table`, `strikethrough`, `autolink` and `tasklist`. |
| Block | A structural unit of a document: heading, paragraph, list, list item, code block, quote, table, thematic break, HTML block. |
| Container block | A block that holds other blocks: document, quote, list, list item, table, table row. |
| Leaf block | A block that holds text, not blocks: paragraph, heading, code block, HTML block, thematic break. The chunker's cut rule looks at the last leaf block. |
| Inline | Content inside a leaf block: text, emphasis, links, images, code spans, breaks. |
| Fence | A code block opened and closed by ```` ``` ```` or `~~~`. An open fence continues until its closing line, so a cut inside it is unsafe. |
| Fence info | The text after the opening fence, usually the language name. The model stores it as `language`. |
| Setext heading | A heading written as text underlined with `===` or `---`. The other form (`# text`) is an ATX heading. |
| Thematic break | A horizontal rule, written as `---`, `***` or `___` on its own line. |
| Soft break | A single newline inside a paragraph. CommonMark shows it as a space. This package shows it as a line break by default. |
| Hard break | An explicit line break: two spaces or a backslash at the end of a line. The model marks it with `.lineBreak`. |
| Reference link | A link written as `[text][label]`, resolved through a definition elsewhere in the document. |
| Reference definition | A line like `[label]: url "title"`. It can appear anywhere, also after the link that uses it. |
| Label | The name inside the square brackets of a reference link or definition. cmark matches labels case-insensitively with Unicode case folding. |
| Autolink | A bare URL such as `https://mega.nz` that becomes a link without brackets. Needs the `autolink` extension. |
| Task item | A list item starting with `[ ]`, `[x]` or `[X]`. cmark's `tasklist` extension finds most of them. The walker reads the state from the source bytes. |
| Source position | The line and column cmark reports for a node. Enabled with `CMARK_OPT_SOURCEPOS`. The model keeps the 0-based start line only. |
| `cmark_iter` | cmark's own tree iterator. It emits enter and exit events for each node, without recursion. |
| Entity | An HTML character reference such as `&amp;` or `&#169;`. cmark decodes it into the text. |
| Smart punctuation | cmark's option that turns `"` into curly quotes and `--` into dashes. The package keeps it off. |

## Package model

| Term | Meaning |
|---|---|
| `MarkdownDocument` | The public value tree: blocks with IDs, source lines and attributed inline text. |
| Block ID | A number assigned per parse in depth-first order. It is not stable across edits. |
| `ParsedBlock` | The internal block tree built by the walker. Same shape as the public tree, but its text is `InlineText`. |
| `InlineText` | The compact text form: a `String`, a run array, and link targets. Converted to `AttributedString` later. |
| Run | One stretch of text with one style set and one link target. Runs are stored by their UTF-8 end offset. |
| Style bits | The `InlineStyle` option set: emphasized, strongly emphasized, strikethrough, code, soft break, line break, inline HTML, block HTML, underline, image. |
| Style tag | A bare inline HTML pair the package turns into a style: `<b>`, `<strong>`, `<i>`, `<em>`, `<s>`, `<del>`, `<strike>`, `<code>`, `<u>`. Unmatched tags stay literal text. |
| Walker | `CmarkTreeWalker`. It turns cmark enter and exit events into `ParsedBlock`s. |
| Frame | The walker's record for one open container block. Exiting the container closes the frame and attaches it to its parent. |
| Inline context | The walker's record of the active style, link and image state. Entering emphasis or a link pushes one; exiting pops it. |
| Piece | One collected text fragment with its context, inside one paragraph, heading or table cell, before style tags are applied. |
| Placeholder | The `U+FFFC` character that stands in for an image with empty alt text, so the image is not lost during traversal. |
| Nesting cap | The depth limit of 64 for quotes and list items. Deeper content joins the deepest open container. |
| Image block | A paragraph of exactly one image with a URL. It becomes one block with that URL and the alt text. |

## Row list

| Term | Meaning |
|---|---|
| Row | One entry of a list model. The preview splits big blocks into rows (`PreviewRow`). |
| Item | One cell of `MarkdownRowList`. In the preview one row is one item. A caller may map one row to several items, for example a large raw table. |
| Estimate | A height guess from `MarkdownRowEstimator`, made before the item's cell exists. |
| Measured height | The height a cell gave when it sized itself. It stays until the width, text size or theme changes, or the caller invalidates it. |
| Anchor item | The item that stays at the same place on screen when every height changes: the pinned item, else the top item. If the top edge cuts it, the same share of its height stays above the edge. A list that showed its end shows its end again. |
| Pinned item | The item whose cell stays attached while the list scrolls far away, for example a row whose text view has the keyboard focus. |

## Large-file preview

| Term | Meaning |
|---|---|
| Batch | The rows of one chunk, sent by `PreviewPipeline`. Rows are only appended, so a batch never changes an earlier row. |
| Generation | A number that grows when the rows of a new text replace the old ones. The list then reads every row again and goes to the top. |
| Restore line | The 0-based source line the host passes to open the preview at a saved place. |
| Restore pin | After a restore jump, the row stays at the top for 1 s while the rows around it size themselves. A drag or a status bar tap ends it. Not the same as a pinned item. |
| Top line | The source line of the top row. The preview reports it to the host when it changes. |

## Selection

| Term | Meaning |
|---|---|
| Selection over rows | A selection in the rich editor whose ends are in different rows, or a divider or raw block selected whole. `CrossBlockSelectionController` draws it. |
| Anchor, head | The two ends of a selection. The anchor stays. The head follows the finger, or ⇧ with an arrow. Not the same as an anchor item. |
| Native selection | A range inside one text row. The row's `UITextView` draws it with its own handles. |
| Handle zone | The touch area of a handle (`SelectionGeometry.handleZone`). Only a touch that starts there can start a handle drag. |
| Takeover | The list layer takes a native handle drag over once the finger leaves its row by more than `SelectionGeometry.takeoverMargin`. |
| Autoscroll | The list scrolls while a selection drag holds the finger in the zone at its top or bottom edge (`SelectionAutoScroller`). |
| Block selection | The preview selection (`PreviewSelectionController`). It always holds whole blocks, with every row of a split block. |

## Chunking

| Term | Meaning |
|---|---|
| Chunk | A byte and line range of the source that parses to the same tree as the whole file would give for that range. |
| Target size | The size the chunker aims for: 1 MiB. The cut is placed at the first safe candidate after it. |
| Cap | The largest chunk allowed: 8 MiB. Past the cap, the rest of the file is returned as plain text. |
| Candidate | A possible cut line: after a blank line, before content at column zero that is not indented and not a list marker. |
| Cut | The line where one chunk ends and the next starts. |
| Safe cut | A cut where the last leaf block of the chunk ends before the chunk's last blank line. Checked by a probe parse. |
| Probe | A small cmark parse used only to answer a question, not to build blocks. The chunker uses two: "is this cut safe" and "which labels are real definitions". |
| Rejected cut | A candidate the probe found unsafe. The chunk then grows about twofold. Tests read `rejectedCuts`. |
| Definition prefix | The confirmed reference definitions of all chunks, rebuilt as Markdown lines and put in front of each chunk's text. |
| Line offset | The number subtracted from cmark's line numbers so a chunk's blocks get document-relative lines. It accounts for the prefix lines. |
| Plain-text remainder | A chunk with `isPlainText = true`. The consumer must show it as text, not parse it. |
| Whole parse | Parsing the full input in one cmark call. The chunk tests compare against it. |
| Parity | Agreement between two outputs: chunked versus whole parse, or the new parser versus Foundation. |

## Tests and measurement

| Term | Meaning |
|---|---|
| Fixture | A checked-in Markdown input used by the tests, under `Tests/MEGAMarkdownTests/Fixtures`. |
| Golden | A checked-in text dump of the exact parser output for one fixture. The golden tests compare against it. |
| Write mode | Running the golden tests with `TEST_RUNNER_MARKDOWN_WRITE_GOLDENS` set. It rewrites the goldens and fails on purpose. |
| Known difference | A deliberate difference from the Foundation output, listed in `ParserDifferenceTests`. |
| Fuzz | Tests that generate random inputs from a seed and compare the chunked tree with the whole tree. |
| Attack input | A hand-written hostile input, for example 50,000 nested `>` or a 5,000-column table. |
| Corpus | The generated benchmark files, such as `mixed-10m` (10 MB of mixed Markdown). Deterministic from a seed. Not in git. |
| Bench | The gated timing and memory tests in `ParsingBenchmarks` (target `MEGAMarkdownBenchmarks`). |
| First content | The time from open until the first row is on screen. A preview measure, not a parser measure. |
| Peak memory | The highest process footprint during one measured operation, sampled from a background thread. |
| Gate | A pass or fail bound in a bench test, for example "chunked peak under half of whole". |
