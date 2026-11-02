@testable import MEGAPDFViewer
import PDFKit
import Testing
import UIKit

@Suite(.serialized)
@MainActor
struct PDFViewFindSessionTests {
    // MARK: - Highlights

    @Test func highlightedMatch_isShownInItsPageOverlayAndMatchesQuery() async throws {
        let fixture = try await SessionFixture(pages: ["alpha one", "alpha two"])

        try await fixture.searchAndWait("alpha")

        let index = fixture.session.highlightedResultIndex
        try #require(index != NSNotFound)
        let highlighted = fixture.pdfView.searchHighlightOverlayViews
            .flatMap(\.boxes)
            .filter(\.isHighlighted)
        #expect(highlighted.map(\.matchIndex) == [index])
        let match = try #require(fixture.pdfView.document?.findString("alpha", withOptions: [])[index])
        #expect(match.string == "alpha")
    }

    @Test func matchFound_isHighlightedBeforeSearchEnds() async throws {
        let searcher = MockPDFDocumentSearcher()
        let fixture = try await SessionFixture(pages: ["alpha one", "alpha two"], searcher: searcher)
        let selection = try #require(fixture.pdfView.document?.findString("alpha", withOptions: []).first)
        fixture.session.performSearch(query: "alpha", options: nil)

        await searcher.report(PDFSearchMatch(selection: selection, pageIndex: 0))
        try await Task.sleep(for: .milliseconds(100))

        #expect(fixture.pdfView.searchHighlightOverlayViews.flatMap(\.boxes).count == 1)
    }

