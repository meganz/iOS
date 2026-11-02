import Combine
import Foundation

/// Owns the matches of one Find session, which one is highlighted, and moving
/// between them.
@MainActor
final class PDFViewFindSessionSearchResultsViewModel {
    /// Tells the view to redraw the results; it reads `matches` and
    /// `highlightedIndex` itself.
    struct ResultsUpdate: Equatable {
        /// The highlighted match, only when `highlightedIndex` changed because
        /// of a search or a next/previous request.
        let scrollTarget: PDFSearchMatch?
        /// True from the first match until a search finds nothing or ends,
        /// including while a new query replaces the matches.
        let dimsPages: Bool
    }

    @Published private(set) var resultsUpdate: ResultsUpdate?
    private(set) var matches: [PDFSearchMatch] = []
    private(set) var highlightedIndex: Int?
    var onSearchResultChanged: ((UUID, Int) -> Void)?

    private let searchUseCase: any PDFDocumentSearchUseCaseProtocol
    private var generationID = UUID()
    private var dimsPages = false
    private var searchTask: Task<Void, Never>?

    init(searchUseCase: some PDFDocumentSearchUseCaseProtocol) {
        self.searchUseCase = searchUseCase
    }

    /// Highlights the first match as soon as it arrives.
    func performSearch(query: String, compareOptions: String.CompareOptions) {
        generationID = UUID()
        searchTask?.cancel()
        clearResults()
        let matches = searchUseCase.matches(for: query, compareOptions: compareOptions)
        searchTask = Task { [weak self] in
            for await match in matches {
                // A match can resume this task after the next search has
                // already cancelled it.
                guard !Task.isCancelled else { return }
                self?.didFind(match)
            }
            guard !Task.isCancelled else { return }
            self?.didFinishSearching()
        }
    }

    /// Moves the highlight, wrapping at both ends.
    func highlightNextResult(forward: Bool) {
        guard let highlightedIndex else { return }
        // Seed the current result before moving it, so the first navigation
        // after a query change reports its initial highlight.
        reportHighlightedResult()
        let count = matches.count
        self.highlightedIndex = (highlightedIndex + (forward ? 1 : count - 1)) % count
        publish(scrollsToHighlighted: true)
        reportHighlightedResult()
    }

    /// Cancels the search, clears the results and starts a new generation.
    func invalidateResults() {
        generationID = UUID()
        endSearch()
    }

    /// Cancels the search and clears the results.
    func endSearch() {
        searchTask?.cancel()
        searchTask = nil
        dimsPages = false
        clearResults()
    }

    private func clearResults() {
        matches = []
        highlightedIndex = nil
        publish(scrollsToHighlighted: false)
    }

    private func didFind(_ match: PDFSearchMatch) {
        matches.append(match)
        dimsPages = true
        guard highlightedIndex == nil else {
            publish(scrollsToHighlighted: false)
            return
        }
        highlightedIndex = 0
        publish(scrollsToHighlighted: true)
    }

    private func didFinishSearching() {
        guard matches.isEmpty, dimsPages else { return }
        dimsPages = false
        publish(scrollsToHighlighted: false)
    }

    private func publish(scrollsToHighlighted: Bool) {
        let scrollTarget = scrollsToHighlighted ? highlightedIndex.map { matches[$0] } : nil
        resultsUpdate = ResultsUpdate(scrollTarget: scrollTarget, dimsPages: dimsPages)
    }

    private func reportHighlightedResult() {
        guard let highlightedIndex else { return }
        onSearchResultChanged?(generationID, highlightedIndex)
    }
}
