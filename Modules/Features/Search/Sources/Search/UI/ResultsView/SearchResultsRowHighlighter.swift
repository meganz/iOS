import SwiftUI

/// Holds the row scroll-and-highlight state for a results list, kept separate
/// from `SearchResultsViewModel` so that view model stays focused on search.
///
/// Owned by `SearchResultsContainerViewModel` and observed by the list view.
@MainActor
final class SearchResultsRowHighlighter: ObservableObject {
    /// The row to flash. `nil` means no row is highlighted.
    @Published var highlightedResultId: ResultId?
    /// One-shot request for the list to scroll a row into view. The list resets
    /// it to `nil` once the scroll is performed.
    @Published var scrollToResultId: ResultId?

    @Published var hasFlashedForCurrentTarget: Bool = false

    /// Scrolls the row with `resultId` into view and flashes it once.
    func scrollToAndHighlight(resultId: ResultId) {
        highlightedResultId = resultId
        scrollToResultId = resultId
        hasFlashedForCurrentTarget = false
    }
}
