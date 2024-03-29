import Foundation
import MEGADomain

struct UploadPhotoAssetsRepository: UploadPhotoAssetsRepositoryProtocol {

    private let store: MEGAStore

    init(store: MEGAStore) {
        self.store = store
    }
    
    func upload(assets: [String], toParent parentHandle: HandleEntity) {
        assets.forEach { identifier in
            store.insertUploadTransfer(withLocalIdentifier: identifier, parentNodeHandle: parentHandle)
        }
        
        Helper.startPendingUploadTransferIfNeeded()
    }
}
