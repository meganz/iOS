import SwiftUI

/// Holds the row scroll-and-highlight state for a results list, kept separate
/// from `SearchResultsViewModel` so that view model stays focused on search.
///
/// Owned by `SearchResultsContainerViewModel` and observed by the list view.
///
/// The flash lifetime lives here, not in the row view's `@State`, so its
/// duration is consistent and survives the row being torn down and rebuilt (e.g.
/// while scrolling) — the row's highlight is just a function of `flashingResultId`.
@MainActor
final class SearchResultsRowHighlighter: ObservableObject {
    /// One-shot request for the list to scroll a row into view. The list clears
    /// it once the target row has been scrolled to.
    @Published var scrollToResultId: ResultId?

    /// A row that should start flashing once it's on screen. Consumed (set to
    /// `nil`) by the target row the moment it begins its flash, so it fires
    /// exactly once and never lingers to re-trigger on a later rebuild.
    @Published private(set) var pendingFlashResultId: ResultId?

    /// The row currently flashing. Drives the row's highlight background; cleared
    /// centrally after the hold duration.
    @Published private(set) var flashingResultId: ResultId?

    private var flashTask: Task<Void, Never>?
    private static let flashHoldNanoseconds: UInt64 = 1_500_000_000

    /// Scrolls the row with `resultId` into view and flashes it once it appears.
    func scrollToAndHighlight(resultId: ResultId) {
        scrollToResultId = resultId
        pendingFlashResultId = resultId
    }

    /// Called by the target row once it's on screen and ready to flash. Runs the
    /// centrally-timed flash so its duration doesn't depend on the row view's
    /// lifetime, and consumes the pending request so it flashes exactly once.
    func beginFlashIfPending(for resultId: ResultId) {
        guard pendingFlashResultId == resultId else { return }
        pendingFlashResultId = nil
        flashTask?.cancel()
        flashingResultId = resultId
        flashTask = Task {
            try? await Task.sleep(nanoseconds: Self.flashHoldNanoseconds)
            guard !Task.isCancelled else { return }
            flashingResultId = nil
        }
    }
}
