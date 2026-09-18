import Foundation
import MEGAAppSDKRepo
import MEGADomain

final class OfflineFilesRepository: OfflineFilesRepositoryProtocol {
    static var newRepo: OfflineFilesRepository {
        OfflineFilesRepository(
            store: MEGAStore.shareInstance(),
            sdk: MEGASdk.shared,
            folderSizeCalculator: FolderSizeCalculator()
        )
    }
    
    private let store: MEGAStore
    private let sdk: MEGASdk
    private let folderSizeCalculator: any FolderSizeCalculatingProtocol
    let offlineURL: URL?
    
    init(
        store: MEGAStore,
        offlineURL: URL? = URL(string: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""),
        sdk: MEGASdk,
        folderSizeCalculator: some FolderSizeCalculatingProtocol
    ) {
        self.store = store
        self.sdk = sdk
        self.offlineURL =  offlineURL
        self.folderSizeCalculator = folderSizeCalculator
    }
    
    func createOfflineFile(name: String, for handle: HandleEntity) {
        guard let node = sdk.node(forHandle: handle) else {
            return
        }
        // The SDK completes an already-downloaded transfer with API_OK, so this runs again
        // for a node already saved at this path. Same node, same path means the same row.
        guard !store.fetchOfflineNodes(withPath: name).contains(where: { $0.base64Handle == node.base64Handle }) else {
            return
        }
        store.insertOfflineNode(node, api: sdk, path: name)
    }
    
    func removeAllStoredOfflineNodes() {
        store.removeAllOfflineNodes()
    }
    
    func offlineSize() -> UInt64 {
        guard let offlineURL else { return 0 }
        
        return folderSizeCalculator.folderSize(at: offlineURL)
    }
}
