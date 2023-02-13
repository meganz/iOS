import MEGADomain

public struct MockTransfersRepository: TransfersRepositoryProtocol {
    public static var newRepo: MockTransfersRepository {
        MockTransfersRepository()
    }

    public func transfers() -> [TransferEntity] {
        [TransferEntity(type: .download, path: "/Documents"), TransferEntity(type: .upload, path: "uploads"), TransferEntity(type: .download, path: "tmp")]
    }
    
    public func downloadTransfers() -> [TransferEntity] {
        [TransferEntity(type: .download, path: "/Documents"), TransferEntity(type: .download, path: "tmp")]
    }
    
    public func uploadTransfers() -> [TransferEntity] {
        [TransferEntity(type: .upload, path: "uploads"), TransferEntity(type: .upload, path: "tmp")]
    }
    
    public func completedTransfers() -> [TransferEntity] {
        [TransferEntity(type: .upload, path: "uploads"), TransferEntity(type: .upload, path: "tmp"),
         TransferEntity(type: .download, path: "/Documents"), TransferEntity(type: .download, path: "tmp")]
    }
    
    public func isExportFileTransfer(_ transfer: MEGADomain.TransferEntity) -> Bool {
        transfer.appData?.contains(">exportFile") ?? false
    }
    
    public func isSaveToPhotosAppTransfer(_ transfer: MEGADomain.TransferEntity) -> Bool {
        transfer.appData?.contains(">SaveInPhotosApp") ?? false
    }
}
