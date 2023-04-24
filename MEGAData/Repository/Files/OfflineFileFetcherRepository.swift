import MEGADomain

struct OfflineFileFetcherRepository: OfflineFileFetcherRepositoryProtocol {
    static var newRepo: OfflineFileFetcherRepository {
        OfflineFileFetcherRepository(store: MEGAStore.shareInstance())
    }
    
    private let store: MEGAStore
    
    init(store: MEGAStore) {
        self.store = store
    }
    
    func offlineFiles() -> [OfflineFileEntity] {
        guard let offlineNodes = store.fetchOfflineNodes(MEGAQuickAccessWidgetMaxDisplayItems as NSNumber, inRootFolder: true) else {
            return []
        }
        
        return offlineNodes.map {
            $0.toOfflineFileEntity()
        }
    }
    
    func offlineFile(for base64Handle: Base64HandleEntity) -> OfflineFileEntity? {
        if let offlineNode = store.offlineNode(withHandle: base64Handle) {
            return offlineNode.toOfflineFileEntity()
        } else {
            return nil
        }
    }
}
