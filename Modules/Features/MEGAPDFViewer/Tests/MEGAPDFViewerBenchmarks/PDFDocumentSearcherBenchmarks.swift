import MEGABenchmark
import MEGAPDFSearchInterceptor
import MEGAPDFSearchInterceptorTestSupport
@testable import MEGAPDFViewer
import PDFKit
import XCTest

/// `PDFDocumentSearcher` benchmarks with XCTest metrics. They run only with
/// `TEST_RUNNER_MEGA_BENCH=1`. Limits: `Limits.json` next to this file.
/// Run: `scripts/benchmark.sh Modules/Features/MEGAPDFViewer`.
@MainActor
final class PDFDocumentSearcherBenchmarks: BenchmarkCase {
    /// The first search on a newly opened document, through the Find
    /// interceptor, ranges included. A word on every line of the text
    /// document.
    func testFirstSearchOfFrequentWord() throws {
        let url = try BenchmarkDocuments.makeTextDocument()
        let expected = try XCTUnwrap(PDFDocument(url: url)).findString("quick", withOptions: []).count
        measure(metrics: [XCTCPUMetric(), MainThreadStallMetric()]) {
            let count = try? runOnMainLoop {
                let (window, pdfView) = try Self.makeHostedView(url: url)
                defer { window.isHidden = true }
                let interceptor = try Self.makeInterceptor(pdfView: pdfView)
                return try await Self.search("quick", on: interceptor, in: pdfView)
            }
            XCTAssertEqual(count, expected)
        }
    }

    /// `testFirstSearchOfFrequentWord` with `beginFindString` alone. The gap
    /// between the two is the cost of the ranges on a first search.
    func testFirstBeginFindStringOfFrequentWord() throws {
        let url = try BenchmarkDocuments.makeTextDocument()
        let expected = try XCTUnwrap(PDFDocument(url: url)).findString("quick", withOptions: []).count
        measure(metrics: [XCTCPUMetric(), MainThreadStallMetric()]) {
            let count = try? runOnMainLoop {
                let (window, pdfView) = try Self.makeHostedView(url: url)
                defer { window.isHidden = true }
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
        let expected = try XCTUnwrap(pdfView.document).findString("quick", withOptions: []).count
        let interceptor = try Self.makeInterceptor(pdfView: pdfView)
        _ = try runOnMainLoop { try await Self.search("quic", on: interceptor, in: pdfView) }
        measure(metrics: [XCTCPUMetric(), MainThreadStallMetric()]) {
            let count = try? runOnMainLoop {
                try await Self.search("quick", on: interceptor, in: pdfView)
            }
            XCTAssertEqual(count, expected)
        }
    }

    /// `testRefinedSearchOfFrequentWord` with `beginFindString` alone. The gap
    /// between the two is the cost of the ranges on a later search.
    func testRefinedBeginFindStringOfFrequentWord() throws {
        let url = try BenchmarkDocuments.makeTextDocument()
        let (window, pdfView) = try Self.makeHostedView(url: url)
        defer { window.isHidden = true }
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

    private static func makeHostedView(url: URL) throws -> (UIWindow, MEGAPDFView) {
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

    private static func makeInterceptor(
        pdfView: PDFView
    ) throws -> MEGAPDFUITextSearchingFindSessionInterceptor {
        try XCTUnwrap(MEGAPDFUITextSearchingFindSessionInterceptor(
            pdfView: pdfView,
            documentSearcher: PDFDocumentSearcher(pdfView: pdfView)
        ))
    }

    /// The match count, once PDFKit has also stopped reporting matches, so no
    /// leftover work is billed to the next iteration.
    private static func search(
        _ query: String,
        on interceptor: MEGAPDFUITextSearchingFindSessionInterceptor,
        in pdfView: PDFView
    ) async throws -> Int {
        let aggregator = MEGARecordingSearchAggregator.performingQuery(query, on: interceptor)
        while !aggregator.didFinishSearching {
            try await Task.sleep(for: .milliseconds(2))
        }
        try await waitUntilPDFKitStopsFinding(in: pdfView.document)
        return aggregator.foundRangeCount
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
