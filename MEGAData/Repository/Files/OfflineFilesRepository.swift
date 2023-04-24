import Foundation
import MEGADomain

final class OfflineFilesRepository: OfflineFilesRepositoryProtocol {
    static var newRepo: OfflineFilesRepository {
        OfflineFilesRepository(store: MEGAStore.shareInstance(), sdk: MEGASdkManager.sharedMEGASdk())
    }
    
    private let store: MEGAStore
    private let sdk: MEGASdk
        
    let offlineURL: URL? = URL(string: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? "")
    
    init(store: MEGAStore, sdk: MEGASdk) {
        self.store = store
        self.sdk = sdk
    }
    
    func createOfflineFile(name: String, for handle: HandleEntity) {
        guard let node = sdk.node(forHandle: handle) else {
            return
        }
        store.insertOfflineNode(node, api: sdk, path: name)
    }
}
