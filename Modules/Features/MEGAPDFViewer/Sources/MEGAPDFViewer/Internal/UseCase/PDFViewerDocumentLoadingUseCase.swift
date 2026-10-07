import Foundation
import PDFKit

enum PDFViewerDocumentLoadingState {
    struct ReadyState {
        let document: PDFDocument
        let thumbnailDocument: PDFDocument?
        let documentIdentifierForLastViewedPageIndex: String?
        let initialPageIndex: Int?
    }

    case ready(ReadyState)
    case failed
}

protocol PDFViewerDocumentLoadingUseCaseProtocol: Sendable {
    /// - Throws `CancellationError` when cancelled before all async loading
    ///   operations are done
    func loadDocument(at url: URL) async throws -> PDFViewerDocumentLoadingState
}

struct PDFViewerDocumentLoadingUseCase: PDFViewerDocumentLoadingUseCaseProtocol {
    private let documentLoader: any PDFDocumentLoading
    private let lastPageUseCase: any PDFViewerLastPageUseCaseProtocol

    init(
        documentLoader: some PDFDocumentLoading,
        lastPageUseCase: some PDFViewerLastPageUseCaseProtocol
    ) {
        self.documentLoader = documentLoader
        self.lastPageUseCase = lastPageUseCase
    }

    func loadDocument(at url: URL) async throws -> PDFViewerDocumentLoadingState {
        guard let document = documentLoader.loadDocument(url: url) else { return .failed }
        let documentIdentifierForLastViewedPageIndex = await lastPageUseCase
            .documentIdentifierForLastViewedPageIndex(forDocumentAt: url)
        try Task.checkCancellation()
        var initialPageIndex: Int?
        if let documentIdentifierForLastViewedPageIndex {
            initialPageIndex = await lastPageUseCase.loadLastPageIndex(
                forDocumentIdentifier: documentIdentifierForLastViewedPageIndex
            )
            try Task.checkCancellation()
        }
        // Thumbnails render off the main thread, so they parse their own
        // instance rather than sharing the one `MEGAPDFView` draws from.
        let thumbnailDocument = documentLoader.loadDocument(url: url)
        return .ready(PDFViewerDocumentLoadingState.ReadyState(
            document: document,
            thumbnailDocument: thumbnailDocument,
            documentIdentifierForLastViewedPageIndex: documentIdentifierForLastViewedPageIndex,
            initialPageIndex: initialPageIndex
        ))
    }
}
