import Foundation
import Observation

/// The state of one preview: its rows while they arrive, and whether the text is too large.
/// The view owns it with `@State` and calls `load(_:)` from `.task(id:)`, so SwiftUI cancels an old load.
@MainActor
@Observable
final class PreviewModel {
    enum Phase: Equatable {
        /// No batch arrived yet for the first text.
        case loading
        case rows
        case tooLarge
    }

    private(set) var phase = Phase.loading
    /// Grows when the rows of a new text replace the old ones, so the list goes back to the top.
    private(set) var generation = 0
    private(set) var rowCount = 0
    /// Lines in the current text.
    private(set) var lineCount = 0
    /// True when every chunk of the current text arrived.
    private(set) var isComplete = false
    /// The base URL of the text the rows come from.
    private(set) var baseURL: URL?
    /// Not observed: `generation` and `rowCount` change with it.
    @ObservationIgnored private(set) var store = PreviewRowStore()
    /// The newest load. Batches of an older load are dropped.
    @ObservationIgnored private var loadToken = 0
    /// The request of the rows shown now, once all of them arrived.
    @ObservationIgnored private var completeRequest: MarkdownParseRequest?
    /// The request of the rows in `store`, even when only some of them arrived.
    private(set) var shownRequest: MarkdownParseRequest?

    /// Parses `request` off the main actor and adds the rows of each chunk as it arrives.
    /// The old rows stay until the first batch of the new text, so the screen never goes blank.
    /// A request that is already complete loads nothing: `.task` runs again each time the view appears,
    /// and a new load would send the list back to the top.
    func load(_ request: MarkdownParseRequest, limits: PreviewParseLimits = PreviewParseLimits()) async {
        // Requests compare their text by bytes, so a text that differs only in Unicode form loads again.
        guard request != completeRequest else { return }
        loadToken += 1
        let token = loadToken
        // A cancelled load of the same text left its first rows. The parse makes them again, so they are skipped.
        var rowsToSkip = request == shownRequest ? store.count : 0
        var isFirstBatch = rowsToSkip == 0
        var textLineCount = 0
        do {
            for try await event in PreviewPipeline.run(request, limits: limits) {
                // The stream still holds batches the parser sent before the cancel. A cancelled load adds none of them.
                guard token == loadToken, !Task.isCancelled else { return }
                switch event {
                case .lineCount(let count):
                    // The old text stays on screen until the first batch, so the count is set with the rows.
                    textLineCount = count
                case .batch(let batch):
                    if isFirstBatch {
                        isFirstBatch = false
                        start(baseURL: request.baseURL, phase: .rows)
                        shownRequest = request
                    }
                    let skipped = min(rowsToSkip, batch.rows.count)
                    rowsToSkip -= skipped
                    store.append(Array(batch.rows.dropFirst(skipped)))
                    lineCount = textLineCount
                    rowCount = store.count
                }
            }
            // A cancelled consumer sees the stream end normally, so check again.
            guard token == loadToken, !Task.isCancelled else { return }
            isComplete = true
            completeRequest = request
        } catch {
            guard token == loadToken, !Task.isCancelled, (error as? PreviewPipeline.Failure) == .tooLarge else { return }
            start(baseURL: request.baseURL, phase: .tooLarge)
            shownRequest = request
            isComplete = true
            completeRequest = request
        }
    }

    /// Drops the rows of the old text.
    private func start(baseURL: URL?, phase: Phase) {
        completeRequest = nil
        store = PreviewRowStore()
        rowCount = 0
        lineCount = 0
        isComplete = false
        generation += 1
        self.baseURL = baseURL
        self.phase = phase
    }
}
