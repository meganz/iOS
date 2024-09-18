public protocol NodesRemovedUseCaseProtocol: Sendable {
    /// Removes the cached files (thumbnail, preview and original image saved when opening a node) associated with the nodes that have been removed.
    func removeCachedFiles() async
}

public struct NodesRemovedUseCase: NodesRemovedUseCaseProtocol {
    private let thumbnailRepository: any ThumbnailRepositoryProtocol
    private let fileRepository: any FileSystemRepositoryProtocol
    private let removedNodes: [NodeEntity]
    
    public init(
        thumbnailRepository: some ThumbnailRepositoryProtocol,
        fileRepository: some FileSystemRepositoryProtocol,
        removedNodes: [NodeEntity]
    ) {
        self.thumbnailRepository = thumbnailRepository
        self.fileRepository = fileRepository
        self.removedNodes = removedNodes
    }
    
    public func removeCachedFiles() async {
        let thumbnailURLs = removedNodes
            .compactMap { thumbnailRepository.cachedThumbnail(for: $0, type: .thumbnail) }
        
        let previewURLs = removedNodes
            .compactMap { thumbnailRepository.cachedThumbnail(for: $0, type: .preview) }
        
        let originalURLs = removedNodes
            .compactMap { thumbnailRepository.cachedThumbnail(for: $0, type: .original) }
        
        let allURLs = thumbnailURLs + previewURLs + originalURLs
        
        allURLs.forEach { url in
            try? fileRepository.removeItem(at: url)
        }
    }
}
