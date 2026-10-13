import Foundation
import PDFKit

enum PDFViewerDocumentLoadingState {
    struct DocumentLockedState {
        let document: PDFDocument
        let localDocumentURL: URL
    }

    struct ReadyState {
        struct OutlineLoadingState {
            let shouldLoadOutline: Bool
            let outlineDocumentURL: URL?
            let loadOutline: (@Sendable () async -> PDFOutlineItems)?

            init(
                shouldLoadOutline: Bool,
                outlineDocumentURL: URL?,
                loadOutline: (@Sendable () async -> PDFOutlineItems)? = nil
            ) {
                self.shouldLoadOutline = shouldLoadOutline
                self.outlineDocumentURL = outlineDocumentURL
                self.loadOutline = loadOutline
            }
        }

        let document: PDFDocument
        let thumbnailDocument: PDFDocument?
        let documentIdentifierForLastViewedPageIndex: String?
        let initialPageIndex: Int?
        let outlineLoadingState: OutlineLoadingState
    }

    case documentLocked(DocumentLockedState)
    case ready(ReadyState)
    case failed
}

protocol PDFViewerDocumentLoadingUseCaseProtocol: Sendable {
    /// - Throws `CancellationError` when cancelled before all async loading
    ///   operations are done
    func loadDocument(at url: URL) async throws -> PDFViewerDocumentLoadingState

    nonisolated(nonsending) func unlockAndLoad(
        document: PDFDocument,
        documentUrl: URL,
        password: String
    ) async throws -> PDFViewerDocumentLoadingState
}

struct PDFViewerDocumentLoadingUseCase: PDFViewerDocumentLoadingUseCaseProtocol {
    private let documentLoader: any PDFDocumentLoading
    private let outlineLoadingUseCase: any PDFOutlineLoadingUseCaseProtocol
    private let lastPageUseCase: any PDFViewerLastPageUseCaseProtocol
    private let documentUnlocker: any PDFDocumentUnlocking

    init(
        documentLoader: some PDFDocumentLoading,
        outlineLoadingUseCase: some PDFOutlineLoadingUseCaseProtocol,
        lastPageUseCase: some PDFViewerLastPageUseCaseProtocol,
        documentUnlocker: some PDFDocumentUnlocking = PDFDocumentUnlocker()
    ) {
        self.documentLoader = documentLoader
        self.outlineLoadingUseCase = outlineLoadingUseCase
        self.lastPageUseCase = lastPageUseCase
        self.documentUnlocker = documentUnlocker
    }

    func loadDocument(at url: URL) async throws -> PDFViewerDocumentLoadingState {
        guard let document = documentLoader.loadDocument(url: url) else { return .failed }
        if document.isLocked {
            return .documentLocked(.init(document: document, localDocumentURL: url))
        }
        return try await loadUnlockedDocument(document, documentUrl: url, unlockPassword: nil)
    }

    nonisolated(nonsending) func unlockAndLoad(
        document: PDFDocument,
        documentUrl: URL,
        password: String
    ) async throws -> PDFViewerDocumentLoadingState {
        try Task.checkCancellation()
        if document.isLocked {
            let isUnlockSuccessful = documentUnlocker.unlock(document: document, password: password)
                && !document.isLocked
            guard isUnlockSuccessful else {
                return .documentLocked(.init(document: document, localDocumentURL: documentUrl))
            }
        }
        return try await loadUnlockedDocument(document, documentUrl: documentUrl, unlockPassword: password)
    }

    private nonisolated(nonsending) func loadUnlockedDocument(
        _ document: PDFDocument,
        documentUrl: URL,
        unlockPassword: String?
    ) async throws -> PDFViewerDocumentLoadingState {
        let shouldLoadOutline = outlineLoadingUseCase.hasOutline(document: document)
        let (documentIdentifierForLastViewedPageIndex, initialPageIndex) = try await loadInitialPageIndex(
            documentUrl: documentUrl
        )
        try Task.checkCancellation()
        let thumbnailDocument = try await loadThumbnailDocument(
            documentUrl: documentUrl,
            unlockPassword: unlockPassword
        )
        try Task.checkCancellation()
        let loadOutline: (@Sendable () async -> PDFOutlineItems)?
        if shouldLoadOutline {
            loadOutline = { [outlineLoadingUseCase] in
                await outlineLoadingUseCase.loadOutline(
                    documentURL: documentUrl,
                    unlockPassword: unlockPassword
                )
            }
        } else {
            loadOutline = nil
        }
        return .ready(.init(
            document: document,
            thumbnailDocument: thumbnailDocument,
            documentIdentifierForLastViewedPageIndex: documentIdentifierForLastViewedPageIndex,
            initialPageIndex: initialPageIndex,
            outlineLoadingState: .init(
                shouldLoadOutline: shouldLoadOutline,
                outlineDocumentURL: shouldLoadOutline ? documentUrl : nil,
                loadOutline: loadOutline
            )
        ))
    }

    private func loadInitialPageIndex(
        documentUrl: URL
    ) async throws -> (documentIdentifier: String?, initialPageIndex: Int?) {
        let identifier = await lastPageUseCase
            .documentIdentifierForLastViewedPageIndex(forDocumentAt: documentUrl)
        try Task.checkCancellation()
        guard let identifier else { return (nil, nil) }
        let initialPageIndex = await lastPageUseCase.loadLastPageIndex(
            forDocumentIdentifier: identifier
        )
        try Task.checkCancellation()
        return (identifier, initialPageIndex)
    }

    @concurrent
    private func loadThumbnailDocument(documentUrl: URL, unlockPassword: String?) async throws -> sending PDFDocument? {
        // Thumbnails render off the main thread, so they parse their own
        // instance rather than sharing the one `MEGAPDFView` draws from.
        try Task.checkCancellation()
        guard let document = documentLoader.loadDocument(url: documentUrl) else { return nil }
        if document.isLocked {
            guard let unlockPassword,
                  documentUnlocker.unlock(document: document, password: unlockPassword),
                  !document.isLocked else { return nil }
        }
        return document
    }
}
