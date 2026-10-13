import Foundation
import PDFKit

enum PDFViewerDocumentLoadingState {
    struct ReadyState {
        struct OutlineLoadingState {
            let shouldLoadOutline: Bool
            let outlineDocumentURL: URL?
        }

        let document: PDFDocument
        let thumbnailDocument: PDFDocument?
        let documentIdentifierForLastViewedPageIndex: String?
        let initialPageIndex: Int?
        let outlineLoadingState: OutlineLoadingState
    }

    case ready(ReadyState)
    case failed
}

protocol PDFViewerDocumentLoadingUseCaseProtocol: Sendable {
    /// - Throws `CancellationError` when cancelled before all async loading
    ///   operations are done
    func loadDocument(at url: URL) async throws(CancellationError) -> PDFViewerDocumentLoadingState
}

struct PDFViewerDocumentLoadingUseCase: PDFViewerDocumentLoadingUseCaseProtocol {
    private let documentLoader: any PDFDocumentLoading
    private let outlineLoadingUseCase: any PDFOutlineLoadingUseCaseProtocol
    private let lastPageUseCase: any PDFViewerLastPageUseCaseProtocol

    init(
        documentLoader: some PDFDocumentLoading,
        outlineLoadingUseCase: some PDFOutlineLoadingUseCaseProtocol,
        lastPageUseCase: some PDFViewerLastPageUseCaseProtocol
    ) {
        self.documentLoader = documentLoader
        self.outlineLoadingUseCase = outlineLoadingUseCase
        self.lastPageUseCase = lastPageUseCase
    }

    func loadDocument(at url: URL) async throws(CancellationError) -> PDFViewerDocumentLoadingState {
        guard let document = documentLoader.loadDocument(url: url) else { return .failed }
        let shouldLoadOutline = outlineLoadingUseCase.hasOutline(document: document)
        let documentIdentifierForLastViewedPageIndex = await lastPageUseCase
            .documentIdentifierForLastViewedPageIndex(forDocumentAt: url)
        guard !Task.isCancelled else { throw CancellationError() }
        var initialPageIndex: Int?
        if let documentIdentifierForLastViewedPageIndex {
            initialPageIndex = await lastPageUseCase.loadLastPageIndex(
                forDocumentIdentifier: documentIdentifierForLastViewedPageIndex
            )
            guard !Task.isCancelled else { throw CancellationError() }
        }
        // Thumbnails render off the main thread, so they parse their own
        // instance rather than sharing the one `MEGAPDFView` draws from.
        let thumbnailDocument = documentLoader.loadDocument(url: url)
        guard !Task.isCancelled else { throw CancellationError() }
        return .ready(PDFViewerDocumentLoadingState.ReadyState(
            document: document,
            thumbnailDocument: thumbnailDocument,
            documentIdentifierForLastViewedPageIndex: documentIdentifierForLastViewedPageIndex,
            initialPageIndex: initialPageIndex,
            outlineLoadingState: .init(
                shouldLoadOutline: shouldLoadOutline,
                outlineDocumentURL: shouldLoadOutline ? url : nil
            )
        ))
    }
}
