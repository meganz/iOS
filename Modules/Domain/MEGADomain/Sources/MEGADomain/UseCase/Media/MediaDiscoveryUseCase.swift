import Combine
import Foundation

public protocol MediaDiscoveryUseCaseProtocol {
    var nodeUpdatesPublisher: AnyPublisher<[NodeEntity], Never> { get }
    func nodes(forParent parent: NodeEntity) async throws -> [NodeEntity]
    func shouldReload(parentNode: NodeEntity, loadedNodes: [NodeEntity], updatedNodes: [NodeEntity]) -> Bool
}

public class MediaDiscoveryUseCase<T: FilesSearchRepositoryProtocol,
                                   U: NodeUpdateRepositoryProtocol>: MediaDiscoveryUseCaseProtocol {
    private let filesSearchRepository: T
    private let nodeUpdateRepository: U
    
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

    public func nodes(forParent parent: NodeEntity) async throws -> [NodeEntity] {
        async let photos = filesSearchRepository.search(string: nil, parent: parent, supportCancel: false, sortOrderType: .defaultDesc, formatType: .photo)
        async let videos = filesSearchRepository.search(string: nil, parent: parent, supportCancel: false, sortOrderType: .defaultDesc, formatType: .video)

        return try await photos + videos
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
