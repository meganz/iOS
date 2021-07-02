import Foundation

struct AccountRepository: AccountRepositoryProtocol {
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func totalNodesCount() -> UInt {
        sdk.totalNodes
    }
}
