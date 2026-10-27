import MEGASwift
import PDFKit

/// Searches the text layer of the document shown in `pdfView`.
@MainActor
final class PDFDocumentSearcher: NSObject, PDFDocumentSearching {
    private weak var pdfView: PDFView?
    private weak var searchedDocument: PDFDocument?
    private var runningSearch: RunningSearch?

    init(pdfView: PDFView) {
        self.pdfView = pdfView
    }

    isolated deinit {
        // A running search would otherwise go on with no delegate.
        if let runningSearch {
            runningSearch.continuation.finish()
            searchedDocument?.cancelFindString()
        }
    }

    func matches(for query: String, compareOptions: String.CompareOptions) -> AnyAsyncSequence<PDFSearchMatch> {
        cancelSearch()
        let (stream, continuation) = AsyncStream.makeStream(of: PDFSearchMatch.self)
        guard let document = pdfView?.document else {
            continuation.finish()
            return AnyAsyncSequence(stream)
        }
        let searchID = UUID()
        continuation.onTermination = { [weak self] termination in
            guard case .cancelled = termination else { return }
            Task { @MainActor in self?.cancelSearch(searchID) }
        }
        // PDFKit's searchable view waits for PDFKit's image text recognition
        // of every page, including the recognition started by an earlier
        // query, so a query typed while that runs reports nothing until it
        // ends. `-[PDFDocument beginFindString:withOptions:]` searches only the
        // text layer and never waits for it.
        runningSearch = RunningSearch(
            id: searchID,
            query: query,
            compareOptions: compareOptions,
            continuation: continuation
        )
        searchedDocument = document
        document.delegate = self
        document.beginFindString(query, withOptions: compareOptions)
        return AnyAsyncSequence(stream)
    }

    /// Stops the running search and finishes its matches.
    func cancelSearch() {
        // `cancelFindString` reports the end of the cancelled search
        // synchronously, so the running search is dropped first.
        let cancelledSearch = runningSearch
        runningSearch = nil
        cancelledSearch?.continuation.finish()
        guard let searchedDocument, searchedDocument.delegate === self else { return }
        searchedDocument.cancelFindString()
    }

    private func cancelSearch(_ searchID: UUID) {
        // A cancelled iteration reports its termination after a hop to the
        // main actor, by which time a later search can be running.
        guard runningSearch?.id == searchID else { return }
        cancelSearch()
    }
}

// MARK: - PDFDocumentDelegate

extension PDFDocumentSearcher: @preconcurrency PDFDocumentDelegate {
    func didMatchString(_ instance: PDFSelection) {
        // PDFKit can keep reporting matches after the search's end, which
        // already dropped `runningSearch`. Its callbacks do not say which search they
        // belong to, so a match of a cancelled search is also dropped by its
        // text, in case PDFKit reports one after the next search begins.
        guard let runningSearch,
              instance.string?.compare(runningSearch.query, options: runningSearch.compareOptions) == .orderedSame,
              let document = searchedDocument,
              let page = instance.pages.first
        else { return }
        runningSearch.continuation.yield(PDFSearchMatch(selection: instance, pageIndex: document.index(for: page)))
    }

    func documentDidEndDocumentFind(_ notification: Notification) {
        let finishedSearch = runningSearch
        runningSearch = nil
        finishedSearch?.continuation.finish()
    }
}

// MARK: - RunningSearch

extension PDFDocumentSearcher {
    private struct RunningSearch {
        let id: UUID
        let query: String
        let compareOptions: String.CompareOptions
        let continuation: AsyncStream<PDFSearchMatch>.Continuation
    }
}
