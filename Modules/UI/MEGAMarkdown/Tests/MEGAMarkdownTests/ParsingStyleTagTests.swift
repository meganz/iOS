import Foundation
@testable import MEGAMarkdown
import SwiftUI
import Testing

// Inline HTML style tags written by the editor exporter (same names as MarkdownImporter.htmlStyleTags).
@Suite struct ParsingStyleTagTests {
    private func paragraph(_ markdown: String) throws -> AttributedString {
        guard case .paragraph(let text) = try #require(parse(markdown).first).kind else {
            Issue.record("not a paragraph")
            return AttributedString()
        }
        return text
    }

    private func intent(of word: String, in text: AttributedString) -> InlinePresentationIntent? {
        guard let range = text.range(of: word) else { return nil }
        return text[range].runs.first?.inlinePresentationIntent
    }

    @Test(arguments: [
        ("strong", InlinePresentationIntent.stronglyEmphasized), ("b", .stronglyEmphasized),
        ("em", .emphasized), ("i", .emphasized),
        ("del", .strikethrough), ("s", .strikethrough), ("strike", .strikethrough),
        ("code", .code)
    ])
    func balancedTagAppliesStyle(tag: String, expected: InlinePresentationIntent) throws {
        let text = try paragraph("before <\(tag)>word</\(tag)> after")
        #expect(text.plain == "before word after")
        #expect(intent(of: "word", in: text) == expected)
        #expect(intent(of: "before", in: text) == nil)
        #expect(intent(of: "after", in: text) == nil)
    }

    @Test func mixedCaseTag() throws {
        let text = try paragraph("<STRONG>x</Strong>")
        #expect(text.plain == "x")
        #expect(intent(of: "x", in: text) == .stronglyEmphasized)
    }

    @Test func differentNamesOfOneStylePair() throws {
        // Same rule as the importer: tags are counted per style, so <b> closes with </strong>.
        let text = try paragraph("<b>x</strong>")
        #expect(text.plain == "x")
        #expect(intent(of: "x", in: text) == .stronglyEmphasized)
    }

    @Test func nestedTagsCombineWithMarkdownStyles() throws {
        let text = try paragraph("<strong><em>both</em> bold</strong> *md <del>struck</del>*")
        #expect(text.plain == "both bold md struck")
        #expect(intent(of: "both", in: text) == [.stronglyEmphasized, .emphasized])
        #expect(intent(of: "bold", in: text) == .stronglyEmphasized)
        #expect(intent(of: "struck", in: text) == [.emphasized, .strikethrough])
    }

    @Test func adjacentClosingTagsInOneRun() throws {
        // Without source positions Foundation can merge `</em></strong>` into one run; both work.
        let text = try paragraph("<strong><em>x</em></strong> y")
        #expect(text.plain == "x y")
        #expect(intent(of: "x", in: text) == [.stronglyEmphasized, .emphasized])
        #expect(intent(of: "y", in: text) == nil)
    }

    @Test func codeTagKeepsTextAndAddsCodeIntent() throws {
        let text = try paragraph("run <code>a*b</code> now")
        #expect(text.plain == "run a*b now")
        #expect(intent(of: "a*b", in: text) == .code)
    }

    @Test func underlineAndBoldTogether() throws {
        let text = try paragraph("<u><strong>x</strong></u>")
        #expect(text.plain == "x")
        let run = try #require(text.runs.first)
        #expect(run.inlinePresentationIntent == .stronglyEmphasized)
        #expect(run[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] == .single)
    }

    @Test(arguments: ["<strong>open only", "close only</em>", "</del>wrong order<del>", "<code>x"])
    func unbalancedTagsStayLiteral(markdown: String) throws {
        let text = try paragraph(markdown)
        #expect(text.plain == markdown)
        let styles: InlinePresentationIntent = [.stronglyEmphasized, .emphasized, .strikethrough, .code]
        #expect(text.runs.allSatisfy { ($0.inlinePresentationIntent ?? []).isDisjoint(with: styles) })
    }

    @Test func oneMatchedAndOneExtraTag() throws {
        let text = try paragraph("<em>a <em>b</em>")
        #expect(text.plain == "<em>a b")
        #expect(intent(of: "b", in: text) == .emphasized)
        #expect(intent(of: "a", in: text) == nil)
    }

    @Test(arguments: [
        ("<u>under</u><br>", "under<br>"), ("<br><u>under</u>", "<br>under"), ("<u>under</u><img src=x>", "under<img src=x>")
    ])
    func unknownTagNextToAPairKeepsThePair(markdown: String, expected: String) throws {
        let text = try paragraph(markdown)
        #expect(text.plain == expected)
        #expect(text.range(of: "under").map { text[$0].runs.first?.underlineStyle } == .single)
    }

    @Test func tagWithAttributesStaysLiteral() throws {
        let text = try paragraph("<strong class=\"x\">a</strong>")
        // The opener has attributes, so it is not a style tag. Then `</strong>` has no opener either.
        #expect(text.plain == "<strong class=\"x\">a</strong>")
        #expect(text.runs.allSatisfy { $0.inlinePresentationIntent?.contains(.stronglyEmphasized) != true })
    }

    @Test func tagsInListItemTableCellAndHeading() throws {
        let list = try #require(parse("- <em>item</em>").first?.list)
        #expect(list.items[0].blocks.first?.paragraphText == "item")
        let table = try #require(parse("| <del>h</del> |\n|---|\n| c |").first?.table)
        #expect(table.header[0].runs.first?.inlinePresentationIntent == .strikethrough)
        let heading = try #require(parse("# <code>api</code> name").first?.heading)
        #expect(heading.text == "api name")
        guard case .heading(_, let headingText) = try #require(parse("# <code>api</code> name").first).kind else { return }
        #expect(intent(of: "api", in: headingText) == .code)
        #expect(intent(of: "name", in: headingText) == nil)
    }
}
