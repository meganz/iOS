import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGASdk
import MEGASDKRepo
import MEGASwift

struct ViewedLinkThumbnailRepository: ViewedLinkThumbnailRepositoryProtocol {
    private enum Constants {
        static let thumbnailCacheDirectory = "thumbnailsV3"
    }

    private let sdk: MEGASdk
    private let fileManager: FileManager
    private let cacheDirectoryURL: URL

    init(sdk: MEGASdk = .sharedSdk, fileManager: FileManager = .default) {
        self.sdk = sdk
        self.fileManager = fileManager
        cacheDirectoryURL = AppGroupContainer(fileManager: fileManager)
            .url(for: .cache)
            .appendingPathComponent(Constants.thumbnailCacheDirectory, isDirectory: true)
    }

    func cachedThumbnail(for handle: HandleEntity) -> ThumbnailEntity? {
        guard
            let url = cacheURL(for: handle),
            fileManager.fileExists(atPath: url.path)
        else { return nil }

        return ThumbnailEntity(url: url, type: .thumbnail)
    }

    func loadThumbnail(for link: ViewedLinkEntity) async throws -> ThumbnailEntity {
        guard let url = cacheURL(for: link.handle) else {
            throw ThumbnailErrorEntity.noThumbnail(.thumbnail)
        }

        if fileManager.fileExists(atPath: url.path) {
            return ThumbnailEntity(url: url, type: .thumbnail)
        }

        guard let node = await publicNode(for: link) else {
            throw ThumbnailErrorEntity.nodeNotFound
        }

        try? fileManager.createDirectory(at: cacheDirectoryURL, withIntermediateDirectories: true)

        return ThumbnailEntity(url: try await downloadThumbnail(for: node, to: url), type: .thumbnail)
    }

    private func cacheURL(for handle: HandleEntity) -> URL? {
        guard let base64Handle = MEGASdk.base64Handle(forHandle: handle) else { return nil }
        return cacheDirectoryURL.appendingPathComponent(base64Handle)
    }

    /// A link node is not part of the account tree, so it has to be resolved from the link itself
    /// before any file attribute can be requested for it.
    private func publicNode(for link: ViewedLinkEntity) async -> MEGANode? {
        await withCheckedContinuation { continuation in
            sdk.publicNode(
                forMegaFileLink: link.linkURL.absoluteString,
                delegate: RequestDelegate { (result: Result<MEGARequest, MEGAError>) in
                    continuation.resume(returning: try? result.get().publicNode)
                }
            )
        }
    }

    private func downloadThumbnail(for node: MEGANode, to url: URL) async throws -> URL {
        try await withAsyncThrowingValue { completion in
            sdk.getThumbnailNode(
                node,
                destinationFilePath: url.path,
                delegate: RequestDelegate { (result: Result<MEGARequest, MEGAError>) in
                    completion(result.map { _ in url }.mapError { $0 as any Error })
                }
            )
        }
    }
}
