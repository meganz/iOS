import Foundation
@testable import MEGAMarkdownEditor
import Testing

/// Edge cases of the fallback diff, the save echo, byte equality, link edits and selection ends.
@Suite("Editor edge cases")
struct EditorEdgeCaseTests {
    // MARK: Fallback diff

    /// U+20000 and U+20400 share their low surrogate. The edit must cover the whole scalar.
    @Test func aChangedScalarWithASharedLowSurrogateIsReplaced() {
        var target = editor([paragraph("\u{20000}")], caret: position(0, 2))
        target.didChangeText(inBlock: 0, to: "\u{20400}", caret: nil)
        #expect(target.blocks == [paragraph("\u{20400}")])
        let edit = RichEditor.editRange(old: "a\u{20000}b", new: "a\u{20400}b")
        #expect(edit.range == 1..<3)
        #expect(edit.replacementLength == 2)
    }

    @Test func aChangedScalarWithASharedHighSurrogateIsReplaced() {
        let edit = RichEditor.editRange(old: "a\u{1F600}b", new: "a\u{1F603}b")
        #expect(edit.range == 1..<3)
        #expect(edit.replacementLength == 2)
    }

    // MARK: Save echo

    /// After a save, the loaded text is new text from outside: a revert. Before a save it is the echo of the load.
    @Test func theLoadedTextIsAnEchoOnlyUntilTheFirstSave() {
        var target = RichEditor(markdown: "abc\n")
        #expect(target.holds("abc\n"))
        target.replaceText(inBlock: 0, range: 3..<3, with: "x")
        #expect(target.exportChanges() == "abcx\n")
        #expect(target.holds("abcx\n"))
        #expect(!target.holds("abc\n"))
    }

    // MARK: Byte equality

    @Test func codeKeepsACanonicallyEqualReplacement() {
        var target = editor([.codeBlock(language: nil, code: "caf\u{E9}")], caret: position(0, 3))
        target.replaceText(inBlock: 0, range: 3..<4, with: "e\u{301}")
        #expect(target.blocks[0].codeText?.utf16.count == 5)
        #expect(RichBlock.rawSource("\u{E9}") != RichBlock.rawSource("e\u{301}"))
        #expect(RichBlock.codeBlock(language: "\u{E9}", code: "") != RichBlock.codeBlock(language: "e\u{301}", code: ""))
    }

    // MARK: Links

    @Test(arguments: ["../guide.md", "#section", "/help", "docs/guide.md", "?page=2"])
    func editingALabelKeepsARelativeDestination(destination: String) throws {
        var target = editor([paragraph("docs", (0..<4, link(destination)))], caret: position(0, 2))
        let linkTarget = try #require(target.linkTarget())
        let draft = target.linkDraft(for: linkTarget)
        target.saveLink(linkTarget, urlText: draft.url, label: "new label")
        #expect(target.blocks == [paragraph("new label", (0..<9, link(destination)))])
    }

    @Test func typedDestinationsStayAsWritten() {
        #expect(RichLinkURL.destination(from: "../guide.md") == "../guide.md")
        #expect(RichLinkURL.destination(from: "./x") == "./x")
        #expect(RichLinkURL.destination(from: "#section") == "#section")
        #expect(RichLinkURL.destination(from: "?page=2") == "?page=2")
        #expect(RichLinkURL.destination(from: "/help") == "/help")
        #expect(RichLinkURL.destination(from: "docs/guide.md") == "docs/guide.md")
        #expect(RichLinkURL.destination(from: "mega.nz/help") == "mega.nz/help")
        #expect(RichLinkURL.destination(from: "README.md") == "README.md")
    }

    @Test func editingALinkKeepsItsTitle() throws {
        var target = editor([paragraph("help", (0..<4, link("https://example.test/help", title: "Help tooltip")))], caret: position(0, 1))
        let linkTarget = try #require(target.linkTarget())
        target.saveLink(linkTarget, urlText: "https://example.test/help", label: "new label")
        #expect(target.blocks == [paragraph("new label", (0..<9, link("https://example.test/help", title: "Help tooltip")))])
    }

    @Test func changingTheURLKeepsTheTitle() throws {
        var target = editor([paragraph("help", (0..<4, link("https://example.test/help", title: "Help tooltip")))], caret: position(0, 1))
        let linkTarget = try #require(target.linkTarget())
        target.saveLink(linkTarget, urlText: "https://example.test/new", label: "help")
        #expect(target.blocks == [paragraph("help", (0..<4, link("https://example.test/new", title: "Help tooltip")))])
    }

    // MARK: Selection end at a row start

    /// An end at offset 0 of the next row selects nothing of that row.
    @Test func aBlockActionSkipsAnEndRowWithNothingSelected() {
        var target = editor([paragraph("a"), paragraph("b")])
        target.select(selection(position(0, 0), position(1, 0)))
        target.apply(.setHeading(2))
        #expect(target.blocks == [heading(2, "a"), paragraph("b")])
    }

    @Test func stylesAreOffWhenNoTextIsSelected() {
        var target = editor([.codeBlock(language: nil, code: "x"), paragraph("b")])
        target.select(selection(position(0, 0), position(1, 0)))
        #expect(!target.selectionSummary.hasText)
        #expect(!target.canApply(.bold))
    }
}
