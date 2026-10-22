@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator. A text size change restyles the rows. They keep the typed keys and take their new heights.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct RichEditorTraitChangeTests {
    private static let rows = """
    # A heading that wraps at large sizes

    Paragraph one with enough words to wrap onto a second line at the default size.

    - Bullet one with some words
    - Bullet two with some more words that wrap

    ## Second heading

    Paragraph two with enough words to wrap onto a second line at the default size.

    > A quote with a few words in it.

    Paragraph three with enough words to wrap onto a second line at the default size.
    """

    @Test func textSizeChangeKeepsTheKeysTypedBefore() async throws {
        let harness = try RichListHarness("abc")
        defer { harness.close() }
        try await harness.settle()
        harness.focus(row: 0, caret: 3)
        try await harness.settle()
        try harness.type("x")
        let sizeBefore = harness.textView(row: 0)?.attributedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        let current = harness.list.view.traitCollection.preferredContentSizeCategory
        // The same call that `RichEditorRowList` makes when the SwiftUI text size changes.
        harness.list.view.traitOverrides.preferredContentSizeCategory = current == .accessibilityLarge ? .extraSmall : .accessibilityLarge
        try await harness.waitUntil {
            let font = harness.textView(row: 0)?.attributedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
            return font?.pointSize != sizeBefore?.pointSize
        }
        #expect(harness.textView(row: 0)?.text == "abcx")
        try harness.type("y")
        try await harness.settle()
        #expect(harness.model.row(at: 0).block.plainText == "abcxy")
    }

    /// Each row is measured while it takes the new size. Its height must come from the new fonts, not the old ones.
    @Test(arguments: [UIContentSizeCategory.accessibilityExtraExtraExtraLarge, .extraSmall])
    func textSizeChangeGivesEveryRowItsNewHeight(to category: UIContentSizeCategory) async throws {
        let harness = try RichListHarness(Self.rows)
        defer { harness.close() }
        try await harness.settle()
        let sizeBefore = (harness.textView(row: 1)?.attributedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)?.pointSize
        harness.list.view.traitOverrides.preferredContentSizeCategory = category
        try await harness.waitUntil {
            let font = harness.textView(row: 1)?.attributedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
            return font != nil && font?.pointSize != sizeBefore
        }
        let view = harness.list.view
        var wrong: [String] = []
        var checked = 0
        while true {
            try await harness.settle(100)
            let rows = rowsOnScreen(harness)
            checked += rows.count
            wrong += rows.filter { abs($0.stored - $0.fitted) >= 1 }.map { "item \($0.item): \($0.stored) instead of \($0.fitted)" }
            let maxOffset = view.contentSize.height + view.adjustedContentInset.bottom - view.bounds.height
            guard view.contentOffset.y < maxOffset - 1 else { break }
            view.contentOffset.y = min(view.contentOffset.y + view.bounds.height / 2, maxOffset)
        }
        #expect(checked >= harness.list.itemCount)
        #expect(wrong.isEmpty, "\(wrong)")
    }

    /// The stored height and the content height of each row on screen.
    private func rowsOnScreen(_ harness: RichListHarness) -> [(item: Int, stored: CGFloat, fitted: CGFloat)] {
        let list = harness.list
        let width = list.view.bounds.width
        return (0..<list.itemCount).compactMap { item in
            let frame = list.itemFrame(at: item)
            guard list.view.bounds.intersects(frame), let cell = list.cell(forItem: item) else { return nil }
            let fitted = cell.contentView.systemLayoutSizeFitting(
                CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            return (item, frame.height, ceil(fitted.height))
        }
    }
}
