# cmark-gfm test corpus

Copied unchanged from `test/` in swift-cmark (https://github.com/swiftlang/swift-cmark) at the revision
in `REVISION`. That is the parser revision pinned in `Package.resolved`.

| File | What it holds |
|---|---|
| `spec.txt` | The CommonMark spec with its 672 examples |
| `extensions.txt` | GFM extension examples (tables, strikethrough, autolinks, task lists, tagfilter) |
| `regression.txt` | Past cmark bugs. Keeps its mixed CR / CRLF / LF line ends on purpose |
| `smart_punct.txt` | Smart punctuation examples |
| `REVISION` | The swift-cmark commit the files were copied from |

After a swift-cmark pin bump, run `bash scripts/refresh-cmark-spec.sh` from the package folder.
`SpecCorpusRevisionTests` fails until the copy matches the pin.

The spec files are licensed CC-BY-SA 4.0 (see each file's front matter).
`SpecCorpus.swift` reads them the same way as cmark's `spec_tests.py`.
