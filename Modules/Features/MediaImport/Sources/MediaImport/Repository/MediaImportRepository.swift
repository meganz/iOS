import Foundation
import UniformTypeIdentifiers

enum MediaImportRepositoryError: Error {
    case noFileURLProvided
}

public struct MediaImportRepository: MediaImportRepositoryProtocol, Sendable {

    private let destinationDirectory: URL
    private let contentTypeResolver: any ContentTypeResolving
    private let fileStagingService: any FileStagingServiceProtocol

    /// - Parameter destinationDirectory: Directory where staged files are written.
    public init(destinationDirectory: URL) {
        self.init(
            destinationDirectory: destinationDirectory,
            contentTypeResolver: ContentTypeResolver(),
            fileStagingService: FileStagingService()
        )
    }

    /// - Parameters:
    ///   - destinationDirectory: Directory where staged files are written.
    ///   - contentTypeResolver: Resolves the preferred content type for a provider.
    ///   - fileStagingService: Handles moving/copying files to the staging directory.
    package init(
        destinationDirectory: URL,
        contentTypeResolver: some ContentTypeResolving,
        fileStagingService: some FileStagingServiceProtocol
    ) {
        self.destinationDirectory = destinationDirectory
        self.contentTypeResolver = contentTypeResolver
        self.fileStagingService = fileStagingService
    }

    public func loadAndStageItem(
        from itemProvider: NSItemProvider,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let contentType = contentTypeResolver.preferredContentType(for: itemProvider)

        var stagedURL: URL?
        for try await event in loadEvents(provider: itemProvider, contentType: contentType) {
            switch event {
            case .progress(let fraction):
                progressHandler(fraction)
            case .completed(let url):
                stagedURL = url
            }
        }

        guard let stagedURL else {
            throw MediaImportRepositoryError.noFileURLProvided
        }
        return stagedURL
    }

    // MARK: - Private

    private enum LoadEvent: Sendable {
        case progress(Double)
        case completed(URL)
    }

    private func loadEvents(
        provider: NSItemProvider,
        contentType: UTType
    ) -> AsyncThrowingStream<LoadEvent, any Error> {
        AsyncThrowingStream { continuation in
            let progress = provider.loadFileRepresentation(
                for: contentType
            ) { [destinationDirectory, fileStagingService] url, _, error in
                if let error {
                    continuation.finish(throwing: error)
                    return
                }

                guard let url else {
                    continuation.finish(throwing: MediaImportRepositoryError.noFileURLProvided)
                    return
                }

                do {
                    let stagedURL = try fileStagingService.stageFile(
                        from: url,
                        to: destinationDirectory
                    )
                    continuation.yield(.completed(stagedURL))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            let observation = progress.observe(
                \.fractionCompleted,
                options: [.new]
            ) { progress, _ in
                continuation.yield(.progress(progress.fractionCompleted))
            }

            continuation.onTermination = { @Sendable _ in
                progress.cancel()
                observation.invalidate()
            }
        }
    }
}
