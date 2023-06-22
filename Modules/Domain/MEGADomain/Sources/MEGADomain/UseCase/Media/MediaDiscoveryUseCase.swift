import Combine
import Foundation

public protocol MediaDiscoveryUseCaseProtocol {
    var nodeUpdatesPublisher: AnyPublisher<[NodeEntity], Never> { get }
    func nodes(forParent parent: NodeEntity) async throws -> [NodeEntity]
    func shouldReload(parentNode: NodeEntity, loadedNodes: [NodeEntity], updatedNodes: [NodeEntity]) -> Bool
}

public class MediaDiscoveryUseCase<T: MediaDiscoveryRepositoryProtocol,
                                   U: NodeUpdateRepositoryProtocol>: MediaDiscoveryUseCaseProtocol {
    private let mediaDiscoveryRepository: T
    private let nodeUpdateRepository: U
    
    public lazy var nodeUpdatesPublisher: AnyPublisher<[NodeEntity], Never> = {
        mediaDiscoveryRepository.nodesUpdatePublisher.handleEvents(receiveSubscription: { [weak self] _ in
            self?.mediaDiscoveryRepository.startMonitoringNodesUpdate()
        }, receiveCompletion: { [weak self] _ in
            self?.mediaDiscoveryRepository.stopMonitoringNodesUpdate()
        }, receiveCancel: { [weak self] in
            self?.mediaDiscoveryRepository.stopMonitoringNodesUpdate()
        })
        .share()
        .eraseToAnyPublisher()
    }()

    public init(mediaDiscoveryRepository: T, nodeUpdateRepository: U) {
        self.mediaDiscoveryRepository = mediaDiscoveryRepository
        self.nodeUpdateRepository = nodeUpdateRepository
    }

    public func nodes(forParent parent: NodeEntity) async throws -> [NodeEntity] {
        try await mediaDiscoveryRepository.loadNodes(forParent: parent)
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
