import Combine
import Foundation

public protocol MediaDiscoveryUseCaseProtocol {
    var nodeUpdatesPublisher: AnyPublisher<[NodeEntity], Never> { get }
    /// Fetch all nodes directly under the given parent node
    /// - Parameters:
    ///   - parent: Location of nodes to be fetched from.
    ///   - recursive: Determine if the request should fetch nodes from further descendants than the parent node
    ///   - excludeSensitive: Determines if sensitive nodes should be excluded from the result
    /// - Returns: List of NodeEntities located directly under the parent node.
    func nodes(forParent parent: NodeEntity, recursive: Bool, excludeSensitive: Bool) async throws -> [NodeEntity]
    func shouldReload(parentNode: NodeEntity, loadedNodes: [NodeEntity], updatedNodes: [NodeEntity]) -> Bool
}

public class MediaDiscoveryUseCase<T: FilesSearchRepositoryProtocol,
                                   U: NodeUpdateRepositoryProtocol>: MediaDiscoveryUseCaseProtocol {
    private let filesSearchRepository: T
    private let nodeUpdateRepository: U
    
    private let searchAllPhotosString = "*"
    
    public lazy var nodeUpdatesPublisher: AnyPublisher<[NodeEntity], Never> = {
        filesSearchRepository.nodeUpdatesPublisher.handleEvents(receiveSubscription: { [weak self] _ in
            self?.filesSearchRepository.startMonitoringNodesUpdate(callback: nil)
        }, receiveCompletion: { [weak self] _ in
            self?.filesSearchRepository.stopMonitoringNodesUpdate()
        }, receiveCancel: { [weak self] in
            self?.filesSearchRepository.stopMonitoringNodesUpdate()
        })
        .share()
        .eraseToAnyPublisher()
    }()

    public init(filesSearchRepository: T, nodeUpdateRepository: U) {
        self.filesSearchRepository = filesSearchRepository
        self.nodeUpdateRepository = nodeUpdateRepository
    }

    public func nodes(forParent parent: NodeEntity, recursive: Bool, excludeSensitive: Bool) async throws -> [NodeEntity] {
        try await [NodeFormatEntity.photo, .video]
            .async
            .map { [weak self] format -> [NodeEntity] in
                guard let self else { throw  FileSearchResultErrorEntity.noDataAvailable }
                let items: [NodeEntity] = try await filesSearchRepository.search(filter: SearchFilterEntity(
                    searchText: searchAllPhotosString,
                    searchTargetLocation: .parentNode(parent),
                    recursive: recursive,
                    supportCancel: false,
                    sortOrderType: .defaultDesc,
                    formatType: format,
                    sensitiveFilterOption: excludeSensitive ? .nonSensitiveOnly : .disabled))
                return items
            }
            .reduce([NodeEntity]()) { $0 + $1 }
    }
    
    public func shouldReload(parentNode: NodeEntity, loadedNodes: [NodeEntity], updatedNodes: [NodeEntity]) -> Bool {
        guard nodeUpdateRepository.shouldProcessOnNodesUpdate(parentNode: parentNode, childNodes: loadedNodes, updatedNodes: updatedNodes) else { return false }
        
        return isAnyNodeMovedToTrash(nodes: loadedNodes, updatedNodes: updatedNodes) ||
        updatedNodes.containsNewNode() ||
        updatedNodes.hasModifiedAttributes() ||
        updatedNodes.hasModifiedParent()
    }
    
    // MARK: Private
    
    private func isAnyNodeMovedToTrash(nodes: [NodeEntity], updatedNodes: [NodeEntity]) -> Bool {
        let existingNodes = Set(nodes.map { $0.handle })
        return updatedNodes.contains { node in
            if node.changeTypes.contains(.parent),
               existingNodes.contains(node.handle),
               node.nodeType == .rubbish {
                return true
            }
            return false
        }
    }
}
