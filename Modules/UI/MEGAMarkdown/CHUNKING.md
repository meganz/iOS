# MEGAMarkdown chunking reference

How a large Markdown file is cut into chunks that parse one at a time. This is the detail page for
the large-input layer. The [architecture guide](ARCHITECTURE.md) gives the overview. The parser
itself is described in [PARSER.md](PARSER.md).

[MarkdownChunker.swift](Sources/MEGAMarkdown/Parsing/MarkdownChunker.swift) is an internal helper.
The public `MarkdownParser.parse` does not use it. It always parses the whole input.

## Why chunks

cmark keeps the full syntax tree in memory. That tree is much bigger than the source text. The
[decision record](DECISIONS.md) holds the measured numbers. In short: a whole-file tree for a
10 MB file needs hundreds of megabytes. Chunks of about 1 MiB keep the peak at a few megabytes.
The first chunk can be shown before the rest is parsed.

Each chunk gets its own cmark tree. The tree is freed after the chunk is converted. Only one tree
lives at a time.

## What a chunk is

A chunk is a line range and a byte range of the source. The chunk parses to the same tree as the
whole file would give for that range. Tests check this for saved inputs, for every example in cmark's own spec files, and for random inputs.

```swift
struct Chunk: Equatable {
    var lines: Range<Int>      // source lines, 0-based
    var bytes: Range<Int>      // UTF-8 offsets in the source
    var isPlainText = false    // true: show this rest of the file as plain text, do not parse it
}
```

The chunker borrows a UTF-8 buffer. The buffer must stay valid while the chunker is used. It
indexes line starts for LF, CRLF, and CR input. It skips an initial UTF-8 byte-order mark.

## Why a blank line is not enough

Cutting at every blank line gives wrong output. A blank line can sit inside a block:

- A fenced code block can hold blank lines. A cut inside it breaks the fence.
- An HTML block can hold blank lines. It can even hold lines that look like fences.
- A link reference definition `[label]: url` can sit at the end of the file. A link `[text][label]`
  in an earlier chunk needs it.

So the chunker only cuts where a cmark probe confirms that the last block is closed. It also
collects the reference definitions of all chunks and shares them.

## Choosing a cut

1. **Find a candidate.** Walk forward from the chunk start for at least the target size (1 MiB by
   default). Then take the first line that follows a blank line and starts a block at column zero.
   A line that starts with a space, a tab, or a list marker (`-`, `+`, `*`, `1.`, `1)`) is skipped.
2. **Probe the cut.** Parse only this chunk with cmark. Look at the last leaf block. A leaf block
   holds text, not other blocks: paragraph, heading, code block, HTML block, thematic break. The
   probe goes down through lists, items, and quotes to find it. If that leaf block reaches the
   chunk's last line, the cut is unsafe. An open fence or an HTML block can cause this. See
   [CmarkParser+ChunkProbe.swift](Sources/MEGAMarkdown/Parsing/CmarkParser+ChunkProbe.swift).
3. **Grow on an unsafe cut.** Double the minimum size and search again from the same start. The
   doubling keeps the number of probe parses small for a file with many unsafe cuts. Tests read
   `rejectedCuts` to check this.
4. **Stop at the cap.** If the chunk would exceed the cap (8 MiB by default), return the rest of the
   file as one chunk with `isPlainText = true`. A consumer must display that remainder as plain
   text. It must not send it through the cmark path.

A single chunk that covers the whole file is not probed. There is nothing to learn or check.

The cap limits the work of one chunk parse. It does not cap total input or result memory. The
caller still owns the source, the line index, the collected definitions, and any retained blocks.

## Sharing reference definitions

A reference such as `[see][late]` can depend on a definition in a later chunk. The chunker handles
this in two steps.

1. **Loose scan.** Find every `[label]:` in the chunk by looking for `]:` and walking back to the
   unescaped `[`. This can report labels that are not real definitions.
2. **Let cmark decide.** The probe parse puts one paragraph `[label]` per found label in front of
   the chunk, each followed by a blank line. After the parse, a probe paragraph that is exactly one
   link means the chunk holds a real definition for that label. The link gives the URL and title.

