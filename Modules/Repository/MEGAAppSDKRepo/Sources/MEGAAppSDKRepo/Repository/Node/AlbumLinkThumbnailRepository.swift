import Foundation
import MEGADomain
import MEGASdk
import MEGASwift

/// A thumbnail repository that loads thumbnails for public album links.
///
/// This repository fetches the backing node via `PublicAlbumNodeProvider` and uses it to retrieve
/// the thumbnail. It intentionally does not call `getThumbnailWithNodeHandle(_:)`, which does not
/// load thumbnails for album links.
///
/// Rationale:
/// - Avoids changing `ThumbnailRepository` to depend on a node provider. The default provider uses
///   `sdk.node(for:)`, which acquires `SdkMutexGuard` and can hang. See IOS-10014.
///
/// See also: `ThumbnailRepositoryProtocol`, `PublicAlbumNodeProvider`.
public struct AlbumLinkThumbnailRepository: ThumbnailRepositoryProtocol {
    public static var newRepo: AlbumLinkThumbnailRepository {
        let sdk = MEGASdk.sharedSdk
        return .init(
            thumbnailRepository: ThumbnailRepository.newRepo,
            nodeProvider: DefaultMEGANodeProvider(sdk: sdk),
            sdk: sdk,
            fileManager: .default
        )
    }
    
    private let thumbnailRepository: any ThumbnailRepositoryProtocol
    private let nodeProvider: any MEGANodeProviderProtocol
    private let sdk: MEGASdk
    private let fileManager: FileManager
    
    public init(
        thumbnailRepository: some ThumbnailRepositoryProtocol,
        nodeProvider: some MEGANodeProviderProtocol,
        sdk: MEGASdk,
        fileManager: FileManager,
    ) {
        self.thumbnailRepository = thumbnailRepository
        self.nodeProvider = nodeProvider
        self.sdk = sdk
        self.fileManager = fileManager
    }
    
    public func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL? {
        thumbnailRepository.cachedThumbnail(for: node, type: type)
    }
    
    public func cachedThumbnail(for nodeHandle: HandleEntity, type: ThumbnailTypeEntity) -> URL? {
        thumbnailRepository.cachedThumbnail(for: nodeHandle, type: type)
    }
    
    public func generateCachingURL(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL {
        thumbnailRepository.generateCachingURL(for: node, type: type)
    }
    
    public func generateCachingURL(for base64Handle: Base64HandleEntity, type: ThumbnailTypeEntity) -> URL {
        thumbnailRepository.generateCachingURL(for: base64Handle, type: type)
    }
    
    public func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> URL {
        try await loadThumbnail(for: node.handle, base64Handle: node.base64Handle, type: type)
    }
    
    public func loadThumbnail(for nodeHandle: HandleEntity, type: ThumbnailTypeEntity) async throws -> URL {
        guard let base64Handle = MEGASdk.base64Handle(forHandle: nodeHandle) else {
            throw ThumbnailErrorEntity.noThumbnail(type)
        }
        return try await loadThumbnail(for: nodeHandle, base64Handle: base64Handle, type: type)
    }
    
    public func cachedPreviewOrOriginalPath(for node: NodeEntity) -> String? {
        thumbnailRepository.cachedPreviewOrOriginalPath(for: node)
    }
    
    private func loadThumbnail(for nodeHandle: HandleEntity, base64Handle: Base64HandleEntity, type: ThumbnailTypeEntity) async throws -> URL {
        guard type == .thumbnail else {
            return try await thumbnailRepository.loadThumbnail(for: nodeHandle, type: type)
        }
        let url = generateCachingURL(for: base64Handle, type: type)
        guard !fileManager.fileExists(atPath: url.path) else {
            return url
        }
        guard let node = await nodeProvider.node(for: nodeHandle) else {
            throw ThumbnailErrorEntity.nodeNotFound
        }
        return try await downloadThumbnail(for: node, to: url)
    }
    
    private func downloadThumbnail(for node: MEGANode, to url: URL) async throws -> URL {
        return try await withAsyncThrowingValue { completion in
            sdk.getThumbnailNode(node, destinationFilePath: url.path, delegate: ThumbnailRequestDelegate { result in
                completion(result)
            })
        }
    }
}

extension AlbumLinkThumbnailRepository {
    /// A preconfigured variation of AlbumLinkThumbnailRepository. This uses the .sharedSDK in conjunction with the PublicAlbumNodeProvider. This version is typically only required to be used when working with Public SetEntities and SetElements.
    /// - Returns: ThumbnailRepository - Public Set and Element Configuration
    public static func albumLinkThumbnailRepository(nodeProvider: PublicAlbumNodeProvider = .shared) -> Self {
        AlbumLinkThumbnailRepository(
            thumbnailRepository: ThumbnailRepository(
                sdk: .sharedSdk,
                fileManager: .default,
                nodeProvider: nodeProvider),
            nodeProvider: nodeProvider,
            sdk: .sharedSdk,
            fileManager: .default)
    }
}
