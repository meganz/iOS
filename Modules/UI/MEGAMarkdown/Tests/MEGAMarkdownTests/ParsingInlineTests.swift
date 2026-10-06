import Foundation
@testable import MEGAMarkdown
import Testing

@Suite struct ParsingInlineTests {
    private func paragraph(_ markdown: String) throws -> AttributedString {
        let block = try #require(parse(markdown).first)
        guard case .paragraph(let text) = block.kind else {
            Issue.record("not a paragraph: \(block.kind)")
            return AttributedString()
        }
        return text
    }

    private func intent(of word: String, in text: AttributedString) -> InlinePresentationIntent? {
        guard let range = text.range(of: word) else { return nil }
        return text[range].runs.first?.inlinePresentationIntent
    }

    @Test func boldItalicCodeStrikethrough() throws {
        let text = try paragraph("**bold** *italic* `code` ~~strike~~ ***both***")
        #expect(text.plain == "bold italic code strike both")
        #expect(intent(of: "bold", in: text) == .stronglyEmphasized)
        #expect(intent(of: "italic", in: text) == .emphasized)
        #expect(intent(of: "code", in: text) == .code)
        #expect(intent(of: "strike", in: text) == .strikethrough)
        #expect(intent(of: "both", in: text) == [.stronglyEmphasized, .emphasized])
    }

    @Test func linkKeepsURL() throws {
        let text = try paragraph("go [here](https://mega.io/x?a=1) now")
        let range = try #require(text.range(of: "here"))
        #expect(text[range].runs.first?.link == URL(string: "https://mega.io/x?a=1"))
        #expect(text.plain == "go here now")
        let before = try #require(text.range(of: "go "))
        #expect(text[before].runs.allSatisfy { $0.link == nil })
    }

    @Test func autolinkKeepsURL() throws {
        let text = try paragraph("<https://mega.io>")
        #expect(text.runs.first?.link == URL(string: "https://mega.io"))
        #expect(text.plain == "https://mega.io")
    }

    /// cmark decodes the destination. It is percent-encoded once, so an existing `%20` stays and `ä` becomes `%C3%A4`.
    @Test(arguments: [
        ("[a](foo%20b&auml;)", "foo%20b%C3%A4"),
        ("[a](./\u{8BF4}\u{660E}%20v2.md)", "./%E8%AF%B4%E6%98%8E%20v2.md"),
        ("[a](<a b>)", "a%20b"),
        ("[a](100%)", "100%25"),
        ("[a](foo\\)\\:)", "./foo):"),
        ("[a](https://mega.io/a?b=1#c)", "https://mega.io/a?b=1#c"),
        ("[a](mailto:x@mega.io)", "mailto:x@mega.io"),
        ("[a](a%20b\\[1\\])", "a%20b%5B1%5D"),
        ("[a](http://[::1]/a%20b)", "http://[::1]/a%20b"),
        ("[a](http://b\u{FC}cher.de/x%20\u{E4})", "http://xn--bcher-kva.de/x%20%C3%A4"),
        // Foundation rejects "`" in a host. It is encoded like cmark does, so the link stays.
        ("<http://foo.bar.`baz>`", "http://foo.bar.%60baz"),
        ("[a](http://a`b.c/d%20e)", "http://a%60b.c/d%20e")
    ])
    func linkURLIsEncodedOnce(markdown: String, url: String) throws {
        let text = try paragraph(markdown)
        #expect(text.runs.compactMap(\.link).map(\.absoluteString) == [url])
    }

    @Test func encodedLinkResolvesAgainstTheBaseURL() throws {
        let markdown = "[a](foo\\)\\:) [b](b%20\u{E4}.md)"
        let blocks = MarkdownParser.parse(markdown, baseURL: URL(string: "https://mega.io/docs/")).blocks
        let text = try #require(blocks.first?.paragraph)
        let links = text.runs.compactMap(\.link).map(\.absoluteString)
        #expect(links == ["https://mega.io/docs/foo):", "https://mega.io/docs/b%20%C3%A4.md"])
    }

    @Test func imageURLIsEncodedOnce() throws {
        let image = try #require(parse("![a](b%20\u{E4}.png)").first?.image)
        #expect(image.url?.absoluteString == "b%20%C3%A4.png")
    }

    /// `//host` takes the base URL's scheme. Its host stays as written, like after `scheme://`.
    @Test(arguments: [
        ("[a](//[::1]/a%20b)", "https://[::1]/a%20b"),
        ("[a](//[2001:db8::1]:8080/a)", "https://[2001:db8::1]:8080/a"),
        ("[a](//b\u{FC}cher.de/x%20\u{E4})", "https://xn--bcher-kva.de/x%20%C3%A4"),
        ("[a](//mega.io/a%20b)", "https://mega.io/a%20b")
    ])
    func schemeRelativeLinkKeepsItsHost(markdown: String, url: String) throws {
        let blocks = MarkdownParser.parse(markdown, baseURL: URL(string: "https://mega.io/docs/")).blocks
        let text = try #require(blocks.first?.paragraph)
        #expect(text.runs.compactMap(\.link).map(\.absoluteString) == [url])
    }

    @Test func schemeRelativeImageKeepsItsHost() throws {
        let blocks = MarkdownParser.parse("![a](//[::1]/a.png)", baseURL: URL(string: "https://mega.io/docs/")).blocks
        #expect(blocks.first?.image?.url?.absoluteString == "https://[::1]/a.png")
    }

    @Test func hardBreakBecomesNewline() throws {
        // Both forms (two trailing spaces, trailing backslash) become "\n" with intent `lineBreak`.
        let text = try paragraph("hard  \nbreak\\\nend")
        #expect(text.plain == "hard\nbreak\nend")
    }

    @Test func presentationIntentAndSourcePositionAreStripped() throws {
        let text = try paragraph("plain **bold** [l](https://a.b)")
        for run in text.runs {
            #expect(run.presentationIntent == nil)
            #expect(run.markdownSourcePosition == nil)
        }
    }

    @Test func escapedCharactersStayLiteral() throws {
        let text = try paragraph("\\*not italic\\* and 1\\. item")
        #expect(text.plain == "*not italic* and 1. item")
        #expect(text.runs.allSatisfy { $0.inlinePresentationIntent == nil })
    }
}
