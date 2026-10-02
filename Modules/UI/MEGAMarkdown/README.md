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

## Architecture

See the [architecture guide](ARCHITECTURE.md) for the layers, the document model, and testing guidance. The guide grows with the implementation as rendering and editing are added. The [parser reference](PARSER.md) and the [chunking reference](CHUNKING.md) hold the details of the implemented layers.

The [decision records](DECISIONS.md) explain why the package is built this way, with the measured data. The [terminology](TERMINOLOGY.md) defines the terms used in the docs, the code, and the tests.

## Benchmarks

```sh
bash scripts/benchmark.sh Modules/UI/MEGAMarkdown                          # from the repo root
bash scripts/benchmark.sh Modules/UI/MEGAMarkdown --only ParsingBenchmarks/testParseTwoMegabytes
```

- The `MEGAMarkdownBenchmarks` target measures the parser with `XCTestCase.measure(metrics:)`: clock, CPU, and the peak heap growth sampler of `Modules/Infrastracture/MEGABenchmark`. See that package's README.
- It runs only with `TEST_RUNNER_MEGA_BENCH=1`. The script sets it, builds Release with testability, runs one test at a time with no coverage, and writes `report.md`, `metrics.json` and `result.xcresult` under `derivedData/benchmarks/`. Without the variable the benchmarks are skipped, and the report then fails on the skipped tests.
- The script fails when a test did not pass, when a test or metric named in `Tests/MEGAMarkdownBenchmarks/Limits.json` is missing, or when an average is outside its limit. The limits come from `--write-limits` on an iPhone 17 Pro iOS 26.4 simulator Release run, the device CI uses (3x the average for time, 1.5x for memory). They are a policy that catches a big regression, not a tight bound.
- `testChunkedParseUsesLessMemoryThanWholeParse` keeps the chunked parse under half the heap of a whole parse, and under 150 MiB.