    @Test func highlights_persistAfterScrollAwayAndBack() async throws {
        let fixture = try await SessionFixture(pages: ["alpha one"] + Array(repeating: "filler", count: 12))
        try await fixture.searchAndWait("alpha")
        let document = try #require(fixture.pdfView.document)

        fixture.pdfView.go(to: try #require(document.page(at: document.pageCount - 1)))
        try await Task.sleep(for: .milliseconds(300))
        fixture.pdfView.go(to: try #require(document.page(at: 0)))
        try await Task.sleep(for: .milliseconds(300))

        #expect(fixture.pdfView.searchHighlightOverlayViews.flatMap(\.boxes).contains { $0.isHighlighted })
    }

    @Test func endSearch_clearsEveryPageOverlay() async throws {
        let fixture = try await SessionFixture(pages: ["alpha one", "alpha two"])
        try await fixture.searchAndWait("alpha")

        fixture.session.endSearch()
        try await Task.sleep(for: .milliseconds(100))

        let overlays = fixture.pdfView.searchHighlightOverlayViews
        #expect(overlays.allSatisfy { $0.boxes.isEmpty && !$0.isDimmed })
    }

    @Test func performSearch_highlightsFirstMatchInDocumentWhateverPageIsShown() async throws {
        let searcher = MockPDFDocumentSearcher()
        let fixture = try await SessionFixture(pages: ["alpha one", "alpha two"], searcher: searcher)
        let document = try #require(fixture.pdfView.document)
        fixture.pdfView.go(to: try #require(document.page(at: 1)))
        let matches = document.findString("alpha", withOptions: []).map {
            PDFSearchMatch(selection: $0, pageIndex: document.index(for: $0.pages[0]))
        }
        fixture.session.performSearch(query: "alpha", options: nil)

        for match in matches { await searcher.report(match) }

        #expect(fixture.session.highlightedResultIndex == 0)
    }

    // MARK: - Scrolling

    @Test func highlightNext_scrollsMatchIntoUsableArea() async throws {
        let pages = ["alpha one"] + Array(repeating: "filler", count: 6) + ["alpha far"]
        let fixture = try await SessionFixture(pages: pages)
        try await fixture.searchAndWait("alpha")
        let document = try #require(fixture.pdfView.document)
        let farMatch = try #require(document.findString("alpha", withOptions: []).last)
        let farPage = try #require(farMatch.pages.first)

        fixture.session.highlightNextResult(in: .forward)
        try await Task.sleep(for: .milliseconds(300))

        let rect = fixture.pdfView.convert(farMatch.bounds(for: farPage), from: farPage)
        #expect(fixture.session.highlightedResultIndex == 1)
        #expect(fixture.pdfView.bounds.contains(rect))
    }

    @Test func adjusterDecline_fallsBackToGoTo() async throws {
        let pages = ["alpha one"] + Array(repeating: "filler", count: 6) + ["alpha far"]
        // Without a scroll view the adjuster declines every jump.
        let adjuster = PDFJumpToSearchResultScrollAdjuster(contentScrollView: { nil })
        let fixture = try await SessionFixture(pages: pages, scrollAdjuster: adjuster)
        try await fixture.searchAndWait("alpha")
        let document = try #require(fixture.pdfView.document)

        fixture.session.highlightNextResult(in: .forward)
        try await Task.sleep(for: .milliseconds(300))

        let farPage = try #require(document.page(at: pages.count - 1))
        #expect(fixture.pdfView.visiblePages.contains(farPage))
    }

    // MARK: - Find interaction

    @Test func resultCountChange_updatesFindInteraction() async throws {
        let searcher = MockPDFDocumentSearcher()
        let fixture = try await SessionFixture(pages: ["alpha one"], searcher: searcher)
        let selection = try #require(fixture.pdfView.document?.findString("alpha", withOptions: []).first)
        fixture.session.performSearch(query: "alpha", options: nil)
        let countBefore = fixture.interaction.updateResultCountCalls

        await searcher.report(PDFSearchMatch(selection: selection, pageIndex: 0))

        #expect(fixture.session.resultCount == 1)
        #expect(fixture.interaction.updateResultCountCalls > countBefore)
    }
}

@MainActor
private final class CountingFindInteraction: UIFindInteraction {
    private(set) var updateResultCountCalls = 0

    override func updateResultCount() {
        updateResultCountCalls += 1
        super.updateResultCount()
    }
}

@MainActor
private final class NoSessionDelegate: NSObject, UIFindInteractionDelegate {
    func findInteraction(_ interaction: UIFindInteraction, sessionFor view: UIView) -> UIFindSession? { nil }
}

/// A `PDFViewFindSession` over a `SearchFixture`, wired as the handler wires it.
@MainActor
private struct SessionFixture {
    let base: SearchFixture
    let session: PDFViewFindSession
    let interaction: CountingFindInteraction
    let overlay: PDFSearchHighlightOverlayProvider
    private let delegate = NoSessionDelegate()

    var pdfView: MEGAPDFView { base.pdfView }

    init(
        pages: [String],
        searcher: (any PDFDocumentSearching)? = nil,
        scrollAdjuster: PDFJumpToSearchResultScrollAdjuster? = nil
    ) async throws {
        let overlay = PDFSearchHighlightOverlayProvider()
        self.overlay = overlay
        base = try await SearchFixture(pages: pages, overlayProvider: overlay)
        let pdfView = base.pdfView
        interaction = CountingFindInteraction(sessionDelegate: delegate)
        session = PDFViewFindSession(
            pdfView: pdfView,
            findInteraction: interaction,
            documentSearcher: searcher ?? base.searcher,
            preferences: PDFViewSearchPreferences(),
            scrollAdjuster: scrollAdjuster ?? PDFJumpToSearchResultScrollAdjuster(
                contentScrollView: { [weak pdfView] in pdfView?.contentScrollView },
                notificationCenter: NotificationCenter()
            ),
            highlightOverlay: overlay
        )
    }

    /// Searches `query` and waits for the search to end with a highlight.
    func searchAndWait(_ query: String) async throws {
        session.performSearch(query: query, options: nil)
        for _ in 0..<60 where base.pdfView.document?.isFinding == true
            || session.highlightedResultIndex == NSNotFound {
            try await Task.sleep(for: .milliseconds(50))
        }
        try #require(session.highlightedResultIndex != NSNotFound)
        try await Task.sleep(for: .milliseconds(100))
    }
}
