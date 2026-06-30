import SwiftUI

/// A one-shot request to flash a row. `token` makes every request distinct, so
/// re-requesting the *same* `resultId` still registers as a change for the row's
/// `onChange` observer (repeat "Show location" taps on the same item).
struct RowFlashRequest: Equatable {
    let resultId: ResultId
    let token: Int
}

/// Holds the row scroll-and-highlight state for a results list, kept separate
/// from `SearchResultsViewModel` so that view model stays focused on search.
///
/// Owned by `SearchResultsContainerViewModel` and observed by the list view.
@MainActor
final class SearchResultsRowHighlighter: ObservableObject {
    /// One-shot request for the list to scroll a row into view. The list resets
    /// it to `nil` once the scroll is performed.
    @Published var scrollToResultId: ResultId?

    /// Pending one-shot flash request. The target row clears it (via
    /// `consumeFlash(token:)`) the moment it starts flashing, so it never lingers
    /// to re-fire when rows are torn down and rebuilt (e.g. re-entering the
    /// screen). A new token is minted per request so the same row can be
    /// re-flashed on repeat taps.
    @Published var flashRequest: RowFlashRequest?

    private var flashToken = 0

    /// Scrolls the row with `resultId` into view and flashes it once.
    func scrollToAndHighlight(resultId: ResultId) {
        scrollToResultId = resultId
        flashToken += 1
        flashRequest = RowFlashRequest(resultId: resultId, token: flashToken)
    }
    
    /// Consumes the pending flash once the target row has started it — mirroring
    /// how the list nils `scrollToResultId` after scrolling.
    func consumeFlash(token: Int) {
        guard flashRequest?.token == token else { return }
        flashRequest = nil
    }
}
