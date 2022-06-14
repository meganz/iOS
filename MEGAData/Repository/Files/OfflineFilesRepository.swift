import Foundation

extension OfflineFilesRepository {
    static let `default` = OfflineFilesRepository(store: MEGAStore.shareInstance(), sdk: MEGASdkManager.sharedMEGASdk())
}

class OfflineFilesRepository: OfflineFilesRepositoryProtocol {
    
    private let store: MEGAStore
    private let sdk: MEGASdk
    
    let relativeOfflinePath: String = URL(string: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])?.lastPathComponent ?? ""
    
    init(store: MEGAStore, sdk: MEGASdk) {
        self.store = store
        self.sdk = sdk
    }
    
    func offlineFiles() -> [OfflineFileEntity] {
        guard let offlineNodes = store.fetchOfflineNodes(MEGAQuickAccessWidgetMaxDisplayItems as NSNumber, inRootFolder: true) else {
            return []
        }
        
        return offlineNodes.map {
            OfflineFileEntity(with: $0)
        }
    }
    
    func offlineFile(for base64Handle: MEGABase64Handle) -> OfflineFileEntity? {
        if let offlineNode = store.offlineNode(withHandle: base64Handle) {
            return OfflineFileEntity(with: offlineNode)
        } else {
            return nil
        }
    }
    
    func createOfflineFile(name: String, for handle: MEGAHandle) {
        guard let node = sdk.node(forHandle: handle) else {
            return
        }
        store.insertOfflineNode(node, api: sdk, path: name)
    }
}
