import Foundation
import MEGADomain

public protocol FileProviderContentUseCaseProtocol: Sendable {
    /// Downloads the contents of the file `item` into a new file in `directory`. Cancelling the calling task
    /// cancels the download.
    /// - Parameters:
    ///   - item: The file whose contents to download.
    ///   - directory: Where to create the file.
    ///   - progress: Called with how many bytes have been downloaded so far.
    /// - Returns: The downloaded file.
    /// - Throws: `CocoaError(.featureUnsupported)` for a folder, whose children are enumerated instead.
    func downloadContents(
        of item: FileProviderItemEntity,
        into directory: URL,
        progress: @escaping @Sendable (Int) -> Void
    ) async throws -> URL
}

public struct FileProviderContentUseCase: FileProviderContentUseCaseProtocol {
    private let downloadRepo: any FileProviderDownloadRepositoryProtocol

    public init(downloadRepo: any FileProviderDownloadRepositoryProtocol) {
        self.downloadRepo = downloadRepo
    }

    public func downloadContents(
        of item: FileProviderItemEntity,
        into directory: URL,
        progress: @escaping @Sendable (Int) -> Void
    ) async throws -> URL {
        guard item.node.isFile else {
            throw CocoaError(.featureUnsupported)
        }
        // A file of its own for every download: two downloads of the same item never write to the same file,
        // which is what the legacy extension needed `FileProviderDownloadCoordinator` for.
        let url = directory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        try await downloadRepo.download(node: item.node, to: url, progress: progress)
        return url
    }
}
