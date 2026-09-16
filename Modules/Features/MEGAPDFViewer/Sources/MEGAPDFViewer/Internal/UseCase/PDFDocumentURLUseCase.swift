import Foundation
import MEGADomain

/// A step in resolving a `PDFViewerDocumentSource` to a file on disk.
enum PDFDocumentLoadEvent: Equatable, Sendable {
    case progress(Float)
    case ready(URL)
}

enum PDFDocumentLoadError: Error, Equatable {
    case transferFailed
    case missingDownloadPath
}

protocol PDFDocumentURLUseCaseProtocol {
    func localDocumentURL(
        for pdfDocumentSource: PDFViewerDocumentSource
    ) -> AsyncThrowingStream<PDFDocumentLoadEvent, any Error>
}

struct PDFDocumentURLUseCase: PDFDocumentURLUseCaseProtocol {
    private let downloadUseCase: any DownloadNodeUseCaseProtocol

    init(downloadUseCase: some DownloadNodeUseCaseProtocol) {
        self.downloadUseCase = downloadUseCase
    }

    func localDocumentURL(
        for pdfDocumentSource: PDFViewerDocumentSource
    ) -> AsyncThrowingStream<PDFDocumentLoadEvent, any Error> {
        switch pdfDocumentSource {
        case .local(let url):
            existingFileEvents(url)
        case .node(let handle):
            downloadEvents(handle: handle)
        }
    }

    // MARK: - Private

    private func existingFileEvents(_ url: URL) -> AsyncThrowingStream<PDFDocumentLoadEvent, any Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        continuation.yield(.ready(url))
        continuation.finish()
        return stream
    }

    private func downloadEvents(handle: HandleEntity) -> AsyncThrowingStream<PDFDocumentLoadEvent, any Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: PDFDocumentLoadEvent.self,
            throwing: (any Error).self
        )
        let task = Task { [downloadUseCase] in
            guard let transferEvents = try? downloadUseCase.downloadFileToTempFolder(
                nodeHandle: handle,
                appData: nil
            ) else {
                continuation.finish(throwing: PDFDocumentLoadError.transferFailed)
                return
            }

            for await event in transferEvents {
                guard !Task.isCancelled else { return }
                switch event {
                case .update(let transfer):
                    guard transfer.totalBytes > 0 else { continue }
                    continuation.yield(.progress(Float(transfer.transferredBytes) / Float(transfer.totalBytes)))
                case .finish(let transfer):
                    if let path = transfer.path {
                        continuation.yield(.ready(URL(fileURLWithPath: path)))
                        continuation.finish()
                    } else {
                        continuation.finish(throwing: PDFDocumentLoadError.missingDownloadPath)
                    }
                    return
                default:
                    break
                }
            }
        }
        continuation.onTermination = { @Sendable _ in task.cancel() }
        return stream
    }
}
