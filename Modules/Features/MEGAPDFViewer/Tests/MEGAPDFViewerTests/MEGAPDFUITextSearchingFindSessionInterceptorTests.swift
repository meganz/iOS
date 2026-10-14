import MEGAPDFSearchInterceptor
import MEGAPDFSearchInterceptorTestSupport
@testable import MEGAPDFViewer
import PDFKit
import Testing
import UIKit

@Suite(.serialized)
@MainActor
struct MEGAPDFUITextSearchingFindSessionInterceptorTests {
    @Test func shortQuery_finishesWithoutMatches() async throws {
        let fixture = try Fixture(pages: [.text("test tested")])
        let interceptor = try fixture.interceptor()

        let aggregator = MEGARecordingSearchAggregator.performingQuery("tes", on: interceptor)

        #expect(aggregator.didFinishSearching)
        #expect(aggregator.foundRangeCount == 0)
    }

    @Test func queryOfThreeCharactersInFourUTF16Units_finishesWithoutSearching() throws {
        let fixture = try Fixture(pages: [.text("test tested")])
        let interceptor = try fixture.interceptor()

        let aggregator = MEGARecordingSearchAggregator.performingQuery("ab👍", on: interceptor)

        #expect(aggregator.didFinishSearching)
        #expect(fixture.pdfView.document?.isFinding == false)
    }

    @Test func matchesOnLaterPages_reportPDFKitsOwnRanges() async throws {
        let fixture = try Fixture(pages: [
            .text("first page words here"),
            .text("second page alpha one"),
            .text("alpha starts third page")
        ])

        let interceptor = try fixture.interceptor()
        let ours = MEGARecordingSearchAggregator.performingQuery("alpha", on: interceptor)
        try await waitUntilFinished(ours)
        let pdfKits = MEGARecordingSearchAggregator.performingQuery(
            "alpha", onPDFKitSearcherIn: fixture.pdfView
        )
        try await waitUntilFinished(pdfKits)

        #expect(ours.foundRangeCount == 2)
        #expect(ours.hasSameRanges(as: pdfKits, in: fixture.pdfView))
        #expect(try fixture.texts(of: ours) == ["alpha", "alpha"])
    }

    @Test func compareFoundRange_ordersMatchesByDocumentPosition() async throws {
        let fixture = try Fixture(pages: [
            .text("alpha on the first page"),
            .text("alpha on the second page")
        ])
        let interceptor = try fixture.interceptor()
        let aggregator = MEGARecordingSearchAggregator.performingQuery("alpha", on: interceptor)
        try await waitUntilFinished(aggregator)
        try #require(aggregator.foundRangeCount == 2)

        #expect(aggregator.compareRange(at: 0, toRangeAt: 1, on: interceptor) == .orderedAscending)
        #expect(aggregator.compareRange(at: 1, toRangeAt: 0, on: interceptor) == .orderedDescending)
        #expect(aggregator.compareRange(at: 0, toRangeAt: 0, on: interceptor) == .orderedSame)
    }

