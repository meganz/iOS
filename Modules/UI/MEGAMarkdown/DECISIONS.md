# MEGAMarkdown decisions

Why the package is built this way.


| Decision | Picked | Alternatives and why not |
|---|---|---|
| Block parser | cmark-gfm via `swiftlang/swift-cmark` (C, BSD-2), pinned `exact: "0.9.0"`. 10 MB in 136 ms. Same blocks, lines, links and tables as Foundation on every corpus and tricky input. | • **Foundation `AttributedString(markdown:)`**: 10 MB in 8.4 s. Wide table (5,000 cols) over 60 s vs 0.28 s.<br>• **`mity/md4c`**: fastest, but no block positions. 10 memory-safety bugs found by OSS-Fuzz in 2026. The app opens untrusted files.<br>• **`github/cmark-gfm` upstream**: no `Package.swift`. Last release 2023. swift-cmark is its maintained SPM fork.<br>• **`Down`, `Ink`**: unmaintained. Down has no GFM. Ink gives HTML only and crashed on 100k `[`.<br>• **swift-markdown-ui, Textual**: renderers. Textual uses Foundation, same cost. |
| Document model | `MarkdownDocument` holds a flat `[MarkdownBlock]` of top-level blocks. Only lists and quotes hold child blocks, so the tree starts below the top level. A consumer iterates the array as rows and maps a row index to a block. Chunked parsing appends each chunk's top-level blocks to the same array. | • **A root `Block` with children**: the root would need an ID, a source line and a `kind` that mean nothing. Every consumer would unwrap it first to reach the rows. Chunked results would need a merge of root nodes instead of an array append. This is the shape of the cmark tree and `swift-markdown`'s `Document`, which the package reads but does not keep (see API level). |
| API level | cmark C API directly, own tree walker with `cmark_iter`. No second tree, no recursion. | • **`swiftlang/swift-markdown`**: same C parser, plus a recursive copy to a Swift tree. 10 MB in 868 ms vs 136 ms, 2x memory. Stack overflow on 50,000 nested `>`. No autolink extension. Tree not `Sendable`. |
| Inline model | Compact `InlineText` (`String` + `Int32` runs). `AttributedString` is built later, so a preview can convert only visible blocks. 10 MB in 264 ms. | • **`AttributedString` during the walk**: 10 MB in 2.2 s, about 5x more memory. 98% of Foundation's time was attributed-string building. |
| Large input | Chunks of about 1 MiB, cut only where a cmark probe says the last leaf block is closed. Grow 2x on a rejected cut. Cap 8 MiB, then plain text. iPhone 15, 10 MB: peak 15 MB. First content 173 ms (simulator). | • **Whole-file tree**: about 20 MB per MB of input (2 GB at 100 MB). iPhone 15, 10 MB: peak 491 MB. First content 11.9 s (simulator).<br>• **Cut at blank lines, parse parts in parallel**: old prototype gave 11 wrong outputs, 7 visible (fence lines inside HTML, hidden definitions). |
| Preview list container | A `UICollectionView` with its own layout on a prefix-sum height tree (`MarkdownRowLayout`), and every row a hosted SwiftUI `PreviewRowView`. When it was chosen (simulator, 100 MB): open 0.05 s, 100 screens 5.45 s, jump to the end 0.03 s. | • **UIKit text cells for text rows, hosted rows for the rest**: scrolled about 28% faster, but opened and jumped slower, and two renderers must look the same.<br>• **SwiftUI `List`**: jump to the end 48.8 s at 20 MB and 168.9 s at 50 MB. At 100 MB it ran out of memory. Open 3 to 4 times slower.<br>• **`LazyVStack`**: iOS ended the app in 3 of 4 scrolls through a 50 MB file on an iPhone 15. |
| Preview data source | A classic `UICollectionViewDataSource` with item indexes. The caller keeps the row identity. | • **Diffable data source**: the first apply took 1.30 s for 67,000 rows, 7.35 s for 335,000 and 43 s with 3 GB more heap for 1.68 million.<br>• **Compositional layout with estimated heights**: open grew from 1.3 s at 2 MB to 42 s at 50 MB. |
| Preview loading | The pipeline sends the rows of each chunk as a batch, and the list appends them with a height guess each. Simulator, 10 MB: the first rows show after 0.17 s, and the longest main-thread stall while all batches arrive is 40 ms. | • **Guess every row on the main thread when the list opens**: 10 MB open blocks the main thread for about 100 ms.<br>• **Parse again and swap all rows**: a swap must keep the reading place, and it reloads the list. |
| Layout animation | Each layout pass of the list runs without animation. | • **UIKit default**: cells that size themselves animate. Rows slid in from far away while scrolling. On an iPhone 15 at 50 MB, the longest stall went from 409 to 571 ms down to 155 to 170 ms with no animation. |
| Rich import check | The import exports its rows, parses the export, and compares the meaning with the parse of the file. A block that changes stays raw. | • **Rules per construct**: each rule guesses from line patterns which source would lose bytes. A missed case loses content silently. The check finds every case, at the cost of one more parse and the export that the save check needs anyway. |
| Link in the rich model | `RichLink` keeps the destination as cmark gives it, and the title. | • **`URL`**: `URL(string:)` encodes the text, so the export would write another destination. A title had no place, so a link with a title stayed raw. |
| Typed link URL | The typed text is saved as written. Empty text, text with spaces and `javascript:` are refused. | • **Add `https://` to bare hosts**: `docs/guide.md` and `mega.nz/help` look the same, so any rule guesses wrong for some input. CommonMark and RFC 3986 accept a relative path, and the Android editor saves the text as typed. • **Add it only for `www.`**: it is not needed to keep a link valid, and a later change can add it. |
| Rich undo | A step keeps the rows it replaced and the selection. | • **Whole document per step**: 50 steps of a 500,000 character document keep 50 row arrays. |
| Code in a right-to-left layout | A code block stays left to right: its text, its side scroll and its language label. The block itself still sits in the right-to-left layout. | • **Mirror like other text**: code is written left to right. Right-aligned lines hide the indent, and the side scroll would start at the end of the line. |

