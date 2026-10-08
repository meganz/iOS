@testable import MEGAMarkdownEditor
import SwiftUI
import Testing
import UIKit

// Needs the iOS simulator. The SwiftUI environment of the editor reaches the rows, and a new size keeps the caret row on screen.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
struct RichEditorEnvironmentTests {
    private static let paragraphs = (0..<80).map { "Paragraph \($0) with some words." }.joined(separator: "\n\n")

    @Test func layoutDirectionAndColorSchemeReachTheList() async throws {
        let harness = try RichListHarness("abc", layoutDirection: .rightToLeft, colorScheme: .dark)
        defer { harness.close() }
        try await waitUntil("the right-to-left dark traits") {
            let traits = harness.list.view.traitCollection
            return traits.layoutDirection == .rightToLeft && traits.userInterfaceStyle == .dark
        }
    }

    @Test func laterEnvironmentChangesReachTheList() async throws {
        let harness = try RichListHarness("abc")
        defer { harness.close() }
        harness.setEnvironment(layoutDirection: .rightToLeft, colorScheme: .dark)
        try await waitUntil("the right-to-left dark traits") {
            let traits = harness.list.view.traitCollection
            return traits.layoutDirection == .rightToLeft && traits.userInterfaceStyle == .dark
        }
        harness.setEnvironment(layoutDirection: .leftToRight, colorScheme: .light)
        try await waitUntil("the left-to-right light traits") {
            let traits = harness.list.view.traitCollection
            return traits.layoutDirection == .leftToRight && traits.userInterfaceStyle == .light
        }
    }

    /// A rotation changes the width, so every row wraps again. The row with the caret must stay on screen.
    @Test func widthChangeKeepsTheCaretRowOnScreen() async throws {
        let harness = try RichListHarness(Self.paragraphs, width: 390, height: 700)
        defer { harness.close() }
        harness.focus(row: 70, caret: 1)
        try await harness.waitUntil { harness.focusedTextView != nil }
        let item = harness.adapter.items(forRow: 70).lowerBound
        #expect(harness.list.view.bounds.contains(harness.list.itemFrame(at: item)))
        harness.resize(width: 844, height: 390)
        try await harness.waitUntil { harness.list.view.bounds.contains(harness.list.itemFrame(at: item)) }
        #expect(harness.list.view.bounds.width == 844)
        #expect(harness.model.selection == .caret(position(70, 1)))
        harness.resize(width: 390, height: 700)
        try await harness.waitUntil { harness.list.view.bounds.contains(harness.list.itemFrame(at: item)) }
        #expect(harness.model.selection == .caret(position(70, 1)))
    }
}
