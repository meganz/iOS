import Combine
import MEGADomain
import MEGASdk

final public class MediaDiscoveryRepository: NSObject, MediaDiscoveryRepositoryProtocol {
    public static var newRepo: MediaDiscoveryRepository {
        MediaDiscoveryRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let updater: PassthroughSubject<[NodeEntity], Never>
    private let sdk: MEGASdk
    
    public let nodesUpdatePublisher: AnyPublisher<[NodeEntity], Never>
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
        
        updater = PassthroughSubject<[NodeEntity], Never>()
        nodesUpdatePublisher = AnyPublisher(updater)
    }
    
    public func loadNodes(forParent parent: NodeEntity) async throws -> [NodeEntity] {
        guard let megaNode = parent.toMEGANode(in: sdk) else { return [] }
        
        return try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else { continuation.resume(throwing: MediaDiscoveryErrorEntity.generic); return }
            
            let nodeList = sdk.children(forParent: megaNode, order: MEGASortOrderType.modificationDesc.rawValue)
            let nodes = nodeList.toNodeEntities()
            
            continuation.resume(returning: nodes)
        }
    }
    
    public func startMonitoringNodesUpdate() {
        sdk.add(self)
    }
    
    public func stopMonitoringNodesUpdate() {
        sdk.remove(self)
    }
}

extension MediaDiscoveryRepository: MEGAGlobalDelegate {
    public func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        updater.send(nodeList?.toNodeEntities() ?? [])
    }
}
