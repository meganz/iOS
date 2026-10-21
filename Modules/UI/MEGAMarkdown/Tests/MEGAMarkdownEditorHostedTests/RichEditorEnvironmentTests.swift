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

    enum MarkerSide: Sendable {
        case left, right
    }

    /// A list marker or checkbox sits on the side where its row's text starts, like the preview.
    /// A Hebrew row in a left-to-right app has it on the right. An English row in a right-to-left app has it on the left.
    @Test(arguments: [
        ("- פריט", LayoutDirection.leftToRight, MarkerSide.right),
        ("- [ ] פריט", LayoutDirection.leftToRight, MarkerSide.right),
        ("1. פריט", LayoutDirection.leftToRight, MarkerSide.right),
        ("- item", LayoutDirection.rightToLeft, MarkerSide.left)
    ])
    func listMarkerSitsOnTheSideWhereItsTextStarts(markdown: String, layout: LayoutDirection, side: MarkerSide) async throws {
        let harness = try RichListHarness(markdown + "\n", width: 390, height: 700, layoutDirection: layout)
        defer { harness.close() }
        try await harness.settle()
        let cell = try #require(harness.list.view.cellForItem(at: IndexPath(item: 0, section: 0)))
        let columns = try inkColumns(of: cell)
        let marker = side == .left ? columns : columns.reversed()
        // The marker is the first block of ink from that side: narrow, with the marker column's gap after it.
        let start = try #require(marker.firstIndex(of: true), "the row draws nothing")
        let width = marker[start...].firstIndex(of: false).map { $0 - start } ?? 0
        let gap = marker[(start + width)...].firstIndex(of: true).map { $0 - start - width } ?? 0
        #expect(start < 40, "the first ink from the \(side) is \(start) points in")
        #expect(width > 0 && width <= 24, "the first ink block from the \(side) is \(width) points wide")
        #expect(gap >= 5, "the gap after the marker is \(gap) points")
    }

    /// One flag per column of the cell, at 1x: true when the column has a dark pixel.
    private func inkColumns(of cell: UIView) throws -> [Bool] {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(bounds: cell.bounds, format: format).image { context in
            UIColor.white.setFill()
            UIRectFill(cell.bounds)
            cell.layer.render(in: context.cgContext)
        }
        let data = try #require(image.cgImage?.dataProvider?.data as Data?)
        let bytesPerRow = try #require(image.cgImage?.bytesPerRow)
        let height = Int(cell.bounds.height)
        return (0..<Int(cell.bounds.width)).map { x in
            (0..<height).contains { y in data[y * bytesPerRow + x * 4] < 128 }
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
