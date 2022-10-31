import MEGADomain
import Combine

final class MediaDiscoveryRepository: NSObject, MediaDiscoveryRepositoryProtocol {
    static var newRepo: MediaDiscoveryRepository {
        MediaDiscoveryRepository(sdk: MEGASdkManager.sharedMEGASdk())
    }
    
    private let updater: PassthroughSubject<[NodeEntity], Never>
    private let sdk: MEGASdk
    
    let nodesUpdatePublisher: AnyPublisher<[NodeEntity], Never>
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
        
        updater = PassthroughSubject<[NodeEntity], Never>()
        nodesUpdatePublisher = AnyPublisher(updater)
    }
    
    func loadNodes(forParent parent: NodeEntity) async throws -> [NodeEntity] {
        guard let megaNode = parent.toMEGANode(in: sdk) else { return [] }
        
        return try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else { continuation.resume(throwing: MediaDiscoveryErrorEntity.generic); return }
            
            let nodeList = sdk.children(forParent: megaNode, order: MEGASortOrderType.modificationDesc.rawValue)
            let nodes = nodeList.toNodeEntities()
            
            continuation.resume(returning: nodes)
        }
    }
    
    func startMonitoringNodesUpdate() {
        sdk.add(self)
    }
    
    func stopMonitoringNodesUpdate() {
        sdk.remove(self)
    }
}

extension MediaDiscoveryRepository: MEGAGlobalDelegate {
    func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        updater.send(nodeList?.toNodeEntities() ?? [])
    }
}
