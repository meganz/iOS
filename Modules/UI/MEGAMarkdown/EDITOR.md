# MEGAMarkdown rich editor model reference

The model layer of the rich editor: the document model, Markdown import and export, editing, undo, the
clipboard and the save check. It lives in the `MEGAMarkdownEditor` target. The [architecture guide](ARCHITECTURE.md)
gives the overview. The parser it builds on is in [PARSER.md](PARSER.md).

A UI shows `rows` and `selection`, and calls one `RichEditor` method for each user action.
No method needs UIKit or SwiftUI, and every method is synchronous.

## Document model

[RichDocument.swift](Sources/MEGAMarkdownEditor/Model/RichDocument.swift) and
[RichText.swift](Sources/MEGAMarkdownEditor/Model/RichText.swift) define the values.

| Type | What it holds |
|---|---|
| `RichDocument` | A flat list of `RichBlock`s and the `RichFileFormat`. |
| `RichBlock` | One row: paragraph, heading, list item, quote, code block, divider, or raw source. |
| `RichListItem` | Ordered or not, indent, task state, and the start number of the first item of a run. |
| `RichText` | Plain text and style spans. No Markdown syntax inside. |
| `RichSpanStyle` | Bold, italic, underline, strikethrough, code, or a link (`RichLink`: destination and title). |
| `RichFileFormat` | Line ending, byte order mark, and whether the last line ends with a line end. |

Rules of the model:

- Lists and quotes are flat rows with an indent or a depth, like the Android editor.
- A list item is at most one level deeper than the list item before it. `RichEditor` keeps this after every edit.
- Offsets are UTF-16 code units, like `NSRange`. Text is sliced on Unicode scalars, so a combining mark stays in place.
- "\n" in a text is a soft break and U+2028 a hard break. Both stay inside the block.
- Spans are always normalized: sorted, inside the text, not empty, and touching spans of one style joined.
- `RichText`, code, code languages and raw source compare by bytes. `String ==` would call "é" and "e" + U+0301 equal, and their offsets differ.
- A character has at most one link. Every other style mix can be saved, also code inside a link.
- `.rawSource` holds Markdown the model cannot edit (tables, images, HTML, lists with block content). It is read-only and saved byte for byte.
- A divider or raw block has no text. Its caret positions are 0 (before it) and 1 (after it).
- A view that renders one raw block alone puts `referenceDefinitionSource` in front of it: the link reference definitions of all raw blocks. So `[text][label]` in a raw table resolves like in the whole file.

## Import

`RichMarkdownConverter.load(_:)` ([MarkdownImporter.swift](Sources/MEGAMarkdownEditor/Conversion/MarkdownImporter.swift))
turns Markdown into a `RichImport`: the document, its export, and the export cache.

1. `MarkdownSourceText` takes off the byte order mark, the line ending and the last line end. The blocks always use "\n". A file of only line ends has no blocks, and it saves as an empty file.
2. YAML front matter (`---`, a non-blank line, then `---` or `...`) becomes a raw block.
3. `CmarkParser.editorBlocks` parses in editor mode (see "Editor mode" below). It gives each top-level block its first and last source line.
4. `RichBlockConversion` turns each top-level block into rows, or gives nil when the model cannot hold it. Then the block's source lines become a raw block.
5. A converted block with a line that looks like a link reference definition stays raw: the definition would be lost on save.
6. Lines between blocks that are not blank (definitions) become raw blocks. Neighbour raw blocks join with the lines between them, so their spacing stays exact.
7. Two lists of the same kind, or two quotes, next to each other get an empty paragraph between them. The exporter starts a new list or quote after it.
8. The import checks itself: it exports the rows, parses the export, and compares it with the parse of the file using `ParsedBlockEquivalence`.
   A block that does not come back the same becomes raw, and the check runs again.

`ParsedBlockEquivalence` compares what a reader sees. It ignores source lines, list markers, tight or loose lists,
and how style runs were split. So `* a` and `- a` are equal, and `*a*` and `_a_` are equal.

### Editor mode

`ParseMode.editor` in [CmarkParser.swift](Sources/MEGAMarkdown/Parsing/CmarkParser.swift) changes three
viewer rules (R1 and R2 in [DECISIONS.md](DECISIONS.md)), so the editor never loses a line:

- Empty headings, code blocks, quotes and list items stay.
- A code block keeps the blank lines before its closing fence. A block of only blank lines stays too. The viewer drops it.
- The alt text of an image inside a link keeps the image style, so it is not taken for link text.

## Export