## Preview display rules

The rule for each choice: keep what matches GitHub. Else follow a standard. Else follow the Android preview
(`feature/text-editor`, develop e430b4c2ee). Paths below are in that Android module.

| Topic | Rule | Why |
|---|---|---|
| Blocks inside a list item or quote | 4 pt between them (`nestedBlockSpacing`). Top-level blocks keep `blockSpacing`. | Android `MarkdownBlockFrame.kt:55-57` (4 dp nested). |
| Text direction | A paragraph, heading or list item takes the direction of its first strong letter. A right-to-left row is right-aligned, with its marker on the right. Quote bars follow the layout. Tables and code stay left to right. | Standard: UAX #9 rules P2 and P3, like HTML `dir="auto"`. Tables: GitHub. |
| Ordered list with `)` | Shows "1.", like any ordered list. The model keeps no delimiter. | GitHub shows "1." too. |
| Ordered task item | Shows the checkbox, not the number. | GitHub hides the number of a task item. |
| Newline inside inline HTML | An unmatched tag stays literal, with its own newline. See PARSER.md "Inline HTML styles". | Android hides inline HTML. Showing raw text keeps every byte visible. |
| Hyphens | Kept. SwiftUI `Text` may add a hyphen when it breaks a long word, also in a table cell URL ("www.github.-com"). Known limit. | SwiftUI has no public switch for hyphens. Typesetting the text as "zxx" (no language) stops them, but it also drops the line height of the reader's language. That can cut the accent marks of Vietnamese text. |
| Inline code chip spacing | The box grows 3 pt (2 pt padding and the 1 pt border) but stays 2 pt from the word next to it. Two chips across one space meet halfway, 2 pt apart. At the start or end of a line the box reaches 3 pt past the text edge. | Figma for the padding and the edge. Android `MarkdownInlineCodeChips.kt:101-108` for the word spacing. |
| Inline code lines | Every line of a paragraph with inline code is as tall as the chip: a body line plus the border above and below. Lines have a 2 pt gap. The code is raised so its glyphs are centered on the body text. Preview and editor draw this text with TextKit 1 and `InlineCodeLayoutManager`. | Figma. SwiftUI `Text` sizes a line of only code by the mono font and has no line height before iOS 26, so it cannot keep these lines. |
| Footnotes | Off. `[^1]` stays text or a link definition, like any label. | Android has no footnote extension. |
| Link with empty text | Draws nothing, so it cannot be seen or tapped. | GitHub draws an empty `<a>` as nothing too. |
| Quote bar | One unbroken bar through the whole quote, also across rows. | Android `MarkdownBlockFrame.kt:207-212`, GitHub `border-left`. |
| Two links side by side | No added space. They can read as one link. Each part opens its own URL. | GitHub shows the same. |
| Table column width | Fixed 140 pt columns. A wide table scrolls sideways. | Android `MarkdownNode.kt` (140 dp). |
| Linked image with empty alt text | Draws nothing. Known limit for now. A later version may show the file name as link text. | Android and the browser rule for `alt=""`. |

