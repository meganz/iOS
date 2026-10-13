import Foundation
@testable import MEGAPDFViewer
import PDFKit

final class MockPDFViewerDocumentLoadingUseCase: PDFViewerDocumentLoadingUseCaseProtocol, @unchecked Sendable {
    struct PreparationInvocation {
        let document: PDFDocument
        let url: URL
        let password: String?
    }

    private let documentUnlocker: MockPDFDocumentUnlocker

    var loadingResult: PDFViewerDocumentLoadingState
    var readyResult: PDFViewerDocumentLoadingState.ReadyState
    var unlockedLoadingResult: PDFViewerDocumentLoadingState?
    var suspendsPreparation = false
    var preparationError: (any Error)?
    private(set) var loadURLs: [URL] = []
    private(set) var preparationInvocations: [PreparationInvocation] = []
    private var preparationContinuation: CheckedContinuation<Void, Never>?
    private let signal = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(1))

    init(document: PDFDocument, url: URL, documentUnlocker: MockPDFDocumentUnlocker) {
        self.documentUnlocker = documentUnlocker
        loadingResult = .documentLocked(.init(document: document, localDocumentURL: url))
        readyResult = .init(
            document: document,
            thumbnailDocument: MockPDFDocumentLoader.makeDocument(),
            documentIdentifierForLastViewedPageIndex: "test-fingerprint",
            initialPageIndex: 2,
            outlineLoadingState: .init(shouldLoadOutline: false, outlineDocumentURL: nil)
        )
    }

    func loadDocument(at url: URL) async throws -> PDFViewerDocumentLoadingState {
        loadURLs.append(url)
        return loadingResult
    }

    nonisolated(nonsending) func unlockAndLoad(
        document: PDFDocument,
        documentUrl: URL,
        password: String
    ) async throws -> PDFViewerDocumentLoadingState {
        if !documentUnlocker.unlock(document: document, password: password) || document.isLocked {
            return .documentLocked(.init(document: document, localDocumentURL: documentUrl))
        }
        preparationInvocations.append(.init(document: document, url: documentUrl, password: password))
        if let preparationError { throw preparationError }
        if suspendsPreparation {
            await withCheckedContinuation { continuation in
                preparationContinuation = continuation
                signal.continuation.yield(())
            }
        }
        return unlockedLoadingResult ?? .ready(readyResult)
    }

    func operationDidReturn() {
        signal.continuation.yield(())
    }

    func waitForOperationOrReturn() async {
        var iterator = signal.stream.makeAsyncIterator()
        _ = await iterator.next()
    }

    func resumePreparation() {
        preparationContinuation?.resume()
        preparationContinuation = nil
    }
}
