@testable import MEGAMarkdownEditor
import Testing

@Suite("Source lines")
struct SourceLinesTests {
    @Test func splitsOnLineFeedAndKeepsEmptyLines() {
        #expect(SourceLines("a\n\nb\n").count == 4)
        #expect(SourceLines("").count == 1)
    }

    @Test func joinsARangeBack() {
        #expect(SourceLines("a\nb\nc").join(1..<3) == "b\nc")
    }

    @Test func blankMeansOnlySpacesAndTabs() {
        let lines = SourceLines(" \t\nx\n")
        #expect(lines.isBlank(0))
        #expect(!lines.isBlank(1))
        #expect(lines.isBlank(2))
        #expect(!lines.isBlank(0..<2))
    }

    @Test func trimmedRemovesBlankLinesAtBothEnds() {
        let lines = SourceLines("\n \na\n\nb\n\n")
        #expect(lines.trimmed(0..<lines.count) == 2..<5)
    }

    @Test func trimmedOfAllBlankLinesIsEmpty() {
        #expect(SourceLines("\n\n").trimmed(0..<3).isEmpty)
    }

    @Test func trimmedClampsARangeOutsideTheText() {
        #expect(SourceLines("a").trimmed(-3..<10) == 0..<1)
    }

    @Test func frontMatterEndsAfterTheClosingLine() {
        #expect(SourceLines("---\ntitle: x\n---\nbody").frontMatterEnd() == 3)
        #expect(SourceLines("---\ntitle: x\n...\nbody").frontMatterEnd() == 3)
    }

    @Test func aDividerWithABlankLineAfterItIsNotFrontMatter() {
        #expect(SourceLines("---\n\ntext\n---").frontMatterEnd() == 0)
        #expect(SourceLines("---\n---\n").frontMatterEnd() == 0)
    }

    @Test func frontMatterThatIsNotClosedIsNotFrontMatter() {
        #expect(SourceLines("---\ntitle: x\nbody").frontMatterEnd() == 0)
        #expect(SourceLines("text\n---\n").frontMatterEnd() == 0)
    }

    @Test(arguments: ["[a]: http://x", "> [a]: x", "- [a]: x", "1. [a]: x", "> - 2) [a]: x", "  [a]:x"])
    func definitionsAreRecognized(line: String) {
        #expect(SourceLines(line).looksLikeDefinition(0))
    }

    @Test(arguments: ["[a] x", "a [b]: x", "-[a]: x", "[a", "text", ""])
    func otherLinesAreNotDefinitions(line: String) {
        #expect(!SourceLines(line).looksLikeDefinition(0))
    }

    @Test func aListMarkerWithMoreThanNineDigitsIsNotAMarker() {
        #expect(!SourceLines("1234567890. [a]: x").looksLikeDefinition(0))
    }
}