## Editor UI

| Topic | Rule | Why |
|---|---|---|
| Source mode text system | TextKit 1. | In a 10 MB file a key at the end took 877 ms worst case on TextKit 2 and 0 to 22 ms on TextKit 1. A 100 MB file only opens on TextKit 1. Writing Tools shows its panel only. |
| Empty row | No placeholder text. | The row keeps the font of its kind, so the caret has the height of the text. |
| Paste into a code block | Plain text. Other rows read Markdown first. | Code is plain text. Markdown marks or fences would end up in the code. |
| Copy | One pasteboard item with plain text and Markdown. | Other apps read the plain text. The editor reads both types. |
| Copy of a part of a code block | Markdown type: the code as escaped text. A private marker type (`nz.mega.markdown.code-part`) tells source mode to paste the plain text, the raw code. A part of several lines pastes into a text block as one paragraph with its lines, without indents or empty lines. | A rich paste reads Markdown first, so raw code like `a*b*c` would turn into formatting. Source mode pastes Markdown as text, and CommonMark reads no escapes inside a code fence, so escaped code would keep its backslashes there. A Markdown paragraph cannot keep leading spaces or empty lines, so no paste into a text block can keep them. Rejected: a part of several lines as a fenced code block, which keeps every character but changes what a paste into a paragraph makes. |
| Copied list rows that start deeper | The first item of each copied list run moves to level 0. A later item nests only under an earlier item of a smaller indent. Ordered items get their numbers after this move, so rows that end up as siblings count up as one list. | A Markdown list starts at level 0. With the old indents, a later, shallower item would nest under the first one. Numbers taken from the old indents would give a sibling its own start number, and the export would then start a second list. Rejected: keeping the old indents, which changes the nesting on paste. |
| Own save | The binding gets the Markdown after 1 s idle, on a mode switch, on disappear and on resign active. | The binding is the only save channel. |
| Loaded text after a save | Not the editor's own text any more. It reloads rich mode. | A host that sets the original text back expects to see it. |
| Block over 100,000 units | Rich mode refuses the file and shows the source with a notice. | One text view holds a whole block, and a key costs time in proportion to its length. |
| Code lines | Wrap in the editor. The preview scrolls them sideways. | An editable text view has no sideways scroll per row. |
| Indented raw block after a list item | The export removes the 1 to 3 spaces before its first line, and up to as many from each later line. An HTML block (first character `<`) loses only the spaces of its first line. | Indented that far, the block would become part of the item on reopen. Outside a list the spaces change nothing, except in an HTML block: CommonMark keeps its lines as they are, so its later lines keep their spaces. Once the first line is outside the item, the item is closed, so the later lines cannot join it. Rejected: an empty HTML comment line before the block, which keeps it byte for byte, but this package shows HTML blocks as text, so the line would show in the preview and in rich mode. |

## Selection over rows

