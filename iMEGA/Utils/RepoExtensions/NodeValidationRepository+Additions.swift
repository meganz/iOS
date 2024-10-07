import Foundation
import MEGADomain
import MEGASdk
import MEGASDKRepo

struct OfflineStoreBridge: OfflineStoreBridgeProtocol {
    
    private let store: MEGAStore
    
    init(store: MEGAStore) {
        self.store = store
    }
    
    func isDownloaded(node: MEGANode) -> Bool {
       store.offlineNode(with: node) != nil
    }
}

extension NodeValidationRepository: @retroactive RepositoryProtocol {
    public static var newRepo: Self {
        NodeValidationRepository(
            sdk: .shared,
            offlineStore: OfflineStoreBridge(store: .shareInstance()))
    }
}
