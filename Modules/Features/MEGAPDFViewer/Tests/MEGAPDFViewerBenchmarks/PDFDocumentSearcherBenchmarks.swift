import MEGABenchmark
@testable import MEGAPDFViewer
import PDFKit
import XCTest

/// `PDFDocumentSearcher` benchmarks with XCTest metrics. They run only with
/// `TEST_RUNNER_MEGA_BENCH=1`. Limits: `Limits.json` next to this file.
/// Run: `scripts/benchmark.sh Modules/Features/MEGAPDFViewer`.
@MainActor
final class PDFDocumentSearcherBenchmarks: BenchmarkCase {
    /// The first search on a newly opened document, through
    /// `PDFDocumentSearcher`. A word on every line of the text document.
    func testFirstSearchOfFrequentWord() throws {
        let url = try BenchmarkDocuments.makeTextDocument()
        let expected = try XCTUnwrap(PDFDocument(url: url)).findString("quick", withOptions: []).count
        measure(metrics: [XCTCPUMetric(), MainThreadStallMetric()]) {
            let count = try? runOnMainLoop {
                let (window, pdfView) = try Self.makeHostedView(url: url)
                defer { window.isHidden = true }
                try await Self.waitUntilDisplayed(pdfView)
                let searcher = PDFDocumentSearcher(pdfView: pdfView)
                return try await Self.search("quick", with: searcher, in: pdfView)
            }
            XCTAssertEqual(count, expected)
        }
    }

    /// `testFirstSearchOfFrequentWord` with `beginFindString` alone. The gap
    /// between the two is the searcher's own cost on a first search.
    func testFirstBeginFindStringOfFrequentWord() throws {
        let url = try BenchmarkDocuments.makeTextDocument()
        let expected = try XCTUnwrap(PDFDocument(url: url)).findString("quick", withOptions: []).count
        measure(metrics: [XCTCPUMetric(), MainThreadStallMetric()]) {
            let count = try? runOnMainLoop {
                let (window, pdfView) = try Self.makeHostedView(url: url)
                defer { window.isHidden = true }
                try await Self.waitUntilDisplayed(pdfView)
                return try await Self.beginFindString("quick", in: try XCTUnwrap(pdfView.document))
            }
            XCTAssertEqual(count, expected)
        }
    }

    /// A later search on the same document, whose text an earlier search
    /// already extracted.
    func testRefinedSearchOfFrequentWord() throws {
        let url = try BenchmarkDocuments.makeTextDocument()
        let (window, pdfView) = try Self.makeHostedView(url: url)
        defer { window.isHidden = true }
        try runOnMainLoop { try await Self.waitUntilDisplayed(pdfView) }
        let expected = try XCTUnwrap(pdfView.document).findString("quick", withOptions: []).count
        let searcher = PDFDocumentSearcher(pdfView: pdfView)
        _ = try runOnMainLoop { try await Self.search("quic", with: searcher, in: pdfView) }
        measure(metrics: [XCTCPUMetric(), MainThreadStallMetric()]) {
            let count = try? runOnMainLoop {
                try await Self.search("quick", with: searcher, in: pdfView)
            }
            XCTAssertEqual(count, expected)
        }
    }

    /// `testRefinedSearchOfFrequentWord` with `beginFindString` alone. The gap
    /// between the two is the searcher's own cost on a later search.
    func testRefinedBeginFindStringOfFrequentWord() throws {
        let url = try BenchmarkDocuments.makeTextDocument()
        let (window, pdfView) = try Self.makeHostedView(url: url)
        defer { window.isHidden = true }
        try runOnMainLoop { try await Self.waitUntilDisplayed(pdfView) }
        let document = try XCTUnwrap(pdfView.document)
        let expected = document.findString("quick", withOptions: []).count
        _ = try runOnMainLoop { try await Self.beginFindString("quic", in: document) }
        measure(metrics: [XCTCPUMetric(), MainThreadStallMetric()]) {
            let count = try? runOnMainLoop {
                try await Self.beginFindString("quick", in: document)
            }
            XCTAssertEqual(count, expected)
        }
    }

    // MARK: - Helpers

    private static func makeHostedView(
        url: URL
    ) throws -> (UIWindow, MEGAPDFView) {
        let frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        let window = UIWindow(frame: frame)
        let root = UIViewController()
        window.rootViewController = root
        window.makeKeyAndVisible()
        let pdfView = MEGAPDFView(frame: frame)
        root.view.addSubview(pdfView)
        pdfView.configure(document: try XCTUnwrap(PDFDocument(url: url)))
        pdfView.layoutIfNeeded()
        return (window, pdfView)
    }

    /// Returns once `configure(document:)` has set `document`, which it does
    /// only after reading the widest page off the main actor.
    private static func waitUntilDisplayed(_ pdfView: MEGAPDFView) async throws {
        let deadline = ContinuousClock.now + .seconds(5)
        while pdfView.document == nil {
            guard ContinuousClock.now < deadline else { throw DisplayTimeout() }
            try await Task.sleep(for: .milliseconds(2))
        }
        pdfView.layoutIfNeeded()
    }

    /// The match count, once PDFKit has also stopped reporting matches, so no
    /// leftover work is billed to the next iteration.
    private static func search(
        _ query: String,
        with searcher: PDFDocumentSearcher,
        in pdfView: PDFView
    ) async throws -> Int {
        var matchCount = 0
        // Matches the case-sensitive `findString` each benchmark expects.
        for await _ in searcher.matches(for: query, compareOptions: []) {
            matchCount += 1
        }
        try await waitUntilPDFKitStopsFinding(in: pdfView.document)
        return matchCount
    }

    /// The matches reported before the first end, once PDFKit has also
    /// stopped reporting matches. An earlier search is cancelled first, the
    /// way `PDFDocumentSearcher` does.
    private static func beginFindString(_ query: String, in document: PDFDocument) async throws -> Int {
        let counter = MatchCounter()
        document.cancelFindString()
        document.delegate = counter
        document.beginFindString(query, withOptions: [])
        while !counter.didEnd {
            try await Task.sleep(for: .milliseconds(2))
        }
        try await waitUntilPDFKitStopsFinding(in: document)
        return counter.matchCountBeforeEnd
    }
}

@MainActor
private func waitUntilPDFKitStopsFinding(in document: PDFDocument?) async throws {
    // PDFKit can run a second pass after the first reports its end, so idle
    // is only trusted once it holds for several polls in a row.
    var idlePolls = 0
    while idlePolls < 5 {
        try await Task.sleep(for: .milliseconds(2))
        idlePolls = document?.isFinding == true ? 0 : idlePolls + 1
    }
}

private struct DisplayTimeout: Error {}

@MainActor
private final class MatchCounter: NSObject {
    var matchCountBeforeEnd = 0
    var didEnd = false
}

extension MatchCounter: @preconcurrency PDFDocumentDelegate {
    func didMatchString(_ instance: PDFSelection) {
        if !didEnd { matchCountBeforeEnd += 1 }
    }

    func documentDidEndDocumentFind(_ notification: Notification) {
        didEnd = true
    }
}

