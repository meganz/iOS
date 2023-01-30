import MEGADomain

final class SDKNodesUpdateListenerRepository: NSObject, MEGAGlobalDelegate, NodesUpdateListenerProtocol {
    var onNodesUpdateHandler: (([NodeEntity]) -> Void)?
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
        super.init()
        sdk.add(self)
    }
    
    deinit {
        sdk.remove(self)
    }
    
    func onNodesUpdateHandler(_ api: MEGASdk, nodeList: MEGANodeList?) {
        guard let updatedNodes = nodeList?.toNodeEntities() else { return }
        onNodesUpdateHandler?(updatedNodes)
    }
}
