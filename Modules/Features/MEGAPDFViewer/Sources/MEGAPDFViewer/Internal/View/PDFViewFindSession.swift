import Foundation
import MEGAPDFSearchInterceptor
import UIKit

/// Keeps Find option checkmarks and search behavior consistent for one PDF.
///
/// UIKit can retain checked options across documents while submitting default
/// options for new queries, so this session uses the viewer's preferences.
@MainActor
final class PDFViewFindSession: UITextSearchingFindSession {
    let analyticsID = UUID()
    var onSearchResultChanged: ((UUID, Int) -> Void)?
    private var generationID = UUID()
    private let preferences: PDFViewSearchPreferences
    private let interceptor: MEGAPDFUITextSearchingFindSessionInterceptor

    init(
        interceptor: MEGAPDFUITextSearchingFindSessionInterceptor,
        preferences: PDFViewSearchPreferences
    ) {
        self.preferences = preferences
        // `searchableObject` is weak, so the session keeps its interceptor
        // alive for as long as the session itself.
        self.interceptor = interceptor
        super.init(searchableObject: interceptor)
    }

    override func performSearch(query: String, options: UITextSearchOptions?) {
        generationID = UUID()
        super.performSearch(
            query: query,
            options: PDFViewTextSearchOptions(preferences: preferences)
        )
    }
    override func highlightNextResult(in direction: UITextStorageDirection) {
        // Seed the current result before UIKit moves it, so the first
        // navigation after a query change uses its initial highlight.
        reportHighlightedResult()
        super.highlightNextResult(in: direction)
        reportHighlightedResult()
    }

    override func invalidateFoundResults() {
        generationID = UUID()
        super.invalidateFoundResults()
    }

    private func reportHighlightedResult() {
        let index = highlightedResultIndex
        guard index != NSNotFound else { return }
        onSearchResultChanged?(generationID, index)
    }

}

/// Stores Find option selections for one PDF viewer, starting with defaults.
@MainActor
final class PDFViewSearchPreferences {
    var matchesCase = false

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

/// Captures viewer preferences so each search receives stable option values.
@MainActor
private final class PDFViewTextSearchOptions: UITextSearchOptions {
    private let matchesCase: Bool

    init(preferences: PDFViewSearchPreferences) {
        matchesCase = preferences.matchesCase
        super.init()
    }

    override var stringCompareOptions: String.CompareOptions {
        matchesCase ? [] : [.caseInsensitive]
    }
}
