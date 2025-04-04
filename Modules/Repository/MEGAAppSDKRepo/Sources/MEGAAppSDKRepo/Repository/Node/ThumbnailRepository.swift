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
    
    public init(sdk: MEGASdk, fileManager: FileManager, nodeProvider: some MEGANodeProviderProtocol) {
        self.sdk = sdk
        self.fileManager = fileManager
        self.nodeProvider = nodeProvider
        groupContainer = AppGroupContainer(fileManager: fileManager)
        appGroupCacheURL = groupContainer.url(for: .cache)
    }
        
    public func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL? {
        let url = generateCachingURL(for: node.base64Handle, type: type)
        return fileExists(at: url) ? url : nil
    }
    
    public func generateCachingURL(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL {
        generateCachingURL(for: node.base64Handle, type: type)
    }
    
    public func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> URL {
        let url = generateCachingURL(for: node, type: type)
        if fileExists(at: url) {
            return url
        } else {
            return try await downloadThumbnail(for: node, type: type, to: url)
        }
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
    private func downloadThumbnail(for node: NodeEntity,
                                   type: ThumbnailTypeEntity,
                                   to url: URL) async throws -> URL {
        guard let node = await nodeProvider.node(for: node.handle) else {
            throw ThumbnailErrorEntity.nodeNotFound
        }
        
        switch type {
        case .thumbnail:
            return try await downloadThumbnail(for: node, to: url)
        case .preview, .original:
            return try await downloadPreview(for: node, to: url)
        }
    }
    
    private func downloadThumbnail(for node: MEGANode, to url: URL) async throws -> URL {
        guard node.hasThumbnail() else {
            throw ThumbnailErrorEntity.noThumbnail(.thumbnail)
        }
        return try await withAsyncThrowingValue { completion in
            sdk.getThumbnailNode(node, destinationFilePath: url.path, delegate: ThumbnailRequestDelegate { result in
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
