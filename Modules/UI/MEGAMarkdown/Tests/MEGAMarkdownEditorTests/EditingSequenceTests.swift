import Foundation
@testable import MEGAMarkdownEditor
import Testing

/// Random edit sequences on random documents. After each edit the editor state must be valid,
/// undo must walk back to the start, redo forward to the end, and the result must save and load back.
@Suite("Random edit sequences")
struct EditingSequenceTests {
    /// To replay one failing seed, set this to `[seed]` while you debug. Do not commit that change.
    /// For a deeper check, widen the range for one local run.
    static let seeds: [UInt64] = Array(0..<200)

    @Test func editsKeepTheEditorValid() {
        var failures: [String] = []
        for seed in Self.seeds {
            var generator = RichDocumentGenerator(seed: seed)
            var random = SeededGenerator(seed: seed &+ 1_000_000)
            let start = generator.document(blockCount: 6)
            var target = editor(start)
            var log: [String] = []
            for _ in 0..<12 {
                log.append(Self.randomEdit(on: &target, random: &random))
                if let problem = Self.problem(in: target) {
                    failures.append("seed \(seed): \(problem)\n  edits: \(log)")
                    break
                }
            }
            // Redo first: after a trailing undo, the newest state is ahead.
            while target.canRedo { target.redo() }
            let end = target.blocks
            while target.canUndo { target.undo() }
            if target.blocks != (start.isEmpty ? [paragraph("")] : start) {
                failures.append("seed \(seed): undo did not reach the start\n  edits: \(log)")
            }
            while target.canRedo { target.redo() }
            if target.blocks != end {
                failures.append("seed \(seed): redo did not reach the end\n  edits: \(log)")
            }
            // What the edits made must save and load back to a document that saves the same.
            let saved = exportedBody(end)
            let loaded = RichMarkdownConverter.load(saved)
            if loaded.repairRounds > 0 || !exportedBody(loaded.document.blocks).hasSameBytes(as: saved) {
                failures.append("seed \(seed): the edited document does not load back (repair \(loaded.repairRounds))\n  markdown \(saved.debugDescription)\n  again    \(exportedBody(loaded.document.blocks).debugDescription)\n  blocks \(end)\n  edits: \(log)")
            }
        }
        let failedSeeds = failures.compactMap { $0.split(separator: ":").first }.joined(separator: ", ")
        #expect(failures.isEmpty, "\(failures.count) of \(Self.seeds.count) (\(failedSeeds)):\n\(failures.prefix(5).joined(separator: "\n"))")
    }

    /// nil when the state is valid.
    private static func problem(in editor: RichEditor) -> String? {
        if editor.rows.isEmpty { return "no rows" }
        if Set(editor.rows.map(\.id)).count != editor.rows.count { return "two rows share an identity" }
        let selection = editor.selection
        for position in [selection.start, selection.end] {
            guard editor.rows.indices.contains(position.blockIndex),
                  (0...editor.rows[position.blockIndex].block.length).contains(position.offset) else {
                return "selection \(selection) outside the document"
            }
        }
        for (index, row) in editor.rows.enumerated() {
            if let text = row.block.richText, RichText(text.text, spans: text.spans) != text {
                return "row \(index) has spans that are not normalized: \(text)"
            }
            if let item = row.block.listItem {
                let maxIndent = index > 0 ? (editor.rows[index - 1].block.listItem.map { $0.indent + 1 } ?? 0) : 0
                if item.indent > maxIndent { return "row \(index) is deeper than Markdown can write: \(row.block)" }
            }
        }
        return nil
    }

    private static let actions: [RichBlockAction] = [
        .setHeading(2), .setHeading(nil), .toggleBulletList, .toggleOrderedList, .toggleTaskList, .toggleQuote, .indent, .outdent
    ]

    private static let styles: [RichSpanStyle] = [.bold, .italic, .underline, .strikethrough, .code, .link(RichLink(destination: "https://mega.nz"))]

    /// Applies one random edit. Returns its name for the failure message.
    private static func randomEdit(on editor: inout RichEditor, random: inout SeededGenerator) -> String {
        selectSomething(on: &editor, random: &random)
        let selection = "\(editor.selection.start.blockIndex):\(editor.selection.start.offset)-\(editor.selection.end.blockIndex):\(editor.selection.end.offset)"
        switch Int.random(in: 0..<14, using: &random) {
        case 0, 1:
            let word = ["a", "**", "_x_", " ", "😀", "\u{301}", "[l](u)"].randomElement(using: &random) ?? "a"
            editor.insertText(word)
            return "type \(word.debugDescription) at \(selection)"
        case 2:
            editor.insertText("one\ntwo")
            return "type lines at \(selection)"
        case 3:
            editor.insertParagraphBreak()
            return "enter at \(selection)"
        case 4, 5:
            editor.deleteBackward()
            return "backspace at \(selection)"
        case 6:
            let style = styles.randomElement(using: &random) ?? .bold
            editor.toggleStyle(style)
            return "toggle \(style) at \(selection)"
        case 7:
            let action = actions.randomElement(using: &random) ?? .indent
            editor.apply(action)
            return "\(action) at \(selection)"
        case 8:
            let content = editor.copy()
            editor.select(.caret(RichPosition(blockIndex: Int.random(in: 0..<editor.rows.count, using: &random), offset: 0)))
            editor.paste(RichPasteContent(markdown: content?.markdown ?? "pasted", plainText: content?.plainText))
            return "copy \(selection), paste at \(editor.selection.start.blockIndex):0"
        case 9:
            _ = editor.cut()
            return "cut \(selection)"
        case 10:
            editor.paste(RichPasteContent(plainText: "# h\n- item\nplain"))
            return "paste plain at \(selection)"
        case 11:
            editor.undo()
            return "undo"
        case 12:
            editor.redo()
            return "redo"
        default:
            editor.toggleCheckbox(at: editor.selection.start.blockIndex)
            return "checkbox \(selection)"
        }
    }

    /// A caret or a range on Character boundaries, sometimes across blocks.
    private static func selectSomething(on editor: inout RichEditor, random: inout SeededGenerator) {
        func randomPosition() -> RichPosition {
            let index = Int.random(in: 0..<editor.rows.count, using: &random)
            let block = editor.rows[index].block
            guard let text = block.plainText else { return RichPosition(blockIndex: index, offset: Int.random(in: 0...1, using: &random)) }
            var boundaries = [0]
            var offset = 0
            for character in text {
                offset += character.utf16.count
                boundaries.append(offset)
            }
            return RichPosition(blockIndex: index, offset: boundaries.randomElement(using: &random) ?? 0)
        }
        let start = randomPosition()
        editor.select(Int.random(in: 0..<3, using: &random) == 0 ? .caret(start) : RichSelection(start: start, end: randomPosition()))
    }
}
