import Combine
import PDFKit
import UIKit

/// Searches one PDF with the viewer's own option preferences, and shows its
/// matches until the search changes or ends.
@MainActor
final class PDFViewFindSession: UIFindSession {
    let analyticsID = UUID()
    var onSearchResultChanged: ((UUID, Int) -> Void)? {
        get { viewModel.onSearchResultChanged }
        set { viewModel.onSearchResultChanged = newValue }
    }

    private let viewModel: PDFViewFindSessionSearchResultsViewModel
    private weak var pdfView: PDFView?
    private weak var findInteraction: UIFindInteraction?
    private let scrollAdjuster: PDFJumpToSearchResultScrollAdjuster
    private let highlightOverlay: PDFSearchHighlightOverlayProvider
    private let preferences: PDFViewSearchPreferences
    private var subscriptions = Set<AnyCancellable>()

    /// UIKit can retain checked options across documents while submitting
    /// default options for new queries, so searches use `preferences` and
    /// ignore the options UIKit passes.
    init(
        pdfView: PDFView,
        findInteraction: UIFindInteraction,
        documentSearcher: any PDFDocumentSearching,
        preferences: PDFViewSearchPreferences,
        scrollAdjuster: PDFJumpToSearchResultScrollAdjuster,
        highlightOverlay: PDFSearchHighlightOverlayProvider
    ) {
        self.pdfView = pdfView
        self.findInteraction = findInteraction
        self.scrollAdjuster = scrollAdjuster
        self.highlightOverlay = highlightOverlay
        self.preferences = preferences
        viewModel = PDFViewFindSessionSearchResultsViewModel(
            searchUseCase: PDFDocumentSearchUseCase(documentSearcher: documentSearcher)
        )
        super.init()
        viewModel.$resultsUpdate
            .compactMap { $0 }
            .sink { [weak self] in self?.apply($0) }
            .store(in: &subscriptions)
    }

    override var resultCount: Int { viewModel.matches.count }

    override var highlightedResultIndex: Int { viewModel.highlightedIndex ?? NSNotFound }

    override func performSearch(query: String, options: UITextSearchOptions?) {
        viewModel.performSearch(
            query: query,
            compareOptions: preferences.compareOptions
        )
    }

    override func highlightNextResult(in direction: UITextStorageDirection) {
        viewModel.highlightNextResult(forward: direction == .forward)
    }

    override func invalidateFoundResults() {
        viewModel.invalidateResults()
    }

    /// Cancels the search and clears its highlights.
    func endSearch() {
        viewModel.endSearch()
    }

    private func apply(_ update: PDFViewFindSessionSearchResultsViewModel.ResultsUpdate) {
        findInteraction?.updateResultCount()
        highlightOverlay.show(viewModel.matches, highlightedIndex: viewModel.highlightedIndex, dims: update.dimsPages)
        guard let scrollTarget = update.scrollTarget, let pdfView else { return }
        scroll(to: scrollTarget.selection, in: pdfView)
    }

    private func scroll(to selection: PDFSelection, in pdfView: PDFView) {
        guard let page = selection.pages.first else { return }
        let rect = pdfView.convert(selection.bounds(for: page), from: page)
        let adjusterDidSuccessfullyScroll = scrollAdjuster.scrollRectIntoUsableArea(rect, in: pdfView)
        if !adjusterDidSuccessfullyScroll {
            pdfView.go(to: selection)
        }
    }
}

/// Stores Find option selections for one PDF viewer, starting with defaults.
@MainActor
final class PDFViewSearchPreferences {
    var matchesCase = false

    /// The options a search uses for the current Find option selections.
    var compareOptions: String.CompareOptions {
        matchesCase ? [] : [.caseInsensitive]
    }

    func makeMenu(defaultOptions: [UIMenuElement]) -> UIMenu {
        func option(_ element: UIMenuElement) -> UIMenuElement? {
            if let menu = element as? UIMenu {
                return menu.replacingChildren(menu.children.compactMap(option))
            }
            guard let action = element as? UIAction else { return element }
            switch action.identifier.rawValue {
            case "matchCase": break
            // `PDFDocumentSearcher` cannot match whole words yet.
            case "wholeWords": return nil
            default: return element
            }
            return UIAction(
                title: action.title,
                image: action.image,
                identifier: action.identifier,
                attributes: action.attributes,
                state: matchesCase ? .on : .off
            ) { [weak self] _ in
                self?.matchesCase.toggle()
                UIControl().sendAction(action)
            }
        }
        return UIMenu(children: defaultOptions.compactMap(option))
    }
}
