import SwiftUI

/// Holds the row scroll-and-highlight state for a results list, kept separate
/// from `SearchResultsViewModel` so that view model stays focused on search.
///
/// Owned by `SearchResultsContainerViewModel` and observed by the list view.
@MainActor
final class SearchResultsRowHighlighter: ObservableObject {
    /// The row to keep tinted (`highlightPersists == true`) or flash once.
    /// `nil` means no row is highlighted.
    @Published var highlightedResultId: ResultId?
    /// Whether `highlightedResultId` stays tinted (persistent) or flashes once.
    @Published var highlightPersists: Bool = false
    /// One-shot request for the list to scroll a row into view. The list resets
    /// it to `nil` once the scroll is performed.
    @Published var scrollToResultId: ResultId?

    @Published var hasFlashedForCurrentTarget: Bool = false
    
    /// Scrolls the row with `resultId` into view and highlights it.
    /// - Parameter persistent: `true` keeps the row tinted until `clear()`;
    ///   `false` flashes it once.
    func scrollToAndHighlight(resultId: ResultId, persistent: Bool) {
        highlightedResultId = resultId
        highlightPersists = persistent
        scrollToResultId = resultId
        hasFlashedForCurrentTarget = false
    }

    /// Removes a persistent highlight.
    func clear() {
        highlightedResultId = nil
        highlightPersists = false
        hasFlashedForCurrentTarget = false
    }
}
