import MEGAMarkdown
@testable import MEGAMarkdownEditor
import SwiftUI
import Testing
import UIKit

// Rows with inline code are drawn by two code paths: UIKit in the editor and SwiftUI in
// the preview. Each row must have the same height in both.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct RichPreviewLayoutParityTests {
    private static let inlineCode = """
    A paragraph with `code` in it.

    `only code`

    A long paragraph with `code` that wraps over more than one line, so the line steps show, and more `code` here.

    ## Heading with `code`

    - Item with `code`
    - `Only code`
    - Plain item

    > Quote with `code`

    Plain paragraph after.
    """

    private static let width: CGFloat = 390

    private func previewHeights(_ markdown: String, size: DynamicTypeSize) async throws -> [CGFloat] {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: Self.width, height: 3_000))
        window.rootViewController = UIHostingController(rootView: MarkdownPreview(markdown).environment(\.dynamicTypeSize, size))
        window.isHidden = false
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        // The preview parses off the main thread, so wait for its rows. The layout after that is synchronous.
        let clock = ContinuousClock()
        let deadline = clock.now + .seconds(10)
        var list = Self.list(in: window)
        while list.map({ $0.numberOfItems(inSection: 0) == 0 }) ?? true {
            guard clock.now < deadline else {
                throw RichLayoutHarness.HarnessError(description: "The preview showed no rows")
            }
            try await Task.sleep(for: .milliseconds(10))
            window.layoutIfNeeded()
            list = Self.list(in: window)
        }
        guard let list else { return [] }
        var last: [CGFloat] = []
        for _ in 0..<8 {
            window.layoutIfNeeded()
            list.layoutIfNeeded()
            let heights = (0..<list.numberOfItems(inSection: 0)).compactMap {
                list.layoutAttributesForItem(at: IndexPath(item: $0, section: 0))?.frame.height
            }
            if heights == last { return heights }
            last = heights
        }
        throw RichLayoutHarness.HarnessError(description: "The preview heights did not settle: \(last)")
    }

    private static func list(in window: UIWindow) -> MarkdownRowListView? {
        var pending: [UIView] = [window]
        while let view = pending.popLast() {
            if let list = view as? MarkdownRowListView { return list }
            pending.append(contentsOf: view.subviews)
        }
        return nil
    }

    @Test(arguments: [DynamicTypeSize.large, .accessibility3])
    func everyRowWithInlineCodeHasThePreviewHeight(size: DynamicTypeSize) async throws {
        let preview = try await previewHeights(Self.inlineCode, size: size)
        let harness = try RichLayoutHarness(Self.inlineCode, width: Self.width, height: 3_000, dynamicType: size)
        defer { harness.close() }
        let editor = harness.heights
        #expect(preview.count == editor.count, "preview \(preview), editor \(editor)")
        // Known gap: at accessibility text sizes the editor's list marker can sit a fraction of a point lower,
        // and the cell rounds that up to 1 pt more. Heights are whole points, so other sizes must be equal.
        let allowed: CGFloat = size.isAccessibilitySize ? 1 : 0
        for (index, pair) in zip(preview, editor).enumerated() {
            #expect(abs(pair.0 - pair.1) <= allowed, "item \(index): preview \(pair.0), editor \(pair.1). preview \(preview), editor \(editor)")
        }
    }

    /// A row that keeps its estimate keeps a fractional height and puts the rows below it off the pixel grid.
    @Test(arguments: [DynamicTypeSize.large, .accessibility3])
    func everyRowHasAWholePointHeight(size: DynamicTypeSize) async throws {
        let preview = try await previewHeights(Self.inlineCode, size: size)
        let harness = try RichLayoutHarness(Self.inlineCode, width: Self.width, height: 3_000, dynamicType: size)
        defer { harness.close() }
        let editor = harness.heights
        #expect(preview.allSatisfy { $0 == $0.rounded() }, "preview \(preview)")
        #expect(editor.allSatisfy { $0 == $0.rounded() }, "editor \(editor)")
    }
}
