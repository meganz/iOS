import Combine
import Foundation
@testable import MEGAPDFViewer
import PDFKit
import Testing
import UIKit

@MainActor
struct PDFViewFindSessionSearchResultsViewModelTests {
    @Test func matchesReported_increaseResultCount() async throws {
        let (sut, searcher, matches) = try makeSUT(matchPages: [0, 1, 2])
        sut.performSearch(query: "alpha", compareOptions: .caseInsensitive)

        for match in matches { await searcher.report(match) }

        #expect(sut.matches.count == 3)
    }

    @Test func firstMatch_isHighlightedOnArrival() async throws {
        let (sut, searcher, matches) = try makeSUT(matchPages: [0, 1, 2])
        sut.performSearch(query: "alpha", compareOptions: .caseInsensitive)
        let updates = UpdateRecorder(sut)

        await searcher.report(matches[0])

        #expect(sut.highlightedIndex == 0)
        #expect(updates.values == [.init(scrollTarget: matches[0], dimsPages: true)])
    }

    @Test func laterMatches_publishUpdatesWithoutScroll() async throws {
        let (sut, searcher, matches) = try makeSUT(matchPages: [0, 1, 2])
        sut.performSearch(query: "alpha", compareOptions: .caseInsensitive)
        await searcher.report(matches[0])
        let updates = UpdateRecorder(sut)

        for match in matches.dropFirst() { await searcher.report(match) }

        #expect(sut.highlightedIndex == 0)
        #expect(updates.values == Array(repeating: .init(scrollTarget: nil, dimsPages: true), count: 2))
    }

    @Test func newQuery_keepsPagesDimmedUntilItsSearchEnds() async throws {
        let (sut, searcher, matches) = try makeSUT(matchPages: [0])
        sut.performSearch(query: "alpha", compareOptions: .caseInsensitive)
        await searcher.report(matches[0])
        let updates = UpdateRecorder(sut)

        sut.performSearch(query: "alphas", compareOptions: .caseInsensitive)

        #expect(sut.matches.isEmpty)
        #expect(!updates.values.isEmpty)
        #expect(updates.values.allSatisfy { $0.dimsPages })
    }

    @Test func searchFindingNothing_undimsPages() async throws {
        let (sut, searcher, matches) = try makeSUT(matchPages: [0])
        sut.performSearch(query: "alpha", compareOptions: .caseInsensitive)
        await searcher.report(matches[0])
        sut.performSearch(query: "alphas", compareOptions: .caseInsensitive)
        let updates = UpdateRecorder(sut)

        await searcher.finish()

        #expect(updates.values.last?.dimsPages == false)
    }

    @Test func endSearch_undimsPages() async throws {
        let (sut, searcher, matches) = try makeSUT(matchPages: [0])
        sut.performSearch(query: "alpha", compareOptions: .caseInsensitive)
        await searcher.report(matches[0])
        let updates = UpdateRecorder(sut)

        sut.endSearch()

        #expect(updates.values.last?.dimsPages == false)
    }

    @Test func highlightNextForward_wrapsFromLastToFirst() async throws {
        let sut = try await makeFinishedSearch(matchPages: [0, 1, 2])

        sut.highlightNextResult(forward: true)
        sut.highlightNextResult(forward: true)
        #expect(sut.highlightedIndex == 2)
        sut.highlightNextResult(forward: true)

        #expect(sut.highlightedIndex == 0)
    }

    @Test func highlightNextBackward_wrapsFromFirstToLast() async throws {
        let sut = try await makeFinishedSearch(matchPages: [0, 1, 2])

        sut.highlightNextResult(forward: false)

        #expect(sut.highlightedIndex == 2)
    }

    @Test func highlightNext_withNoMatches_leavesNoHighlight() async throws {
        let (sut, searcher, _) = try makeSUT(matchPages: [])
        sut.performSearch(query: "alpha", compareOptions: .caseInsensitive)
        await searcher.finish()

        sut.highlightNextResult(forward: true)

        #expect(sut.highlightedIndex == nil)
    }

