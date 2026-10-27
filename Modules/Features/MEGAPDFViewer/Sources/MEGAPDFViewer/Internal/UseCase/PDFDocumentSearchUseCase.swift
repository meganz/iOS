import Foundation
import MEGASwift

@MainActor
protocol PDFDocumentSearchUseCaseProtocol {
    /// Yields each match of `query` in document order and finishes when the
    /// search ends.
    /// - A query shorter than four characters finishes without matches.
    /// - Cancelling the task that iterates the matches cancels the search.
    func matches(for query: String, compareOptions: String.CompareOptions) -> AnyAsyncSequence<PDFSearchMatch>
}

struct PDFDocumentSearchUseCase: PDFDocumentSearchUseCaseProtocol {
    private let documentSearcher: any PDFDocumentSearching

    init(documentSearcher: some PDFDocumentSearching) {
        self.documentSearcher = documentSearcher
    }

    func matches(for query: String, compareOptions: String.CompareOptions) -> AnyAsyncSequence<PDFSearchMatch> {
        guard query.count >= 4 else {
            return AnyAsyncSequence(AsyncStream<PDFSearchMatch> { $0.finish() })
        }
        return documentSearcher.matches(for: query, compareOptions: compareOptions)
    }
}
