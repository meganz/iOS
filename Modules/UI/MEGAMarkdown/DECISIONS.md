# MEGAMarkdown decisions

Why the package is built this way.


| Decision | Picked | Alternatives and why not |
|---|---|---|
| Block parser | cmark-gfm via `swiftlang/swift-cmark` (C, BSD-2), pinned `exact: "0.9.0"`. 10 MB in 136 ms. Same blocks, lines, links and tables as Foundation on every corpus and tricky input. | • **Foundation `AttributedString(markdown:)`**: 10 MB in 8.4 s. Wide table (5,000 cols) over 60 s vs 0.28 s.<br>• **`mity/md4c`**: fastest, but no block positions. 10 memory-safety bugs found by OSS-Fuzz in 2026. The app opens untrusted files.<br>• **`github/cmark-gfm` upstream**: no `Package.swift`. Last release 2023. swift-cmark is its maintained SPM fork.<br>• **`Down`, `Ink`**: unmaintained. Down has no GFM. Ink gives HTML only and crashed on 100k `[`.<br>• **swift-markdown-ui, Textual**: renderers. Textual uses Foundation, same cost. |
| Document model | `MarkdownDocument` holds a flat `[MarkdownBlock]` of top-level blocks. Only lists and quotes hold child blocks, so the tree starts below the top level. A consumer iterates the array as rows and maps a row index to a block. Chunked parsing appends each chunk's top-level blocks to the same array. | • **A root `Block` with children**: the root would need an ID, a source line and a `kind` that mean nothing. Every consumer would unwrap it first to reach the rows. Chunked results would need a merge of root nodes instead of an array append. This is the shape of the cmark tree and `swift-markdown`'s `Document`, which the package reads but does not keep (see API level). |
| API level | cmark C API directly, own tree walker with `cmark_iter`. No second tree, no recursion. | • **`swiftlang/swift-markdown`**: same C parser, plus a recursive copy to a Swift tree. 10 MB in 868 ms vs 136 ms, 2x memory. Stack overflow on 50,000 nested `>`. No autolink extension. Tree not `Sendable`. |
| Inline model | Compact `InlineText` (`String` + `Int32` runs). `AttributedString` is built later, so a preview can convert only visible blocks. 10 MB in 264 ms. | • **`AttributedString` during the walk**: 10 MB in 2.2 s, about 5x more memory. 98% of Foundation's time was attributed-string building. |
| Large input | Chunks of about 1 MiB, cut only where a cmark probe says the last leaf block is closed. Grow 2x on a rejected cut. Cap 8 MiB, then plain text. iPhone 15, 10 MB: peak 15 MB. First content 173 ms (simulator). | • **Whole-file tree**: about 20 MB per MB of input (2 GB at 100 MB). iPhone 15, 10 MB: peak 491 MB. First content 11.9 s (simulator).<br>• **Cut at blank lines, parse parts in parallel**: old prototype gave 11 wrong outputs, 7 visible (fence lines inside HTML, hidden definitions). |
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
| Inline code chip spacing | The box grows 2 pt but stays 2 pt from the word next to it. Two chips across one space meet halfway, 2 pt apart. | Android `MarkdownInlineCodeChips.kt:101-108`. |
| Footnotes | Off. `[^1]` stays text or a link definition, like any label. | Android has no footnote extension. |
| Link with empty text | Draws nothing, so it cannot be seen or tapped. | GitHub draws an empty `<a>` as nothing too. |
| Quote bar | One unbroken bar through the whole quote, also across rows. | Android `MarkdownBlockFrame.kt:207-212`, GitHub `border-left`. |
| Two links side by side | No added space. They can read as one link. Each part opens its own URL. | GitHub shows the same. |
| Table column width | Fixed 140 pt columns. A wide table scrolls sideways. | Android `MarkdownNode.kt` (140 dp). |
| Linked image with empty alt text | Draws nothing. Known limit for now. A later version may show the file name as link text. | Android and the browser rule for `alt=""`. |

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