Confirmed definitions are rebuilt as Markdown lines, `[label]: <url> "title"`, in
`definitionPrefix(for:)`. The URL and title are backslash-escaped on Unicode scalars, so a title
cannot start a new block and a combining mark after `<` cannot hide it. `&` is written as `&amp;`,
because cmark decodes entities before backslashes. A line break that cmark decoded from `&#10;` or
`&#13;` is written back as that entity, so each definition stays one line. A blank line ends the
prefix. `definitionLineCount(for:)` is the number of lines in the prefix. A label that was already
seen keeps its first definition, as CommonMark requires. Labels are compared as UTF-8 bytes, like
cmark does. Swift `String` equality would merge `é` and `e` + U+0301 into one label and drop the
second definition. A chunk after the first always gets at least
one empty line in front: cmark drops a byte order mark on its first line, and only the file start
may lose one.

When a cut is not safe the chunk doubles. When doubling would pass the 8 MiB cap, the next few
candidates are tried one by one (`maxStepsAfterDoubling`), so a safe cut under the cap is not skipped.

## How a consumer parses chunks

The [chunk parity helper](Tests/MEGAMarkdownTests/ChunkedParseTests.swift) shows the intended use:

1. Call `next()` until it returns `nil`. Collect all chunks first. This also collects all
   definitions.
2. Parse each chunk with `definitionPrefix(for: chunk)` in front. The preview parses each chunk right
   away, so a reference to a definition in a later chunk stays literal text. The parity helper
   collects all chunks first, so it does not show this limit.
3. Pass `lineOffset = chunk.lines.lowerBound - definitionLineCount(for: chunk)` to the tree walker. This removes
   the prefix lines and restores document-relative line numbers.
4. Carry the last block line from one chunk to the next. The walker uses it for nodes without a
   cmark position.
5. Append each chunk's top-level blocks to the same block array. Free the cmark tree after each
   chunk.

## Origin of the design

The design is specific to this package. It builds on the CommonMark parsing strategy: block
structure is found first, inline text is parsed after, and link reference definitions are
collected during the block phase. That is why a cut between closed top-level blocks is safe.
See the [CommonMark spec appendix](https://spec.commonmark.org/0.31.2/#appendix-a-parsing-strategy).

The probe rule ("does the last leaf block reach the last line") and the definition prefix are
this package's own additions. Related tools solve a different problem: cmark's streaming input
still builds one tree, and incremental editor parsers reparse edited regions rather than bounding
memory.

## Tests for this layer

| Coverage | Where to read |
|---|---|
| Whole versus chunked syntax trees | [ChunkedParseTests.swift](Tests/MEGAMarkdownTests/ChunkedParseTests.swift) checks 208 saved inputs at several chunk sizes and seeded fuzz cases. |
| Byte ranges, Unicode, line endings, BOMs, and late definitions | [ChunkerEdgeTests.swift](Tests/MEGAMarkdownTests/ChunkerEdgeTests.swift). |
| Every CommonMark and GFM spec example | [SpecCorpusChunkTests.swift](Tests/MEGAMarkdownTests/SpecCorpusChunkTests.swift) runs the 742 examples from cmark's own test files. Each example is cut at targets of 1, 2, 5, 13, and 50 bytes, so a cut lands inside each construct. A seeded fuzz joins 2 to 8 random examples with an empty, single, or double newline separator. |
| Pathological inputs | [PathologicalInputTests.swift](Tests/MEGAMarkdownTests/PathologicalInputTests.swift) also chunks each input from cmark's `pathological_tests.py` at a 4 KiB target and compares with a whole parse. |
| Time, peak memory, and input-size scaling | [ParsingBenchmarks.swift](Tests/MEGAMarkdownBenchmarks/ParsingBenchmarks.swift), run with `scripts/benchmark.sh`. |

The spec examples live in [Fixtures/cmark-spec](Tests/MEGAMarkdownTests/Fixtures/cmark-spec/NOTICE.md). They are copied unchanged from the swift-cmark test folder at the pinned revision. [PARSER.md](PARSER.md#cmark-owns-syntax-recognition) describes the revision check and the refresh script. [SpecCorpus.swift](Tests/MEGAMarkdownTests/SpecCorpus.swift) reads them the same way as cmark's `spec_tests.py`: the Markdown between a 32-backtick `example` line and a `.` line, with `→` as a tab. Disabled examples are skipped. The chunk tests use only the Markdown input of each example. The expected HTML is not compared.

Chunk benchmarks that use `ParsedBlock` measure a different path from whole public parsing, which
includes attributed-text conversion. See [Testing](ARCHITECTURE.md#testing) for the environment
variables that enable the fuzz count, extra chunk files, and benchmarks.
