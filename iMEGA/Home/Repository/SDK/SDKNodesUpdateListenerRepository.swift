import Combine
import MEGADomain

final class SDKNodesUpdateListenerRepository: NSObject, NodesUpdateListenerProtocol {
    static var newRepo = SDKNodesUpdateListenerRepository(sdk: MEGASdk.shared)
    
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
}

extension SDKNodesUpdateListenerRepository: MEGAGlobalDelegate {
    func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        guard let updatedNodes = nodeList?.toNodeEntities() else { return }
        onNodesUpdateHandler?(updatedNodes)
    }
}
