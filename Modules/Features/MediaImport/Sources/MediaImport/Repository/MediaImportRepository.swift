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

        for try await url in stagedFileURL(provider: itemProvider, contentType: contentType, progressHandler: progressHandler) {
            return url
        }
        throw MediaImportRepositoryError.noFileURLProvided
    }

    // MARK: - Private

    private func stagedFileURL(
        provider: NSItemProvider,
        contentType: UTType,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) -> AsyncThrowingStream<URL, any Error> {
        AsyncThrowingStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
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
                    if case .terminated = continuation.yield(stagedURL) {
                        // Consumer already cancelled, remove staged file
                        try? FileManager.default.removeItem(at: stagedURL)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            let observation = progress.observe(
                \.fractionCompleted,
                options: [.new]
            ) { progress, _ in
                progressHandler(progress.fractionCompleted)
            }

            // Deliberately no progress.cancel() here: cancelling the PhotosUI-owned
            // progress races its in-flight completion, which double-removes an internal
            // KVO observer and crashes with NSRangeException.
            continuation.onTermination = { @Sendable _ in
                observation.invalidate()
            }
        }
    }
}
