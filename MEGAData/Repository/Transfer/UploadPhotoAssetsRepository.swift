import Foundation

struct UploadPhotoAssetsRepository: UploadPhotoAssetsRepositoryProtocol {

    private let store: MEGAStore

    init(store: MEGAStore) {
        self.store = store
    }
    
    func upload(assets: [String], toParent parentHandle: MEGAHandle, cancelToken: MEGACancelToken) {
        assets.forEach { identifier in
            store.insertUploadTransfer(withLocalIdentifier: identifier, parentNodeHandle: parentHandle)
        }
        
        Helper.startPendingUploadTransferIfNeeded(with: cancelToken)
    }
}
