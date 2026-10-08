import MEGAMarkdown
@testable import MEGAMarkdownEditor
import SwiftUI
import Testing
import UIKit

// Needs the iOS simulator. Rows with inline code are drawn by two code paths: UIKit in the editor and SwiftUI in
// the preview. Each row must have the same height in both.
@MainActor
@Suite(.serialized, .hostedUI, .timeLimit(.minutes(1)))
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
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        var last: [CGFloat] = []
        var stable = 0
        // The preview measures its rows in its own display pass, so wait until the heights stop changing.
        for _ in 0..<100 {
            try await Task.sleep(for: .milliseconds(30))
            window.layoutIfNeeded()
            guard let list = Self.list(in: window) else { continue }
            list.layoutIfNeeded()
            let heights = (0..<list.numberOfItems(inSection: 0)).compactMap {
                list.layoutAttributesForItem(at: IndexPath(item: $0, section: 0))?.frame.height
            }
            stable = heights == last && !heights.isEmpty ? stable + 1 : 0
            last = heights
            if stable >= 5 { return heights }
        }
        throw RichListHarness.HarnessError(description: "The preview heights did not settle: \(last)")
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
        let harness = try RichListHarness(Self.inlineCode, width: Self.width, height: 3_000, dynamicType: size)
        defer { harness.close() }
        try await harness.settle(300)
        let editor = (0..<harness.list.itemCount).map { harness.list.itemFrame(at: $0).height }
        #expect(preview.count == editor.count, "preview \(preview), editor \(editor)")
        for (index, pair) in zip(preview, editor).enumerated() {
            #expect(abs(pair.0 - pair.1) < 1, "item \(index): preview \(pair.0), editor \(pair.1). preview \(preview), editor \(editor)")
        }
    }
}