`RichMarkdownConverter.markdown(from:cache:)` writes the document as Markdown
([MarkdownExporter.swift](Sources/MEGAMarkdownEditor/Conversion/MarkdownExporter.swift)).

| Block | Written as |
|---|---|
| Paragraph | Inline Markdown. An empty paragraph is not written. |
| Heading | `#` to `######`. A level 1 or 2 heading with a break is a setext heading (`===` or `---`) to keep the break. |
| List item | `-` or `1.`, with `[ ] ` or `[x] ` for a task, indented under its parent. |
| Quote | `> ` per depth. Rows of one quote are joined by a `>` line. |
| Code block | A backtick fence longer than any backtick run in the code. A tilde fence when the language has a backtick. |
| Divider | `---` |
| Raw source | The source, byte for byte. |

Blocks are separated by a blank line, and items of one list by a line end. Two lists next to each other use other
markers (`*` after `-`, `)` after `.`), so they do not join. A nested list that would read wrong without a blank line
gets one: an ordered list not starting at 1, or an empty first item, under an item with text.

[InlineWriter.swift](Sources/MEGAMarkdownEditor/Conversion/InlineWriter.swift) writes one text:

- It escapes syntax characters (`MarkdownTextEscaper`). It works on Unicode scalars, because cmark reads bytes.
- `https://` and `www.` are escaped, so typed text does not become a link on reopen.
- Styles are written as `**`, `*`, `~~`, `` ` ``, `<u>` and `[text](destination "title")`. A link whose text is its URL is an autolink, like `<https://mega.nz>`.
- The writer parses its output again. When the styles differ, it writes HTML tags (`<strong>`, `<em>`, `<del>`, `<code>`), which have no flanking rules.
- `InlineTextCleaner` first removes what a re-parse drops anyway: spaces and tabs at line edges, empty lines, and breaks at the text edges. A space inside a code span or a same-line link stays.

`InlineExportCache` keeps the written Markdown of each text. A save after one key writes only that text again.

## Editing

[RichEditor.swift](Sources/MEGAMarkdownEditor/Editor/RichEditor.swift) is a value type. Its methods by job:

| User action | Method |
|---|---|
| Open a file | `RichEditor(markdown:)`. Call it off the main thread for a large file. |
| Caret move or selection | `select(_:)`, `selectAll()`, `placeCaretAtEnd()` |
| Type, autocorrect, dictation | `replaceText(inBlock:range:with:)`, `insertText(_:)`, `didChangeText(inBlock:to:caret:)` |
| Enter | `insertParagraphBreak()` |
| Backspace | `deleteBackward()`, `deleteSelection()` |
| Style buttons | `toggleStyle(_:)`, `activeStyles`, `canApply(_:)`, `typingStyles` |
| Heading, list, quote, indent buttons | `apply(_:)` with a `RichBlockAction`, `headingLevel(at:)` |
| Task checkbox | `toggleCheckbox(at:)` |
| Link dialog | `linkTarget()`, `linkDraft(for:)`, `saveLink(_:urlText:label:)`, `removeLink(_:)`, `RichLinkURL.canSave(urlText:)` |
| Copy, cut, paste | `copy()`, `cut()`, `paste(_:)` |
| Undo, redo | `undo()`, `redo()`, `canUndo`, `canRedo`, `endTypingBurst()` |
| Save | `exportChanges()`, or `makeExportJob()` off the main thread and then `finishExport(_:)` |
| List numbers | `orderedNumbers()` |

- A `RichSelection` can span blocks. Block actions and styles apply to every selected block.
  A range that ends at offset 0 of a row selects nothing of that row. A block action skips it, and it does not count as selected text.
- Each row has a `RichRowID`. An edit keeps the identities of rows it does not replace, so a view keeps its text views.
- `lastChange` names the rows the last edit replaced, so a list view reloads only those.
- Typing styles follow the caret: the styles of the character before it. A link does not continue past its end.
  A style turned off at the caret stays off for typed text, also inside a styled word.
- Typing over a selection takes the styles of its first character.
- A typed link URL is saved as written (`www.mega.nz`, `README.md`, `docs/a.md`, `#top`). The model adds no scheme.
  Empty text, text with spaces and `javascript:` are refused.
  Saving a link keeps its title, also when the URL changes. The dialog has no title field. An unchanged URL with spaces stays valid.