    @Test func invalidateResults_clearsMatchesAndStartsNewGeneration() async throws {
        let (sut, searcher, matches) = try makeSUT(matchPages: [0, 1])
        var reports: [(generation: UUID, index: Int)] = []
        sut.onSearchResultChanged = { reports.append(($0, $1)) }
        sut.performSearch(query: "alpha", compareOptions: .caseInsensitive)
        for match in matches { await searcher.report(match) }
        await searcher.finish()
        sut.highlightNextResult(forward: true)

        sut.invalidateResults()

        #expect(sut.matches.isEmpty)
        #expect(sut.highlightedIndex == nil)
        sut.performSearch(query: "alpha", compareOptions: .caseInsensitive)
        for match in matches { await searcher.report(match) }
        await searcher.finish()
        sut.highlightNextResult(forward: true)
        let generations = reports.map(\.generation)
        try #require(generations.count == 4)
        #expect(generations[0] == generations[1])
        #expect(generations[2] == generations[3])
        #expect(generations[1] != generations[2])
    }

    @Test func endSearch_clearsMatchesAndHighlight() async throws {
        let (sut, searcher, matches) = try makeSUT(matchPages: [0, 1])
        sut.performSearch(query: "alpha", compareOptions: .caseInsensitive)
        for match in matches { await searcher.report(match) }
        let cancelsBefore = searcher.cancelCount

        sut.endSearch()
        await settle()

        #expect(searcher.cancelCount == cancelsBefore + 1)
        #expect(sut.matches.isEmpty)
        #expect(sut.highlightedIndex == nil)
    }

    @Test(arguments: [String.CompareOptions(), .caseInsensitive])
    func performSearch_passesItsCompareOptionsToTheSearcher(compareOptions: String.CompareOptions) throws {
        let (sut, searcher, _) = try makeSUT(matchPages: [])

        sut.performSearch(query: "alpha", compareOptions: compareOptions)

        #expect(searcher.searches == [.init(query: "alpha", compareOptions: compareOptions)])
    }

    @Test func highlightNext_reportsCurrentThenNewIndex() async throws {
        let sut = try await makeFinishedSearch(matchPages: [0, 1, 2])
        var reports: [(generation: UUID, index: Int)] = []
        sut.onSearchResultChanged = { reports.append(($0, $1)) }

        sut.highlightNextResult(forward: true)

        #expect(reports.map(\.index) == [0, 1])
        #expect(Set(reports.map(\.generation)).count == 1)
    }

    // MARK: - Helpers

    private func makeSUT(
        matchPages: [Int]
    ) throws -> (PDFViewFindSessionSearchResultsViewModel, MockPDFDocumentSearcher, [PDFSearchMatch]) {
        let searcher = MockPDFDocumentSearcher()
        let sut = PDFViewFindSessionSearchResultsViewModel(searchUseCase: PDFDocumentSearchUseCase(documentSearcher: searcher))
        return (sut, searcher, try makeMatches(onPages: matchPages))
    }

    /// A search that found one match on each of `matchPages`, highlighting the
    /// first.
    private func makeFinishedSearch(matchPages: [Int]) async throws -> PDFViewFindSessionSearchResultsViewModel {
        let (sut, searcher, matches) = try makeSUT(matchPages: matchPages)
        sut.performSearch(query: "alpha", compareOptions: .caseInsensitive)
        for match in matches { await searcher.report(match) }
        await searcher.finish()
        try #require(sut.highlightedIndex == 0)
        return sut
    }

    private func makeMatches(onPages pageIndices: [Int]) throws -> [PDFSearchMatch] {
        guard !pageIndices.isEmpty else { return [] }
        let bounds = CGRect(x: 0, y: 0, width: 200, height: 200)
        let data = UIGraphicsPDFRenderer(bounds: bounds).pdfData { context in
            for _ in pageIndices {
                context.beginPage()
                "alpha".draw(at: CGPoint(x: 20, y: 20))
            }
        }
        let document = try #require(PDFDocument(data: data))
        let selections = document.findString("alpha", withOptions: [])
        try #require(selections.count == pageIndices.count)
        return zip(selections, pageIndices).map { PDFSearchMatch(selection: $0, pageIndex: $1) }
    }
}

@MainActor
private final class UpdateRecorder {
    private(set) var values: [PDFViewFindSessionSearchResultsViewModel.ResultsUpdate] = []
    private var subscription: AnyCancellable?

    init(_ viewModel: PDFViewFindSessionSearchResultsViewModel) {
        subscription = viewModel.$resultsUpdate
            .dropFirst()
            .compactMap { $0 }
            .sink { [weak self] in self?.values.append($0) }
    }
}
