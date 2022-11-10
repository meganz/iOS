import Foundation
@testable import MEGA

final class MockSDKNodesUpdateListenerRepository: NSObject, MEGAGlobalDelegate, SDKNodesUpdateListenerProtocol {
    private let sdk: MockSdk
    var onUpdateHandler: (([MEGANode]) -> Void)?
    
    init(sdk: MockSdk) {
        self.sdk = sdk
        super.init()
        sdk.add(self)
    }
    
    deinit {
        sdk.remove(self)
    }
    
    func onNodesUpdate(_ api: MockSdk, nodeList: MEGANodeList?) {
        guard let updatedNodes = nodeList?.toNodeArray() else { return }
        onUpdateHandler?(updatedNodes)
    }
}