| Decision | Picked | Alternatives and why not |
|---|---|---|
| Selection over rows | Inside one row the text view keeps its own selection. When a handle drag leaves its row, a layer on the list takes the touch over. It moves the head with the finger, scrolls the list near its edges, and gives the model the selection when the finger lifts. Simulator, a mixed text of about 480,000 characters (`SelectionBenchmarks`): 10,000 pt of autoscroll take 7.25 s with a selection and 7.24 s without. The package supports iOS 17, but the selection display, the handle zones and the drag cancel are checked only on iOS 18.6 and 26.4. | • **One text input over the whole document**: about 40 `UITextInput` methods over rows that may have no cell, and it fights each row's text view for the keyboard.<br>• **Rows of whole blocks only (a select mode)**: no selection inside a text.<br>• **Merge neighbour rows into one text view**: breaks one row per block, and still stops at lists, code and dividers. |
| Highlight and handles of a selection over rows | `UITextSelectionDisplayInteraction` on the list, fed by a small `UITextInput` that gives the carets and rects of the rows on screen. The handles and the highlight look like the system's. | • **TextKit temporary attributes**: they exist only on macOS.<br>• **A drawn overlay in each row and a tint on divider rows**: works, but needs code in every row and a new row configuration for dividers. |
| Preview selection | Whole blocks only, across blocks. A long press selects one block, the handles grow the selection block by block, and Copy writes plain text. It shares the selection display, the handles and the autoscroll with the editor. | • **Character selection with SwiftUI `Text`**: needs own glyph geometry, through `TextRenderer` on iOS 18 and later only.<br>• **A `UITextView` per text row**: a second renderer that must look the same, and more memory per row. |
| Edit menu of a selection over rows | The menu sits on the keyboard responder of the list and shows the edit actions that responder can do. The items are the system's, already translated, and ⌘C, ⌘X, ⌘V and ⌘A run the same actions. | • **A menu on the list view**: the system items check the list view's responder chain, which cannot copy, so no item shows. Own items would need five new strings. |

## Source of truth

Each parser behaviour has one source of truth. A bug is output that differs from it, when no rule below explains the difference. Any other difference is a product decision. Add it to this file first, then change the code.

| Behaviour | Source of truth | Checked by |
|---|---|---|
| CommonMark blocks and inlines | The HTML of cmark-gfm from the pinned `swift-cmark`, for the same input and the same extensions. | `CmarkReferenceTests`: every spec example, every fixture file, and 3,000 seeded mutations of spec examples. |
| GFM tables, strikethrough and autolinks | The same cmark HTML. | `CmarkReferenceTests`. |
| Task items | The GFM task list rule, with two fixes to cmark's `tasklist` extension (see "Task items"). | `ParsingNestingTests` and `ParserEdgeCaseTests`. The cmark comparison ignores task markers. |
| Style tags like `<b>` and `<u>` | Bare tags for bold, italic, strike, code and underline. The names and the pairing rule live in `StyleTag.swift`. | `ParsingStyleTagTests`. The cmark comparison pairs tags with the same `StyleTag` rule (R5). |
| Link and image URLs | RFC 3986. The URL keeps the destination cmark gives, encoded once. | Fixed strings in `ParsingInlineTests`. |
| Display rules for the viewer | The rules R1 to R6 below. | `CmarkReferenceTests` checks that each rule is still needed. |
| Chunked parsing | A whole-file parse of the same text. | `ChunkedParseTests`, `ChunkerEdgeTests` and `SpecCorpusChunkTests`. |
| Pathological inputs | cmark's `pathological_tests.py`. | `PathologicalInputTests`. |

Golden snapshots (`ParserGoldenTests`, `SpecCorpusGoldenTests`) are not a source of truth. They only show which outputs a change touches.

Foundation's `AttributedString(markdown:)` is not a source of truth. Its output changes with the OS, and the old viewer never shipped. `SpecCorpusParityTests` still compares with it when `MARKDOWN_FOUNDATION_PARITY=1` is set.

The cmark comparison renders the parser output as cmark HTML. A canonical form removes what the model does not keep: tight or loose lists, the order of nested style tags, split text runs, and the alignment of empty cells. Raw HTML is compared as text on both sides.

## Intended differences from cmark

Each rule has the same ID in `CmarkReference.rules`. A test fails when a rule no longer changes its example.

