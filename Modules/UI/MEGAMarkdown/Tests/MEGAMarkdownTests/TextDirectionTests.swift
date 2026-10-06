@testable import MEGAMarkdown
import SwiftUI
import Testing

/// A text row takes its direction from its first strong letter (UAX #9 rules P2 and P3).
@Suite struct TextDirectionTests {
    @Test(arguments: [
        ("שלום עולם", LayoutDirection.rightToLeft),
        ("مرحبا بالعالم", .rightToLeft),
        ("Hello עולם", .leftToRight),
        ("123 - שלום", .rightToLeft),
        ("«ܫܠܡܐ»", .rightToLeft),
        ("  (42) Ünïcode", .leftToRight),
        ("日本語", .leftToRight)
    ])
    func firstStrongLetterSetsTheDirection(text: String, direction: LayoutDirection) {
        #expect(firstStrongDirection(of: text) == direction)
    }

    /// Digits, marks and punctuation are not strong: such a row follows the layout.
    @Test(arguments: ["", "123", "- • ...", "\u{05B0}\u{0651}", "١٢٣"])
    func textWithoutALetterHasNoDirection(text: String) {
        #expect(firstStrongDirection(of: text) == nil)
    }

    @Test func rowsWithoutTextFollowTheLayout() throws {
        let rows = PreviewRows.rows(forMarkdown: "```\nשלום\n```\n\n| א |\n|---|\n| ב |\n\n- שלום\n\n# Title", softBreak: .lineBreak)
        #expect(rows.map(\.textDirection) == [nil, nil, .rightToLeft, .leftToRight])
    }
}