    @Test func matchAfterSearchEnded_leavesSelectionUntouched() async throws {
        let fixture = try Fixture(pages: [.text("alpha on a page")])
        let searcher = PDFDocumentSearcher(pdfView: fixture.pdfView)
        let interceptor = try #require(MEGAPDFUITextSearchingFindSessionInterceptor(
            pdfView: fixture.pdfView,
            documentSearcher: searcher
        ))
        let aggregator = MEGARecordingSearchAggregator.performingQuery("alpha", on: interceptor)
        try await waitUntilFinished(aggregator)
        let match = try #require(
            fixture.pdfView.document?.findString("alpha", withOptions: []).first
        )
        let selectionChanges = SelectionChangeCounter()
        let observer = NotificationCenter.default.addObserver(
            forName: .PDFViewSelectionChanged,
            object: fixture.pdfView,
            queue: nil
        ) { _ in selectionChanges.increment() }
        defer { NotificationCenter.default.removeObserver(observer) }

        searcher.didMatchString(match)

        #expect(selectionChanges.count == 0)
    }

    @Test func releasedSearcher_cancelsItsSearch() throws {
        let fixture = try Fixture(pages: [.text("alpha on a page")])
        do {
            let interceptor = try fixture.interceptor()
            _ = MEGARecordingSearchAggregator.performingQuery("alpha", on: interceptor)
            #expect(fixture.pdfView.document?.isFinding == true)
        }

        #expect(fixture.pdfView.document?.isFinding == false)
    }

    @Test func cancelSearch_afterDocumentReplaced_cancelsSearchedDocument() throws {
        let fixture = try Fixture(pages: [.text("alpha on a page")])
        let searchedDocument = try #require(fixture.pdfView.document)
        let searcher = PDFDocumentSearcher(pdfView: fixture.pdfView)
        let interceptor = try #require(MEGAPDFUITextSearchingFindSessionInterceptor(
            pdfView: fixture.pdfView,
            documentSearcher: searcher
        ))
        _ = MEGARecordingSearchAggregator.performingQuery("alpha", on: interceptor)
        try #require(searchedDocument.isFinding)
        fixture.pdfView.document = PDFDocument()

        searcher.cancelSearch()

        #expect(searchedDocument.isFinding == false)
    }

    @Test func staleMatchOfEarlierQuery_isNotReported() async throws {
        let fixture = try Fixture(pages: [.text("alpha beta")])
        let searcher = PDFDocumentSearcher(pdfView: fixture.pdfView)
        let interceptor = try #require(MEGAPDFUITextSearchingFindSessionInterceptor(
            pdfView: fixture.pdfView,
            documentSearcher: searcher
        ))
        let staleMatch = try #require(
            fixture.pdfView.document?.findString("alpha", withOptions: []).first
        )

        let aggregator = MEGARecordingSearchAggregator.performingQuery("beta", on: interceptor)
        searcher.didMatchString(staleMatch)
        try await waitUntilFinished(aggregator)

        #expect(try fixture.texts(of: aggregator) == ["beta"])
    }

    @Test(arguments: ["ALPHA", "alpha beta"])
    func ownQueryMatches_areAllReported(query: String) async throws {
        let fixture = try Fixture(pages: [.text("alpha\nbeta alpha beta")])
        let searcher = PDFDocumentSearcher(pdfView: fixture.pdfView)
        let expectedCount = try #require(
            fixture.pdfView.document?.findString(query, withOptions: .caseInsensitive).count
        )
        var matchCount = 0
        var didFinish = false

        searcher.search(
            for: query,
            options: CaseInsensitiveSearchOptions(),
            in: try fixture.pdfKitTextInput(),
            onMatch: { _ in matchCount += 1 },
            onFinish: { didFinish = true }
        )
        for _ in 0..<100 where !didFinish {
            try await Task.sleep(for: .milliseconds(50))
        }

        #expect(didFinish)
        #expect(matchCount == expectedCount)
    }

    @Test func newQuery_reportsOnlyItsOwnMatchesToItsAggregator() async throws {
        let fixture = try Fixture(pages: [
            .text("alpha beta"),
            .text("beta alpha beta")
        ])
        let interceptor = try fixture.interceptor()

        let first = MEGARecordingSearchAggregator.performingQuery("alpha", on: interceptor)
        let second = MEGARecordingSearchAggregator.performingQuery("beta", on: interceptor)
        try await waitUntilFinished(second)
        try await Task.sleep(for: .milliseconds(200))

        #expect(second.foundRangeCount == 3)
        #expect(try fixture.texts(of: second) == ["beta", "beta", "beta"])
        #expect(try fixture.texts(of: first).allSatisfy { $0 == "alpha" })
    }

    private func waitUntilFinished(_ aggregator: MEGARecordingSearchAggregator) async throws {
        for _ in 0..<400 where !aggregator.didFinishSearching {
            try await Task.sleep(for: .milliseconds(50))
        }
        try #require(aggregator.didFinishSearching)
    }
}

private final class CaseInsensitiveSearchOptions: UITextSearchOptions {
    override var stringCompareOptions: String.CompareOptions { .caseInsensitive }
}

private final class SelectionChangeCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    var count: Int { lock.withLock { value } }

    func increment() {
        lock.withLock { value += 1 }
    }
}

@MainActor
private struct Fixture {
    enum Page {
        case text(String)
    }

    let window: UIWindow
    let pdfView: MEGAPDFView

    init(pages: [Page]) throws {
        let frame = CGRect(x: 0, y: 0, width: 400, height: 700)
        window = UIWindow(frame: frame)
        let root = UIViewController()
        window.rootViewController = root
        window.makeKeyAndVisible()
        pdfView = MEGAPDFView(frame: frame)
        root.view.addSubview(pdfView)
        let bounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 28)]
        let data = UIGraphicsPDFRenderer(bounds: bounds).pdfData { context in
            for page in pages {
                context.beginPage()
                switch page {
                case .text(let text):
                    text.draw(at: CGPoint(x: 48, y: 48), withAttributes: attributes)
                }
            }
        }
        pdfView.configure(document: try #require(PDFDocument(data: data)))
        pdfView.layoutIfNeeded()
    }

    func interceptor() throws -> MEGAPDFUITextSearchingFindSessionInterceptor {
        try #require(MEGAPDFUITextSearchingFindSessionInterceptor(
            pdfView: pdfView,
            documentSearcher: PDFDocumentSearcher(pdfView: pdfView)
        ))
    }

    func pdfKitTextInput() throws -> any UITextInput {
        try #require(textInput(in: pdfView))
    }

    func texts(of aggregator: MEGARecordingSearchAggregator) throws -> [String] {
        let input = try pdfKitTextInput()
        return aggregator.foundRanges.map { input.text(in: $0) ?? "" }
    }

    private func textInput(in view: UIView) -> (any UITextInput)? {
        for subview in view.subviews {
            if let input = subview as? any UITextInput { return input }
            if let input = textInput(in: subview) { return input }
        }
        return nil
    }
}
