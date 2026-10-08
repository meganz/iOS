@testable import MEGAMarkdownEditor
import Testing
import UIKit

// Needs the iOS simulator. A text size change restyles the focused row. It must keep the keys typed before.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct RichEditorTraitChangeTests {
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
}
