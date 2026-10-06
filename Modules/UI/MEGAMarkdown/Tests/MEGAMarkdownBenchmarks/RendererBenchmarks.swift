import MEGABenchmark
@testable import MEGAMarkdown
import QuartzCore
import SwiftUI
import UIKit
import XCTest

/// `MarkdownView` benchmarks with XCTest metrics. The view parses and builds every block on the main thread,
/// so these guard the largest text it is made for: 4 KB. Limits: `Limits.json` next to this file.
@MainActor
final class RendererBenchmarks: BenchmarkCase {
    private static let phoneSize = CGSize(width: 402, height: 874)
    private static let documentBytes = 4_000

    // MARK: - Open

    func testOpenMixedDocument() throws {
        try measureOpen(BenchmarkDocuments.makeLargeDocument(targetBytes: Self.documentBytes))
    }

    func testOpenTableDocument() throws {
        try measureOpen(Self.tableDocument())
    }

    func testOpenInlineCodeDocument() throws {
        try measureOpen(Self.inlineCodeDocument())
    }

    /// Hosting in a window to the first committed frame. The block blocks the main thread,
    /// so the longest stall is the time the user waits for the view. The clock stops before the close.
    private func measureOpen(_ markdown: String) throws {
        let expectedHeight = try Self.contentHeight(of: markdown)
        let options = XCTMeasureOptions.default
        options.invocationOptions = [.manuallyStop]
        measure(metrics: [XCTClockMetric(), MainThreadStallMetric(), PeakFootprintMetric()], options: options) {
            let window = UIWindow(frame: CGRect(origin: .zero, size: Self.phoneSize))
            let host = UIHostingController(rootView: ScrollView { MarkdownView(markdown) })
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.layoutIfNeeded()
            CATransaction.flush()
            stopMeasuring()
            // The time only means something if the whole document was laid out, the same as outside the bench.
            XCTAssertEqual(Self.scrollContentHeight(in: host.view), expectedHeight)
            window.rootViewController = nil
            window.isHidden = true
        }
    }

    // MARK: - Redraw

    /// 100 parent redraws with the same text. `MarkdownParseCache` must skip the parse, so only the diff is left.
    func testParentRedrawWithSameText() throws {
        let markdown = BenchmarkDocuments.makeLargeDocument(targetBytes: Self.documentBytes)
        let redraws = 100
        let probe = RedrawProbe()
        let window = UIWindow(frame: CGRect(origin: .zero, size: Self.phoneSize))
        let host = UIHostingController(rootView: RedrawHost(probe: probe, markdown: markdown))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
            let start = probe.bodyCount
            for _ in 0..<redraws {
                probe.tick += 1
                host.view.layoutIfNeeded()
            }
            // Each tick must reach the parent body, or the bench measures nothing.
            XCTAssertEqual(probe.bodyCount - start, redraws)
        }
        window.rootViewController = nil
        window.isHidden = true
    }

    // MARK: - Documents

    /// 4 tables of 5 columns and 25 rows, about 4 KB.
    private static func tableDocument() -> String {
        let header = "| Name | Size | Type | Date | Owner |\n|:--|--:|:-:|---|---|\n"
        let rows = (1...25).map { "| file\($0).md | \($0) KB | Text | 2026-10-02 | me |" }.joined(separator: "\n")
        return Array(repeating: header + rows, count: 4).joined(separator: "\n\n")
    }

    /// 40 paragraphs with 8 inline code spans each, about 4 KB. Each span draws a chip.
    private static func inlineCodeDocument() -> String {
        let paragraph = (1...8).map { "word `code\($0)`" }.joined(separator: " ")
        return Array(repeating: paragraph, count: 40).joined(separator: "\n\n")
    }

    // MARK: - Helpers

    private static func contentHeight(of markdown: String) throws -> CGFloat {
        let window = UIWindow(frame: CGRect(origin: .zero, size: phoneSize))
        let host = UIHostingController(rootView: ScrollView { MarkdownView(markdown) })
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        defer {
            window.rootViewController = nil
            window.isHidden = true
        }
        let height = scrollContentHeight(in: host.view)
        // Taller than the screen: every test document fills more than one page.
        XCTAssertGreaterThan(height, phoneSize.height)
        return height
    }

    private static func scrollContentHeight(in view: UIView) -> CGFloat {
        if let scrollView = view as? UIScrollView { return scrollView.contentSize.height }
        return view.subviews.lazy.map(scrollContentHeight).first { $0 > 0 } ?? 0
    }
}

/// Counts parent body calls. A change of `tick` redraws the parent.
@MainActor
private final class RedrawProbe: ObservableObject {
    @Published var tick = 0
    var bodyCount = 0
}

/// A parent whose body depends on `tick`, with a `MarkdownView` of the same text below.
private struct RedrawHost: View {
    @ObservedObject var probe: RedrawProbe
    let markdown: String

    var body: some View {
        probe.bodyCount += 1
        return VStack {
            Text("\(probe.tick)")
            MarkdownView(markdown)
        }
    }
}