| ID | Rule | Why |
|---|---|---|
| R1 | A block with no content is dropped: an empty heading or code block, a quote or list item with no content, and a table body row of empty cells. A code block counts as empty after R2, so a block of only blank lines is dropped. A line of spaces is content. An ordered list then starts at its first kept item. An empty task item stays. | The viewer has nothing to show for an empty row. An empty task item stays, because `- [ ] ` is a valid task marker. |
| R2 | A code block loses all trailing newlines. cmark keeps the blank lines before the closing fence. | Trailing blank lines would show as empty space at the end of the block. |
| R3 | An image inside a link shows its alt text as the link text. | The model has one link per text run, so an image cannot sit inside a link. |
| R4 | An image block has no title. An inline image keeps its title. | `ParsedBlock.Kind.image` has no title. |
| R5 | Matched bare style tags style the text between them and are removed. | Markdown has no syntax for underline, and `**`, `_`, `~~` or backticks do not always parse, for example `_` inside a word. These tags still give the style. |
| R6 | A link inside a link keeps only the inner link. cmark nests an autolink inside link text. | The model has one link per text run. |

A line break inside image alt text becomes a space, like cmark writes it. The words of the alt text stay apart.

## Task items

| Rule | cmark's `tasklist` extension | This package |
|---|---|---|
| Marker | `[ ]`, `[x]` or `[X]` right after the list marker, then a space or tab on the same line. | The same. |
| Checked state | True when `[x]` appears anywhere on the line, so `- [ ] see [x]` is checked. | Read from the marker itself. |
| Marker after `>` or after a second list marker (`> - [x] a`, `- - [x] a`) | Not found. The marker stays text. | Found at the start of the item's first paragraph. |
| Escaped marker `\[x]` or entity `&#91;x&#93;` | Text. | Text. |
| Marker that cmark already read as a reference link, like `[x]` with a `[x]: /url` definition | A link, when the marker is after `>` or a second list marker. | The same. |
| Spaces after the marker | Removed. A space written as `&#32;` stays. | The same. |

GitHub.com is not the source of truth for task items. It turns an escaped `\[x]` into a checkbox, and a `[x]: /url` definition wins over the marker even at the line start. The package follows cmark, with the two fixes above.

## Reporting a parser bug

Check every report against the "Source of truth" table before you change code.

1. Find the row for the behaviour, for example task items, link URLs or tables.
2. Compare the output with that source of truth. For syntax, run the cmark comparison on the input. For the other rows, read the rule in this file and its tests.
3. Sort the report with the table below.
4. Give three things in the report: the input, the source-of-truth output and the parser output. "GitHub does X" or "I expect Y" alone is not enough.

| Result | Meaning | Next step |
|---|---|---|
| The output differs, and no rule here explains it. | A bug. | Fix it, and add the input as a test. |
| The output differs, and a rule here explains it (R1 to R6, or "Task items"). | Intended. | No change. |
| The output matches the source of truth, but another output is wanted. | A product decision. | Change this file first, then the code and its tests. |

Run the cmark comparison on one input from the package folder:

```sh
export TEST_RUNNER_MARKDOWN_REFERENCE_FILES=/absolute/input.md
export TEST_RUNNER_MARKDOWN_REFERENCE_REPORT=/absolute/report.txt
xcodebuild test -scheme MEGAMarkdown \
  -destination 'platform=iOS Simulator,id=<SIMULATOR_UDID>' \
  -skipPackagePluginValidation SWIFT_SUPPRESS_WARNINGS=NO \
  -only-testing:MEGAMarkdownTests/CmarkReferenceTests
```

The report file lists every difference, with the cmark output and the parser output in canonical form.

When an AI tool checks a parser change, start the request with this text:

```text
Check MEGAMarkdown parser changes against Modules/UI/MEGAMarkdown/DECISIONS.md.
Each parser behaviour has one source of truth, listed in "Source of truth".
For each problem:
- Give the input, the source-of-truth output, and the parser output.
- Say which source of truth applies.
- If a rule in "Intended differences from cmark" or "Task items" explains
  the difference, it is not a bug. Do not report it.
- If the output matches the source of truth but should change, label it
  "product decision", not "bug".
For syntax problems, run the cmark comparison in "Reporting a parser bug".
```
