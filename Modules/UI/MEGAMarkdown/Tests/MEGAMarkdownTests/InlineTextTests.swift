import Foundation
@testable import MEGAMarkdown
import SwiftUI
import Testing

@Suite struct InlineTextTests {
    private func sample() -> InlineText {
        var text = InlineText(links: [InlineLink(url: "https://mega.io", title: "Home"), InlineLink(url: "img.png", title: "")])
        text.append("plain ", style: [])
        text.append("bold", style: .stronglyEmphasized)
        text.append(" 👩‍💻 ", style: [])
        text.append("link", style: .underline, link: 0)
        text.append("alt", style: .image, link: 1)
        return text
    }

    @Test func appendJoinsRunsWithTheSameStyle() {
        var text = InlineText()
        text.append("a", style: .code)
        text.append("b", style: .code)
        text.append("", style: [])
        #expect(text.runs == [InlineRun(end: 2, style: .code, link: -1)])
    }

    @Test func conversionKeepsEveryAttribute() throws {
        let attributed = sample().attributed(baseURL: URL(string: "https://base.io/dir/"))
        let runs = Array(attributed.runs)
        #expect(String(attributed.characters) == "plain bold 👩‍💻 linkalt")
        #expect(runs[1].inlinePresentationIntent == .stronglyEmphasized)
        #expect(runs[3].link?.absoluteString == "https://mega.io")
        #expect(runs[3].alternateDescription == "Home")
        #expect(runs[3][AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] == .single)
        #expect(runs[4].imageURL?.absoluteString == "https://base.io/dir/img.png")
        #expect(runs[4].link == nil)
    }

    @Test func sliceKeepsStylesAndCharacters() {
        let text = sample()
        let emojiEnd = "plain bold 👩‍💻".utf8.count
        let piece = text.slice(6..<emojiEnd)
        #expect(piece.text == "bold 👩‍💻")
        #expect(piece.runs.first?.style == .stronglyEmphasized)
        #expect(piece.links == text.links)
        #expect(text.slice(0..<text.text.utf8.count) == text)
    }

    @Test func dropFirstBytesRemovesThePrefix() {
        var text = sample()
        text.dropFirstBytes(6)
        #expect(text.text.hasPrefix("bold"))
        #expect(text.runs.first?.style == .stronglyEmphasized)
        // Only the prefix goes: the rest of the text, the run ends and the links stay whole.
        #expect(text.text == "bold 👩‍💻 linkalt")
        #expect(text.runs.last?.end == text.text.utf8.count)
        #expect(text.runs.map(\.style) == [.stronglyEmphasized, [], .underline, .image])
        #expect(text.links == sample().links)
    }
}
