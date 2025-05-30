import Foundation
import MEGADomain
import MEGASdk
import MEGASwift

public struct ThumbnailRepository: ThumbnailRepositoryProtocol {
    public static var newRepo: ThumbnailRepository {
        let sdk = MEGASdk.sharedSdk
        return ThumbnailRepository(sdk: sdk, fileManager: .default,
                                   nodeProvider: DefaultMEGANodeProvider(sdk: sdk))
    }
    
    private enum Constants {
        static let thumbnailCacheDirectory = "thumbnailsV3"
        static let previewCacheDirectory = "previewsV3"
        static let originalCacheDirectory = "originalV3"
    }
    
    public enum SupportedVariation {
        case defaultNodes
        case folderLinkNodes
        case publicNodes
    }
    
    private let sdk: MEGASdk
    private let fileManager: FileManager
    private let groupContainer: AppGroupContainer
    private let nodeProvider: any MEGANodeProviderProtocol
    private let appGroupCacheURL: URL
    private let base64HandleProvider: @Sendable (HandleEntity) -> Base64HandleEntity?
    
    public init(
        sdk: MEGASdk,
        fileManager: FileManager,
        nodeProvider: some MEGANodeProviderProtocol,
        base64HandleProvider: @Sendable @escaping (HandleEntity) -> Base64HandleEntity? = { MEGASdk.base64Handle(forHandle: $0) }
    ) {
        self.sdk = sdk
        self.fileManager = fileManager
        self.nodeProvider = nodeProvider
        groupContainer = AppGroupContainer(fileManager: fileManager)
        appGroupCacheURL = groupContainer.url(for: .cache)
        self.base64HandleProvider = base64HandleProvider
    }
        
    public func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL? {
        cachedThumbnail(for: node.base64Handle, type: type)
    }
    
    public func cachedThumbnail(for nodeHandle: HandleEntity, type: ThumbnailTypeEntity) -> URL? {
        guard let base64Handle = base64HandleProvider(nodeHandle) else {
            return nil
        }
        return cachedThumbnail(for: base64Handle, type: type)
    }
    
    public func generateCachingURL(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL {
        generateCachingURL(for: node.base64Handle, type: type)
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
    
    public func generateCachingURL(for base64Handle: Base64HandleEntity, type: ThumbnailTypeEntity) -> URL {
        let directory: String
        switch type {
        case .thumbnail:
            directory = Constants.thumbnailCacheDirectory
        case .preview:
            directory = Constants.previewCacheDirectory
        case .original:
            directory = Constants.originalCacheDirectory
        }
        
        let directoryURL = appGroupCacheURL.appendingPathComponent(directory, isDirectory: true)
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL.appendingPathComponent(base64Handle)
    }
    
    public func cachedPreviewOrOriginalPath(for node: NodeEntity) -> String? {
        let previewFileURL = generateCachingURL(for: node.base64Handle, type: .preview)
        if fileExists(at: previewFileURL) {
            return previewFileURL.path
        }
        
        let originalFileURL = generateCachingURL(for: node.base64Handle, type: .original)
        if fileExists(at: originalFileURL) {
            return originalFileURL.path.append(pathComponent: node.name)
        }
        
        return nil
    }
}

// MARK: - download thumbnail from remote -
extension ThumbnailRepository {
    private func cachedThumbnail(for base64Handle: Base64HandleEntity, type: ThumbnailTypeEntity) -> URL? {
        let url = generateCachingURL(for: base64Handle, type: type)
        return fileExists(at: url) ? url : nil
    }
    
    private func loadThumbnail(for nodeHandle: HandleEntity, base64Handle: Base64HandleEntity, type: ThumbnailTypeEntity) async throws -> URL {
        let url = generateCachingURL(for: base64Handle, type: type)
        if fileExists(at: url) {
            return url
        } else {
            return try await downloadThumbnail(for: nodeHandle, type: type, to: url)
        }
    }
    
    private func downloadThumbnail(for nodeHandle: HandleEntity,
                                   type: ThumbnailTypeEntity,
                                   to url: URL) async throws -> URL {
        switch type {
        case .thumbnail:
            return try await downloadThumbnail(for: nodeHandle, to: url)
        case .preview, .original:
            guard let node = await nodeProvider.node(for: nodeHandle) else {
                throw ThumbnailErrorEntity.nodeNotFound
            }
            return try await downloadPreview(for: node, to: url)
        }
    }
    
    private func downloadThumbnail(for nodeHandle: HandleEntity, to url: URL) async throws -> URL {
        return try await withAsyncThrowingValue { completion in
            sdk.getThumbnailWithNodeHandle(nodeHandle, destinationFilePath: url.path, delegate: ThumbnailRequestDelegate { result in
                completion(result)
            })
        }
    }
    
    private func downloadPreview(for node: MEGANode, to url: URL) async throws -> URL {
        guard node.hasPreview() else {
            throw ThumbnailErrorEntity.noThumbnail(.preview)
        }
        return try await withAsyncThrowingValue { completion in
            sdk.getPreviewNode(node, destinationFilePath: url.path, delegate: ThumbnailRequestDelegate { result in
                completion(result)
            })
        }
    }
    
    private func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }
}

extension ThumbnailRepository {
    
    /// A preconfigured variation of ThumbnailRepository. This uses the .sharedSDK in conjunction with the DefaultMEGANodeProvider. This version is default version to use in most situation with working with a actively logged in session.
    /// - Returns: ThumbnailRepository - Default Configured
    public static func defaultThumbnailRepository() -> Self {
        ThumbnailRepository(
            sdk: .sharedSdk,
            fileManager: .default,
            nodeProvider: DefaultMEGANodeProvider(sdk: .sharedSdk))
    }
    
    /// A preconfigured variation of ThumbnailRepository. This uses the .sharedSDK in conjunction with the PublicAlbumNodeProvider. This version is typically only required to be used when working with Public SetEntities and SetElements.
    /// - Returns: ThumbnailRepository - Public Set and Element Configuration
    public static func publicThumbnailRepository(nodeProvider: PublicAlbumNodeProvider = .shared) -> Self {
        ThumbnailRepository(
            sdk: .sharedSdk,
            fileManager: .default,
            nodeProvider: nodeProvider)
    }
    
    /// A preconfigured variation of ThumbnailRepository. This uses the .sharedFolderLinkSdk in conjunction with the DefaultMEGANodeProvider. This version is typically only required to be used when working with folder links.
    /// - Returns: ThumbnailRepository - Folder Links Configured
    public static func folderLinkThumbnailRepository() -> Self {
        ThumbnailRepository(
            sdk: .sharedFolderLinkSdk,
            fileManager: .default,
            nodeProvider: DefaultMEGANodeProvider(sdk: .sharedSdk))
    }
}
