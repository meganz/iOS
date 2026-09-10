import Foundation
import MEGADomain

/// Process-wide single-flight download registry for the File Provider extension.
///
/// `startProvidingItem` blocks until the whole transfer finishes, so for large files fileproviderd gives up
/// waiting and reports a failure to the Files app even though the SDK transfer keeps running and completes.
/// When the user retries, the extension used to start a *second* download of the same node to the same path
/// with `.overwrite`, so two transfers wrote the same file. This actor keys in-flight downloads by their
/// destination path: the first caller starts the transfer, later callers for the same destination await it.
///
/// The key is the destination rather than the node handle on purpose. The legacy provider derives the local
/// path from the node's MEGA path, so a node renamed mid-transfer is requested again under a new URL; that
/// request must get its own transfer to the new location instead of joining one that is writing to the old one.
///
/// The download task is intentionally unstructured: cancelling a waiting caller (for example when fileproviderd
/// times out) must not cancel the transfer, otherwise the retry would start from zero every time.
actor FileProviderDownloadCoordinator {
    static let shared = FileProviderDownloadCoordinator()

    private var inFlightDownloads: [String: Task<Void, any Error>] = [:]

    /// Downloads `node` to `url`, or joins the download already running to that destination.
    /// `didFinish` runs exactly once per transfer, after it completes successfully, even if every waiting
    /// caller has already been cancelled.
    func download(
        node: NodeEntity,
        to url: URL,
        using transferUseCase: some TransferUseCaseProtocol,
        didFinish: @Sendable @escaping () async -> Void
    ) async throws {
        // fileproviderd hands the same location over as `/private/var/…` and `/var/…`, so normalise first.
        let destination = url.path.fileProviderStoragePath
        if let inFlightDownload = inFlightDownloads[destination] {
            return try await inFlightDownload.value
        }

        let download = Task {
            _ = try await transferUseCase.download(
                node: node,
                to: url,
                collisionResolution: .overwrite,
                startHandler: nil,
                progressHandler: nil
            )
        }
        inFlightDownloads[destination] = download

        Task {
            let result = await download.result
            finishDownload(to: destination)
            if case .success = result {
                await didFinish()
            }
        }

        try await download.value
    }

    private func finishDownload(to destination: String) {
        inFlightDownloads[destination] = nil
    }
}
