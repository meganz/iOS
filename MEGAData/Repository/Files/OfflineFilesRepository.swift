import Foundation
import MEGADomain

final class OfflineFilesRepository: OfflineFilesRepositoryProtocol {
    static var newRepo: OfflineFilesRepository {
        OfflineFilesRepository(store: MEGAStore.shareInstance(), sdk: MEGASdk.shared)
    }
    
    private let store: MEGAStore
    private let sdk: MEGASdk
    let offlineURL: URL?
    
    init(
        store: MEGAStore,
        offlineURL: URL? = URL(string: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""),
        sdk: MEGASdk
    ) {
        self.store = store
        self.sdk = sdk
        self.offlineURL =  offlineURL
    }
    
    func createOfflineFile(name: String, for handle: HandleEntity) {
        guard let node = sdk.node(forHandle: handle) else {
            return
        }
        store.insertOfflineNode(node, api: sdk, path: name)
    }
    
    func removeAllStoredOfflineNodes() {
        store.removeAllOfflineNodes()
    }
}
