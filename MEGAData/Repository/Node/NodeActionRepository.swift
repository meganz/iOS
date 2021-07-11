struct NodeActionRepository: NodeActionRepositoryProtocol {
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func nodeAccessLevel(nodeHandle: MEGAHandle) -> NodeAccessTypeEntity {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            return .unknown
        }
        return NodeAccessTypeEntity(shareAccess: sdk.accessLevel(for: node)) ?? .unknown
    }
    
    func downloadToOffline(nodeHandle: MEGAHandle) {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            return
        }
        node.mnz_downloadNode()
    }
}
