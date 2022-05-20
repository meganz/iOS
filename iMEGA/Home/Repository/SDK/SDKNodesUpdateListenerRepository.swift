protocol SDKNodesUpdateListenerProtocol {
    var onUpdateHandler: (([MEGANode]) -> Void)? { get set }
}

final class SDKNodesUpdateListenerRepository: NSObject, MEGAGlobalDelegate, SDKNodesUpdateListenerProtocol {
    private let sdk: MEGASdk
    var onUpdateHandler: (([MEGANode]) -> Void)?
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
        super.init()
        sdk.add(self)
    }
    
    deinit {
        sdk.remove(self)
    }
    
    func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        guard let updatedNodes = nodeList?.toNodeArray() else { return }
        onUpdateHandler?(updatedNodes)
    }
}
