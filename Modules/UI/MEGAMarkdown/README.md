# MEGAMarkdown

A Markdown renderer and a rich + source Markdown editor for SwiftUI.
It parses blocks with cmark-gfm (C, from `swiftlang/swift-cmark`). Everything else uses Apple APIs.

- Parsing: cmark-gfm (CommonMark + GitHub Flavored Markdown tables, strikethrough and autolinks).
- Inline-only text (`MarkdownLabel`): Foundation `AttributedString(markdown:)`.
- Rendering: SwiftUI, in lazy rows.
- Editing: rich mode has one `UITextView` per block. Source mode has one TextKit 2 `UITextView`.

It matches the Android text editor (`feature/text-editor/text-editor-snowflake-components`).

## Requirements

- iOS 17+
- Swift 6 tools, Xcode 16+

## Dependencies

| Package | Version | Products | Used for |
|---|---|---|---|
| `meganz/MEGADesignToken` | branch `main` | `MEGADesignToken` | colors, spacing, corner radius |
| `swiftlang/swift-cmark` | `exact: "0.9.0"` | `cmark-gfm`, `cmark-gfm-extensions` | the block parser (`MEGAMarkdown` target only) |

- We use swift-cmark because it parsed a 10 MB file in 135 ms, while Foundation `AttributedString(markdown:)` took 8.9 s and swift-markdown was about 5x slower and crashed on deeply nested quotes.
- The swift-cmark version is pinned. A new version can change the parser output, so it needs a review.
- `iMEGA.xcworkspace` pins it in its `Package.resolved` too (revision `08ddb528`).
