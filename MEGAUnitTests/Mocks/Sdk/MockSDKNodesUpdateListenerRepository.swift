import Foundation
@testable import MEGA

final class MockSDKNodesUpdateListenerRepository: NSObject, SDKNodesUpdateListenerProtocol {
    private let sdk: MockSdk
    var onUpdateHandler: (([MEGANode]) -> Void)?
    
    init(sdk: MockSdk) {
        self.sdk = sdk
        super.init()
    }
    
    func onNodesUpdate(_ api: MockSdk, nodeList: MEGANodeList?) {
        guard let updatedNodes = nodeList?.toNodeArray() else { return }
        onUpdateHandler?(updatedNodes)
    }
}
