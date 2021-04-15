import Foundation

struct UploadFromAlbum {

    var upload: (
        _ photoAssets: [String],
        _ parentNodeHandle: MEGAHandle
    ) -> Void
}

extension UploadFromAlbum {
    
    static var live: Self {
        let megaStore = MEGAStore.shareInstance()
        
        return Self { assets, parentNodeHandle in
            assets.forEach { identifier in
                megaStore.insertUploadTransfer(withLocalIdentifier: identifier, parentNodeHandle: parentNodeHandle)
            }
            Helper.startPendingUploadTransferIfNeeded()
        }
    }
}