- Enter continues a list or quote. On an empty item it removes one level. Backspace at a block start removes structure first, then joins.
- Enter on an empty last line of a code block leaves the block. A tap below a final code, divider or raw block adds an empty paragraph.
- Typing at a divider or raw block starts a new paragraph before it (caret 0) or after it (caret 1). A paste there goes before or after it.

## Undo

[RichUndoStack.swift](Sources/MEGAMarkdownEditor/Editor/RichUndoStack.swift) keeps up to 100 steps.

- A step holds only the rows it replaced and the selection before the change. Undo puts both back, with their row identities.
- Keys in one row form one step. `endTypingBurst()` ends it: a UI calls it after a pause. A caret move to another row or any other edit ends it too.
- Paste, cut, a style or block action, Enter and a join are one step each.

## Clipboard

[RichClipboard.swift](Sources/MEGAMarkdownEditor/Editing/RichClipboard.swift) holds the rules.
A copy gives one pasteboard item with two types:

| Type | Content |
|---|---|
| `public.utf8-plain-text` | The visible text, with no escapes. List items keep a `- `, `1. ` or `- [ ] ` marker. |
| `net.daringfireball.markdown` (`RichClipboardContent.markdownType`) | The Markdown of the selection. |

- A part of one block copies as inline Markdown, without its block syntax.
- A whole block or more copies as block Markdown. An ordered item keeps the number it shows.
- A paste reads the Markdown type first. Plain text from another app is read as Markdown too, so `**bold**` renders.
  Its soft breaks split paragraphs, so each line becomes a row.
- In a text block, a first pasted paragraph joins the text before the caret. Later pasted paragraphs take the kind of
  a list item or quote target. Other pasted blocks keep their kind. The text after the caret joins the last pasted paragraph.
- In a code block, the plain text goes in as code.
- A source mode can paste the Markdown type as text. That gives the Markdown syntax of a rich copy.

## Save check

[RichExportState.swift](Sources/MEGAMarkdownEditor/Editor/RichExportState.swift) compares exports, not the file:
a file that was not edited never saves, even when its Markdown would be written differently.

- `exportChanges()` returns the Markdown only when it differs from the last export. After undo back to the start it returns nil.
- A background export of an older version is dropped by `finishExport(_:)`. Its cache is kept.
- `holds(_:)` tells a UI whether a text is the last export, so its own save does not reload the editor.
  The loaded text counts only until the first export is given out. After that it is a revert from outside.

## Limits

- `RichTextLimit.maxLength` is 500,000 UTF-16 units. A larger text needs a source mode.
- `SourceTextLimit` checks the source mode limits: 100 MiB, and lines of at most 100,000 UTF-16 units.

## Known limits

| Case | What happens |
|---|---|
| A plain email address (`a@b.co`) | It becomes a mailto link after save and reopen. cmark joins text nodes before it looks for email addresses, so no escape keeps it plain. |
| Spaces or tabs at a line edge | They are dropped on save. A tab at a line start (`&#9;foo`) stays raw on load. |
| An empty paragraph or quote row | It is not saved. Markdown has no empty paragraph. |
| Mixed line endings | An edited file is saved with the line ending of its first line, raw blocks too. |
| Blank lines at the file end | An edited file keeps one last line end, not more. |
| A code block with one empty line | It is saved as an empty code block. |
| Syntax that changes but means the same | A setext heading with one line becomes `#`, indented code becomes fenced, `*` lists become `-`. |
| A raw HTML block that is not closed | Content written after it in rich mode can become part of it. |
| Quotes or lists deeper than 60 levels | They stay raw. |

## Tests and benchmarks

| Test | What it checks |
|---|---|
| `RoundTripCorpusTests` | Every cmark spec example loads, exports and parses to the same meaning, and the export is stable. |
| `GeneratedRoundTripTests` | Random rich documents export and import back to the same blocks. |
| `EditingSequenceTests` | Random edit sequences keep a valid state, undo and redo walk the whole history, and the result saves and loads back. |
| `ImportTests`, `ExportTests` | The import and export rules above. |
| `StructureEditingTests`, `EditorTests` | Enter, Backspace, block actions, typing, styles, links, undo and the save check. |
| `ClipboardTests` | Copy, paste, cut, and copy then paste for each block kind. |

`RichEditorBenchmarks` in the `MEGAMarkdownBenchmarks` target measures load, save, typing, Enter, Backspace, styles,
undo, copy, paste and cut at the rich limit. It uses the clock, CPU, peak heap growth, memory, and the import signposts
(`RichImportSignposts`). Run it with `scripts/benchmark.sh Modules/UI/MEGAMarkdown --only RichEditorBenchmarks`.
