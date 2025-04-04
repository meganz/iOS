import MEGADomain
import MEGASdk

public struct NodeValidationRepository: NodeValidationRepositoryProtocol {

    private let sdk: MEGASdk
    private let offlineStore: any OfflineStoreBridgeProtocol
    
    public init(sdk: MEGASdk, offlineStore: some OfflineStoreBridgeProtocol) {
        self.sdk = sdk
        self.offlineStore = offlineStore
    }
    
    public func hasVersions(nodeHandle: HandleEntity) -> Bool {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            return false
        }
        
        return sdk.hasVersions(for: node)
    }
    
    public func isDownloaded(nodeHandle: HandleEntity) -> Bool {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            return false
        }
        
        return offlineStore.isDownloaded(node: node)
    }
    
    public func isInRubbishBin(nodeHandle: HandleEntity) -> Bool {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            return false
        }
        
        return sdk.isNode(inRubbish: node)
    }
    
    public func isFileNode(handle: HandleEntity) -> Bool {
        guard let node = sdk.node(forHandle: handle) else {
            return false
        }
        
        return node.isFile()
    }
    
    public func isNode(_ node: NodeEntity, descendantOf ancestor: NodeEntity) async -> Bool {
        let isDescendantNodeTask = Task.detached { () -> Bool in
            guard let parent = ancestor.toMEGANode(in: sdk) else {
                return false
            }
            
            var megaNode = node.toMEGANode(in: sdk)
            while let node = megaNode {
                if node == parent {
                    return true
                }
                megaNode = sdk.parentNode(for: node)
            }
            return false
        }
        return await isDescendantNodeTask.value
    }
}
