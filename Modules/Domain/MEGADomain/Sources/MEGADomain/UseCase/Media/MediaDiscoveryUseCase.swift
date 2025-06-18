import Foundation
import MEGASwift

public protocol MediaDiscoveryUseCaseProtocol: Sendable {
    var nodeUpdates: AnyAsyncSequence<[NodeEntity]> { get }
    /// Fetch all nodes directly under the given parent node
    /// - Parameters:
    ///   - parent: Location of nodes to be fetched from.
    ///   - recursive: Determine if the request should fetch nodes from further descendants than the parent node
    ///   - excludeSensitive: Determines if sensitive nodes should be excluded from the result
    /// - Returns: List of NodeEntities located directly under the parent node.
    func nodes(forParent parent: NodeEntity, recursive: Bool, excludeSensitive: Bool) async throws -> [NodeEntity]
    func shouldReload(parentNode: NodeEntity, loadedNodes: [NodeEntity], updatedNodes: [NodeEntity]) -> Bool
}

public final class MediaDiscoveryUseCase<T: FilesSearchRepositoryProtocol,
                                   U: NodeUpdateRepositoryProtocol>: MediaDiscoveryUseCaseProtocol {
    private let filesSearchRepository: T
    private let nodeUpdateRepository: U
    
    private let searchAllPhotosString = ""
    
    private let isFolderLink: Bool
    
    public init(filesSearchRepository: T, nodeUpdateRepository: U, isFolderLink: Bool = false) {
        self.filesSearchRepository = filesSearchRepository
        self.nodeUpdateRepository = nodeUpdateRepository
        self.isFolderLink = isFolderLink
    }

    public var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        if isFolderLink {
            filesSearchRepository.folderLinkNodeUpdates
        } else {
            filesSearchRepository.nodeUpdates
        }
    }
    
    public func nodes(forParent parent: NodeEntity, recursive: Bool, excludeSensitive: Bool) async throws -> [NodeEntity] {
        try await [NodeFormatEntity.photo, .video]
            .async
            .map { [weak self] format -> [NodeEntity] in
                guard let self else { throw  FileSearchResultErrorEntity.noDataAvailable }
                let sensitiveFilterOption: SearchFilterEntity.SensitiveFilterOption = excludeSensitive ? .nonSensitiveOnly : .disabled
                
                let filter: SearchFilterEntity = if recursive {
                    .recursive(
                        searchText: searchAllPhotosString,
                        searchTargetLocation: .parentNode(parent),
                        supportCancel: false,
                        sortOrderType: .defaultDesc,
                        formatType: format,
                        sensitiveFilterOption: sensitiveFilterOption,
                        nodeTypeEntity: .file)
                } else {
                    .nonRecursive(
                        searchText: searchAllPhotosString,
                        searchTargetNode: parent,
                        supportCancel: false,
                        sortOrderType: .defaultDesc,
                        formatType: format,
                        sensitiveFilterOption: sensitiveFilterOption,
                        nodeTypeEntity: .file)
                }
                return try await filesSearchRepository.search(filter: filter)
            }
            .reduce([NodeEntity]()) { $0 + $1 }
    }
    
    public func shouldReload(parentNode: NodeEntity, loadedNodes: [NodeEntity], updatedNodes: [NodeEntity]) -> Bool {
        nodeUpdateRepository.shouldProcessOnNodesUpdate(parentNode: parentNode, childNodes: loadedNodes, updatedNodes: updatedNodes)
    }
}
