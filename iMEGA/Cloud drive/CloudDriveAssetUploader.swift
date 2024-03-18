import Foundation

struct CloudDriveAssetUploader: AssetUploader {
    private let store: MEGAStore

    init(store: MEGAStore = .shareInstance()) {
        self.store = store
    }

    func upload(assets: [PHAsset], to handle: MEGAHandle) {
        guard !assets.isEmpty else { return }

        assets.forEach { asset in
            store.insertUploadTransfer(
                withLocalIdentifier: asset.localIdentifier,
                parentNodeHandle: handle
            )
        }

        Helper.startPendingUploadTransferIfNeeded()
    }
}
